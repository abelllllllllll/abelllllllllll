"""
Cálculo hidráulico: ¿qué presión y qué fuerza hacen falta para mover crema espesa?

Como no hay bomba ni crema para probar en real, este script es la "prueba de banco"
en papel. Compara dos sistemas:

  A) Bomba peristáltica barata en el mango + tubo largo hasta el cabezal.
  B) Jeringa de 60 ml empujada por un motorreductor N20 (6 V, 1:210, alimentado a
     3,7 V desde una celda 18650) + varilla roscada M5, con un tubo corto hasta el
     cabezal (el diseño elegido).

Modelo de la crema: fluido "ley de potencia" (pseudoplástico), que es como se comportan
las cremas: cuanto más rápido fluyen, menos viscosas parecen.
    tensión = K * (velocidad_de_cizalla ** n)
Valores típicos de la literatura de reología cosmética (orden de magnitud):
    loción espesa:            K ≈ 10  Pa·s^n, n ≈ 0.40
    crema emoliente:          K ≈ 50  Pa·s^n, n ≈ 0.30
    bálsamo / pomada densa:   K ≈ 200 Pa·s^n, n ≈ 0.25

Uso:  python3 hidraulica.py          (imprime tabla y guarda grafica_presion.png)
"""

import math

CREMAS = {
    "Loción espesa": (10.0, 0.40),
    "Crema emoliente": (50.0, 0.30),
    "Bálsamo denso": (200.0, 0.25),
}

CAUDAL_ML_S = 0.70          # caudal objetivo: una dosis de 2 ml en ~3 s
G = 9.81


def caida_presion_tubo(K, n, caudal_ml_s, diametro_int_mm, largo_mm):
    """Pérdida de presión (Pa) en un tubo recto para un fluido ley de potencia."""
    Q = caudal_ml_s * 1e-6
    R = diametro_int_mm / 2 * 1e-3
    L = largo_mm * 1e-3
    gamma_pared = (3 * n + 1) / n * Q / (math.pi * R ** 3)
    tau_pared = K * gamma_pared ** n
    return 2 * L * tau_pared / R


# ---------------------------------------------------------------- Sistema A
# Peristáltica genérica: tubo de bomba 3x5 mm, 0,6 m de tubo 4x6 hasta el cabezal,
# más 0,3 m de aspiración desde el depósito.
PERI_MAX_BAR = 1.0          # presión típica máxima de una peristáltica DC barata
PERI_ASPIRACION_MAX_BAR = 0.6   # depresión realista antes de cavitar / colapsar tubo


def sistema_peristaltica(K, n):
    impulsion = (caida_presion_tubo(K, n, CAUDAL_ML_S, 4, 600)
                 + caida_presion_tubo(K, n, CAUDAL_ML_S, 3, 80))
    aspiracion = caida_presion_tubo(K, n, CAUDAL_ML_S, 4, 300)
    return impulsion / 1e5, aspiracion / 1e5


# ---------------------------------------------------------------- Sistema B
JERINGA_DI_MM = 27.0        # jeringa 60 ml punta catéter (medir la tuya)
ROZ_EMBOLO_N = 15.0         # rozamiento del émbolo de goma (estimado, lubricado)
PASO_M5_MM = 0.8
RENDIMIENTO_HUSILLO = 0.20  # rosca métrica M5 en tuerca de acero, engrasada
PAR_N20_UTIL_KGCM = 0.35    # par continuo conservador: N20 6 V 1:210 a 3,7 V
PAR_N20_BLOQUEO_KGCM = 1.8  # par de bloqueo típico a 3,7 V (no trabajar ahí)
RPM_MOTOR = 90              # N20 6 V 1:210 (150 rpm a 6 V) a ~3,7 V


def sistema_jeringa(K, n):
    p = (caida_presion_tubo(K, n, CAUDAL_ML_S, 4, 20)       # punta catéter
         + caida_presion_tubo(K, n, CAUDAL_ML_S, 6, 150)    # tubo 6x9 hasta cabezal
         + caida_presion_tubo(K, n, CAUDAL_ML_S, 5, 25))    # canal del cabezal
    area = math.pi * (JERINGA_DI_MM / 2 * 1e-3) ** 2
    fuerza = p * area + ROZ_EMBOLO_N
    par_nm = fuerza * PASO_M5_MM * 1e-3 / (2 * math.pi * RENDIMIENTO_HUSILLO)
    par_kgcm = par_nm / G * 100
    return p / 1e5, fuerza, par_kgcm


def main():
    print(f"Caudal objetivo: {CAUDAL_ML_S} ml/s\n")
    print("A) PERISTÁLTICA + tubo largo (límite típico: "
          f"{PERI_MAX_BAR} bar impulsión, {PERI_ASPIRACION_MAX_BAR} bar aspiración)")
    for nombre, (K, n) in CREMAS.items():
        imp, asp = sistema_peristaltica(K, n)
        ok = imp <= PERI_MAX_BAR and asp <= PERI_ASPIRACION_MAX_BAR
        print(f"   {nombre:16s} impulsión {imp:5.2f} bar | aspiración {asp:5.2f} bar"
              f"  -> {'OK' if ok else 'NO FUNCIONA'}")

    print(f"\nB) JERINGA 60 ml + N20 + M5 (par útil ≈ {PAR_N20_UTIL_KGCM} kg·cm, "
          f"bloqueo ≈ {PAR_N20_BLOQUEO_KGCM} kg·cm)")
    for nombre, (K, n) in CREMAS.items():
        p, F, T = sistema_jeringa(K, n)
        margen = PAR_N20_UTIL_KGCM / T
        print(f"   {nombre:16s} presión {p:5.2f} bar | fuerza {F:5.1f} N | "
              f"par {T:4.2f} kg·cm -> margen x{margen:3.1f}"
              f"{'  OK' if margen >= 1 else '  OK pero más lento (lejos del bloqueo); con bálsamos usar N20 1:298'}")

    vol_mm = math.pi * (JERINGA_DI_MM / 2) ** 2 / 1000
    print(f"\nJeringa: {vol_mm:.3f} ml por mm de avance; "
          f"N20 {RPM_MOTOR} rpm x M5 = {RPM_MOTOR * PASO_M5_MM / 60:.2f} mm/s = "
          f"{RPM_MOTOR * PASO_M5_MM / 60 * vol_mm:.2f} ml/s")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        caudales = [i / 20 for i in range(1, 41)]
        fig, ax = plt.subplots(figsize=(7, 4))
        for nombre, (K, n) in CREMAS.items():
            ax.plot(caudales, [caida_presion_tubo(K, n, q, 4, 600) / 1e5 for q in caudales],
                    "--", label=f"A peristáltica · {nombre}")
            ax.plot(caudales, [(caida_presion_tubo(K, n, q, 4, 20)
                                + caida_presion_tubo(K, n, q, 6, 150)
                                + caida_presion_tubo(K, n, q, 5, 25)) / 1e5 for q in caudales],
                    label=f"B jeringa · {nombre}")
        ax.axhline(PERI_MAX_BAR, color="grey", lw=0.8)
        ax.text(0.1, PERI_MAX_BAR * 1.05, "límite peristáltica barata", fontsize=8)
        ax.set_xlabel("Caudal (ml/s)")
        ax.set_ylabel("Presión necesaria (bar)")
        ax.set_yscale("log")
        ax.set_title("Presión para mover la crema hasta el cabezal")
        ax.legend(fontsize=7)
        fig.tight_layout()
        fig.savefig("grafica_presion.png", dpi=120)
        print("\nGráfica guardada en grafica_presion.png")
    except ImportError:
        print("\n(matplotlib no instalado: sin gráfica)")


if __name__ == "__main__":
    main()
