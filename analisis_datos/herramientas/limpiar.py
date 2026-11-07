"""
PASO 2: LIMPIAR
===============
Los datos reales casi siempre vienen "sucios": filas repetidas,
celdas vacías, números guardados como texto ("$1,200"), fechas como texto...
Aquí se arregla eso y se anota TODO lo que se cambió, para que sepas
exactamente qué le pasó a tus datos.
"""

import warnings

import pandas as pd

import config


def limpiar(tabla: pd.DataFrame) -> tuple[pd.DataFrame, list[str]]:
    """Regresa la tabla limpia y una lista de notas con lo que se hizo."""
    notas = []
    tabla = tabla.copy()

    # 1. Nombres de columnas sin espacios de más
    tabla.columns = [str(c).strip() for c in tabla.columns]

    # 2. Quitar filas y columnas completamente vacías
    filas_antes, columnas_antes = tabla.shape
    tabla = tabla.dropna(how="all").dropna(axis=1, how="all")
    if (n := filas_antes - len(tabla)):
        notas.append(f"Se quitaron {n} filas completamente vacías.")
    if (n := columnas_antes - tabla.shape[1]):
        notas.append(f"Se quitaron {n} columnas completamente vacías.")

    # 3. Quitar espacios de más dentro de los textos
    for columna in tabla.select_dtypes(include=["object", "string"]).columns:
        tabla[columna] = tabla[columna].str.strip()

    # 4. Quitar filas duplicadas
    if config.QUITAR_DUPLICADOS:
        duplicados = int(tabla.duplicated().sum())
        if duplicados:
            tabla = tabla.drop_duplicates()
            notas.append(f"Se quitaron {duplicados} filas repetidas.")

    # 5. Convertir texto a número o fecha cuando se pueda
    for columna in tabla.select_dtypes(include=["object", "string"]).columns:
        convertida, tipo = _intentar_convertir(tabla[columna])
        if tipo:
            tabla[columna] = convertida
            notas.append(f"La columna '{columna}' se convirtió a {tipo}.")

    if not notas:
        notas.append("Los datos ya venían limpios, no se cambió nada.")

    return tabla.reset_index(drop=True), notas


def _intentar_convertir(columna: pd.Series):
    """Prueba convertir una columna de texto a número y luego a fecha."""
    valores = columna.dropna()
    if valores.empty:
        return columna, None

    # ¿Es número? Quitamos símbolos comunes: $, comas de miles, %, espacios
    texto_limpio = (
        columna.astype("string")
        .str.replace(r"[$€%\s]", "", regex=True)
        .str.replace(",", "", regex=False)
    )
    como_numero = pd.to_numeric(texto_limpio, errors="coerce")
    if como_numero.notna().sum() / len(valores) >= config.PORCENTAJE_PARA_CONVERTIR:
        return como_numero, "número"

    # ¿Es fecha?
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")  # pandas avisa si adivina el formato
        como_fecha = pd.to_datetime(columna, errors="coerce", dayfirst=True)
    if como_fecha.notna().sum() / len(valores) >= config.PORCENTAJE_PARA_CONVERTIR:
        return como_fecha, "fecha"

    return columna, None
