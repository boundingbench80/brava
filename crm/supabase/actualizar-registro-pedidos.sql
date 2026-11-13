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
revoke all on function public.registrar_pedido(jsonb) from public,authenticated;
grant execute on function public.registrar_pedido(jsonb) to anon;
