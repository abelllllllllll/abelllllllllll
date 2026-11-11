"""
Simulación de escenarios: todos los tipos de mate, de yerba y de agua (estado de la yerba usada).

Uso:    python calculos/simulacion_escenarios.py     (necesita numpy y matplotlib)
Salida: docs/v1/simulaciones.md  +  docs/v1/imagenes/sim_*.png

IMPORTANTE: son MODELOS con supuestos, no mediciones. Sirven para ver qué
combinaciones van a andar bien, cuáles van a dar trabajo y qué conviene probar
primero. Cada número de las tablas CATÁLOGO es una estimación típica: cambiala
por la tuya cuando midas.
"""
import math
import os

import numpy as np

rng = np.random.default_rng(11)
AQUI = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.join(AQUI, "..", "docs", "v1")

# ====================================================================== EQUIPO (de equipo_v1.scad)
ASIENTO_R0, ASIENTO_R1, ASIENTO_Z0, ASIENTO_ANG = 20, 62, 64, 25
BOCA_TAPA = 127 - 12          # boca del techo menos el soporte de sensores
TECHO_LIBRE = 220 - 1.6 - 5   # debajo del reborde de la tapa
ROTOR_Z = 3 + 55 + 1 + 10     # donde arrancan las paletas
PALETAS = {"corta": 60, "media": 85, "larga": 110}
PALETA_RADIO = 42
NICHO_ANCHO, PLATO_Z, SALIDA_Z = 118, 32 + 8, 176.8
CAJON_CM3 = 520
TOLVA_CM3 = 560
TOLVA_ANG = 60
SINFIN_D, NUCLEO_D, PASO, ALETA = 24.0, 8.0, 30.0, 40 / 360
HOLGURA = 0.8                 # mm por lado entre sinfín y tubo
RPM = 85
PAR_MOTOR = 0.12              # N·m, N20 de 100 rpm
ROTOR_RPM, N_PALETAS = 130, 3
LIMPIEZA_S, LIMPIEZA_LARGA_S = 20.0, 40.0   # ciclo normal y limpieza larga
VOL_VUELTA = math.pi / 4 * (SINFIN_D**2 - NUCLEO_D**2) * PASO * (1 - ALETA) / 1000   # cm3


def z_asiento(r):
    return ASIENTO_Z0 + (r - ASIENTO_R0) * math.tan(math.radians(ASIENTO_ANG))


# ====================================================================== CATÁLOGO DE MATES
# nombre, boca interior, ancho máximo, alto, capacidad (ml), material, base plana
MATES = [
    ("Calabaza chica (porongo)", 45, 75, 85, 150, "calabaza", True),
    ("Calabaza mediana", 55, 90, 100, 220, "calabaza", True),
    ("Camionero", 70, 105, 130, 330, "calabaza", True),
    ("Imperial", 65, 100, 120, 300, "calabaza", True),
    ("Torpedo", 60, 85, 140, 300, "calabaza", True),
    ("Uruguayo boca ancha", 85, 120, 120, 450, "calabaza", True),
    ("Madera (algarrobo)", 50, 80, 95, 180, "madera", True),
    ("Palo santo", 48, 78, 90, 160, "madera", True),
    ("Vidrio forrado", 60, 80, 95, 200, "vidrio", True),
    ("Cerámica / enlozado", 65, 85, 90, 220, "ceramica", True),
    ("Acero térmico", 75, 85, 105, 240, "acero", True),
    ("Silicona", 62, 80, 85, 190, "silicona", True),
    ("Plástico (mate listo)", 60, 75, 90, 180, "plastico", True),
    ("Guampa (cuerno, tereré)", 55, 65, 150, 250, "cuerno", False),
]
# Cuánto se pega la yerba a cada material (1 = referencia; más = más pegada)
SUPERFICIE = {"calabaza": 1.30, "madera": 1.25, "cuerno": 1.10, "plastico": 0.90,
              "ceramica": 0.80, "vidrio": 0.78, "acero": 0.75, "silicona": 0.70}
LLENADO_MATE = 0.40           # fracción del volumen del mate que se llena de yerba

# ====================================================================== CATÁLOGO DE YERBAS
# nombre, densidad g/cm3, fracción de palo, palo más largo mm, fracción de polvo, ángulo de reposo
YERBAS = [
    ("Tradicional con palo", 0.30, 0.25, 12, 0.15, 42),
    ("Despalada (sin palo)", 0.33, 0.03, 5, 0.20, 44),
    ("Suave / bajo polvo", 0.28, 0.30, 14, 0.07, 40),
    ("Compuesta con hierbas", 0.27, 0.25, 15, 0.12, 45),
    ("Barbacuá / estacionada", 0.29, 0.30, 16, 0.10, 42),
    ("Para tereré (gruesa)", 0.26, 0.30, 18, 0.05, 38),
    ("Orgánica hoja gruesa", 0.25, 0.20, 14, 0.06, 40),
    ("Uruguaya (fina, sin palo)", 0.38, 0.00, 3, 0.45, 50),
    ("Chimarrão (brasileña)", 0.42, 0.05, 6, 0.65, 55),
]

# ====================================================================== AGUA / ESTADO DE LA YERBA USADA
# nombre, cuánto más pegada queda (1 = recién usada), agua libre que escurre (ml), g mojado por g seco
ESTADOS = [
    ("Recién usado, agua caliente", 1.0, 15, 3.0),
    ("Tereré recién usado (agua fría)", 1.0, 25, 2.6),
    ("Lavado, con mucha agua", 0.8, 40, 3.3),
    ("Reposado 2 horas", 1.3, 5, 2.9),
    ("Mate dulce (azúcar o miel)", 1.8, 12, 3.0),
    ("Con jugo (tereré con jugo)", 1.6, 25, 2.8),
    ("Seco de un día", 2.2, 0, 1.6),
    ("Seco de varios días", 3.5, 0, 1.2),
]
E0 = {"optimista": 0.06, "base": 0.03, "pesimista": 0.015}   # fracción que saca cada pasada de paleta


# ====================================================================== 1 · ¿ENTRA CADA MATE?
def analizar_mate(m):
    nombre, boca, ancho, alto, ml, material, plana = m
    prof = alto - 15
    r_apoyo = (boca + 10) / 2                       # el borde de la boca apoya en el cono
    zs = z_asiento(max(r_apoyo, ASIENTO_R0))
    problemas = []
    if r_apoyo < ASIENTO_R0:
        problemas.append("boca demasiado chica para el asiento")
    if r_apoyo > ASIENTO_R1:
        problemas.append("boca más grande que el asiento")
    if ancho > BOCA_TAPA:
        problemas.append(f"no pasa por la boca de arriba ({BOCA_TAPA} mm)")
    if zs + alto > TECHO_LIBRE:
        problemas.append("boca abajo choca con la tapa")
    if ancho > NICHO_ANCHO - 6:
        problemas.append("no entra en el nicho de carga")
    if PLATO_Z + alto > SALIDA_Z - 3:
        problemas.append("boca arriba choca con la salida de yerba")
    if not plana:
        problemas.append("no se para solo (base redonda)")
    # paleta más larga que entra con 5 mm de luz
    paleta = None
    for nom, hp in sorted(PALETAS.items(), key=lambda kv: -kv[1]):
        if ROTOR_Z + hp + 5 <= zs + prof:
            paleta = nom
            break
    if paleta is None:
        problemas.append("ninguna paleta entra")
    hp = PALETAS.get(paleta, 0)
    cobertura = min(1.0, PALETA_RADIO / (ancho / 2 - 6)) * min(1.0, (hp + 12) / prof) if paleta else 0
    dosis = LLENADO_MATE * ml * 0.30
    return dict(nombre=nombre, boca=boca, ancho=ancho, alto=alto, ml=ml, material=material,
                paleta=paleta, cobertura=cobertura, dosis=dosis, problemas=problemas,
                ok=not problemas)


# ====================================================================== 2 · LIMPIEZA
def limpieza(mate, estado, e0, segundos=LIMPIEZA_S):
    _, pegado, _, _ = estado
    adh = pegado * SUPERFICIE[mate["material"]]
    suelta = min(0.6, 0.35 / adh)                                  # cae sola al dar vuelta el mate
    e = e0 * mate["cobertura"] / adh
    pasadas = ROTOR_RPM / 60 * N_PALETAS * segundos * 0.9
    sacado = 1 - (1 - suelta) * (1 - e) ** pasadas
    sacado *= 0.85 + 0.15 * mate["cobertura"]                      # rincones donde no llega la paleta
    # tiempo para llegar al 90 %
    objetivo = 0.90 / (0.85 + 0.15 * mate["cobertura"])
    if objetivo >= 1 or e <= 0:
        t90 = float("inf")
    else:
        resto = (1 - objetivo) / (1 - suelta)
        t90 = 0.0 if resto >= 1 else math.log(resto) / math.log(1 - e) / (ROTOR_RPM / 60 * N_PALETAS * 0.9)
    return sacado, t90


# ====================================================================== 3 · DOSIFICACIÓN POR YERBA
def dosificar(yerba, dosis=30.0, n=20000):
    nombre, dens, palo, palo_max, polvo, reposo = yerba
    llenado = 0.455 * (1 + 0.25 * (polvo - 0.15)) * (1 - 0.25 * palo * max(0, palo_max - 12) / 12)
    gpv = VOL_VUELTA * llenado * dens
    vueltas = dosis / gpv
    ent = int(vueltas)
    sigma = 0.15 * (1 + palo)
    p_frena = 0.03 * (palo / 0.25) * (palo_max / 12)               # un palo frena media vuelta
    v = rng.normal(1.0, sigma, (n, ent + 1))
    v *= np.where(rng.random((n, ent + 1)) < p_frena, 0.5, 1.0)
    v[:, -1] *= vueltas - ent
    masa = v.sum(axis=1) * gpv
    masa += rng.uniform(-0.15, 0.15, n) * gpv
    masa *= rng.normal(1.0, 0.03, n)
    masa *= 1 - 0.06 * (1 - rng.uniform(0.15, 1.0, n))
    cv = masa.std() / masa.mean() * 100
    p_atasco_vuelta = 0.002 * (palo / 0.25) * max(0.0, (palo_max - 10) / 2)
    p_atasco = 1 - (1 - p_atasco_vuelta) ** vueltas                 # el equipo retrocede y sigue
    p_bloqueo = p_atasco * 0.05                                     # 3 reintentos no alcanzan
    p_puente = 0.3 / (1 + math.exp(-(reposo - (TOLVA_ANG - 8)) / 2.5))   # la yerba no baja en la tolva
    goteo = polvo * HOLGURA * 0.5                                   # g de polvo que se cuela por dosis
    cebadas = TOLVA_CM3 * dens / dosis
    return dict(nombre=nombre, dens=dens, gpv=gpv, vueltas=vueltas, t=vueltas / RPM * 60, cv=cv,
                p_atasco=p_atasco, p_bloqueo=p_bloqueo, p_puente=p_puente, goteo=goteo, cebadas=cebadas)


# ====================================================================== 4 · AGUA Y CAJÓN
def residuos(estado, dosis=30.0):
    nombre, _, agua, factor = estado
    masa = dosis * factor
    vol = masa / 0.55                                               # yerba mojada suelta
    return dict(nombre=nombre, masa=masa, vol=vol, agua=agua, ciclos=CAJON_CM3 / vol)


# ====================================================================== 5 · TOLERANCIAS DE IMPRESIÓN
def tolerancias(n=200000):
    """Probabilidad de que una pieza impresa roce o quede floja (error de impresión típico ±0,15 mm)."""
    err = lambda s: rng.normal(0, s, n)
    res = {}
    luz = HOLGURA + err(0.10) - err(0.10) - np.abs(err(0.15))       # tubo, sinfín y sinfín torcido
    res["Sinfín dentro del tubo (0,8 mm por lado)"] = (np.mean(luz < 0.15), np.mean(luz > 1.3))
    luz = 0.30 + err(0.12) - err(0.12)
    res["Tapa de limpieza en su rebaje (0,3 mm)"] = (np.mean(luz < 0.05), np.mean(luz > 0.6))
    luz = 0.50 + err(0.15) - err(0.15)
    res["Cajón en su boca (0,5 mm)"] = (np.mean(luz < 0.10), np.mean(luz > 0.9))
    luz = 0.125 + err(0.06) - err(0.03)
    res["Eje del motor en el sinfín (0,125 mm)"] = (np.mean(luz < 0.0), np.mean(luz > 0.25))
    luz = 0.30 + err(0.12) - err(0.12)
    res["Tolva sobre el cuello (0,3 mm)"] = (np.mean(luz < 0.05), np.mean(luz > 0.6))
    return res


# ====================================================================== 6 · UN AÑO DE USO
def un_anio(yerba_res, estado_res, mates_dia=3, n=2000):
    ciclos = mates_dia * 365
    atascos = rng.binomial(ciclos, yerba_res["p_atasco"], n)
    bloqueos = rng.binomial(ciclos, yerba_res["p_bloqueo"], n)
    puentes = rng.binomial(ciclos, yerba_res["p_puente"] * 0.1, n)
    return dict(ciclos=ciclos, atascos=atascos.mean(), bloqueos=bloqueos.mean(), puentes=puentes.mean(),
                recargas_tolva=ciclos / yerba_res["cebadas"], vaciados=ciclos / estado_res["ciclos"],
                cargas_bateria=ciclos / 440, horas_motor=ciclos * 30 / 3600,
                kg_yerba=ciclos * 30 / 1000)


# ====================================================================== 7 · SENSIBILIDAD
def sensibilidad():
    base = YERBAS[0]
    ref = dosificar(base)["cv"]
    filas = []
    for etiqueta, mod in [("Palo: 0 % a 40 %", [(2, 0.0), (2, 0.40)]),
                          ("Palo más largo: 6 a 20 mm", [(3, 6), (3, 20)]),
                          ("Polvo: 5 % a 50 %", [(4, 0.05), (4, 0.50)]),
                          ("Densidad: 0,25 a 0,40", [(1, 0.25), (1, 0.40)])]:
        vals = []
        for idx, val in mod:
            y = list(base)
            y[idx] = val
            vals.append(dosificar(tuple(y))["cv"])
        filas.append((etiqueta, min(vals), max(vals)))
    for etiqueta, dosis in [("Dosis: 15 g a 60 g", (60, 15))]:
        vals = [dosificar(base, d)["cv"] for d in dosis]
        filas.append((etiqueta, min(vals), max(vals)))
    return ref, filas


# ====================================================================== SALIDA
def pct(x):
    return f"{x * 100:.0f} %"


def main():
    mates = [analizar_mate(m) for m in MATES]
    yerbas = [dosificar(y) for y in YERBAS]
    res_est = [residuos(e) for e in ESTADOS]
    tol = tolerancias()
    ref_cv, sens = sensibilidad()

    L = []
    w = L.append
    w("# Simulaciones con todos los mates, yerbas y aguas\n")
    w("Generado por [`calculos/simulacion_escenarios.py`](../../calculos/simulacion_escenarios.py). "
      "Para rehacerlo: `python calculos/simulacion_escenarios.py`.\n")
    w("> **Son modelos con supuestos, no mediciones.** Los catálogos de mates y yerbas usan medidas típicas.\n"
      "> Lo que más vale de estas tablas es el **orden** (qué anda mejor y qué peor) y los **límites**\n"
      "> (qué no entra). Los porcentajes exactos se confirman con el equipo armado.\n")

    # ---- 1 mates
    w("## 1. ¿Qué mates entran?\n")
    w("| Mate | Boca | Ancho | Alto | ¿Entra? | Paleta | Dosis sugerida | Observaciones |")
    w("|---|---|---|---|---|---|---|---|")
    for m in mates:
        w(f"| {m['nombre']} | {m['boca']} mm | {m['ancho']} mm | {m['alto']} mm | "
          f"{'✅' if m['ok'] else '❌'} | {m['paleta'] or '—'} | {m['dosis']:.0f} g | "
          f"{'; '.join(m['problemas']) or '—'} |")
    n_ok = sum(m["ok"] for m in mates)
    w(f"\n**{n_ok} de {len(mates)} tipos entran sin cambios.** La dosis sugerida llena el "
      f"{LLENADO_MATE * 100:.0f} % del volumen del mate; se cambia con `d=<gramos>`.\n")

    # ---- 2 limpieza
    w("## 2. Limpieza: mate × estado de la yerba usada\n")
    w(f"Porcentaje de yerba retirada con la limpieza **normal de {LIMPIEZA_S:.0f} s** y, entre paréntesis, con la "
      f"**larga de {LIMPIEZA_LARGA_S:.0f} s** (escenario base). Meta: **90 %**.\n")
    ok_m = [m for m in mates if m["ok"]]
    w("| Mate | " + " | ".join(e[0] for e in ESTADOS) + " |")
    w("|---|" + "---|" * len(ESTADOS))
    matriz = np.zeros((len(ok_m), len(ESTADOS)))
    t90 = np.zeros_like(matriz)
    for i, m in enumerate(ok_m):
        fila = []
        for j, e in enumerate(ESTADOS):
            s, t = limpieza(m, e, E0["base"])
            s2, _ = limpieza(m, e, E0["base"], LIMPIEZA_LARGA_S)
            matriz[i, j], t90[i, j] = s, t
            fila.append(("✅ " if s >= 0.895 else "⚠️ " if s2 >= 0.895 else "❌ ") + f"{pct(s)} ({pct(s2)})")
        w(f"| {m['nombre']} | " + " | ".join(fila) + " |")
    w("\nSegundos necesarios para llegar al 90 % (promedio de todos los mates que entran):\n")
    w("| Estado de la yerba | Optimista | Base | Pesimista |")
    w("|---|---|---|---|")
    for j, e in enumerate(ESTADOS):
        celdas = []
        for esc in ("optimista", "base", "pesimista"):
            ts = [limpieza(m, e, E0[esc])[1] for m in ok_m]
            ts = [t for t in ts if math.isfinite(t)]
            med = np.median(ts) if ts else float("inf")
            celdas.append(f"{med:.0f} s" if med < 120 else "más de 2 min")
        w(f"| {e[0]} | " + " | ".join(celdas) + " |")
    w("\n✅ llega con la limpieza normal · ⚠️ llega con la limpieza larga · ❌ no llega ni con la larga.\n")
    w("**Lectura:** los mates **lisos** (vidrio, cerámica, acero, silicona) salen limpios casi siempre. "
      "Los **porosos** (calabaza, madera) llegan justo con yerba recién usada y necesitan la **limpieza larga** "
      "si la yerba reposó, es dulce o se secó. La yerba **seca de varios días** no sale bien de un mate poroso: "
      "ahí hay que mojarla un minuto antes o limpiar a mano. Por eso la limpieza normal pasó de 15 a 20 s.\n")

    # ---- 3 yerbas
    w("## 3. Dosificación con cada tipo de yerba (carga de 30 g)\n")
    w("| Yerba | g por vuelta | Vueltas | Tiempo | Variación (CV) | Se traba y se destraba solo | Bloqueo real | "
      "Hace puente en la tolva | Cebadas por tolva |")
    w("|---|---|---|---|---|---|---|---|---|")
    for y in yerbas:
        w(f"| {y['nombre']} | {y['gpv']:.2f} | {y['vueltas']:.0f} | {y['t']:.0f} s | {y['cv']:.1f} % | "
          + (f"1 de cada {1 / y['p_atasco']:.0f}" if y['p_atasco'] > 1e-6 else "casi nunca") + " | "
          + (f"1 de cada {1 / y['p_bloqueo']:.0f}" if y['p_bloqueo'] > 1e-6 else "casi nunca")
          + f" | {pct(y['p_puente'])} | {y['cebadas']:.1f} |")
    w("\n**Lectura:** todas quedan muy por debajo del 15 % de variación. Hay dos familias con problemas distintos:\n"
      "- **Yerbas gruesas con palo largo** (tereré, barbacuá): más atascos. El programa retrocede y sigue.\n"
      "- **Yerbas muy finas** (uruguaya, chimarrão): no se traban, pero **hacen puente en la tolva** y dan más "
      "gramos por vuelta. Para ellas hace falta un **agitador** en la tolva y recalibrar (`g=`).\n")

    # ---- 4 agua
    w("## 4. Agua y residuos\n")
    w("| Estado de la yerba | Peso del residuo | Volumen | Agua que escurre | Vaciar el cajón cada |")
    w("|---|---|---|---|---|")
    for r in res_est:
        w(f"| {r['nombre']} | {r['masa']:.0f} g | {r['vol']:.0f} cm³ | {r['agua']:.0f} ml | {r['ciclos']:.1f} ciclos |")
    agua_max = max(r["agua"] for r in res_est)
    w(f"\n**Lectura:** el cajón alcanza para **3 a 5 mates** mojados. El peor caso de agua es el mate lavado "
      f"(**{agua_max:.0f} ml** por ciclo): en 3 ciclos son más de 100 ml sueltos. El cajón tiene que ser "
      "**estanco** (sin la ranura abierta abajo) o llevar una **rejilla con bandeja** para el agua.\n")

    # ---- 5 tolerancias
    w("## 5. Tolerancias de impresión\n")
    w("Probabilidad de que una pieza impresa quede mal por el error normal de una impresora (±0,15 mm).\n")
    w("| Encastre | Roza o no entra | Queda flojo |")
    w("|---|---|---|")
    for k, (a, b) in tol.items():
        w(f"| {k} | {a * 100:.1f} % | {b * 100:.1f} % |")
    w("\n**Lectura:** el punto fino es el **eje del motor en el sinfín**: conviene imprimir primero una "
      "pieza de prueba chica con el agujero y ajustar `holgura` antes de imprimir el sinfín entero.\n")

    # ---- 6 un año
    w("## 6. Un año de uso (3 mates por día)\n")
    w("| Yerba | Atascos que se resuelven solos | Bloqueos (hay que abrir) | Puentes en la tolva | "
      "Recargas de tolva | Vaciados de cajón |")
    w("|---|---|---|---|---|---|")
    anio = None
    for y in yerbas:
        a = un_anio(y, res_est[0])
        anio = anio or a
        w(f"| {y['nombre']} | {a['atascos']:.0f} | {a['bloqueos']:.1f} | {a['puentes']:.0f} | "
          f"{a['recargas_tolva']:.0f} | {a['vaciados']:.0f} |")
    w(f"\nEn un año son **{anio['ciclos']} ciclos**, **{anio['kg_yerba']:.0f} kg** de yerba, "
      f"**{anio['cargas_bateria']:.1f} cargas** de batería y solo **{anio['horas_motor']:.0f} horas** de motor "
      "(los motores de este tipo duran cientos de horas).\n")

    # ---- 7 sensibilidad
    w("## 7. ¿Qué cambia más la precisión de la dosis?\n")
    w(f"Variación de referencia (yerba tradicional, 30 g): **{ref_cv:.1f} %**.\n")
    w("| Si cambia… | CV mínimo | CV máximo |")
    w("|---|---|---|")
    for et, lo, hi in sens:
        w(f"| {et} | {lo:.1f} % | {hi:.1f} % |")
    w("\n**Lectura:** lo que más pesa es el **tamaño de la dosis** (menos vueltas = menos precisión) y la "
      "**cantidad de palo**. En ningún caso se pasa del 15 %.\n")

    # ---- conclusiones
    w("## Qué cambia en el diseño con todo esto\n")
    w("| # | Hallazgo | Qué se hace |")
    w("|---|---|---|")
    w("| 1 | El camionero y otros mates medianos quedaban entre dos paletas | **Se agrega una paleta media (85 mm)** ✅ hecho |")
    w("| 2 | Las calabazas quedaban justo por debajo del 90 % en 15 s | **La limpieza normal pasa a 20 s** ✅ hecho |")
    w("| 2b | La yerba seca y el mate dulce necesitan más | **Limpieza larga de 40 s** manteniendo el botón 2 s ✅ hecho en el firmware |")
    w("| 3 | Cada mate necesita otra dosis (18 a 40 g) | **3 tamaños de dosis** (20, 30 y 40 g) que se eligen con doble toque ✅ hecho en el firmware |")
    w("| 4 | Las yerbas finas hacen puente en la tolva | Agitador en la tolva (pendiente de diseño) |")
    w("| 5 | El agua del mate lavado se junta en el cajón | Cajón estanco o con rejilla (pendiente de diseño) |")
    w("| 6 | Torpedo, uruguayo ancho y guampa no entran | Versión alta/ancha cambiando `H` y `nicho_ancho` (pendiente) |")
    w("| 7 | El eje del motor en el sinfín es el encastre más sensible | Imprimir primero una pieza de prueba |")
    w("")
    w("![Limpieza por mate y estado](imagenes/sim_limpieza.png)\n")
    w("![Dosificación por yerba](imagenes/sim_yerbas.png)\n")
    with open(os.path.join(DOCS, "simulaciones.md"), "w") as f:
        f.write("\n".join(L))

    # ================================================================== GRÁFICOS
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap

    cmap = LinearSegmentedColormap.from_list("mate", ["#b3261e", "#e9a23b", "#4f7a28"])
    fig, ax = plt.subplots(figsize=(13, 7.5))
    im = ax.imshow(matriz * 100, cmap=cmap, vmin=40, vmax=100, aspect="auto")
    ax.set_xticks(range(len(ESTADOS)), [e[0].replace(" (", "\n(").replace(", ", ",\n") for e in ESTADOS], fontsize=9)
    ax.set_yticks(range(len(ok_m)), [m["nombre"] for m in ok_m])
    for i in range(matriz.shape[0]):
        for j in range(matriz.shape[1]):
            ax.text(j, i, f"{matriz[i, j] * 100:.0f}", ha="center", va="center", color="white", weight="bold")
    plt.colorbar(im, ax=ax, label="Yerba retirada en 20 s (%)")
    ax.set_title("Limpieza simulada en 20 s: cada mate con cada estado de la yerba (meta: 90 %)", weight="bold")
    fig.text(0.01, 0.01, "Modelo con supuestos, escenario base. No es una medición.", fontsize=9, color="#5d685f")
    plt.tight_layout()
    plt.savefig(os.path.join(DOCS, "imagenes", "sim_limpieza.png"), dpi=90, facecolor="white")

    fig, axs = plt.subplots(1, 3, figsize=(15, 5.5), sharey=True)
    nombres = [y["nombre"] for y in yerbas]
    ypos = np.arange(len(yerbas))
    axs[0].barh(ypos, [y["cv"] for y in yerbas], color="#4f7a28")
    axs[0].axvline(15, color="#b3261e", ls="--")
    axs[0].text(14.7, len(yerbas) - 0.6, "límite 15 %", color="#b3261e", ha="right")
    axs[0].set(yticks=ypos, yticklabels=nombres, xlabel="Variación de la dosis, CV (%)", title="Precisión")
    axs[1].barh(ypos, [y["p_atasco"] * 100 for y in yerbas], color="#b8860b")
    axs[1].set(xlabel="Dosis con un atasco que se resuelve solo (%)", title="Atascos por palo")
    axs[2].barh(ypos, [y["p_puente"] * 100 for y in yerbas], color="#1e4d8c")
    axs[2].set(xlabel="Riesgo de puente en la tolva (%)", title="Yerba que no baja")
    for a in axs:
        a.invert_yaxis()
        a.spines[["top", "right"]].set_visible(False)
        a.title.set_fontweight("bold")
    fig.suptitle("Dosificación simulada con cada tipo de yerba (30 g)", weight="bold", fontsize=14)
    plt.tight_layout()
    plt.savefig(os.path.join(DOCS, "imagenes", "sim_yerbas.png"), dpi=90, facecolor="white")
    print(f"{n_ok}/{len(mates)} mates entran. Escrito docs/v1/simulaciones.md")


if __name__ == "__main__":
    main()
