"""
PASO 3: RESUMIR
===============
Calcula las estadísticas importantes y las traduce a frases simples
("hallazgos") para que no tengas que interpretar tablas de números.
"""

import pandas as pd

import config


def tipos_de_columnas(tabla: pd.DataFrame) -> dict[str, list[str]]:
    """Separa las columnas en números, textos y fechas."""
    return {
        "numeros": tabla.select_dtypes(include="number").columns.tolist(),
        "fechas": tabla.select_dtypes(include="datetime").columns.tolist(),
        "textos": tabla.select_dtypes(include=["object", "string", "category"]).columns.tolist(),
    }


def resumir(tabla: pd.DataFrame) -> dict:
    """Regresa un diccionario con todo el resumen del análisis."""
    tipos = tipos_de_columnas(tabla)

    resumen = {
        "filas": len(tabla),
        "columnas": tabla.shape[1],
        "tipos": tipos,
        "vacios": _celdas_vacias(tabla),
        "numeros": _resumen_numeros(tabla, tipos["numeros"]),
        "textos": _resumen_textos(tabla, tipos["textos"]),
        "fechas": _resumen_fechas(tabla, tipos["fechas"]),
        "correlaciones": _correlaciones(tabla, tipos["numeros"]),
    }
    resumen["hallazgos"] = _hallazgos(tabla, resumen)
    return resumen


# --------------------------------------------------------------------------
# Piezas del resumen
# --------------------------------------------------------------------------

def _celdas_vacias(tabla):
    """Cuántas celdas vacías tiene cada columna (solo las que tienen)."""
    vacios = tabla.isna().sum()
    vacios = vacios[vacios > 0]
    return {col: (int(n), n / len(tabla) * 100) for col, n in vacios.items()}


def _resumen_numeros(tabla, columnas):
    if not columnas:
        return pd.DataFrame()
    resumen = tabla[columnas].agg(["count", "sum", "mean", "median", "min", "max", "std"]).T
    resumen.columns = ["Datos", "Suma", "Promedio", "Mediana", "Mínimo", "Máximo", "Variación (desv. est.)"]
    return resumen


def _resumen_textos(tabla, columnas):
    resultado = {}
    for col in columnas:
        conteo = tabla[col].value_counts()
        resultado[col] = {
            "distintos": int(tabla[col].nunique()),
            "top": conteo.head(config.TOP_VALORES),
        }
    return resultado


def _resumen_fechas(tabla, columnas):
    resultado = {}
    for col in columnas:
        fechas = tabla[col].dropna()
        if fechas.empty:
            continue
        resultado[col] = {
            "desde": fechas.min(),
            "hasta": fechas.max(),
            "dias": (fechas.max() - fechas.min()).days,
        }
    return resultado


def _correlaciones(tabla, columnas):
    """Pares de columnas numéricas que se mueven juntas."""
    if len(columnas) < 2:
        return []
    matriz = tabla[columnas].corr()
    pares = []
    for i, a in enumerate(columnas):
        for b in columnas[i + 1:]:
            valor = matriz.loc[a, b]
            if pd.notna(valor) and abs(valor) >= config.UMBRAL_CORRELACION:
                pares.append((a, b, valor))
    return sorted(pares, key=lambda p: -abs(p[2]))


# --------------------------------------------------------------------------
# Hallazgos en lenguaje simple
# --------------------------------------------------------------------------

def _hallazgos(tabla, resumen):
    frases = []

    for col, (n, pct) in resumen["vacios"].items():
        if pct >= 5:
            frases.append(f"⚠️ A la columna **{col}** le faltan datos en el {pct:.0f}% de las filas.")

    for col, datos in resumen["fechas"].items():
        frases.append(
            f"📅 Los datos van del **{datos['desde']:%d/%m/%Y}** al "
            f"**{datos['hasta']:%d/%m/%Y}** ({datos['dias']} días)."
        )

    for col, fila in resumen["numeros"].iterrows():
        promedio, mediana = fila["Promedio"], fila["Mediana"]
        frases.append(
            f"🔢 **{col}**: en promedio {_n(promedio)}, va de {_n(fila['Mínimo'])} a {_n(fila['Máximo'])}."
        )
        # Si el promedio está muy lejos de la mediana, hay valores extremos
        if mediana and abs(promedio - mediana) / abs(mediana) > 0.3:
            frases.append(
                f"↳ El promedio ({_n(promedio)}) es muy distinto a la mediana ({_n(mediana)}): "
                f"hay algunos valores muy {'altos' if promedio > mediana else 'bajos'} que jalan el promedio."
            )

    for col, datos in resumen["textos"].items():
        if datos["top"].empty:
            continue
        valor, veces = datos["top"].index[0], int(datos["top"].iloc[0])
        pct = veces / resumen["filas"] * 100
        frases.append(f"🏷️ En **{col}** lo más común es **{valor}** ({pct:.0f}% de las filas).")

    for a, b, r in resumen["correlaciones"]:
        sentido = "sube" if r > 0 else "baja"
        frases.append(f"🔗 Cuando **{a}** sube, **{b}** también {sentido} (relación de {r:.2f}).")

    return frases


def _n(valor):
    """Formatea un número de forma legible: 1234.5 -> 1,234.5"""
    if pd.isna(valor):
        return "-"
    if float(valor).is_integer():
        return f"{valor:,.0f}"
    return f"{valor:,.2f}"
