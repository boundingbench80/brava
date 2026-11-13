# Resultado: prendas BRAVA con volumen

Se crearon cinco SVG independientes en `viewBox="0 0 400 440"`, sin dimensiones fijas, con cuerpos coloreables mediante `--garment`. Incluyen gradientes de luz y sombra, interiores oscuros, costuras, detalles de construcción y recorte de las capas de volumen a la silueta. Se conservaron las zonas de estampado sin costuras ni pliegues fuertes.

Archivos entregados:

- `canguro-frente.svg`
- `canguro-espalda.svg`
- `polera-frente.svg`
- `polera-espalda.svg`
- `gorra-frente.svg`
- `prueba.html`: 40 instancias inline (cinco prendas en cada uno de ocho colores), con IDs reescritos para que no colisionen entre instancias.
- `captura-prueba.png`: captura de Edge headless del HTML de prueba.

## Verificación

- Los cinco SVG parsean como XML y cada uno pesa menos de 5 KB (límite solicitado: 25 KB).
- Edge generó la captura del HTML completo. Se revisó visualmente: las luces y sombras conservan contraste sobre marfil, negro y azul marino, además de los otros cinco colores.
- Chrome está instalado, pero su proceso headless falló al iniciar el proceso GPU; Edge produjo la captura solicitada.

## Qué quedó flojo

- Son ilustraciones vectoriales de producto, no fotografías: el volumen se entiende, aunque el acabado todavía se percibe estilizado y simplificado frente a una foto real de maniquí fantasma.
- La gorra es frontal; la curvatura de la visera se ve, pero el ángulo leve 3/4 habría dado más profundidad.
- La textura acanalada está sugerida con líneas y sombreado, sin patrón de tejido fino.
