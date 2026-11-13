# Conectar BRAVA a Supabase

1. En el SQL Editor del proyecto, pega y ejecuta `esquema.sql`. Luego pega y ejecuta `semilla.sql`.
2. En `semilla.sql`, edita el correo del último comentario y ejecuta la sentencia `insert into equipo(email) values (...)`.
3. En **Authentication → URL Configuration**, configura Site URL y Redirect URLs con `https://matiasbtt.github.io/brava/crm/` y `http://localhost:5195/`.
4. Copia la Project URL y la clave pública anon/publishable en `brava-config.js`. No coloques la `service_role`.
5. Abre la web, envía un pedido de prueba y entra al CRM con el enlace mágico. Confirma que aparece en el Pipeline.

## Datos de ejemplo (simulación de 80 compradores)

- `simulacion-80.sql` carga 100 clientes (80 compradores), unos 130 pedidos desde el 1-sep, el pipeline abierto, pedidos perdidos, stock e insumos. Todo pedido lleva código `SIM-xxxx` y todo cliente la nota «simulación». Se corre **una sola vez** en el SQL Editor (si ya está cargado, avisa y no hace nada).
- `vaciar-simulacion.sql` deja la base sin pedidos, clientes ni movimientos y el stock en 0. **Úsalo antes de empezar con ventas reales**; si ya entraron pedidos reales, no lo corras tal cual (ver el comentario del archivo).
