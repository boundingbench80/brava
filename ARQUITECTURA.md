# BRAVA · Arquitectura del sitio web

Versión 1 · 23 de octubre de 2026 · Estado: **propuesta para aprobar**

Este documento define qué páginas tiene el sitio, cómo se mueve el cliente, qué contiene cada pantalla, cómo se guardan los datos, cómo se calcula el precio y cómo se cierra un pedido. No define el aspecto visual, que se decide en la etapa de maqueta.

> Todo precio, plazo, número o medida que aparece aquí es **de ejemplo** y está marcado como tal. Los valores reales se cargan en un solo archivo de configuración (§7) cuando el taller los confirme.

---

## 1. Decisiones tomadas

| Tema | Decisión | Por qué |
|---|---|---|
| Producto | Canguros, poleras y gorras serigrafiadas por pedido | Definido en la propuesta |
| Personalización v1 | Diseños propios y posiciones predefinidas | Cada combinación tiene que poder producirse bien. Subir una imagen propia queda para la v2 |
| Pago | **QR estático en la web** | Decisión del usuario. Sin pasarela ni comisiones |
| Cierre | **WhatsApp con un mensaje predeterminado** que lleva todas las especificaciones, más el comprobante | Decisión del usuario. Es como ya se compra en Cochabamba |
| Cuentas de usuario | No hay | Agregan fricción y no hacen falta para un pedido por WhatsApp |
| Dispositivo principal | Celular | El tráfico llega desde Instagram, TikTok y WhatsApp |
| Backend | Ninguno en la v1 | El catálogo es un JSON y el pedido viaja en el mensaje |

---

## 2. Mapa del sitio

```
Inicio  /
├── Personalizá tu prenda   /personaliza          ← puerta principal
│     (pasos: prenda · color · talla · diseño · ubicación · texto · tintas)
├── Colecciones             /colecciones
│     ├── Cocha de raíz      /colecciones/cocha-de-raiz
│     ├── Fauna brava        /colecciones/fauna-brava
│     ├── Mi departamento    /colecciones/mi-departamento   (próximamente)
│     └── Ficha de diseño    /disenos/<diseño>             → abre /personaliza con el diseño cargado
├── Guía de tallas          /guia-de-tallas
├── Cómo comprar            /como-comprar
└── Contacto                /contacto

Global, desde cualquier página:
  Pedido (panel lateral) ──► /pedido  (resumen → datos y entrega → pago QR → enviar por WhatsApp)
                                └──► /pedido/enviado  (confirmación)
```

**Navegación principal (5 entradas):** Personalizá tu prenda · Colecciones · Guía de tallas · Cómo comprar · Contacto. El botón «Pedido (n)» queda siempre visible arriba a la derecha.

**En el celular:** logo y «Pedido» arriba. El menú se abre con un botón «Menú» con texto, no solo con un ícono. Dentro del personalizador y del pago, una barra inferior fija lleva el precio y la acción del paso.

**Enlaces directos:** el personalizador acepta su estado en la dirección, por ejemplo `/personaliza?prenda=canguro&diseno=paraba&ubicacion=espalda`. Sirve para anuncios («este diseño en canguro»), para las fichas de diseño y para que un cliente comparta lo que armó.

---

## 3. Flujos

### 3.1 Flujo principal: del anuncio al taller

```
Anuncio o historia ─► Inicio o /personaliza (enlace directo)
  1. Elige prenda
  2. Color y talla
  3. Diseño y ubicación
  4. Texto y tintas
  5. Ve la vista previa y el precio  ──►  «Agregar al pedido»
  6. Abre el pedido: revisa, quita o suma prendas
  7. Datos y entrega: nombre, celular, recojo o delivery (zona y referencia)
  8. Pago: ve el monto exacto y el QR
       · en el celular: «Guardar QR» → abre la app del banco → paga desde la galería
       · en la compu: escanea el QR con el celular
  9. «Enviar pedido por WhatsApp» → se abre WhatsApp con el mensaje escrito
 10. Adjunta la captura del comprobante y envía
 11. Pantalla de confirmación con el código del pedido y los próximos pasos
──► El taller recibe el pedido completo y pagado
```

### 3.2 Flujo secundario: entrada por colecciones

Colecciones → ficha del diseño (historia, prendas compatibles) → «Usar este diseño» → personalizador con el diseño cargado. Desde ahí sigue el flujo principal en el paso 1.

### 3.3 Flujo de pedido especial

Contacto → formulario corto (nombre, qué necesita, cantidad aproximada) → abre WhatsApp con ese texto. Es para grupos, promociones o diseños fuera del catálogo. No pasa por el QR, porque el precio se cotiza.

### 3.4 Lo que pasa del lado del taller (fuera de la web)

```
Llega el WhatsApp ─► ¿el comprobante coincide con el total y el código?
   ├─ sí ─► responde «Pedido BR-… confirmado, listo el <fecha>» ─► producción ─► «Tu pedido está listo» ─► entrega o recojo
   └─ no ─► pide el comprobante correcto o la diferencia
```

Conviene guardar respuestas rápidas en WhatsApp Business para cada estado: recibido, confirmado, en producción, listo y entregado.

---

## 4. Contenido de cada página

Cada página se describe en el orden en que aparece al bajar.

### P-01 · Inicio `/`
**Para qué:** que en cinco segundos se entienda qué se vende y que el siguiente toque sea el personalizador.
1. Barra superior: logo, navegación y «Pedido (n)».
2. Portada: lema «Tu tierra. Tu estilo.», una frase de apoyo y una prenda real vista de espalda, donde va el diseño grande. Acción principal: «Personalizá tu prenda». Secundaria: «Ver colecciones».
3. Cómo funciona en tres pasos: Elegí la prenda · Elegí el diseño · Recibilo en Cocha.
4. Las tres colecciones como tarjetas.
5. Diseños destacados: los seis, cada uno con un enlace directo al personalizador.
6. Franja de confianza con datos verificables, por ejemplo «Hecho en Cochabamba», «Pago por QR» o «Recojo o delivery». Sin testimonios hasta tener clientes reales.
7. Pie (§4.9).

### P-02 · Personalizador `/personaliza`
**Para qué:** elegir y ver el resultado en la misma pantalla.
- **Vista previa**, fija mientras se baja por las opciones: la prenda en su color con el diseño en su lugar, un selector Frente/Espalda y etiquetas de la ubicación con su medida en cm y de las tintas.
- **Siete pasos**, en este orden. Cada uno muestra la elección actual junto al título:

| # | Paso | Opciones v1 | Reglas |
|---|---|---|---|
| 1 | Prenda | Canguro · Polera · Gorra | Cambiar de prenda conserva el diseño y reajusta lo demás |
| 2 | Color | 2 o 3 por prenda | Solo los colores que el proveedor tiene |
| 3 | Talla | S · M · L · XL / Gorra: única | Enlace a la guía de tallas |
| 4 | Diseño | 6 diseños | Cada diseño declara en qué prendas va |
| 5 | Ubicación | Pecho · Espalda · Pecho + espalda / Gorra: frente | Con solo espalda, el pecho lleva el logo chico de BRAVA |
| 6 | Texto | Departamento, BOLIVIA o sin texto | Solo aparece si hay estampado en la espalda |
| 7 | Tintas | 1 o 2 tintas, más el color de acento | La tinta principal se elige sola por contraste con la prenda. No se ofrece un acento igual al color de la prenda |

- **Orden de taller**: resumen con prenda, diseño, posición, medida, tintas, técnica y plazo, más el precio desglosado y el total.
- **Acción:** «Agregar al pedido · Bs —». En el celular va en una barra inferior fija.
- Después de agregar: un aviso corto («Agregado. Llevás 2 prendas») con las opciones «Ver pedido» y «Armar otra».

### P-03 · Colecciones `/colecciones`
1. Filtro: Todas · Cocha de raíz · Fauna brava · Mi departamento.
2. Una tarjeta por diseño con la imagen, el nombre y el botón «Personalizar».
3. Mi departamento: los nueve departamentos con su estado («Cochabamba disponible», el resto «próximamente»).

### P-04 · Ficha de diseño `/disenos/<diseño>`
1. El diseño en grande y fotos de cómo queda en cada prenda.
2. Nombre y dato real (el nombre científico de la especie o el lugar).
3. Texto corto sobre de dónde sale el diseño, verificado contra fuentes.
4. Prendas compatibles, tintas y medida del estampado.
5. «Usar este diseño», que lleva al personalizador con el diseño cargado.

### P-05 · Guía de tallas `/guia-de-tallas`
1. Una pestaña por prenda.
2. Tabla en cm con ancho de pecho, largo y manga. Medidas de ejemplo hasta que las confirme el proveedor.
3. Dibujo de cómo medir una prenda propia sobre una mesa.
4. Gorra: talla única regulable y su contorno.

### P-06 · Cómo comprar `/como-comprar`
1. Cuatro pasos: Armá → Revisá → Pagá con QR → Enviá por WhatsApp.
2. Cómo pagar con QR desde el mismo celular (guardar la imagen y pagar desde la galería), con capturas.
3. Plazos, entregas, zonas y costos.
4. Cuidado del estampado: lavar al revés, agua fría, no planchar encima.
5. Preguntas frecuentes, en acordeón.

### P-07 · Contacto `/contacto`
WhatsApp, Instagram y horario. Formulario de pedido especial (§3.3).

### P-08 · Pedido `/pedido` (panel lateral más página de pago)
Se arma en cuatro pasos visibles: **1 Resumen · 2 Datos y entrega · 3 Pago · 4 Enviar**.

1. **Resumen:** cada prenda con su miniatura, sus elecciones y su precio, y botones Editar y Quitar. Al final, el subtotal.
2. **Datos y entrega:** nombre, celular (para coordinar), recojo o delivery. Si es delivery: zona y referencia. El costo de entrega se suma al momento.
3. **Pago:**
   - Monto exacto en grande, con botón «Copiar monto».
   - Código del pedido (por ejemplo `BR-2610-K7Q`), con el texto «Escribilo en la glosa o referencia de la transferencia».
   - Imagen del QR y datos del titular de la cuenta.
   - En el celular: **«Guardar QR»**, con la ayuda «Abrí tu app del banco › Pagar con QR › elegí la imagen de tu galería».
   - En la compu: «Escaneá este QR con la app de tu banco».
   - Casilla: «Ya pagué Bs —».
4. **Enviar:** «Enviar pedido por WhatsApp», con el recordatorio «Adjuntá la captura del comprobante antes de enviar».

### P-09 · Confirmación `/pedido/enviado`
Código del pedido, qué pasa ahora («El taller revisa tu comprobante y te confirma la fecha por WhatsApp»), un botón para volver a abrir WhatsApp por si no se abrió y la opción «Armar otro pedido».

### 4.9 · Pie (todas las páginas)
Logo, enlaces a las secciones, WhatsApp, Instagram y TikTok, la frase «Hecho en Cochabamba» y el aviso de precios vigentes con su fecha.

---

## 5. El mensaje de WhatsApp

Es el centro del sistema: reemplaza al formulario, a la base de datos y a la confirmación por correo. Se arma en el navegador y se abre con `https://wa.me/591XXXXXXXX?text=<mensaje codificado>`.

**Plantilla (los valores entre <> salen del pedido):**

```
Hola BRAVA, quiero confirmar mi pedido <BR-2610-K7Q>.

1) Canguro · Verde monte · Talla M
   Diseño: Paraba frente roja
   Ubicación: Espalda (30 × 35 cm) + logo en pecho
   Texto: COCHABAMBA
   Tintas: 2 (Hueso + Ocre)
   Cantidad: 1 · Bs <220>

2) Gorra · Carbón · Talla única
   Diseño: Tunari · Frente (10 × 6 cm) · 1 tinta (Hueso)
   Cantidad: 1 · Bs <90>

Subtotal: Bs <310>
Entrega: Delivery · Zona <Queru Queru> · Ref.: <…> · Bs <15>
TOTAL PAGADO: Bs <325> por QR

Nombre: <…>
Celular: <…>

Adjunto el comprobante de pago.
```

**Reglas del mensaje:**
- Siempre lleva el código del pedido y el total exacto, que es lo que el taller compara con el comprobante.
- Una línea por cada dato que el taller necesita para producir. Nada queda librado a «lo que hablamos».
- Hay que probarlo en WhatsApp de Android, de iPhone y en WhatsApp Web, porque el texto largo y los saltos de línea se codifican distinto.
- Con muchas prendas el enlace se alarga. Se resumen las líneas cuando pasa de unos 1.500 caracteres; el límite exacto se mide en las pruebas.

**Compartir la imagen junto con el texto (mejora opcional):** en celulares que lo permiten, el botón puede usar la función de compartir del sistema para mandar a WhatsApp una imagen generada con la ficha del pedido y la vista previa del diseño, junto con el texto. Donde no se pueda, se descarga la imagen y se abre el enlace `wa.me` con el texto. El comprobante siempre lo adjunta el cliente, porque la web no puede tomarlo de la app del banco.

---

## 6. Riesgos del QR estático y cómo cubrirlos

| Riesgo | Qué puede pasar | Cómo se cubre en la arquitectura |
|---|---|---|
| El QR no lleva el monto | El cliente escribe otro monto | Monto en grande, botón «Copiar monto» y la casilla «Ya pagué Bs —». El taller compara contra el mensaje |
| Pagos sin identificar | Llegan dos pagos iguales el mismo día | El código del pedido va en la glosa y en el mensaje |
| QR en la misma pantalla | En el celular no se puede escanear la propia pantalla | «Guardar QR» y la ayuda para pagar desde la galería |
| Paga y no envía el WhatsApp | Hay plata sin pedido | El pedido queda guardado en el navegador. La confirmación ofrece «Volver a abrir WhatsApp» |
| WhatsApp no se abre (compu sin WhatsApp) | El cliente se traba | El enlace abre WhatsApp Web, y hay un botón «Copiar mensaje» como respaldo |
| QR vencido o cambiado | Pagos a una cuenta vieja | El QR es un solo archivo de configuración, con fecha de vigencia |
| Precios desactualizados | Margen negativo por la inflación | Precios en un solo archivo con fecha visible, revisados al menos cada trimestre |

---

## 7. Modelo de datos

Todo el catálogo vive en archivos JSON. Cambiar un precio, sumar un diseño o cambiar el QR no requiere tocar código.

### 7.1 `config.json`
```jsonc
{
  "whatsapp": "591XXXXXXXX",              // ejemplo
  "qr": { "imagen": "/pago/qr.png", "titular": "…", "banco": "…", "vigente_hasta": "2027-01-31" },
  "precios_vigentes_desde": "2026-11-01",
  "moneda": "Bs",
  "entrega": [
    { "id": "recojo",   "nombre": "Recojo en el taller", "costo": 0 },
    { "id": "delivery", "nombre": "Delivery en Cochabamba", "costo": 15, "pide_zona": true }   // ejemplo
  ],
  "plazo_dias_habiles": [5, 7]            // ejemplo
}
```

### 7.2 `prendas.json`
```jsonc
[
  {
    "id": "canguro",
    "nombre": "Canguro",
    "precio_base": 180,                    // ejemplo
    "colores": ["carbon", "hueso", "monte"],
    "tallas": ["S", "M", "L", "XL"],
    "ubicaciones": ["pecho", "espalda", "pecho_espalda"],
    "vistas": { "frente": "canguro-frente.svg", "espalda": "canguro-espalda.svg" },
    "zonas": {                             // dónde cae el estampado en el dibujo
      "pecho":   { "x": 230, "y": 118, "ancho": 38 },
      "espalda": { "x": 140, "y": 128, "ancho": 120 }
    },
    "tela": "…"                            // a confirmar con el proveedor
  }
]
```

### 7.3 `colores.json`
```jsonc
[{ "id": "monte", "nombre": "Verde monte", "hex": "#264A3B", "oscuro": true }]
```
El campo `oscuro` decide la tinta principal: hueso sobre prendas oscuras y carbón sobre prendas claras.

### 7.4 `disenos.json`
```jsonc
[
  {
    "id": "paraba",
    "nombre": "Paraba frente roja",
    "dato": "Ara rubrogenys",
    "coleccion": "fauna-brava",
    "archivo": "/disenos/paraba.svg",       // capas .tinta1 y .tinta2
    "prendas": ["canguro", "polera", "gorra"],
    "tintas_max": 2,
    "historia": "…"                         // texto verificado
  }
]
```

### 7.5 `ubicaciones.json` y `tintas.json`
```jsonc
[
  { "id": "pecho",         "nombre": "Pecho",           "extra": 15, "medida": "10 × 10 cm" },
  { "id": "espalda",       "nombre": "Espalda",         "extra": 30, "medida": "30 × 35 cm", "logo_pecho": true },
  { "id": "pecho_espalda", "nombre": "Pecho + espalda", "extra": 40 },
  { "id": "frente",        "nombre": "Frente",          "extra": 20, "medida": "10 × 6 cm", "solo": ["gorra"] }
]
// tintas.json
{ "segunda_tinta_extra": 10, "acentos": [{ "id": "ocre", "hex": "#D9A93F" }, { "id": "terra", "hex": "#C65A34" }] }
```
Todos los montos son de ejemplo.

### 7.6 El pedido (vive en el navegador, no en un servidor)
```jsonc
{
  "codigo": "BR-2610-K7Q",                   // fecha + 3 caracteres al azar
  "items": [
    { "prenda": "canguro", "color": "monte", "talla": "M", "diseno": "paraba",
      "ubicacion": "espalda", "texto": "COCHABAMBA", "tintas": 2, "acento": "ocre",
      "cantidad": 1, "precio_unitario": 220 }
  ],
  "cliente": { "nombre": "", "celular": "" },
  "entrega": { "tipo": "delivery", "zona": "", "referencia": "" },
  "total": 0,
  "creado": "2026-10-23T15:20:00-04:00"
}
```
Se guarda en el navegador para que el cliente no pierda el pedido si cierra la pestaña. Si los precios cambian entre que armó y que paga, el resumen recalcula y avisa.

---

## 8. Lógica del personalizador

### 8.1 Precio
```
precio_unitario = prenda.precio_base
                + ubicacion.extra
                + (tintas == 2 ? segunda_tinta_extra : 0)
total = Σ (precio_unitario × cantidad) + entrega.costo
```
El costo real que respalda cada número es **prenda + estampado + personalización + empaque + otros + margen**. Los valores salen de cotizar con el taller y se revisan al menos cada trimestre.

### 8.2 Reglas de combinación
1. La ubicación debe estar en `prenda.ubicaciones`. La gorra solo admite «frente».
2. El diseño debe incluir la prenda en `diseno.prendas`.
3. El paso de texto solo aparece si hay estampado en la espalda.
4. El acento no puede ser igual al color de la prenda.
5. La tinta principal se elige sola según `color.oscuro`.
6. Al cambiar de prenda se conserva lo que siga siendo válido y lo demás se reemplaza por el primer valor válido, sin dejar el formulario vacío.

### 8.3 Vista previa
- Prenda dibujada en vectores, con el color como variable. Así un color nuevo no necesita una foto nueva.
- Diseño en vectores con dos capas de tinta, colocado en la zona de la prenda.
- Cambia de lado sola: pecho muestra el frente; espalda y pecho + espalda muestran la espalda.
- Para la v2, las fotos reales de producto pueden reemplazar los dibujos sin cambiar la lógica.

---

## 9. Componentes

| Componente | Dónde aparece | Estados que tiene que resolver |
|---|---|---|
| Barra superior con «Pedido (n)» | Todas | Pedido vacío y con prendas |
| Botón principal y secundario | Todas | Normal, al pasar el cursor, al tocar, enfocado y desactivado |
| Tarjeta de diseño | Inicio, Colecciones | Diseño no disponible para la prenda actual |
| Vista previa de prenda | Personalizador, Pedido | Frente o espalda; gorra sin espalda |
| Selector de opciones (prenda, color, talla, ubicación, tintas) | Personalizador | Elegido, desactivado con motivo |
| Orden de taller | Personalizador | Precio que se actualiza |
| Barra inferior fija (celular) | Personalizador, Pedido | Precio, acción del paso |
| Panel de pedido | Global | Vacío, con prendas, editando |
| Pasos del pedido (1 a 4) | /pedido | Paso actual, completo, con error |
| Bloque de pago QR | /pedido | Celular o compu, QR que no carga |
| Botón «Enviar por WhatsApp» | /pedido | Abierto, falló, copiar como respaldo |
| Tabla de tallas | Guía de tallas | Desplazamiento horizontal en el celular |
| Aviso breve | Global | «Agregado», «Copiado» |
| Acordeón de preguntas | Cómo comprar | Abierto y cerrado |

---

## 10. Estados y casos borde

| Situación | Qué ve el cliente |
|---|---|
| Pedido vacío | «Todavía no agregaste prendas» y el botón «Armar la primera» |
| Combinación inválida | La opción aparece desactivada con su motivo, por ejemplo «La gorra solo se estampa al frente» |
| Falta el nombre o el celular | Error junto al campo: «Escribí tu celular para coordinar la entrega» |
| Delivery sin zona | Error junto al campo, sin borrar lo demás |
| El QR no carga | Datos de la cuenta en texto y el botón «Pedir el QR por WhatsApp» |
| Celular sin WhatsApp | Abre WhatsApp Web y ofrece «Copiar mensaje» |
| Cambio de precios | «Los precios cambiaron el <fecha>; revisá tu total» antes del pago |
| Diseño agotado o retirado | Desaparece del catálogo y, si estaba en un pedido guardado, se avisa |
| Sin conexión a mitad del pedido | El pedido queda guardado. Al volver sigue donde estaba |

---

## 11. Celular primero, accesibilidad y movimiento

**Celular.** Se diseña primero a 375 px y después se amplía a 768, 1024 y 1440. La vista previa ocupa el tercio superior y queda fija; las opciones se recorren debajo. Las acciones van en la barra inferior, al alcance del pulgar. Nada se desplaza de costado salvo la tabla de tallas, dentro de su propio recuadro.

**Accesibilidad (WCAG 2.2 AA).**
- Contraste de 4,5:1 en texto normal y de 3:1 en texto grande, en modo claro y oscuro.
- Objetivos táctiles de 44 × 44 px como mínimo, con 8 px de separación.
- Las opciones son controles reales (botones de opción con su etiqueta), así que se usan con teclado y lector de pantalla.
- La vista previa tiene una descripción en texto que se actualiza: «Canguro verde monte, espalda, paraba frente roja».
- Etiquetas visibles en todos los campos. El texto de ejemplo dentro del campo no reemplaza a la etiqueta.
- Errores junto al campo, que explican cómo corregir.
- El color nunca es la única señal: cada muestra lleva su nombre.

**Movimiento** (criterios de Emil Kowalski).
- Solo se anima lo que ayuda a entender:
  - el estampado aparece de arriba abajo, como el paso de la racleta, cuando cambia el diseño o la ubicación;
  - el panel de pedido se desliza desde el lado donde está su botón;
  - los botones se hunden un poco al tocarlos.
- No se animan las elecciones que se repiten mucho: talla, color y pasos.
- Entradas con curva de salida rápida y en menos de 300 ms. La salida es más rápida que la entrada.
- Solo se anima posición y opacidad, para no trabar celulares de gama media.
- Con movimiento reducido activado, los cambios son instantáneos o con un fundido corto.

**Rendimiento.** Pensado para datos móviles prepagos: prendas y diseños en vectores (pocos KB), fotos en WebP o AVIF que cargan al acercarse, dos familias tipográficas como máximo y nada de video en la portada. La primera pantalla debería pesar menos de 1 MB.

---

## 12. Tecnología propuesta (por confirmar)

| Pieza | Propuesta | Alternativa |
|---|---|---|
| Sitio | HTML, CSS y JavaScript sin framework, o Astro si se suman muchas páginas | Shopify, Tiendanube o WooCommerce: mucho más pesados para un pedido por WhatsApp |
| Catálogo | Archivos JSON (§7) en el mismo repositorio | Una planilla de Google exportada a JSON |
| Alojamiento | GitHub Pages (gratis, ya usado en otros proyectos) | Netlify o Cloudflare Pages |
| Dominio | Por definir (por ejemplo, un `.bo` o un `.shop`) | Subdominio gratuito en la etapa académica |
| Pedidos | Mensaje de WhatsApp más el pedido guardado en el navegador | v2: registrar cada pedido en una planilla por medio de un formulario |
| Medición | Eventos: abrió el personalizador, agregó al pedido, llegó al pago, tocó WhatsApp | Meta Pixel cuando haya anuncios |

**Estructura de carpetas sugerida:**
```
brava/
├── index.html
├── personaliza/        colecciones/       disenos/
├── guia-de-tallas/     como-comprar/      contacto/      pedido/
├── data/               config.json · prendas.json · colores.json · disenos.json · ubicaciones.json · tintas.json
├── assets/
│   ├── prendas/        canguro-frente.svg · canguro-espalda.svg · polera-… · gorra-frente.svg
│   ├── disenos/        paraba.svg · jucumari.svg · condor.svg · tunari.svg · cristo.svg · kantuta.svg
│   ├── pago/           qr.png
│   └── fotos/
└── js/
    ├── catalogo.js     (lee los JSON)
    ├── personalizador.js  (estado, reglas §8.2, vista previa)
    ├── precio.js       (§8.1)
    ├── pedido.js       (guardar, editar, código)
    └── whatsapp.js     (arma el mensaje §5 y el enlace)
```

---

## 13. Lo que necesita el taller antes de construir

1. Precios por prenda, por ubicación y por tinta extra, después de cotizar.
2. Colores reales que tiene el proveedor por prenda.
3. Medidas reales de cada talla.
4. Técnica para gorras: serigrafía directa, transfer o bordado.
5. Plazo de elaboración y zonas y costo del delivery.
6. Número de WhatsApp Business, banco, titular e imagen del QR.
7. Los seis diseños finales en vectores, a una o dos tintas.
8. Fotos de prendas reales, aunque sean de muestra.

## 14. Fuera de la v1 (posible v2)

- Subir una imagen propia, con revisión manual de resolución y viabilidad.
- QR dinámico con monto y confirmación automática (requiere un banco o una pasarela).
- Pedidos registrados en una planilla y estados visibles para el cliente.
- Colecciones por departamento completas y fotos de producto en lugar de los dibujos.
- Precio por cantidad para pedidos grupales.

---

## 15. Notas para la etapa de maqueta

- La paleta y la voz de la propuesta (§ Brand Commitments en `PRODUCT.md`) mandan. La paleta genérica de e-commerce que sugirió UI UX Pro Max (verde y naranja, Rubik y Nunito Sans) se descarta porque no tiene que ver con la marca.
- De UI UX Pro Max se toman las reglas de calidad: contraste, objetivos táctiles, foco visible, movimiento reducido, cursor en todo lo que se puede tocar, íconos en SVG y no emojis, y pruebas a 375, 768, 1024 y 1440 px.
- De Impeccable: el sitio funciona en modo **Persuadir** en Inicio y Colecciones, y en modo **Operar** en el personalizador y el pedido, donde manda que se entienda rápido.
- Ya existe un borrador de maqueta en `Brava Proyect/index.html`. Está pausado, sin revisar y sin publicar, y se ajustará a esta arquitectura cuando se apruebe (falta el paso de pago con QR, por ejemplo).
