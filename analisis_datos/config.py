"""
CONFIGURACIÓN
=============
Aquí están los ajustes del análisis en un solo lugar.
Si quieres cambiar cómo se comporta el programa, cambia estos valores
(no hace falta tocar el resto del código).
"""

from pathlib import Path

# --- Carpetas -------------------------------------------------------------
CARPETA_BASE = Path(__file__).parent
CARPETA_DATOS = CARPETA_BASE / "datos"          # Aquí pones tus archivos
CARPETA_RESULTADOS = CARPETA_BASE / "resultados"  # Aquí salen los reportes

# Tipos de archivo que el programa sabe leer
EXTENSIONES_VALIDAS = [".csv", ".xlsx", ".xls"]

# --- Limpieza -------------------------------------------------------------
# Quitar filas repetidas exactamente iguales
QUITAR_DUPLICADOS = True

# Si una columna de texto se puede convertir a número o fecha en al menos
# este porcentaje de sus valores, se convierte automáticamente.
PORCENTAJE_PARA_CONVERTIR = 0.8

# --- Resumen --------------------------------------------------------------
# Cuántos valores más frecuentes mostrar por cada columna de texto
TOP_VALORES = 5

# A partir de qué valor una correlación se considera "notable" (0 a 1)
UMBRAL_CORRELACION = 0.5

# --- Gráficas -------------------------------------------------------------
# Máximo de gráficas por tipo (para que el reporte no sea eterno)
MAX_GRAFICAS_POR_TIPO = 6

# Una columna de texto con más valores distintos que esto no se grafica
# (por ejemplo, nombres o IDs, que no aportan en una gráfica de barras)
MAX_CATEGORIAS_PARA_GRAFICAR = 30

# Colores de las gráficas
COLOR_PRINCIPAL = "#4C72B0"
COLOR_SECUNDARIO = "#DD8452"
