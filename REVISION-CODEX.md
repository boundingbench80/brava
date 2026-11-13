# Revisión de código — maqueta BRAVA

Revisión estática del `<script>` final de `index.html` contra `ARQUITECTURA.md`. No se modificaron archivos existentes.

## Errores de JavaScript y selectores

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Media | Arranque, líneas 1565–1568 | `store.get()` absorbe JSON inválido, pero JSON válido con forma inesperada no se valida. Un `cart` guardado con elementos incompletos o un `P` con valores inválidos puede romper `renderCart()`/`renderPedido()` al acceder a catálogo o campos. | `cart = Array.isArray(saved.cart) ? saved.cart.filter(validItem) : []; P = {...defaults, ...validPedido(saved.P)};` |
| Baja | Handlers delegados de pedido, líneas 2003–2027 | `#to-4`, `#howpay-cel`, `#howpay-pc` y `#wa-msg` solo se insertan en pasos concretos. Los accesos actuales ocurren desde acciones de esos mismos pasos y por eso están presentes en el uso normal; conviene protegerlos ante estados restaurados/DOM alterado. | `const el=$('#to-4'); if(el) el.disabled=!t.checked;` (análogamente para los otros selectores). |

No encontré variables usadas antes de declararse ni selectores estáticos `$('#id')` cuyo elemento correspondiente falte del HTML. Los controles condicionales citados se crean al renderizar el paso que los usa.

## Rutas y enlaces

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Baja | `go()`, líneas 1630–1638 | Un hash desconocido cae silenciosamente a `inicio`; no hay aviso de enlace inválido. No encontré `href="#..."` roto en el HTML actual. | `if (!validRoute(id) && !validPlanId(id)) showNotFound();` |

Verifiqué que los `href` a rutas (incluidos `#pedido` y `#diseno-paraba`) se resuelven, y que los enlaces de planos apuntan a `mapa`, `flujo`, `p01`–`p09` y `m01` existentes. `show()` alterna las vistas `maqueta` y `planos` existentes.

## Pedido en cuatro pasos

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Alta | `renderPedido()`/handler `[data-step]`, líneas 1906–1913 y 2021–2022 | La protección del paso 4 es solo el atributo `disabled` del botón. El handler acepta cualquier `data-step`, y `renderPedido()` trata cualquier paso distinto de 1, 2 o 3 como Enviar. Un `P.step=4` persistido o un evento disparado fuera del flujo salta «Ya pagué». | `if (+st.dataset.step===4 && !P.pagado) return;` y validar `P.step` al restaurarlo. |
| Media | Handler `[data-edit]`, líneas 2019–2020 | Editar quita una prenda, pero no reinicia `P.pagado`; si se vuelve al pedido puede persistir la marca de pago para un total/carro cambiado (o incluso vacío). | `P.pagado=false; P.step=1;` antes de persistir. |
| Baja | `validateDatos()`, línea 1988 | La expresión sí exige ocho dígitos y prefijo 6/7 tras quitar espacios, pero permite espacios internos arbitrarios (p. ej. `7 0 0 1 2 3 4 5`). | `const cel=P.cel.replace(/\s/g,''); const cOk=/^[67]\d{7}$/.test(cel);` (o quitar solo espacios permitidos al pegar). |

La validación de nombre, celular y zona para delivery está conectada al `submit` del paso 2. Cambiar cantidad, quitar una prenda y agregar otra reinicia `P.pagado`; editar es la excepción señalada. La cantidad mínima se mantiene en 1.

## Mensaje de WhatsApp — comparación con §5

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Media | `buildMessage()`, línea 1861 | La línea de cada prenda muestra `precio_unitario × cantidad` como importe de línea, pero no informa explícitamente el precio unitario como en la plantilla. | `Cantidad: ${it.qty} · Bs ${unitPrice(it)} c/u · Bs ${unitPrice(it)*it.qty}` |
| Baja | `buildMessage()`, línea 1859 | La plantilla pide diseño y ubicación con medida; el mensaje sí lo incluye. Sin embargo, para la combinación de pecho + espalda, `UB.ambos.med` muestra medidas, pero no agrega la indicación del logo en pecho como sí hace para espalda sola. | `...${UB[it.ub].logo || it.ub==='ambos' ? ' + logo en pecho' : ''}` (si esa combinación lleva logo según definición de taller). |

El mensaje contiene código, prenda/color/talla, diseño, ubicación y medida, texto cuando existe, tintas, cantidad e importe de línea, subtotal, entrega/costo, total pagado, nombre, celular y recordatorio del comprobante. No sobra ningún campo evidente de la plantilla. La referencia de delivery se omite si está vacía; la zona usa un marcador si falta.

## Reglas de combinación (§8.2)

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Media | `renderControls()` y `normalize()`, líneas 1725–1732 | La gorra limita ubicaciones a «frente» y el acento desactiva colores iguales al color de prenda. Pero la lista de diseños no declara/filtra compatibilidad por prenda (`DIS` carece de `prendas`), así que no se puede hacer cumplir la regla 2 si el catálogo cambia. | Añadir `prendas:[...]` por diseño y filtrar opciones con `d.prendas.includes(S.prenda)`. |

Correcto en la maqueta actual: el paso de texto se oculta en gorra y en pecho solo; la tinta principal se deriva automáticamente del atributo oscuro/claro del color; cambiar prenda normaliza color, talla y ubicación; el acento actual no puede coincidir con el color de prenda.

## localStorage

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| Baja | Restauración, líneas 1520–1523 y 1565–1569 | Todas las llamadas directas a `localStorage` están dentro de `try/catch` (`get` y `set`). El JSON corrupto no rompe el arranque. La estructura válida pero incompatible no se sanea; ver observación de arranque en la primera tabla. | Validar estructura y catálogo tras parsear; conservar `try/catch` alrededor de lectura y escritura. |

## Rayas largas o medias en texto visible

| Gravedad (alta/media/baja) | Dónde (función o línea aproximada) | Problema | Arreglo sugerido (código corto) |
|---|---|---|---|
| — | Documento visible | No encontré caracteres `—` ni `–`, ni entidades `&mdash;`/`&ndash;` en `index.html`. | No requiere cambio. |

## Verificado y correcto

- `go()`, `route()` y `show()` reconocen las rutas principales y las vistas; todos los `href="#..."` inspeccionados tienen destino válido.
- No detecté referencias a variables antes de su declaración ni selectores estáticos inexistentes.
- El paso 2 valida nombre, celular de ocho dígitos con inicio 6/7 y zona si se elige delivery.
- Los cambios de cantidad, quitar y agregar recalculan importes desde el carrito; cantidad no baja de uno.
- `buildMessage()` incluye los campos de producción y los totales principales de la plantilla §5.
- La gorra solo ofrece «frente»; texto se condiciona a espalda; contraste principal y exclusión de acento coincidente están implementados.
- `localStorage.getItem`, `setItem` y el parseo están protegidos con `try/catch`; JSON malformado se convierte en estado vacío.
- No aparecen rayas largas ni medias en texto de `index.html`.
