insert into public.sku(prenda,color,talla,stock,minimo)
select g.prenda,c.color,t.talla,0,case when g.prenda='gorra' then 5 else 4 end
from (values('canguro'),('polera'),('gorra')) g(prenda)
cross join (values('blanco'),('negro'),('marino'),('pacay')) c(color)
cross join lateral (select unnest(case when g.prenda='gorra' then array['U'] else array['S','M','L','XL'] end) talla) t
on conflict(prenda,color,talla) do nothing;
insert into public.insumo(nombre,unidad,stock,minimo,consumo_por_prenda) values
('Tinta carbón','ml',0,250,2),('Tinta hueso','ml',0,250,2),('Tinta ocre','ml',0,250,2),('Tinta terracota','ml',0,250,2),('Emulsión','ml',0,500,1),('Bolsas kraft','unidad',0,25,1),('Etiquetas','unidad',0,25,1)
on conflict(nombre) do nothing;
-- Matías: edita el correo y ejecuta esta línea para autorizar tu cuenta:
-- insert into equipo(email) values ('CORREO@...');
