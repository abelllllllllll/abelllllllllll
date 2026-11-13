# 📊 Analizador de datos

Le das un archivo de datos (CSV o Excel) y te regresa un **reporte fácil de leer**
con lo más importante, estadísticas y gráficas. Sin tener que programar nada.

👉 **Mira un ejemplo de reporte:** [resultados/ventas_ejemplo/REPORTE.md](resultados/ventas_ejemplo/REPORTE.md)

---

## 🚀 Cómo usarlo (3 pasos)

**1. Instalar lo necesario** (solo la primera vez):

```bash
pip install -r requirements.txt
```

**2. Poner tus datos** en la carpeta `datos/` (archivos `.csv` o `.xlsx`).

**3. Ejecutar:**

```bash
python analizar.py
```

Listo. Tu reporte aparece en `resultados/<nombre-de-tu-archivo>/REPORTE.md`.

> 🔒 **Tus datos son privados:** lo que pongas en `datos/` y los reportes que se generen
> **nunca se suben a GitHub** (están bloqueados en `.gitignore`). Se quedan solo en tu computadora.
> Lo único que se sube son los datos de ejemplo, que son inventados.

> Si solo quieres analizar un archivo: `python analizar.py datos/mi_archivo.csv`

---

## 🗂️ Cómo está organizado

```
analisis_datos/
├── analizar.py              ← EL QUE EJECUTAS. Llama a los 5 pasos en orden.
├── config.py                ← AJUSTES. Cambia aquí cómo se comporta todo.
├── crear_datos_ejemplo.py   ← Crea datos inventados para practicar.
├── requirements.txt         ← Librerías que se necesitan.
├── CAMBIOS.md               ← Bitácora: qué se ha ido ajustando y por qué.
│
├── herramientas/            ← Cada archivo hace UNA sola cosa:
│   ├── cargar.py            ← 1. Abre el archivo (CSV o Excel)
│   ├── limpiar.py           ← 2. Quita duplicados, vacíos, convierte "$1,200" a número...
│   ├── resumir.py           ← 3. Calcula estadísticas y escribe hallazgos en español
│   ├── graficar.py          ← 4. Crea las gráficas
│   └── reporte.py           ← 5. Junta todo en REPORTE.md
│
├── datos/                   ← 📥 Aquí pones tus archivos
└── resultados/              ← 📤 Aquí salen los reportes y gráficas
```

**El flujo es siempre el mismo:**

```
tu archivo → cargar → limpiar → resumir → graficar → REPORTE.md
```

Si algo falla o quieres cambiar algo, ya sabes en qué archivo buscar.

---

## 📖 Qué te dice el reporte

| Sección | Qué significa |
|---|---|
| **Lo más importante** | Los hallazgos en frases simples. Empieza por aquí. |
| **¿Qué hay en los datos?** | Cuántas filas y columnas, y de qué tipo es cada una. |
| **Limpieza que se hizo** | Todo lo que se cambió en tus datos (nada se cambia a escondidas). |
| **Datos faltantes** | Qué columnas tienen celdas vacías. |
| **Estadísticas** | Suma, promedio, mínimo, máximo, etc. de cada columna numérica. |
| **Valores más comunes** | Lo que más se repite en cada columna de texto. |
| **Gráficas** | Lo mismo pero en dibujo. |

---

## 🧠 Glosario (en palabras simples)

- **Promedio:** sumas todo y lo divides entre cuántos hay.
- **Mediana:** el valor de en medio si ordenas todo de menor a mayor.
  Si el promedio y la mediana son muy distintos, hay valores extremos que "jalan" el promedio.
- **Desviación estándar (variación):** qué tan dispersos están los valores.
  Número chico = todos se parecen. Número grande = hay mucha diferencia entre ellos.
- **Correlación (relación):** número de -1 a 1 que dice si dos columnas se mueven juntas.
  - Cerca de **1**: cuando una sube, la otra también.
  - Cerca de **-1**: cuando una sube, la otra baja.
  - Cerca de **0**: no tienen que ver.
  - ⚠️ Que se muevan juntas **no significa** que una cause la otra.
- **Histograma:** gráfica que muestra cuántas veces aparece cada rango de valores.

---

## 🔧 Cómo ajustarlo

La mayoría de cambios se hacen en **`config.py`**, por ejemplo:

- `TOP_VALORES = 5` → cuántos valores comunes mostrar por columna.
- `UMBRAL_CORRELACION = 0.5` → qué tan fuerte debe ser una relación para mencionarla.
- `MAX_GRAFICAS_POR_TIPO = 6` → para que el reporte no sea demasiado largo.
- `PALABRAS_PARA_PROMEDIAR` → columnas que en la gráfica "por mes" se promedian en vez de sumarse (precios, edades, %...).
- `COLOR_PRINCIPAL` → el color de las gráficas.

Cada cambio importante se anota en [CAMBIOS.md](CAMBIOS.md).
