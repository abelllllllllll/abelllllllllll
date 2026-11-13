"""
PASO 4: GRAFICAR
================
Crea las gráficas como imágenes PNG. Cada función crea un tipo de gráfica:

    histogramas      -> cómo se reparten los valores de cada columna numérica
    barras           -> los valores más comunes de cada columna de texto
    linea_de_tiempo  -> cómo cambian los números mes a mes (suma o promedio)
    mapa_correlacion -> qué columnas numéricas se mueven juntas
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # Dibuja sin abrir ventanas
import matplotlib.pyplot as plt
import pandas as pd

import config

plt.rcParams.update({"figure.figsize": (8, 4.5), "axes.spines.top": False, "axes.spines.right": False})


def graficar(tabla: pd.DataFrame, tipos: dict, carpeta: Path) -> list[tuple[str, str]]:
    """Crea todas las gráficas. Regresa una lista de (título, nombre_de_archivo)."""
    carpeta.mkdir(parents=True, exist_ok=True)
    graficas = []
    graficas += histogramas(tabla, tipos["numeros"], carpeta)
    graficas += barras(tabla, tipos["textos"], carpeta)
    graficas += linea_de_tiempo(tabla, tipos["fechas"], tipos["numeros"], carpeta)
    graficas += mapa_correlacion(tabla, tipos["numeros"], carpeta)
    return graficas


def histogramas(tabla, columnas, carpeta):
    resultado = []
    for col in columnas[: config.MAX_GRAFICAS_POR_TIPO]:
        fig, ax = plt.subplots()
        ax.hist(tabla[col].dropna(), bins=20, color=config.COLOR_PRINCIPAL, edgecolor="white")
        ax.axvline(tabla[col].mean(), color=config.COLOR_SECUNDARIO, linestyle="--", label="Promedio")
        ax.set(title=f"¿Cómo se reparte '{col}'?", xlabel=col, ylabel="Cantidad de filas")
        ax.legend()
        resultado.append(_guardar(fig, carpeta, f"histograma_{col}", f"Distribución de {col}"))
    return resultado


def barras(tabla, columnas, carpeta):
    resultado = []
    utiles = [c for c in columnas if 1 < tabla[c].nunique() <= config.MAX_CATEGORIAS_PARA_GRAFICAR]
    for col in utiles[: config.MAX_GRAFICAS_POR_TIPO]:
        conteo = tabla[col].value_counts().head(10).sort_values()
        fig, ax = plt.subplots()
        ax.barh(conteo.index.astype(str), conteo.values, color=config.COLOR_PRINCIPAL)
        ax.set(title=f"Lo más común en '{col}'", xlabel="Cantidad de filas")
        resultado.append(_guardar(fig, carpeta, f"barras_{col}", f"Valores más comunes de {col}"))
    return resultado


def linea_de_tiempo(tabla, fechas, numeros, carpeta):
    if not fechas or not numeros:
        return []
    col_fecha = fechas[0]
    resultado = []
    meses = tabla.set_index(col_fecha)[numeros].resample("MS")
    if meses.ngroups < 2:
        return []
    for col in numeros[: config.MAX_GRAFICAS_POR_TIPO]:
        promediar = _se_promedia(col)
        por_mes = meses[col].mean() if promediar else meses[col].sum()
        calculo = "promedio" if promediar else "suma"
        fig, ax = plt.subplots()
        ax.plot(por_mes.index, por_mes.values, marker="o", color=config.COLOR_PRINCIPAL)
        ax.set(title=f"'{col}' por mes ({calculo})", xlabel="Mes", ylabel=col)
        fig.autofmt_xdate()
        resultado.append(_guardar(fig, carpeta, f"tiempo_{col}", f"{col} a lo largo del tiempo"))
    return resultado


def _se_promedia(columna):
    """True si en esta columna sumar no tiene sentido (precios, edades, %...)."""
    nombre = columna.lower()
    return any(palabra in nombre for palabra in config.PALABRAS_PARA_PROMEDIAR)


def mapa_correlacion(tabla, numeros, carpeta):
    if len(numeros) < 2:
        return []
    matriz = tabla[numeros].corr()
    fig, ax = plt.subplots(figsize=(1.2 * len(numeros) + 3, 1.0 * len(numeros) + 2))
    imagen = ax.imshow(matriz, cmap="RdBu_r", vmin=-1, vmax=1)
    ax.set_xticks(range(len(numeros)), numeros, rotation=45, ha="right")
    ax.set_yticks(range(len(numeros)), numeros)
    for i in range(len(numeros)):
        for j in range(len(numeros)):
            ax.text(j, i, f"{matriz.iloc[i, j]:.2f}", ha="center", va="center", fontsize=9)
    fig.colorbar(imagen, ax=ax, label="Relación (-1 a 1)")
    ax.set_title("¿Qué columnas se mueven juntas?")
    return [_guardar(fig, carpeta, "correlaciones", "Relación entre columnas numéricas")]


def _guardar(fig, carpeta, nombre, titulo):
    nombre_archivo = _nombre_seguro(nombre) + ".png"
    fig.tight_layout()
    fig.savefig(carpeta / nombre_archivo, dpi=110)
    plt.close(fig)
    return titulo, nombre_archivo


def _nombre_seguro(texto):
    """Convierte un texto en un nombre de archivo sin espacios ni símbolos raros."""
    return "".join(c if c.isalnum() or c in "-_" else "_" for c in texto).lower()
