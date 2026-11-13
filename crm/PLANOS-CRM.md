# BRAVA CRM — Planos

Versión 1 · 2026-10-26 · Orquesta: Claude · Construye: Codex

Este documento sirve para dos cosas: construir el CRM real y armar la **simulación** que viene a continuación. En la simulación todo dato es inventado y se rotula así en pantalla. Los precios salen de la maqueta (`index.html`, «precios de ejemplo»), porque BRAVA todavía no tiene precios confirmados.

---

## 1. Qué resuelve

BRAVA vende por pedido. El cliente arma su prenda en la web, paga con un QR estático y cierra por WhatsApp. El CRM sigue al pedido desde el primer mensaje hasta la entrega, avisa cuándo faltan prendas lisas o tintas, y muestra quién compra, qué compra y cuánto pesa cada cliente.

Usuarios: Matías y el taller, de 1 a 3 personas. Se usa en la laptop del taller y también en el celular.

## 2. Secciones

| # | Sección | Para qué sirve |
|---|---|---|
| S1 | **Pipeline** | Un tablero kanban con los pedidos y sus etapas, que se arrastran de una columna a otra |
| S2 | **Clientes** | Ficha de cada cliente, su historial, su segmento y su banda de compra |
| S3 | **Inventario** | Stock de prendas lisas por prenda, color y talla, y de insumos; alertas de reposición |
| S4 | **Estadísticas** | KPIs y gráficos: barras, áreas, bandas, Pareto, cohortes y embudo |
| S5 | **Pedido (ficha)** | Panel lateral con todo lo del pedido: ítems, pago, entrega y notas |

## 3. Pipeline (S1)

Las etapas siguen el flujo real de BRAVA:

| Etapa | Entra cuando… | Sale cuando… | Alerta si pasa más de |
|---|---|---|---|
| 1 Consulta | Llega un WhatsApp (con el mensaje predeterminado o sin él) | Se le confirma diseño y precio | 2 días |
| 2 Cotizado | El cliente tiene el precio | Manda el comprobante del QR | 3 días → pasa a «Perdido» si no responde |
| 3 Pago por verificar | Llega el comprobante | Se ve el abono en el banco | 1 día |
| 4 En producción | Pago verificado; **aquí se descuenta el stock** | Serigrafía y secado terminados | 4 días |
| 5 Listo | El pedido está empacado | Se recoge o se entrega por delivery | 3 días |
| 6 Entregado | Se entregó | — (cerrado) | — |
| ✕ Perdido | No respondió o canceló | Se puede reabrir a «Consulta» | — |

Cada tarjeta muestra el código (`BR-0001`), el cliente, una miniatura de la prenda con su color, el total en Bs, los días que lleva en la etapa (en rojo si supera la alerta) y un ícono de recojo o delivery.

Al pie de cada columna van la cantidad de pedidos y la suma en Bs. Hay filtros por prenda, departamento, canal y fecha, y un buscador por nombre, teléfono o código.

Al mover una tarjeta se guarda un `evento` (de qué etapa, a cuál, cuándo y quién), y con esos eventos se calculan los tiempos por etapa y el embudo.

## 4. Modelo de datos

```
cliente      id, nombre, telefono, zona, canal_origen, fecha_alta, nacimiento_aprox (rango), notas
pedido       id, codigo, cliente_id, fecha, etapa, entrega(recojo|delivery), zona, costo_delivery,
             total, pagado(bool), fecha_pago, motivo_perdida, canal
item         id, pedido_id, prenda(canguro|polera|gorra), color, talla, diseno/departamento,
             ubicacion(pecho|espalda|ambos|frente), tintas(1|2), cantidad, precio_unit
evento       id, pedido_id, de_etapa, a_etapa, fecha_hora, usuario
sku          id, prenda, color, talla, stock, minimo, costo_unit, proveedor
insumo       id, nombre, unidad, stock, minimo, consumo_por_prenda
movimiento   id, sku_id|insumo_id, tipo(entrada|salida|ajuste), cantidad, fecha, pedido_id?
```

- **Catálogo** (sacado de la maqueta): canguro (S/M/L/XL, Bs 180), polera (S/M/L/XL, Bs 90) y gorra (talla única, Bs 70). Colores: blanco, negro, azul marino y verde pacay. Recargos: pecho +15, espalda +30, ambos +40, frente de gorra +20, segunda tinta +10. Delivery Bs 15.
- **SKU** = prenda × color × talla, en total 36: 16 de canguro, 16 de polera y 4 de gorra.
- **Departamentos**: cochabamba, lapaz, santacruz, oruro, potosi, chuquisaca, tarija, beni y pando.
- **Zonas**: Centro, Cala Cala, Queru Queru, Sarco, Tupuraya, Muyurina, Recoleta y Otra.
- **Canales de origen**: Instagram, TikTok, WhatsApp referido, Web directa y Feria/UMSS.

## 5. Inventario (S3)

- Hay una matriz por prenda: las filas son colores, las columnas son tallas y cada celda muestra el stock. El color de la celda indica el nivel: rojo si está bajo el mínimo, ocre si le falta menos del 50 % para llegar al mínimo y neutro si está bien.
- **Cobertura en días** = stock ÷ consumo diario promedio de los últimos 30 días. Con menos de 10 días aparece la alerta «Reponer».
- **Sugerencia de compra** = (consumo diario × 21 días) − stock, redondeada a la docena (el proveedor vende por docenas).
- Los insumos son tinta carbón, tinta hueso, tinta ocre, tinta terracota, emulsión, bolsas kraft y etiquetas. Cada prenda consume una cantidad fija por tinta.
- El historial de movimientos se puede filtrar, y la reposición se registra con un botón de «entrada».
- La regla de oro es que el stock baja **solo al pasar a «En producción»**, no al cotizar.

## 6. Estadísticas (S4)

### 6.1 KPIs del período (arriba, en tarjetas)
Ingresos, pedidos, clientes compradores, ticket promedio, % de recompra, conversión de Consulta a Pagado, tiempo promedio de Pagado a Entregado. Cada uno va con su variación frente al mes anterior y una sparkline.

### 6.2 Gráficos de barras
- **B1** Ingresos por mes, con barras apiladas por prenda.
- **B2** Ventas por departamento (barras horizontales ordenadas): unidades y Bs. Responde qué diseño reimprimir.
- **B3** Tallas × prenda (barras agrupadas). Sirve para comprar las prendas lisas en la proporción correcta.
- **B4** Pedidos por canal de origen, con conversión. Dice dónde poner la publicidad.

### 6.3 Gráficos de área
- **A1** Ingresos diarios con media móvil de 7 días, y la base sombreada en área. Muestra picos, como una feria o un posteo viral.
- **A2** Área apilada al 100 % de la participación por prenda en el tiempo, para ver si el canguro sube con el frío.
- **A3** Clientes acumulados: un área de clientes nuevos y otra de clientes que vuelven.

### 6.4 Gráficos de bandas: cómo hacerlos útiles
Una banda con el «% de compra de cada cliente» y 150 o más clientes por mes no se puede leer: serían 150 franjas finas. Por eso la banda se aplica a **grupos de clientes**, y el porcentaje individual va **dentro de la ficha y la tabla**.

- **BD1 Pareto ABC**: los clientes se ordenan por gasto. **A** son los que juntan el 80 % del ingreso, **B** el siguiente 15 % y **C** el último 5 %. Se muestra una barra horizontal al 100 % con las tres bandas, que dice «el 22 % de los clientes genera el 80 % del ingreso», y al lado la curva de Pareto con el ingreso acumulado frente al % de clientes.
- **BD2 Bandas por segmento RFM y por mes**: una columna al 100 % por mes, partida en segmentos (Campeones, Leales, Nuevos, En riesgo y Dormidos). Muestra si el negocio depende de clientes nuevos o de los que vuelven.
- **BD3 Banda del cliente**: en la tabla de clientes cada fila lleva una mini barra al 100 % con su gasto por prenda, más el % que representa del ingreso total y su percentil («top 5 %»).
- **BD4 Nuevo vs. recurrente**: una banda por mes con la parte del ingreso de clientes nuevos y la de clientes que ya habían comprado.

### 6.5 Análisis de clientes
- **RFM**: Recencia (días desde la última compra), Frecuencia (pedidos) y Monto (Bs). Cada uno va de 1 a 5 por quintiles. Los segmentos son:
  - Campeones: R ≥ 4, F ≥ 4
  - Leales: F ≥ 3
  - Nuevos: 1 pedido y R ≥ 4
  - En riesgo: R ≤ 2 y F ≥ 2
  - Dormidos: el resto con R ≤ 2
  - Ocasionales: los demás
- **Cohortes**: un mapa de calor con el mes de primera compra en las filas y el % que vuelve a comprar en el mes +1, +2… en las columnas.
- **Embudo**: Consulta → Cotizado → Pagado → Entregado, con el % de paso entre etapas y los motivos de pérdida.
- Cada segmento lleva una acción sugerida. Por ejemplo, «En riesgo» recibe un mensaje de WhatsApp con el diseño nuevo de su departamento. **El CRM no envía nada solo**: la plantilla se copia y la manda una persona.

## 7. Implementación real con Supabase (desde el inicio)

Decisión del 2026-10-26: se descarta el esquema de Google Sheets con Apps Script. La base de datos es **Supabase** (Postgres) desde el primer día.

### 7.1 Piezas
| Pieza | Qué es | Costo |
|---|---|---|
| Base de datos | Proyecto Supabase con las tablas del §4 en Postgres | Plan gratuito: 500 MB, sobra para años de pedidos |
| Frontend | Este mismo HTML estático en GitHub Pages, con `@supabase/supabase-js` cargado desde un CDN en versión fija | Gratis |
| Acceso | Supabase Auth con enlace mágico por correo, solo para el equipo | Gratis |
| Tiempo real | Supabase Realtime en `pedido` y `sku`: si alguien mueve una tarjeta, se ve en los otros equipos | Gratis |

### 7.2 Tablas y reglas en la base
- Las tablas del §4 van tal cual. Los `id` son `uuid`, los `codigo` de pedido salen de una secuencia (`BR-0001`), el dinero va en `numeric(10,2)` y las fechas en `timestamptz` con hora de Bolivia (`America/La_Paz`).
- `etapa` es un tipo `enum` (`consulta`, `cotizado`, `pago_verificar`, `produccion`, `listo`, `entregado`, `perdido`).
- **Trigger de eventos**: cada cambio de `pedido.etapa` inserta solo una fila en `evento`. El frontend no lo hace a mano.
- **Trigger de stock**: al pasar a `produccion`, la base descuenta el SKU de cada ítem y registra el `movimiento` en la misma transacción. Si un pedido vuelve atrás, se devuelve el stock. Así el stock no se desfasa aunque dos personas muevan pedidos a la vez.
- **Vistas para las estadísticas**: `v_ventas_mes`, `v_rfm`, `v_abc`, `v_cohortes`, `v_embudo` y `v_cobertura_sku`. El frontend las lee ya calculadas. En la simulación, las mismas cuentas viven en `js/analitica.js`, que sirve de referencia para escribir el SQL.

### 7.3 Seguridad
- La tabla `equipo` lleva los correos autorizados (1 a 3 personas). Todas las tablas tienen **RLS activado** con la política «solo usuarios autenticados que estén en `equipo`».
- En el HTML solo va la clave pública (`anon`), que es segura gracias a la RLS. La clave `service_role` **nunca** va en el frontend ni en el repositorio.
- No se activa el registro abierto: los usuarios se invitan desde el panel de Supabase.

### 7.4 Operación
- **Pausa por inactividad**: el plan gratuito pausa el proyecto si pasa 7 días sin uso. Se reactiva con un clic desde el panel, y con el uso diario del taller no debería pasar.
- **Captura**: el mensaje predeterminado de WhatsApp ya trae todo el pedido. Un botón «Pegar mensaje» en el CRM lo lee y crea el pedido en la etapa «Consulta». Más adelante, una Edge Function de Supabase podría recibir el webhook de WhatsApp Cloud API y crearlo sola.
- **Respaldo**: el CRM exporta un CSV de cada tabla y conviene descargarlo una vez por semana. El plan gratuito no incluye copias automáticas descargables, así que sin ese CSV no hay respaldo.
- **Migración desde la simulación**: `sim/generar.mjs` puede exportar los mismos datos como `seed.sql` para probar la base con datos de ejemplo. Antes de usarla de verdad, se vacían.

### 7.5 Orden de trabajo
1. Crear el proyecto Supabase y correr `supabase/esquema.sql` (tablas, enum, triggers, vistas y RLS).
2. Agregar `js/datos.js`, una capa que hoy lee `BRAVA_SIM` y mañana Supabase, con las mismas funciones para que las pantallas no cambien.
3. Agregar la pantalla de inicio de sesión y Realtime en el pipeline.
4. Agregar el botón «Pegar mensaje» y la exportación a CSV.

## 8. Simulación (lo que se construye ahora)

- **Período**: del 2026-05-01 al 2026-10-26.
- **Volumen**: **al menos 150 clientes compradores distintos por mes** y entre 200 y 280 pedidos por mes, con un crecimiento suave de alrededor del 6 % mensual. Junio y julio tienen un pico de canguros (es invierno en Cochabamba), y hay un pico de ferias en mayo (la UMSS) y en septiembre (el Día del Estudiante, 21-sep).
- **Recompra**: un 25–35 % de los compradores de cada mes ya había comprado antes. La distribución del gasto es de cola larga y sale de la frecuencia de compra y de algunos pedidos de grupo, no de cantidades infladas. Con un ticket de estudiante (mediana de unos Bs 205), el resultado es que alrededor del 48 % de los clientes genera el 80 % del ingreso, y el 20 % de arriba, cerca del 58 %. La meta inicial de 20/80 se ajustó el 2026-10-26 porque obligaba a usar tickets irreales.
- **Mezcla**: un 45 % de polera, un 35 % de canguro y un 20 % de gorra en unidades. Tallas M 35 %, L 30 %, S 20 %, XL 15 %. Colores negro 40 %, blanco 25 %, marino 20 %, pacay 15 %. Cochabamba es el departamento que más vende, seguido de La Paz y Santa Cruz.
- **Pipeline vivo**: los pedidos de los últimos 10 días están repartidos entre las etapas abiertas, y alrededor de un 18 % de las consultas termina en «Perdido».
- **Inventario**: un stock inicial y reposiciones cada 2 o 3 semanas, con 3 a 5 SKUs bajo el mínimo hoy para que se vean las alertas.
- **Nombres**: nombres y apellidos bolivianos comunes, combinados al azar. Los teléfonos tienen el formato `+591 7XXXXXXX` y son ficticios.
- **Generador** con semilla fija, para que siempre dé los mismos datos.
- **Rótulo fijo**: «Datos simulados · precios de ejemplo».
