"""
Simulación del equipo v1 para encontrar la "receta" (medidas y tiempos de partida).

Uso:   python calculos/simulacion.py            (necesita numpy y matplotlib)
Salida: tabla en pantalla + docs/v1/imagenes/simulacion.png

IMPORTANTE: es un MODELO con supuestos razonables, no una medición.
Sirve para elegir de dónde arrancar y qué medir. Los supuestos están en la
sección SUPUESTOS: cuando midas algo real, cambialo ahí y volvé a correr.
"""
import itertools
import math
import os

import numpy as np

rng = np.random.default_rng(7)

# ============================================================ SUPUESTOS
DOSIS_G = 30.0
DENSIDAD = 0.30            # g/cm3, yerba suelta (MEDIR)
LLENADO_BASE = 0.50        # fracción del volumen del sinfín que se llena
ALETA_FRAC = 40 / 360      # parte de la vuelta que ocupa la aleta
PALO_LARGO = 12.0          # mm, palo más largo esperado
TUBO_DE_MAX = 32.0         # mm, lo que entra entre el mate y el techo
LARGO_TUBO = 160.0         # mm

# Variabilidad de la dosis
SIGMA_VUELTA = 0.15        # variación al azar de cada vuelta
P_PALO = 0.03              # probabilidad de que un palo frene media vuelta de yerba
SIGMA_HUMEDAD = 0.03       # cambio de densidad de un día a otro
EFECTO_NIVEL = 0.06        # la tolva casi vacía da hasta 6 % menos
ERROR_PARADA = 0.15        # vueltas de más o de menos al frenar

# Motores N20 de 6 V: rpm sin carga -> par de bloqueo (N·m), valores típicos
MOTORES_N20 = {50: 0.20, 100: 0.12, 150: 0.08, 200: 0.06, 300: 0.04}
FUERZA_PALO = 5.0          # N para destrabar o cortar un palo
MARGEN_MIN = 1.8           # el motor debe tener al menos 1,8 veces la fuerza necesaria

# Limpieza
RPM_ROTOR = 130
PALETAS = 3
TRAMOS, TRAMO_S = 6, 2.5   # 6 tramos de 2,5 s alternando sentido

# Energía (batería 2S de 2600 mAh)
BATERIA_WH = 7.4 * 2.6 * 0.85
P_ROTOR_W, P_SINFIN_W, P_ELEC_W, P_LED_W = 4.0, 1.0, 0.4, 0.6
REPOSO_W = 0.0006          # sueño profundo + BMS

# Objetivos del plan
CV_OBJ, CICLO_OBJ_S, AUTONOMIA_OBJ = 15.0, 45.0, 20
TIEMPO_VUELTA_USUARIO_S = 6.0


# ============================================================ DOSIFICADOR
def g_por_vuelta(d_ext, nucleo, paso, rpm):
    vol = math.pi / 4 * (d_ext**2 - nucleo**2) * paso * (1 - ALETA_FRAC) / 1000
    llenado = LLENADO_BASE * (1 - 0.15 * rpm / 300) * (1 - 0.2 * max(0.0, paso / d_ext - 1))
    return vol * llenado * DENSIDAD


def simular_dosis(gpv, n=20000):
    """Monte Carlo: devuelve n dosis en gramos."""
    vueltas = DOSIS_G / gpv
    enteras = int(math.floor(vueltas))
    resto = vueltas - enteras
    por_vuelta = rng.normal(1.0, SIGMA_VUELTA, size=(n, enteras + 1))
    por_vuelta *= np.where(rng.random((n, enteras + 1)) < P_PALO, 0.5, 1.0)
    por_vuelta[:, -1] *= resto
    masa = por_vuelta.sum(axis=1) * gpv
    masa += rng.uniform(-ERROR_PARADA, ERROR_PARADA, n) * gpv
    masa *= rng.normal(1.0, SIGMA_HUMEDAD, n)
    masa *= 1 - EFECTO_NIVEL * (1 - rng.uniform(0.15, 1.0, n))
    return masa


def evaluar(d_ext, nucleo, paso, rpm_motor):
    rpm = rpm_motor * 0.85                       # con carga
    gpv = g_por_vuelta(d_ext, nucleo, paso, rpm)
    vueltas = DOSIS_G / gpv
    t = vueltas / rpm * 60
    masa_tubo = gpv * LARGO_TUBO / paso / 1000   # kg
    par = 2 * (6 * masa_tubo * 9.81 * d_ext / 2000 * 0.6) + FUERZA_PALO * d_ext / 2000
    geo = (
        paso * (1 - ALETA_FRAC) >= PALO_LARGO + 2          # pasa un palo entre aletas
        and (d_ext - nucleo) / 2 >= 5.5                      # canal radial
        and d_ext + 1.6 + 4.8 <= TUBO_DE_MAX                 # entra sobre el mate
        and vueltas >= 20                                    # resolución
        and t <= 16                                          # rápido
    )
    ok = geo and MOTORES_N20[rpm_motor] >= MARGEN_MIN * par  # el motor puede, con margen
    return dict(d=d_ext, nucleo=nucleo, paso=paso, rpm_motor=rpm_motor, rpm=rpm, gpv=gpv,
                vueltas=vueltas, t=t, par=par, margen=MOTORES_N20[rpm_motor] / par, ok=ok, geo=geo)


def buscar_receta():
    candidatos, sin_margen = [], []
    for d, nuc, paso, rpm in itertools.product(
            np.arange(18, 26.5, 0.5), [8, 9, 10], np.arange(14, 31, 1), MOTORES_N20):
        e = evaluar(float(d), nuc, float(paso), rpm)
        if e["geo"]:
            sin_margen.append(e)
        if e["ok"]:
            m = simular_dosis(e["gpv"], 4000)
            e["cv"] = m.std() / m.mean() * 100
            candidatos.append(e)
    # Puntaje: poca variación, rápido y con margen de fuerza
    for e in candidatos:
        e["puntaje"] = e["cv"] / 5 + e["t"] / 15 + 1.0 / e["margen"]
    candidatos.sort(key=lambda e: e["puntaje"])
    return candidatos, sin_margen


# ============================================================ LIMPIEZA
def limpieza():
    pasadas = RPM_ROTOR / 60 * PALETAS * TRAMOS * TRAMO_S * 0.9   # 10 % se pierde al invertir
    efic = np.linspace(0.005, 0.08, 200)       # fracción que saca cada pasada de paleta
    suelta = 0.35                              # parte que cae sola al dar vuelta el mate
    queda = (1 - suelta) * (1 - efic) ** pasadas
    necesaria = 1 - (0.10 / (1 - suelta)) ** (1 / pasadas)
    return pasadas, efic, 1 - queda, necesaria


# ============================================================ ENERGÍA Y USO
def energia(t_dosis):
    t_limp = TRAMOS * TRAMO_S + (TRAMOS - 1) * 0.15
    t_total = t_limp + TIEMPO_VUELTA_USUARIO_S + t_dosis
    j = P_ROTOR_W * t_limp + P_SINFIN_W * t_dosis + (P_ELEC_W + P_LED_W) * (t_total + 20)
    wh = j / 3600
    return t_limp, t_total, wh, BATERIA_WH / wh


def main():
    cand, sin_margen = buscar_receta()
    mejor = cand[0]
    actual = evaluar(21.4, 9, 24.0, 200)
    m_act = simular_dosis(actual["gpv"])
    actual["cv"] = m_act.std() / m_act.mean() * 100

    print(f"Combinaciones válidas: {len(cand)}")
    print("\n=== Las 5 mejores ===")
    print(" Ø ext  núcleo  paso  motor   g/vuelta  vueltas  tiempo   CV    margen de fuerza")
    for e in cand[:5]:
        print(f" {e['d']:5.1f}  {e['nucleo']:5d}  {e['paso']:4.0f}  {e['rpm_motor']:4d}    {e['gpv']:6.2f}   {e['vueltas']:6.1f}  {e['t']:5.1f} s  {e['cv']:4.1f} %   x{e['margen']:.1f}")
    print(f"\nDiseño anterior (Ø21,4 paso 24, 200 rpm): {actual['gpv']:.2f} g/vuelta, "
          f"{actual['t']:.1f} s, CV {actual['cv']:.1f} %, margen x{actual['margen']:.1f}, válido={actual['ok']}")

    masas = simular_dosis(mejor["gpv"])
    cv = masas.std() / masas.mean() * 100
    dentro = np.mean(np.abs(masas - masas.mean()) <= 0.15 * masas.mean()) * 100
    print(f"\n=== Receta: dosis de {DOSIS_G:.0f} g ===")
    print(f"Promedio {masas.mean():.1f} g, CV {cv:.1f} % (objetivo < {CV_OBJ:.0f} %), "
          f"{dentro:.1f} % de las dosis a ±15 %")
    print(f"El promedio queda {100 * (1 - masas.mean() / DOSIS_G):.1f} % abajo: se corrige con la calibración.")

    pasadas, efic, sacado, necesaria = limpieza()
    print("\n=== Limpieza ===")
    print(f"{pasadas:.0f} pasadas de paleta en {TRAMOS * TRAMO_S:.0f} s. Para llegar al 90 % cada pasada "
          f"tiene que sacar al menos el {necesaria * 100:.1f} % de lo que queda pegado.")

    t_limp, t_total, wh, ciclos = energia(mejor["t"])
    print("\n=== Ciclo y batería ===")
    print(f"Limpieza {t_limp:.1f} s + dar vuelta {TIEMPO_VUELTA_USUARIO_S:.0f} s + carga {mejor['t']:.1f} s "
          f"= {t_total:.1f} s (objetivo < {CICLO_OBJ_S:.0f} s)")
    print(f"{wh * 1000:.0f} mWh por ciclo -> {ciclos:.0f} ciclos por carga (objetivo >= {AUTONOMIA_OBJ})")
    dias_reposo = BATERIA_WH / (REPOSO_W * 24)
    print(f"En reposo la batería dura ~{dias_reposo / 30:.0f} meses.")
    for usos in (3, 6):
        print(f"Con {usos} mates por día: recarga cada ~{BATERIA_WH / (usos * wh + REPOSO_W * 24):.0f} días")

    # ---------------------------------------------------------------- gráfico
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    V, A, G = "#4f7a28", "#1e4d8c", "#5d685f"
    fig, ax = plt.subplots(2, 2, figsize=(13, 9.5))
    fig.patch.set_facecolor("white")

    a = ax[0, 0]
    for rpm_m, c in zip(MOTORES_N20, ["#1e4d8c", "#4f7a28", "#b8860b", "#c0622a", "#b3261e"]):
        pts = [e for e in sin_margen if e["rpm_motor"] == rpm_m]
        if pts:
            a.scatter([e["t"] for e in pts], [e["margen"] for e in pts], s=14, color=c, alpha=0.6,
                      edgecolor="none", label=f"motor de {rpm_m} rpm")
    a.axhline(MARGEN_MIN, color=G, ls="--", lw=1)
    a.text(4.2, MARGEN_MIN + 0.04, "margen mínimo ×1,8", color=G)
    a.scatter([mejor["t"]], [mejor["margen"]], s=240, facecolor="none", edgecolor="black", lw=2.5)
    a.annotate("receta", (mejor["t"], mejor["margen"]), textcoords="offset points", xytext=(-55, 14), weight="bold")
    a.legend(frameon=False, fontsize=9)
    a.set(xlabel="Tiempo de carga (s)", ylabel="Margen de fuerza del motor (veces)",
          title=f"1 · {len(sin_margen)} sinfines posibles: más rápido = menos fuerza")

    a = ax[0, 1]
    a.hist(masas, bins=60, color=V, alpha=0.85)
    for lim in (0.85, 1.15):
        a.axvline(masas.mean() * lim, color=G, ls="--", lw=1)
    a.set(xlabel="Gramos por dosis", ylabel="Cantidad de dosis (de 20.000)",
          title=f"2 · Dosis simuladas: CV {cv:.1f} %  ({dentro:.0f} % dentro de ±15 %)")

    a = ax[1, 0]
    a.plot(efic * 100, sacado * 100, color=A, lw=2.5)
    a.axhline(90, color=G, ls="--", lw=1)
    a.axvline(necesaria * 100, color=V, ls="--", lw=1.5)
    a.annotate(f"mínimo {necesaria * 100:.1f} % por pasada", (necesaria * 100, 60), textcoords="offset points",
               xytext=(8, 0), color=V, weight="bold")
    a.set(xlabel="Yerba pegada que saca cada pasada de paleta (%)", ylabel="Yerba retirada en 15 s (%)",
          title="3 · Limpieza: qué tiene que lograr cada pasada", ylim=(40, 101))

    a = ax[1, 1]
    partes = [("Limpieza", t_limp, A), ("Dar vuelta", TIEMPO_VUELTA_USUARIO_S, "#b8860b"), ("Carga", mejor["t"], V)]
    x = 0
    for nombre, dur, c in partes:
        a.barh(0, dur, left=x, color=c, height=0.5)
        a.text(x + dur / 2, 0, f"{nombre}\n{dur:.0f} s", ha="center", va="center", color="white", weight="bold")
        x += dur
    a.axvline(CICLO_OBJ_S, color="#b3261e", ls="--")
    a.text(CICLO_OBJ_S, 0.42, "objetivo 45 s ", ha="right", color="#b3261e")
    a.set(yticks=[], xlim=(0, 50), ylim=(-0.6, 0.6), xlabel="Segundos",
          title=f"4 · Ciclo completo: {t_total:.0f} s  ·  {ciclos:.0f} ciclos por carga de batería")

    for a in ax.flat:
        a.spines[["top", "right"]].set_visible(False)
        a.title.set_fontweight("bold")
    fig.suptitle("Simulación del equipo v1 (modelo con supuestos, no mediciones)", fontsize=15, weight="bold")
    plt.tight_layout()
    salida = os.path.join(os.path.dirname(__file__), "..", "docs", "v1", "imagenes", "simulacion.png")
    plt.savefig(salida, dpi=90)
    print(f"\nGráfico: {os.path.normpath(salida)}")


if __name__ == "__main__":
    main()
