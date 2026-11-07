"""
PASO 1: CARGAR
==============
Abre un archivo CSV o Excel y lo convierte en una tabla (DataFrame)
con la que pandas puede trabajar.
"""

from pathlib import Path

import pandas as pd


def cargar(ruta: Path) -> pd.DataFrame:
    """Lee el archivo y regresa la tabla."""
    ruta = Path(ruta)

    if not ruta.exists():
        raise FileNotFoundError(f"No encontré el archivo: {ruta}")

    extension = ruta.suffix.lower()

    if extension == ".csv":
        return _cargar_csv(ruta)

    if extension in (".xlsx", ".xls"):
        try:
            return pd.read_excel(ruta)
        except ImportError:
            raise ImportError(
                "Para leer Excel instala esto primero:  pip install openpyxl"
            )

    raise ValueError(f"No sé leer archivos '{extension}'. Usa CSV o Excel.")


def _cargar_csv(ruta: Path) -> pd.DataFrame:
    """
    Los CSV pueden venir separados por coma, punto y coma o tabulador,
    y con distintas codificaciones (acentos). Aquí probamos hasta que funcione.
    """
    for codificacion in ("utf-8", "utf-8-sig", "latin-1"):
        try:
            # sep=None hace que pandas adivine el separador
            return pd.read_csv(ruta, sep=None, engine="python", encoding=codificacion)
        except UnicodeDecodeError:
            continue

    raise ValueError(f"No pude leer {ruta.name}. Revisa que sea un CSV válido.")
