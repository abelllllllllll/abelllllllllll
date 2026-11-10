"""
Cálculos del dosificador de yerba (sinfín).

Uso:   python calculos/dosificador.py
Después de la prueba con balanza, cambiá GRAMOS_POR_VUELTA_MEDIDO por el
valor real y volvé a correrlo.

Todos los valores marcados (MEDIR) son estimaciones: medilos.
"""
import math

# --- Sinfín (igual que en mecanica/dispositivo_mate.scad) ---
SINFIN_D = 21.4      # mm
NUCLEO_D = 9.0       # mm
PASO = 24.0          # mm
ALETA_ANG = 40       # grados

# --- Yerba (MEDIR) ---
DENSIDAD_YERBA = 0.30   # g/cm3: llená un vaso medidor de 100 cm3 sin apretar y pesalo
EFICIENCIA = 0.5        # fracción del volumen que realmente se llena (0,4-0,6)
GRAMOS_POR_VUELTA_MEDIDO = None   # p. ej. 0.62 después de la prueba

# --- Motor (MEDIR) ---
RPM_MOTOR = 150         # N20 de 6 V ~200 rpm, a ~4 V da ~150 rpm (MEDIR)

# --- Objetivo ---
DOSIS_G = 30.0   # mate camionero: tiendas indican 30-40 g de yerba (el plan decía 7-9 g)

# --- Tolva del equipo (volumen aproximado del concepto) ---
TOLVA_CM3 = 116 * 41 * 134 / 1000 * 0.9  # equipo de 200 mm de alto   # caja trasera, menos 10 % de esquinas


def main():
    vol_geo = math.pi / 4 * (SINFIN_D**2 - NUCLEO_D**2) * PASO * (1 - ALETA_ANG / 360) / 1000
    g_vuelta_teo = vol_geo * EFICIENCIA * DENSIDAD_YERBA
    g_vuelta = GRAMOS_POR_VUELTA_MEDIDO or g_vuelta_teo
    origen = "MEDIDO" if GRAMOS_POR_VUELTA_MEDIDO else "estimado"

    vueltas = DOSIS_G / g_vuelta
    segundos = vueltas / RPM_MOTOR * 60

    print("=== Dosificador ===")
    print(f"Volumen geométrico por vuelta: {vol_geo:.2f} cm3")
    print(f"Gramos por vuelta ({origen}): {g_vuelta:.2f} g")
    print(f"Vueltas para {DOSIS_G:.0f} g: {vueltas:.1f}")
    print(f"Tiempo a {RPM_MOTOR} rpm: {segundos:.1f} s  (objetivo del ciclo completo: < 45 s)")
    print()
    print("=== Tolva del equipo ===")
    gramos = TOLVA_CM3 * DENSIDAD_YERBA
    print(f"Volumen: {TOLVA_CM3:.0f} cm3 -> {gramos:.0f} g -> {gramos / DOSIS_G:.0f} dosis")
    print()
    print("=== Cómo medir el CV (objetivo < 15 %) ===")
    print("Hacé 10 dosis seguidas, pesá cada una y calculá:")
    print("  CV = desviación estándar / promedio x 100")
    ejemplo = [28.5, 31.2, 30.4, 27.9, 32.1, 29.6, 30.0, 31.5, 28.8, 30.7]
    prom = sum(ejemplo) / len(ejemplo)
    desv = math.sqrt(sum((x - prom) ** 2 for x in ejemplo) / (len(ejemplo) - 1))
    print(f"  Ejemplo inventado {ejemplo}: promedio {prom:.2f} g, CV {desv / prom * 100:.1f} %")


if __name__ == "__main__":
    main()
