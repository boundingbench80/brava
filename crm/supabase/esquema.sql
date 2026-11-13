create extension if not exists pgcrypto;
do $$ begin create type public.etapa_pedido as enum ('consulta','cotizado','pago_verificar','produccion','listo','entregado','perdido'); exception when duplicate_object then null; end $$;
create table if not exists public.equipo(email text primary key);
create table if not exists public.cliente(id uuid primary key default gen_random_uuid(),nombre text not null,telefono text not null unique check (telefono ~ '^[67][0-9]{7}$'),zona text,canal_origen text,fecha_alta timestamptz not null default now(),nacimiento_aprox text,notas text);
create table if not exists public.pedido(id uuid primary key default gen_random_uuid(),codigo text not null unique,cliente_id uuid not null references public.cliente(id),fecha timestamptz not null default now(),etapa public.etapa_pedido not null default 'consulta',entrega text not null check(entrega in ('recojo','delivery')),zona text,costo_delivery numeric(10,2) not null default 0,total numeric(10,2) not null default 0,pagado boolean not null default false,fecha_pago timestamptz,motivo_perdida text,canal text,referencia text);
create table if not exists public.item(id uuid primary key default gen_random_uuid(),pedido_id uuid not null references public.pedido(id) on delete cascade,prenda text not null,color text not null,talla text not null,diseno text,departamento text,ubicacion text not null,tintas integer not null check(tintas in (1,2)),cantidad integer not null check(cantidad between 1 and 30),precio_unit numeric(10,2) not null);
create table if not exists public.evento(id uuid primary key default gen_random_uuid(),pedido_id uuid not null references public.pedido(id) on delete cascade,de_etapa public.etapa_pedido,a_etapa public.etapa_pedido not null,fecha_hora timestamptz not null default now(),usuario text not null);
create table if not exists public.sku(id uuid primary key default gen_random_uuid(),prenda text not null,color text not null,talla text not null,stock integer not null default 0,minimo integer not null default 3,costo_unit numeric(10,2) not null default 0,proveedor text,unique(prenda,color,talla));
create table if not exists public.insumo(id uuid primary key default gen_random_uuid(),nombre text not null unique,unidad text not null,stock numeric(10,2) not null default 0,minimo numeric(10,2) not null default 1,consumo_por_prenda numeric(10,2) not null default 0);
create table if not exists public.movimiento(id uuid primary key default gen_random_uuid(),sku_id uuid references public.sku(id),insumo_id uuid references public.insumo(id),tipo text not null check(tipo in ('entrada','salida','ajuste')),cantidad numeric(10,2) not null check(cantidad>0),fecha timestamptz not null default now(),pedido_id uuid references public.pedido(id),check(num_nonnulls(sku_id,insumo_id)=1));
create table if not exists public.catalogo_prenda(prenda text primary key,base numeric(10,2) not null);
insert into public.catalogo_prenda values('canguro',180),('polera',90),('gorra',70) on conflict(prenda) do update set base=excluded.base;
create table if not exists public.catalogo_recargo(clave text primary key,monto numeric(10,2) not null);
insert into public.catalogo_recargo values('pecho',15),('espalda',30),('ambos',40),('frente',20),('segunda_tinta',10),('delivery',15) on conflict(clave) do update set monto=excluded.monto;
create or replace function public.registrar_evento_pedido() returns trigger language plpgsql security definer set search_path=public as $$ begin if tg_op='INSERT' or new.etapa is distinct from old.etapa then insert into evento(pedido_id,de_etapa,a_etapa,usuario) values(new.id,case when tg_op='INSERT' then null else old.etapa end,new.etapa,coalesce(auth.email(),'web')); end if; return new; end $$;
drop trigger if exists pedido_evento on public.pedido;
create trigger pedido_evento after insert or update of etapa on public.pedido for each row execute function public.registrar_evento_pedido();
create or replace function public.ajustar_stock_pedido() returns trigger language plpgsql security definer set search_path=public as $$ declare it record; delta integer; begin if (tg_op='INSERT' and new.etapa='produccion') or (tg_op='UPDATE' and old.etapa is distinct from new.etapa and new.etapa='produccion') then delta:= -1; elsif tg_op='UPDATE' and old.etapa='produccion' and new.etapa in ('consulta','cotizado','pago_verificar','perdido') then delta:=1; else return new; end if; for it in select * from item where pedido_id=new.id loop update sku set stock=stock+(delta*it.cantidad) where prenda=it.prenda and color=it.color and talla=it.talla; if not found then raise exception 'SKU inexistente: % / % / %',it.prenda,it.color,it.talla; end if; insert into movimiento(sku_id,tipo,cantidad,pedido_id) select id,case when delta<0 then 'salida' else 'entrada' end,it.cantidad,new.id from sku where prenda=it.prenda and color=it.color and talla=it.talla; end loop; return new; end $$;
drop trigger if exists pedido_stock on public.pedido;
create trigger pedido_stock after insert or update of etapa on public.pedido for each row execute function public.ajustar_stock_pedido();
revoke all on function public.registrar_evento_pedido() from public,anon,authenticated;
revoke all on function public.ajustar_stock_pedido() from public,anon,authenticated;
create or replace function public.registrar_pedido(p jsonb) returns jsonb language plpgsql security definer set search_path=public as $$
declare tel text; nm text; cod text; cli uuid; pid uuid; it jsonb; n integer:=0; base numeric; rec numeric; delivery_fee numeric; unit numeric; subtotal numeric:=0; total_calc numeric; ep etapa_pedido;
begin
 nm:=btrim(p->>'nombre'); tel:=regexp_replace(coalesce(p->>'telefono',''),'[^0-9]','','g'); cod:=nullif(btrim(p->>'codigo'),'');
 if nm is null or char_length(nm) not between 2 and 80 then raise exception 'Nombre debe tener entre 2 y 80 caracteres'; end if;
 if tel !~ '^[67][0-9]{7}$' then raise exception 'Teléfono debe tener 8 dígitos y empezar en 6 o 7'; end if;
 if cod is null then raise exception 'Falta el código del pedido'; end if;
 perform pg_advisory_xact_lock(hashtext(cod));
 perform pg_advisory_xact_lock(hashtext(tel));
 select id into pid from pedido where codigo=cod; if pid is not null then select jsonb_build_object('codigo',codigo,'total',total,'etapa',etapa) into p from pedido where id=pid; return p; end if;
 if (select count(*) from pedido where cliente_id in (select id from cliente where telefono=tel) and fecha>now()-interval '60 minutes')>=5 then raise exception 'Límite de 5 pedidos por teléfono cada 60 minutos'; end if;
 if jsonb_typeof(p->'items') is distinct from 'array' or coalesce(jsonb_array_length(p->'items'),0) not between 1 and 20 then raise exception 'El pedido debe tener entre 1 y 20 ítems'; end if;
 if p->>'entrega' not in ('recojo','delivery') then raise exception 'Entrega debe ser recojo o delivery'; end if;
 insert into cliente(nombre,telefono,zona,canal_origen) values(nm,tel,p->>'zona',p->>'canal') on conflict(telefono) do update set nombre=excluded.nombre,zona=excluded.zona returning id into cli;
 for it in select value from jsonb_array_elements(p->'items') loop
  n:=n+1; if coalesce((it->>'cantidad')::integer,0) not between 1 and 30 then raise exception 'Cantidad del ítem % debe estar entre 1 y 30',n; end if;
  if not exists(select 1 from catalogo_prenda where prenda=it->>'prenda') or it->>'color' not in ('blanco','negro','marino','pacay') or (it->>'prenda'='gorra' and it->>'talla'<>'U') or (it->>'prenda'<>'gorra' and it->>'talla' not in ('S','M','L','XL')) then raise exception 'Prenda, color o talla inválidos en ítem %',n; end if;
  if nullif(it->>'departamento','') is not null and it->>'departamento' not in ('cochabamba','lapaz','santacruz','oruro','potosi','chuquisaca','tarija','beni','pando') then raise exception 'Departamento inválido en ítem %',n; end if;
  if it->>'ubicacion' not in ('pecho','espalda','ambos','frente') or (it->>'prenda'='gorra' and it->>'ubicacion'<>'frente') or (it->>'prenda'<>'gorra' and it->>'ubicacion'='frente') then raise exception 'Ubicación inválida en ítem %',n; end if;
  if coalesce(it->>'tintas','') not in ('1','2') then raise exception 'Tintas debe ser 1 o 2 en ítem %',n; end if;
  select c.base into base from catalogo_prenda c where c.prenda=it->>'prenda'; select monto into rec from catalogo_recargo where clave=it->>'ubicacion';
  if rec is null then raise exception 'Recargo inválido en ítem %',n; end if;
  unit:=base+rec+case when (it->>'tintas')::integer=2 then (select monto from catalogo_recargo where clave='segunda_tinta') else 0 end;
  subtotal:=subtotal+unit*(it->>'cantidad')::integer;
 end loop;
 select monto into delivery_fee from catalogo_recargo where clave='delivery'; if delivery_fee is null then raise exception 'Falta el recargo de delivery en catalogo_recargo'; end if;
 total_calc:=subtotal+case when p->>'entrega'='delivery' then delivery_fee else 0 end;
 -- El navegador solo puede declarar que el cliente reportó el pago. El equipo debe validar y marcarlo como pagado.
 ep:=case when coalesce((p->>'pagado')::boolean,false) then 'pago_verificar'::etapa_pedido else 'consulta'::etapa_pedido end;
 insert into pedido(codigo,cliente_id,etapa,entrega,zona,referencia,costo_delivery,total,pagado,fecha_pago,canal) values(cod,cli,ep,case when p->>'entrega'='delivery' then 'delivery' else 'recojo' end,p->>'zona',p->>'referencia',case when p->>'entrega'='delivery' then delivery_fee else 0 end,total_calc,false,null,p->>'canal') returning id into pid;
 for it in select value from jsonb_array_elements(p->'items') loop
  select c.base into base from catalogo_prenda c where c.prenda=it->>'prenda'; select monto into rec from catalogo_recargo where clave=it->>'ubicacion';
  unit:=base+rec+case when (it->>'tintas')::integer=2 then 10 else 0 end;
  insert into item(pedido_id,prenda,color,talla,diseno,departamento,ubicacion,tintas,cantidad,precio_unit) values(pid,it->>'prenda',it->>'color',it->>'talla',it->>'diseno',it->>'departamento',it->>'ubicacion',(it->>'tintas')::integer,(it->>'cantidad')::integer,unit);
 end loop;
 return jsonb_build_object('codigo',cod,'total',total_calc,'etapa',ep);
end $$;
create or replace function public.registrar_entrada(p_sku uuid,p_insumo uuid,p_cantidad numeric) returns void language plpgsql security definer set search_path=public as $$ begin if not public.es_equipo() then raise exception 'Sin acceso'; end if; if p_cantidad<=0 or num_nonnulls(p_sku,p_insumo)<>1 then raise exception 'Entrada inválida'; end if; if p_sku is not null then update sku set stock=stock+p_cantidad where id=p_sku; else update insumo set stock=stock+p_cantidad where id=p_insumo; end if; insert into movimiento(sku_id,insumo_id,tipo,cantidad) values(p_sku,p_insumo,'entrada',p_cantidad); end $$;
create or replace view public.v_ventas_mes with (security_invoker=true) as
with orders as (select to_char(date_trunc('month',fecha),'YYYY-MM') mes,count(*) filter(where pagado) pedidos,count(*) consultas,count(distinct cliente_id) filter(where pagado) clientes,coalesce(sum(total) filter(where pagado),0) ingresos from pedido group by 1),
items as (select to_char(date_trunc('month',p.fecha),'YYYY-MM') mes,coalesce(sum(i.cantidad*i.precio_unit) filter(where i.prenda='canguro'),0) canguro,coalesce(sum(i.cantidad*i.precio_unit) filter(where i.prenda='polera'),0) polera,coalesce(sum(i.cantidad*i.precio_unit) filter(where i.prenda='gorra'),0) gorra,coalesce(sum(i.cantidad),0) unidades from pedido p join item i on i.pedido_id=p.id where p.pagado group by 1)
select o.mes,o.pedidos,o.consultas,o.clientes,o.ingresos,coalesce(i.canguro,0) canguro,coalesce(i.polera,0) polera,coalesce(i.gorra,0) gorra,coalesce(i.unidades,0) unidades from orders o left join items i using(mes);
create or replace view public.v_rfm with (security_invoker=true) as
with raw as (select cliente_id,count(*) frecuencia,sum(total) monto,max(fecha) ultima_compra,extract(day from now()-max(fecha))::integer recencia from pedido where pagado group by cliente_id),
scored as (select *,ntile(5) over(order by recencia) r_score,ntile(5) over(order by frecuencia) f_score,ntile(5) over(order by monto) m_score from raw)
select *,case when r_score>=4 and f_score>=4 then 'Campeones' when f_score>=3 then 'Leales' when frecuencia=1 and r_score>=4 then 'Nuevos' when r_score<=2 and f_score>=2 then 'En riesgo' when r_score<=2 then 'Dormidos' else 'Ocasionales' end segmento from scored;
create or replace view public.v_abc with (security_invoker=true) as
with raw as (select cliente_id,sum(total) ingreso from pedido where pagado group by cliente_id), ranked as (select *,sum(ingreso) over(order by ingreso desc rows unbounded preceding)/nullif(sum(ingreso) over(),0) acumulado,percent_rank() over(order by ingreso desc) percentil from raw)
select *,case when acumulado<=0.8+ingreso/nullif(sum(ingreso) over(),0) then 'A' when acumulado<=0.95+ingreso/nullif(sum(ingreso) over(),0) then 'B' else 'C' end clase from ranked;
create or replace view public.v_cohortes with (security_invoker=true) as
with paid as (select cliente_id,date_trunc('month',min(fecha))::date cohorte from pedido where pagado group by cliente_id), activity as (select p.cliente_id,c.cohorte,date_trunc('month',p.fecha)::date mes from pedido p join paid c using(cliente_id) where p.pagado), counts as (select cohorte,mes,count(distinct cliente_id) compradores from activity group by cohorte,mes), bases as (select cohorte,count(*) clientes from paid group by cohorte)
select c.cohorte,c.mes,b.clientes,((extract(year from c.mes)-extract(year from c.cohorte))*12+extract(month from c.mes)-extract(month from c.cohorte))::integer meses_desde_inicio,100.0*c.compradores/nullif(b.clientes,0) porcentaje_retorno from counts c join bases b using(cohorte);
create or replace view public.v_embudo with (security_invoker=true) as
select x.etapa,x.orden,x.pedidos,100.0*x.pedidos/nullif((select count(*) from pedido),0) porcentaje from
(select 'Consulta'::text etapa,1 orden,count(*) pedidos from pedido union all select 'Cotizado',2,count(distinct p.id) from pedido p where p.etapa in ('cotizado','pago_verificar','produccion','listo','entregado') or exists(select 1 from evento e where e.pedido_id=p.id and e.a_etapa='cotizado') union all select 'Pagado',3,count(*) from pedido where pagado union all select 'Entregado',4,count(*) from pedido where pagado and etapa='entregado') x;
create or replace view public.v_cobertura_sku with (security_invoker=true) as
select s.id,s.prenda,s.color,s.talla,s.stock,s.minimo,coalesce(sum(i.cantidad) filter(where p.etapa in ('produccion','listo','entregado') and p.fecha>now()-interval '30 days'),0)/30.0 consumo_diario,
case when coalesce(sum(i.cantidad) filter(where p.etapa in ('produccion','listo','entregado') and p.fecha>now()-interval '30 days'),0)=0 then 999 else s.stock/(sum(i.cantidad) filter(where p.etapa in ('produccion','listo','entregado') and p.fecha>now()-interval '30 days')/30.0) end cobertura_dias
from sku s left join item i on (i.prenda,i.color,i.talla)=(s.prenda,s.color,s.talla) left join pedido p on p.id=i.pedido_id group by s.id,s.prenda,s.color,s.talla,s.stock,s.minimo;
create or replace function public.es_equipo() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.equipo where lower(email)=lower(auth.email())) $$;
revoke all on function public.es_equipo() from public,anon;
grant execute on function public.es_equipo() to authenticated;
do $$ declare t text; begin foreach t in array array['cliente','pedido','item','evento','sku','insumo','movimiento','equipo','catalogo_prenda','catalogo_recargo'] loop execute format('alter table public.%I enable row level security',t); execute format('drop policy if exists equipo_acceso on public.%I',t); execute format('create policy equipo_acceso on public.%I for all to authenticated using (public.es_equipo()) with check (public.es_equipo())',t); end loop; end $$;
revoke all on all tables in schema public from anon;
grant select,insert,update,delete on all tables in schema public to authenticated;
revoke all on function public.registrar_pedido(jsonb) from public,authenticated;
grant execute on function public.registrar_pedido(jsonb) to anon;
revoke all on function public.registrar_entrada(uuid,uuid,numeric) from public,anon;
grant execute on function public.registrar_entrada(uuid,uuid,numeric) to authenticated;
do $$ begin alter publication supabase_realtime add table public.pedido; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.item; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.sku; exception when duplicate_object then null; when undefined_object then null; end $$;
