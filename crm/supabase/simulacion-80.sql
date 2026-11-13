-- BRAVA · Simulación: 80 compradores + consultas, pipeline, perdidos, stock e insumos.
-- Todo pedido lleva código SIM-xxxx y todo cliente la nota «simulación». Para borrarlo: vaciar-simulacion.sql
-- Se corre una sola vez en el SQL Editor de Supabase. Semilla fija: da siempre lo mismo.
do $$ begin
  if exists(select 1 from public.pedido where codigo like 'SIM-%') then
    raise exception 'La simulación ya está cargada. Corre vaciar-simulacion.sql primero.';
  end if;
end $$;

select setseed(0.2810);
alter table public.pedido disable trigger pedido_stock;
alter table public.pedido disable trigger pedido_evento;

-- Elige un valor según pesos
create or replace function pg_temp.pick(v text[], w numeric[]) returns text language plpgsql as $f$
declare r numeric := random()*(select sum(x) from unnest(w) x); acc numeric := 0; i int;
begin
  for i in 1..array_length(v,1) loop acc := acc + w[i]; if r <= acc then return v[i]; end if; end loop;
  return v[array_length(v,1)];
end $f$;

create temp table t_cfg on commit drop as select (now() at time zone 'America/La_Paz')::date hoy;

-- 1) Clientes: 80 compradores (1-80) y 20 que solo consultaron (81-100)
create temp table t_cli on commit drop as
select i,
  n[1+floor(random()*array_length(n,1))::int]||' '||a[1+floor(random()*array_length(a,1))::int] nombre,
  '7'||lpad(((i*7654321+1234567)%10000000)::text,7,'0') tel,
  pg_temp.pick(z,array[25,15,14,10,8,8,10,10]) zona,
  pg_temp.pick(array['Instagram','TikTok','WhatsApp referido','Web directa','Feria/UMSS'],array[34,22,20,14,10]) canal
from generate_series(1,100) i, (select
  array['Daniela','Carlos','Sofía','Javier','Valeria','Marco','Andrea','Luis','Camila','Diego','Fernanda','Mateo','Paola','Rodrigo','Lucía','Gabriel','Noelia','Adrián','Micaela','Esteban','Carla','Bruno','Natalia','Kevin','Rocío','René','Fátima','Pablo','Alejandra','Miguel','Mariana','Sebastián','Jimena','Óscar','Gabriela','Álvaro','Ximena','Kiara','Joaquín','Tatiana'] n,
  array['Quiroga','Mamani','Flores','Rojas','Torrico','Choque','Montenegro','Pérez','Salazar','Cruz','Gutiérrez','Arce','Camacho','Sánchez','Ledezma','Céspedes','Prado','Soria','Iriarte','Mercado','Heredia','Paredes','López','Rivera','Daza','Quispe','Vargas','Villarroel','Zambrana','Rocabado','Ayala','Terrazas'] a,
  array['Centro','Cala Cala','Queru Queru','Sarco','Tupuraya','Muyurina','Recoleta','Otra zona de la ciudad'] z) q;

insert into public.cliente(nombre,telefono,zona,canal_origen,notas)
select nombre,tel,zona,canal,'simulación' from t_cli order by i;

-- 2) Fechas de las compras pagadas: crecen con el tiempo, pico del Día del Estudiante (21-sep), y algunos recompran
create temp table t_o1 on commit drop as
select i cli, case when random()<0.16 then date '2026-09-19'+floor(random()*4)::int
  else (select hoy from t_cfg)-57+floor(58*power(random(),0.8))::int end d
from generate_series(1,80) i;
create temp table t_o2 on commit drop as
select * from (select cli, d+9+floor(random()*18)::int d from t_o1 where random()<0.32) x where d<=(select hoy from t_cfg);
create temp table t_o3 on commit drop as
select * from (select cli, d+9+floor(random()*18)::int d from t_o2 where random()<0.30) x where d<=(select hoy from t_cfg);
create temp table t_o4 on commit drop as
select * from (select cli, d+9+floor(random()*18)::int d from t_o3 where random()<0.30) x where d<=(select hoy from t_cfg);

-- 3) Todas las órdenes: pagadas, abiertas (consulta/cotizado) y perdidas
create temp table t_all on commit drop as
select cli,d,'pagado' kind from (select * from t_o1 union all select * from t_o2 union all select * from t_o3 union all select * from t_o4) p
union all select i, (select hoy from t_cfg)-floor(random()*9)::int, 'abierto' from generate_series(81,88) i
union all select (1+floor(random()*80))::int, (select hoy from t_cfg)-floor(random()*7)::int, 'abierto' from generate_series(1,6)
union all select i, (select hoy from t_cfg)-45+floor(random()*43)::int, 'perdido' from generate_series(89,100) i
union all select i, (select hoy from t_cfg)-45+floor(random()*43)::int, 'perdido' from generate_series(81,88) i where random()<0.3
union all select (1+floor(random()*80))::int, (select hoy from t_cfg)-35+floor(random()*30)::int, 'perdido' from generate_series(1,5);

-- 4) Atributos de cada orden y su etapa (según la antigüedad)
create temp table t_ord on commit drop as
select s.*,
  case when s.kind='perdido' then 6
       when s.kind='abierto' then case when s.age_h>7 and random()<0.5 then 1 else 0 end
       else case when s.age_h<=40 then least(2,s.m) when random()<0.14 then greatest(2,s.m-2) when random()<0.30 then greatest(2,s.m-1) else s.m end end stage
from (
  select r.*,
    (select max(j) from generate_series(0,5) j where (c[j+1]-c[r.st+1])*1.3 <= r.age_h) m
  from (
    select q.*, extract(epoch from (now()-q.ts))/3600 age_h,
      case when q.kind='pagado' and random()<0.55 then 2 else 0 end st,
      array[0,5,20,40,110,150] c
    from (
      select row_number() over (order by a.d,a.cli) rn, a.cli, a.d, a.kind,
        least(((a.d::timestamp+interval '8 hours'+random()*interval '11 hours')) at time zone 'America/La_Paz', now()-interval '25 minutes'-random()*interval '2 hours') ts,
        (0.8+random()*0.5) k,
        pg_temp.pick(array['delivery','recojo'],array[45,55]) entrega,
        (random()<0.03) grupo
      from t_all a
    ) q
  ) r
) s;
-- las pagadas siempre arrancan en pago por verificar si son muy nuevas
update t_ord set st=2 where kind='pagado' and st=0 and (c[3]-c[1])*1.3 > age_h;
update t_ord set stage=greatest(2,least(stage,(select max(j) from generate_series(0,5) j where (c[j+1]-c[st+1])*1.3 <= age_h))) where kind='pagado';

-- 5) Pedidos
insert into public.pedido(codigo,cliente_id,fecha,etapa,entrega,zona,costo_delivery,total,pagado,fecha_pago,motivo_perdida,canal,referencia)
select 'SIM-'||lpad(o.rn::text,4,'0'), c.id, o.ts,
  (case when o.kind='perdido' then 'perdido' else (array['consulta','cotizado','pago_verificar','produccion','listo','entregado'])[o.stage+1] end)::public.etapa_pedido,
  o.entrega, case when o.entrega='delivery' then t.zona end, case when o.entrega='delivery' then 15 else 0 end, 0,
  o.kind='pagado',
  case when o.kind='pagado' then o.ts+((o.c[3]-o.c[o.st+1])*o.k)*interval '1 hour' end,
  case when o.kind='perdido' then pg_temp.pick(array['No respondió','Precio','Talla agotada','Demora'],array[40,28,12,20]) end,
  t.canal, case when o.grupo and o.kind='pagado' then 'Pedido de grupo (curso/promoción)' end
from t_ord o join t_cli t on t.i=o.cli join public.cliente c on c.telefono=t.tel;

create temp table t_ped on commit drop as
select o.*, p.id pid from t_ord o join public.pedido p on p.codigo='SIM-'||lpad(o.rn::text,4,'0');

-- 6) Ítems: qué compró cada uno
create temp table t_it on commit drop as
select o.pid, g.line,
  pg_temp.pick(array['polera','canguro','gorra'],array[45,35,20]) prenda
from t_ped o, lateral generate_series(1, case when o.grupo and o.kind='pagado' then 1 else pg_temp.pick(array['1','2','3'],array[72,22,6])::int end) g(line);
alter table t_it add column color text, add column talla text, add column ubic text, add column tintas int, add column cant int, add column dep text, add column diseno text;
update t_it i set prenda='polera' from t_ped o where o.pid=i.pid and o.grupo and o.kind='pagado' and random()<0.7;
update t_it set
  color=pg_temp.pick(array['negro','blanco','marino','pacay'],array[40,25,20,15]),
  tintas=pg_temp.pick(array['1','2'],array[80,20])::int,
  cant=pg_temp.pick(array['1','2','3'],array[84,12,4])::int,
  ubic=case prenda when 'gorra' then 'frente' when 'polera' then pg_temp.pick(array['pecho','espalda'],array[40,60])
       else pg_temp.pick(array['pecho','espalda','ambos'],array[15,55,30]) end,
  talla=case prenda when 'gorra' then 'U' else pg_temp.pick(array['S','M','L','XL'],array[20,35,30,15]) end;
update t_it i set cant=6+floor(random()*10)::int from t_ped o where o.pid=i.pid and o.grupo and o.kind='pagado';
update t_it set dep=case prenda
    when 'canguro' then pg_temp.pick(array['cochabamba','santacruz','tarija','beni','chuquisaca'],array[35,22,15,14,14])
    when 'polera' then case when ubic='pecho' then null else pg_temp.pick(array['lapaz','oruro'],array[85,15]) end
    else case when random()<0.6 then null else pg_temp.pick(array['cochabamba','lapaz','santacruz','tarija','potosi','oruro'],array[30,20,20,10,10,10]) end end;
update t_it set diseno=case
    when prenda='polera' and ubic='pecho' then 'BRAVA'
    when prenda='polera' then case dep when 'oruro' then 'Carnaval 1956'
         else pg_temp.pick(array['La Paz, Illimani','Ciudad Ajayu','Salteña','La Mamani','Kusillo'],array[22,24,14,12,16]) end
    when prenda='gorra' and dep is null then 'BOLIVIA'
    else (select nombre from (values ('cochabamba','Cochabamba'),('santacruz','Santa Cruz'),('tarija','Tarija'),('beni','Beni'),('chuquisaca','Chuquisaca'),('lapaz','La Paz'),('potosi','Potosí'),('oruro','Oruro')) v(id,nombre) where v.id=dep) end;

insert into public.item(pedido_id,prenda,color,talla,diseno,departamento,ubicacion,tintas,cantidad,precio_unit)
select i.pid,i.prenda,i.color,i.talla,i.diseno,i.dep,i.ubic,i.tintas,i.cant,
  cp.base+cr.monto+case when i.tintas=2 then (select monto from public.catalogo_recargo where clave='segunda_tinta') else 0 end
from t_it i join public.catalogo_prenda cp on cp.prenda=i.prenda join public.catalogo_recargo cr on cr.clave=i.ubic;

update public.pedido p set total=x.t+p.costo_delivery
from (select pedido_id, sum(cantidad*precio_unit) t from public.item group by 1) x
where x.pedido_id=p.id and p.codigo like 'SIM-%';

-- 7) Eventos: el recorrido de cada pedido por el pipeline
insert into public.evento(pedido_id,de_etapa,a_etapa,fecha_hora,usuario)
select o.pid,
  case when j=o.st then null else (array['consulta','cotizado','pago_verificar','produccion','listo','entregado'])[j]::public.etapa_pedido end,
  (array['consulta','cotizado','pago_verificar','produccion','listo','entregado'])[j+1]::public.etapa_pedido,
  o.ts+((o.c[j+1]-o.c[o.st+1])*o.k)*interval '1 hour',
  case when j=o.st then 'web' else 'simulación' end
from t_ped o, lateral generate_series(o.st, case when o.kind='perdido' then 0 else o.stage end) j
where o.kind<>'perdido'
   or j=0;
insert into public.evento(pedido_id,de_etapa,a_etapa,fecha_hora,usuario)
select o.pid,'consulta','cotizado',o.ts+(5*o.k)*interval '1 hour','simulación' from t_ped o where o.kind='perdido' and o.stage=6 and random()<0.5 and o.age_h>50;
insert into public.evento(pedido_id,de_etapa,a_etapa,fecha_hora,usuario)
select o.pid, case when exists(select 1 from public.evento e where e.pedido_id=o.pid and e.a_etapa='cotizado') then 'cotizado'::public.etapa_pedido else 'consulta'::public.etapa_pedido end,
  'perdido', least(now()-interval '1 hour', o.ts+(24+random()*96)*interval '1 hour'),'simulación'
from t_ped o where o.kind='perdido';

-- 8) Stock de prendas: reposiciones y salidas al entrar a producción
insert into public.movimiento(sku_id,tipo,cantidad,fecha,pedido_id)
select s.id,'salida',sum(i.cantidad),
  o.ts+((o.c[4]-o.c[o.st+1])*o.k)*interval '1 hour', o.pid
from t_ped o join public.item i on i.pedido_id=o.pid join public.sku s on (s.prenda,s.color,s.talla)=(i.prenda,i.color,i.talla)
where o.kind='pagado' and o.stage>=3
group by s.id,o.ts,o.c,o.st,o.k,o.pid;

create temp table t_cons on commit drop as
select s.id, coalesce(sum(m.cantidad),0) cons, row_number() over (order by coalesce(sum(m.cantidad),0) desc, s.id) rk
from public.sku s left join public.movimiento m on m.sku_id=s.id and m.tipo='salida'
group by s.id;
create temp table t_tgt on commit drop as
select id, cons, cons+case when rk<=4 then 1+floor(random()*3)::int else 7+floor(random()*22)::int end total_in,
       case when rk<=4 then 0 else 1 end ok from t_cons;
insert into public.movimiento(sku_id,tipo,cantidad,fecha)
select id,'entrada',ceil(total_in*0.65),timestamptz '2026-09-01 10:00-04' from t_tgt where ceil(total_in*0.65)>0
union all
select id,'entrada',total_in-ceil(total_in*0.65),timestamptz '2026-10-06 10:00-04' from t_tgt where total_in-ceil(total_in*0.65)>0;
update public.sku s set stock=t.total_in-t.cons from t_tgt t where t.id=s.id;

-- 9) Insumos: stock inicial de modo que hoy queden unos bajo el mínimo
update public.insumo i set stock=v.hoy_stock + coalesce((
  select sum(it.cantidad) from t_ped o join public.item it on it.pedido_id=o.pid where o.kind='pagado' and o.stage>=3),0)*i.consumo_por_prenda
from (values ('Tinta carbón',900),('Tinta hueso',640),('Tinta ocre',180),('Tinta terracota',420),('Emulsión',760),('Bolsas kraft',70),('Etiquetas',18)) v(nombre,hoy_stock)
where v.nombre=i.nombre;

update public.cliente c set fecha_alta=m.f
from (select cliente_id, min(fecha) f from public.pedido where codigo like 'SIM-%' group by 1) m
where m.cliente_id=c.id and c.notas='simulación';

alter table public.pedido enable trigger pedido_stock;
alter table public.pedido enable trigger pedido_evento;

select (select count(*) from public.cliente) clientes,
  (select count(distinct cliente_id) from public.pedido where pagado) compradores,
  (select count(*) from public.pedido) pedidos,
  (select count(*) from public.pedido where pagado) pagados,
  (select count(*) from public.item) items,
  (select count(*) from public.evento) eventos,
  (select sum(total) from public.pedido where pagado) ingresos;
