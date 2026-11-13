# Auditoría y correcciones de BRAVA

Fecha: 13 de noviembre de 2026

## Diagnóstico

### Críticos

- Se corrigió la codificación de `index.html`: el texto en español aparecía como `SerigrafÃ­a` en el navegador. El archivo ahora conserva UTF-8 y los acentos se leen correctamente.
- `index.html` vaciaba el carrito y mostraba el pedido enviado sin esperar el resultado de Supabase. `registro.js` enviaba en segundo plano y los rechazos del servidor podían perderse. Ahora el envío espera confirmación del RPC, muestra el error y conserva el carrito si no hay confirmación.
- La RPC `registrar_pedido` confiaba en el campo `pagado` recibido desde el navegador y podía guardar el pago como confirmado. Ahora esa señal solo pone el pedido en `pago_verificar`; `pagado` queda en `false` hasta que el equipo lo valide.

### Importantes

- El código tenía solo tres caracteres aleatorios, haciendo probables las colisiones al crecer los pedidos. Ahora genera ocho caracteres con aleatoriedad criptográfica cuando está disponible. La restricción `UNIQUE` sigue siendo la garantía de unicidad; la RPC serializa inserciones concurrentes por código.
- Se actualizó el identificador de caché del registro para que los navegadores carguen el JavaScript corregido.
- Los pasos del pedido ahora solo aceptan valores enteros del 1 al 4 y bloquean el paso final sin la confirmación declarada por el cliente.

### Menores y mejoras recomendadas

- El CRM conectado permite cambiar etapas e inventario, pero no ofrece una acción para que el equipo marque `pagado=true` luego de revisar el comprobante. Un miembro autorizado debe registrar esa validación en el flujo de operación actual.
- La tienda identifica el QR y los datos de contacto/precios como demostrativos. Actualizarlos antes de publicar ventas reales.

## Archivos modificados

- `index.html`: códigos de pedido más resistentes a colisiones, validación de pasos, espera del RPC antes de vaciar el carrito y caché actualizada.
- `registro.js`: espera respuesta del RPC, reintenta fallos transitorios y propaga rechazos o errores de conexión.
- `crm/supabase/esquema.sql`: bloqueo por código y protección para no marcar pagos como confirmados desde la tienda.
- `crm/supabase/actualizar-registro-pedidos.sql`: migración puntual de la RPC y permisos para un proyecto existente.

## Supabase

No hacen falta tablas ni columnas nuevas. En un proyecto existente, ejecutar `crm/supabase/actualizar-registro-pedidos.sql` en el editor SQL de Supabase, primero en un proyecto de prueba. Esta migración actualiza solo la función y sus permisos, sin recargar precios ni recrear vistas. Hacer una copia de seguridad y revisar las políticas RLS antes de aplicarla en producción. La RPC sigue disponible para `anon`; las tablas siguen protegidas por RLS para el CRM. La clave `anon` es pública por diseño; nunca colocar `service_role` en el frontend.

El estado es `consulta` si no se reportó pago y `pago_verificar` si el cliente indicó que pagó. En ambos casos `pagado` permanece falso hasta la validación del equipo.

## Comprobaciones realizadas

- Sintaxis JavaScript con `vm.Script`: `registro.js`, los tres archivos JavaScript del CRM y el script embebido de `index.html` pasaron.
- Análisis HTML estático: ambos HTML incluyen viewport y las referencias locales principales a scripts y estilos existen.
- Búsqueda de claves: no hay `service_role` en el código de la aplicación. `brava-config.js` contiene la clave pública `anon`.
- No se pudo verificar Supabase ni ejecutar la migración por falta de acceso al proyecto y sesión del equipo.
- No se pudo verificar la interfaz en navegador: el navegador de prueba no logró conectarse al servidor local, incluso con permiso para iniciarlo.
- No afirmo pruebas reales de pedidos, CRM, responsive ni consola del navegador.

## Pasos

1. Descomprimir `BRAVA-corregido.zip` o usar los archivos modificados.
2. Aplicar `crm/supabase/actualizar-registro-pedidos.sql` después de respaldar y revisar RLS.
3. Configurar URL y clave pública en `brava-config.js`; nunca incluir claves privadas.
4. Abrir desde un servidor estático en la raíz, por ejemplo `python -m http.server 5191`, y probar los flujos con Supabase configurado.
