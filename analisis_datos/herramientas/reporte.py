"""
PASO 5: REPORTE
===============
Junta el resumen, la limpieza y las gráficas en un archivo REPORTE.md.
Markdown se ve bonito directo en GitHub o en VS Code (Ctrl+Shift+V).
"""

from datetime import datetime
from pathlib import Path

import pandas as pd

from herramientas.resumir import _n


def escribir_reporte(nombre: str, resumen: dict, notas: list[str],
                     graficas: list[tuple[str, str]], carpeta: Path) -> Path:
    tipos = resumen["tipos"]
    lineas = [
        f"# 📊 Reporte de análisis: `{nombre}`",
        f"_Generado el {datetime.now():%d/%m/%Y a las %H:%M}_",
        "",
        "## 1. Lo más importante",
        "",
        *[(f"  - {h[2:]}" if h.startswith("↳") else f"- {h}") for h in resumen["hallazgos"]],
        "",
        "## 2. ¿Qué hay en los datos?",
        "",
        f"- **Filas:** {resumen['filas']:,}",
        f"- **Columnas:** {resumen['columnas']}",
        f"- **Numéricas:** {_lista(tipos['numeros'])}",
        f"- **De texto:** {_lista(tipos['textos'])}",
        f"- **De fecha:** {_lista(tipos['fechas'])}",
        "",
        "## 3. Limpieza que se hizo",
        "",
        *[f"- {n}" for n in notas],
        "",
    ]

    if resumen["vacios"]:
        lineas += ["## 4. Datos faltantes", "", "| Columna | Celdas vacías | % |", "|---|---|---|"]
        lineas += [f"| {c} | {n} | {p:.1f}% |" for c, (n, p) in resumen["vacios"].items()]
        lineas.append("")
    else:
        lineas += ["## 4. Datos faltantes", "", "✅ No hay celdas vacías.", ""]

    if not resumen["numeros"].empty:
        lineas += ["## 5. Estadísticas de las columnas numéricas", "", _tabla_markdown(resumen["numeros"]), ""]

    if resumen["textos"]:
        lineas += ["## 6. Valores más comunes en columnas de texto", ""]
        for col, datos in resumen["textos"].items():
            lineas.append(f"**{col}** ({datos['distintos']} valores distintos)")
            lineas.append("")
            lineas += [f"- {v}: {c:,}" for v, c in datos["top"].items()]
            lineas.append("")

    if graficas:
        lineas += ["## 7. Gráficas", ""]
        for titulo, archivo in graficas:
            lineas += [f"### {titulo}", "", f"![{titulo}](graficas/{archivo})", ""]

    lineas += [
        "---",
        "💡 ¿No entiendes algún término? Revisa el glosario en el `README.md` del proyecto.",
    ]

    ruta = carpeta / "REPORTE.md"
    ruta.write_text("\n".join(lineas), encoding="utf-8")
    return ruta


def _lista(columnas):
    return ", ".join(f"`{c}`" for c in columnas) if columnas else "ninguna"


def _tabla_markdown(df: pd.DataFrame) -> str:
    encabezado = "| Columna | " + " | ".join(df.columns) + " |"
    separador = "|---" * (len(df.columns) + 1) + "|"
    filas = [f"| **{i}** | " + " | ".join(_n(v) for v in fila) + " |" for i, fila in df.iterrows()]
    return "\n".join([encabezado, separador, *filas])
