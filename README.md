# harbour-quickchart-pdf

Ejemplo práctico de generación de PDF con gráficas profesionales en Harbour usando QuickChart + Chart.js v2.

---

## Descripción

Este repositorio contiene el código fuente del ejemplo publicado en el blog.  
Incluye una gráfica de barras con línea comparativa y una gráfica de dona, embebidas en un PDF generado con libharu (tpdfclass).

## Requisitos

- Harbour 3.x compilado con soporte curl y hbhpdf
- Docker Desktop instalado
- Contenedor QuickChart corriendo en puerto 3000

```bash
docker run -d -p 3000:3000 ianw/quickchart
```

## Entrada de blog

Para la explicación completa del problema, la solución y el paso a paso:

👉 **[Leer la entrada completa en el blog](https://jparadaa.github.io/2026/03/05/harbour-quickchart-pdf.html)**