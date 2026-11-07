"""
ANALIZADOR DE DATOS
===================
Este es el archivo que ejecutas. Hace todo el análisis en 5 pasos:

    1. Cargar   -> abre tu archivo
    2. Limpiar  -> arregla los datos
    3. Resumir  -> calcula estadísticas y hallazgos
    4. Graficar -> crea las gráficas
    5. Reporte  -> lo junta todo en resultados/<nombre>/REPORTE.md

CÓMO USARLO
-----------
    python analizar.py                      # analiza TODOS los archivos de datos/
    python analizar.py datos/mi_archivo.csv # analiza solo ese archivo
"""

import sys
from pathlib import Path

import config
from herramientas.cargar import cargar
from herramientas.graficar import graficar
from herramientas.limpiar import limpiar
from herramientas.reporte import escribir_reporte
from herramientas.resumir import resumir


def analizar_archivo(ruta: Path) -> Path:
    """Analiza un archivo y regresa la ruta de su reporte."""
    nombre = ruta.stem
    carpeta_salida = config.CARPETA_RESULTADOS / nombre
    print(f"\n📂 Analizando: {ruta.name}")

    tabla = cargar(ruta)
    print(f"   1. Cargado: {len(tabla):,} filas y {tabla.shape[1]} columnas")

    tabla, notas = limpiar(tabla)
    print(f"   2. Limpio: {len(notas)} ajustes")

    resumen = resumir(tabla)
    print(f"   3. Resumen: {len(resumen['hallazgos'])} hallazgos")

    graficas = graficar(tabla, resumen["tipos"], carpeta_salida / "graficas")
    print(f"   4. Gráficas: {len(graficas)} creadas")

    ruta_reporte = escribir_reporte(nombre, resumen, notas, graficas, carpeta_salida)
    print(f"   5. ✅ Reporte listo: {ruta_reporte.relative_to(config.CARPETA_BASE)}")
    return ruta_reporte


def buscar_archivos() -> list[Path]:
    """Todos los archivos de datos que hay en la carpeta datos/."""
    return sorted(
        p for p in config.CARPETA_DATOS.iterdir()
        if p.suffix.lower() in config.EXTENSIONES_VALIDAS
    )


def main():
    if len(sys.argv) > 1:
        archivos = [Path(a) for a in sys.argv[1:]]
    else:
        archivos = buscar_archivos()

    if not archivos:
        print(f"No hay archivos para analizar. Pon un CSV o Excel en: {config.CARPETA_DATOS}")
        return

    for archivo in archivos:
        try:
            analizar_archivo(archivo)
        except Exception as error:  # Si un archivo falla, seguimos con los demás
            print(f"   ❌ No se pudo analizar {archivo.name}: {error}")


if __name__ == "__main__":
    main()
