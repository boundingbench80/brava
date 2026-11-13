# Segunda pasada del CRM BRAVA

## Resultado mensual

Compradores = clientes con al menos un pedido pagado cuya fecha de pago cae en el mes. Consultas = pagados + perdidos + abiertos.

| Mes | Compradores | Pagados | Consultas | Ingresos pagados (Bs) | Ticket mediano | Ticket promedio | Recompra |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2026-05 | 163 | 200 | 244 | 46.071 | 203 | 230 | 0,0% |
| 2026-06 | 169 | 210 | 256 | 48.014 | 213 | 229 | 29,0% |
| 2026-07 | 177 | 220 | 268 | 55.949 | 218 | 254 | 28,8% |
| 2026-08 | 184 | 230 | 280 | 52.208 | 203 | 227 | 29,9% |
| 2026-09 | 193 | 240 | 293 | 59.842 | 208 | 249 | 30,1% |
| 2026-10 (1-26) | 166 | 205 | 330 | 49.812 | 203 | 243 | 30,1% |

Pareto medido por gasto pagado: top 20% concentra 58,3% (meta 70-80%, pendiente). Gasto maximo de cliente: Bs 3.642. Pedidos abiertos: 80.

## Cambios

- Se mantuvo la semilla 20260501. Se aumentaron las consultas totales para alojar pagos, perdidos y un pipeline vivo sin reducir los compradores pagados.
- Los pagos se cuentan por pagado=true y fecha_pago; compradores, ingresos, tickets, ABC/Pareto, RFM, cohortes y bandas se calculan solo con pagos.
- Se ajustaron las lineas por pedido a 80/17/3. Las cantidades de lineas regulares siguen la distribucion 85/12/3; los pedidos de grupo son aproximadamente 2%, con una sola linea de 6 a 15 unidades y grupo:true.
- Se limito la frecuencia maxima a nueve pedidos pagados por cliente en el periodo. El pipeline tiene 80 pedidos abiertos con fecha entre el 17 y el 26 de octubre. Los demas pedidos estan Entregados o Perdidos. Los eventos incluyen el cambio a la etapa actual; los dias de etapa leen ese evento.
- Las perdidas usan los motivos No respondio, Precio, Talla agotada y Demora. Se corrigio el calculo de recompra sobre compras pagadas.
- En Estadisticas, la conversion usa pagados / (pagados + perdidos). Las cohortes dejan vacias las celdas sin dato y ya no formatean valores indefinidos.
- Clientes muestra compradores por defecto y agrega el filtro Incluir solo consultas. Inventario conserva cuatro SKU bajo minimo.

## Verificacion

- Ejecutado node sim/generar.mjs; el resumen de consola imprime las metricas pedidas. Se verifico que la semilla queda fija.
- node --check paso para sim/generar.mjs, js/app.js y js/analitica.js.
- En Node se ejecutaron aggregate, RFM, ABC, cohortes, inventario, resumen mensual y motivos de perdida. Se ejecutaron tambien los generadores SVG de Estadisticas y la tabla de cohortes con los datos nuevos: sin excepciones, NaN ni undefined.
- Verificaciones de datos: 80 pedidos abiertos recientes; 4 SKU bajo minimo; mediana mensual Bs 203-218; promedio Bs 227-254; gasto maximo Bs 3.642.
- No se completo una inspeccion visual del navegador en claro/oscuro ni a 360 px. La comprobacion de UI fue estatica y los graficos se ejercitaron en Node.
- El Pareto queda por debajo de la meta indicada: 58,3% del ingreso en el top 20%. No lo presento como cumplimiento.



## Pasada 3

- Clientes muestra solo los 789 registros con pagos y pagina 25 filas. Se elimino la lectura de un checkbox inexistente que detenia el renderizado.
- Recompra cuenta compradores pagados del periodo que ya tenian un pago anterior. Los departamentos se muestran con nombre propio.
- A3 presenta nuevos y recurrentes en dos areas apiladas y etiqueta octubre como parcial. B4 calcula conversion por canal con pedidos pagados y perdidos. A1 y BD2 muestran conclusiones calculadas.
- BD1 incluye guias al 80% y banda ABC. BD2 ordena seis segmentos RFM y muestra cantidad y porcentaje en los tooltips.
- Se ajusto la escala tipografica SVG a 11 px y el ancho renderizado; BD1, BD2 y BD4 no superan 360 px.
- Los movimientos tienen filtro por tipo y paginacion de 30 filas. El stock de insumos descuenta consumo estimado por prendas en produccion, listas o entregadas.
- Verificacion Node: app.js, analitica.js, sim.js y generar.mjs pasan node --check. Render simulado: 25 filas iniciales de Clientes (789 compradores), Estadisticas e Inventario sin NaN ni undefined en el HTML. Los archivos revisados no tienen BOM. sim.js y generar.mjs contienen U+FFFD preexistente y no se modificaron por la instruccion de preservarlos.
## Conexión Supabase

- Añadidos `brava-config.js` y `registro.js`: la web usa RPC con clave pública, reintenta una vez y conserva envíos fallidos para la siguiente visita. La llamada no espera antes de continuar el flujo a WhatsApp.
- Añadidos `crm/supabase/esquema.sql`, `semilla.sql` y `PASOS.md`: esquema idempotente, validación/calculado del pedido, triggers de evento e inventario, vistas, RLS, realtime, SKU/insumos y pasos de instalación.
- Añadido `crm/js/datos.js`: la configuración vacía carga la simulación; con URL carga Supabase JS fijo, autentica por enlace mágico y trae datos del equipo. `app.js` evita persistir etapas en localStorage en vivo y actualiza la etapa/entradas mediante Supabase.
- El payload web toma los ítems directamente del carrito y convierte talla única a `U`; el total se vuelve a calcular en Postgres con los catálogos.
- Verificado con Node: `datos.js` carga el modo simulado (1.671 pedidos y seis meses); con la configuración vacía `registro.js` no expone llamada; con `http://localhost:9` reintenta, no lanza errores y conserva el payload en `brava-pendientes`. `node --check` y `git diff --check` pasan.
- Revisado estáticamente: enum, funciones `security definer`, permisos `anon`, RLS, vistas, triggers e idempotencia. No se pudo ejecutar un parser SQL ni probar PostgreSQL, porque no hay proyecto ni credenciales. Auth real, políticas, RPC y Realtime quedan por probar.
