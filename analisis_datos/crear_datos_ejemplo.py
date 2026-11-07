"""
DATOS DE EJEMPLO
================
Crea datos/ventas_ejemplo.csv: ventas inventadas de una tienda, para probar
el analizador. Tiene "errores" a propósito (filas repetidas, celdas vacías,
precios con "$") para que veas cómo se limpian.

Cuando tengas tus propios datos ya no necesitas este archivo.

    python crear_datos_ejemplo.py
"""

import random
from datetime import date, timedelta

import config

random.seed(42)  # Siempre genera los mismos datos

PRODUCTOS = {
    "Refresco": ("Bebidas", 18), "Agua": ("Bebidas", 12), "Café": ("Bebidas", 35),
    "Papas": ("Botanas", 20), "Galletas": ("Botanas", 16), "Cacahuates": ("Botanas", 14),
    "Pan": ("Panadería", 8), "Pastel": ("Panadería", 250), "Leche": ("Lácteos", 28),
    "Queso": ("Lácteos", 65), "Yogurt": ("Lácteos", 15),
}
CIUDADES = ["CDMX", "CDMX", "CDMX", "Guadalajara", "Guadalajara", "Monterrey", "Puebla"]
PAGOS = ["Efectivo", "Efectivo", "Tarjeta", "Transferencia"]


def crear_filas(cantidad=600):
    inicio = date(2026, 1, 1)
    filas = []
    for _ in range(cantidad):
        dia = inicio + timedelta(days=random.randint(0, 299))
        producto = random.choice(list(PRODUCTOS))
        categoria, precio = PRODUCTOS[producto]
        # Más ventas en diciembre-ish y fines de semana
        piezas = random.randint(1, 6) + (2 if dia.weekday() >= 5 else 0)
        total = piezas * precio
        filas.append([
            dia.strftime("%d/%m/%Y"), producto, categoria, piezas,
            f"${precio}", total, random.choice(CIUDADES),
            random.choice(PAGOS) if random.random() > 0.08 else "",  # algunos vacíos
        ])
    filas += random.sample(filas, 12)  # filas repetidas a propósito
    return filas


def main():
    ruta = config.CARPETA_DATOS / "ventas_ejemplo.csv"
    encabezado = "fecha,producto,categoria,piezas,precio_unitario,total,ciudad,metodo_pago"
    lineas = [encabezado] + [",".join(map(str, f)) for f in crear_filas()]
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")
    print(f"✅ Datos de ejemplo creados en {ruta}")


if __name__ == "__main__":
    main()
