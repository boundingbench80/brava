# BRAVA CRM · Simulación

Simulación local del CRM con datos ficticios, sin dependencias ni servicios externos. Los cambios del pipeline y del inventario se guardan en el navegador.

## Abrir

Desde la carpeta del proyecto, inicia el servidor estático incluido (usa solo Node integrado):

```sh
node crm/servidor.mjs
```

Abre `http://localhost:8000/` en el navegador. También funciona con cualquier servidor estático que sirva la carpeta `crm/`.

## Regenerar datos

Con Node.js 18 o posterior, ejecuta desde la raíz del proyecto:

```sh
node crm/sim/generar.mjs
```

El generador usa mulberry32 con semilla `20260501` y escribe `crm/data/sim.js`.
