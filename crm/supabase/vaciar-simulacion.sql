-- Deja la base de BRAVA vacía de pedidos, clientes y movimientos, con el stock en 0.
-- SOLO sirve mientras todos los datos sean de la simulación (SIM-xxxx). Si ya hay pedidos reales, NO lo corras tal cual:
-- cambia cada «delete» por uno con «where codigo like 'SIM-%'» (y las demás tablas por los pedidos SIM-).
delete from public.movimiento;
delete from public.evento;
delete from public.item;
delete from public.pedido;
delete from public.cliente;
update public.sku set stock=0;
update public.insumo set stock=0;
select (select count(*) from public.pedido) pedidos, (select count(*) from public.cliente) clientes;
