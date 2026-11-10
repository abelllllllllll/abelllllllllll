// ============================================================================
//  APLICADOR DE CREMA · piezas imprimibles (OpenSCAD, paramétrico)
// ============================================================================
//  Uso:
//    - Abre este archivo en OpenSCAD (gratis: openscad.org).
//    - Cambia `pieza` para ver cada pieza o el conjunto, F6 para renderizar,
//      y "Export as STL" para imprimirla.
//    - MIDE tus piezas compradas (calibre/pie de rey) y corrige las medidas
//      de la sección MEDIDAS antes de imprimir. Son las típicas, no las tuyas.
//
//  Material recomendado: PETG (aguanta agua y jabón). Paleta: TPU 95A.
//  Desde línea de comandos:
//      openscad -D 'pieza="carro"' -o carro.stl aplicador.scad
// ============================================================================

// "conjunto" | "conjunto_corte" | "tapa_superior" | "paleta" | "carro"
// | "soporte_motor" | "trineo" | "tapa_inferior" | "plantilla_taladro" | "pinza_cable"
// | "alma_paleta" | "molde_paleta_base" | "molde_paleta_tapa" | "plantilla_tapon"
pieza = "conjunto_corte";
corte_y = 0;   // solo para la vista "cabeza_corte"

// ============================================================================
//  MEDIDAS (mídelas en tus piezas)
// ============================================================================
// Tubo de PVC de evacuación Ø40 (en España suele ser 40 x 3,0 mm -> interior 34)
tubo_de = 40.0;
tubo_di = 34.0;

// Jeringa 60 ml PUNTA CATÉTER (cono ancho, mejor para crema espesa)
jer_de        = 30.0;   // diámetro exterior del cuerpo
jer_di        = 27.0;   // diámetro interior (donde va el tapón de goma)
jer_largo     = 122.0;  // desde el borde abierto (aletas) hasta donde empieza el cono
jer_hombro    = 8.0;    // altura del cono (hombro) hasta la punta
jer_punta_d   = 7.5;    // diámetro de la punta catéter en su base
tapon_largo   = 15.0;   // largo del tapón de goma del émbolo

// Tubo de silicona platino 6 x 9 mm (interior x exterior)
sil_de = 9.0;

// Motorreductor N20 (cuerpo 12 x 10 mm)
n20_ancho = 12.2;  n20_alto = 10.2;  n20_largo = 25.0;  // motor + reductora

// Rodamiento 625ZZ (5 x 16 x 5) para aguantar el empuje axial
rod_de = 16.0;  rod_h = 5.0;

// Acoplador rígido eje 3 mm -> 5 mm (diámetro exterior máx.)
acopl_de = 13.0;  acopl_largo = 20.0;

// Microinterruptor KW10 mini con palanca (12,8 x 5,8 x 6,5; agujeros M2 a 6,5 mm)
mi_l = 12.8;  mi_a = 5.8;  mi_h = 6.5;  mi_sep = 6.5;

// Tuerca M5 (entre caras) y varilla guía Ø4 (varilla roscada M4 o acero plata)
m5_tuerca = 8.0;  guia_d = 4.0;

// Celda 18650 en portapilas simple (largo x ancho x alto)
porta_l = 78;  porta_a = 21;  porta_h = 19;

// Módulo de carga TP4056 USB-C con protección (largo x ancho)
tp_l = 28;  tp_a = 17.5;

holg = 0.3;     // holgura general de ajuste
$fn = 64;

// ============================================================================
//  COTAS DERIVADAS (no tocar: se calculan solas)
// ============================================================================
// Tapa inferior: "pvc" = tapón de PVC Ø40 de ferretería, solo taladrado (más barato,
// recomendado) | "impresa" = pieza impresa tapa_inferior
tapa_inferior_tipo = "pvc";
tapon_pvc_fondo = 3;  // grosor del fondo del tapón de PVC (mídelo)
tapa_inf_h = tapa_inferior_tipo == "pvc" ? 1 : 15;   // espacio que ocupa dentro del tubo
trineo_l   = 165;     // bandeja de electrónica
soporte_h  = n20_largo + (acopl_largo + 6) + 4 + 10;  // motor + cámara acoplador + escalón + rodamiento y tuerca
carro_h    = 16;
empuje_l   = 110;     // tubo empujador (sustituye al vástago del émbolo)
empuje_de  = jer_di - 5;     // Ø22: deja paso a la varilla guía
empuje_di  = 5 + 3;   // la varilla M5 entra por dentro con holgura
guia_r     = 13.8;    // radio al que va la varilla guía (al lado del empujador)

z_soporte  = tapa_inf_h + trineo_l;
z_sop_top  = z_soporte + soporte_h;
z_carro0   = z_sop_top + 2;                    // carro en "casa" (pisa el final de carrera)
z_emp_top0 = z_carro0 + carro_h + empuje_l;    // punta del empujador en casa
z_aletas   = z_emp_top0 + 2 + 1;               // borde abierto de la jeringa
z_hombro   = z_aletas + jer_largo;
tapa_sup_bore = 22;                            // cuánto entra la jeringa en la tapa
tapa_sup_l = tapa_sup_bore + jer_hombro + 5;
z_tapa_sup = z_hombro - tapa_sup_bore;
tubo_largo = z_tapa_sup + tapa_sup_l;

carrera_total = (z_hombro - tapon_largo) - (z_aletas + 1) + 2;   // desde casa hasta vacía
recorrido_firmware = floor(carrera_total - 2);
varilla_bajo = z_soporte + n20_largo + acopl_largo / 2;   // mitad del acoplador
varilla_alto = z_aletas - 8;   // queda dentro del empujador incluso en casa

echo(str("=== CORTAR TUBO PVC Ø", tubo_de, " A: ", tubo_largo, " mm"));
echo(str("=== VARILLA M5 INOX: ", ceil(varilla_alto - varilla_bajo), " mm   ",
         "VARILLA GUÍA Ø4: ", ceil(varilla_alto - 1 - (z_sop_top - 12)), " mm"));
echo(str("=== RECORRIDO_MAX_MM para el firmware: ", recorrido_firmware,
         " (luego confírmalo midiendo)"));
assert(empuje_de / 2 + 0.5 < guia_r - guia_d / 2, "la guía choca con el empujador");
assert(guia_r + guia_d / 2 < tubo_di / 2 - 0.3, "la guía no cabe en el tubo");
assert(jer_de + 2 * holg < tubo_di, "la jeringa no cabe en el tubo");
assert(guia_r - guia_d / 2 > rod_de / 2 + 1, "la guía choca con el rodamiento");
echo(str("=== AGUJEROS EN EL PVC (medidos desde el extremo de abajo): botón DOSIS Ø12 a ", z_boton_dosis,
         " mm, LED Ø5 a ", z_led, " mm, botón RETRAER Ø12 a ", z_boton_retraer, " mm"));
assert(varilla_alto < z_carro0 + carro_h + empuje_l - 2 - 1, "la varilla M5 choca dentro del empujador");
assert(varilla_alto >= (z_hombro - tapon_largo - empuje_l) - carro_h + 5, "la varilla no llega a la tuerca al final");

// ============================================================================
//  UTILIDADES
// ============================================================================
module tapon(d, h) { cylinder(d = d - 2 * holg, h = h); }

// Agujero radial para tornillo autorroscante M3 que atraviesa el PVC
module agujero_m3_radial(z, ang) {
  rotate([0, 0, ang]) translate([0, 0, z]) rotate([0, 90, 0]) cylinder(d = 2.6, h = 30);
}

// Canal a lo largo de la pared para pasar cables (ángulo 270º)
module canal_cables(h) {
  rotate([0, 0, 270]) translate([tubo_di / 2 - 3.5, -2.5, -1]) cube([4, 5, h + 2]);
}

// ============================================================================
//  1) SOPORTE DEL MOTOR (sujeta N20, rodamiento, varilla guía y final de carrera)
// ============================================================================
module soporte_motor() {
  difference() {
    tapon(tubo_di, soporte_h);
    // alojamiento del N20 desde abajo
    translate([-n20_ancho / 2 - holg, -n20_alto / 2 - holg, -1])
      cube([n20_ancho + 2 * holg, n20_alto + 2 * holg, n20_largo + 1]);
    // cámara del acoplador + tuerca inferior de la varilla
    translate([0, 0, n20_largo - 0.01]) cylinder(d = acopl_de + 4, h = acopl_largo + 6);
    // paso de la varilla M5 por el escalón
    cylinder(d = 6, h = soporte_h + 1);
    // rodamiento 625 encajado desde arriba, APOYADO en el escalón (el empuje va hacia abajo)
    // y encima la tuerca + arandela que lo aprietan, rehundidas para no tocar el carro
    translate([0, 0, soporte_h - 10]) cylinder(d = rod_de + 0.2, h = 11);
    // varilla guía (agujero ciego de 12 mm, pegar con epoxi)
    translate([-guia_r, 0, soporte_h - 12]) cylinder(d = guia_d + 0.1, h = 13);
    // final de carrera trasero: rebaje en la cara de arriba, palanca hacia arriba
    rotate([0, 0, 90]) translate([guia_r - 1.5, 0, soporte_h - 3]) {
      translate([-mi_a / 2, -mi_l / 2, 0]) cube([mi_a + 0.4, mi_l + 0.4, 4]);
      for (s = [-1, 1]) translate([mi_a / 2, s * mi_sep / 2, -10]) cylinder(d = 1.8, h = 11);
    }
    canal_cables(soporte_h);
    // cables del motor y del final de carrera bajan por aquí
    rotate([0, 0, 90]) translate([guia_r - 1, 0, -1]) cylinder(d = 3.5, h = soporte_h - 2);
    // fijación al tubo: 2 tornillos M3 a través del PVC
    agujero_m3_radial(n20_largo / 2, 45);
    agujero_m3_radial(n20_largo / 2, 225);
  }
}

// ============================================================================
//  2) CARRO + TUBO EMPUJADOR (una sola pieza)
//     Lleva 2 tuercas M5 (arriba y abajo) y desliza por la varilla guía.
// ============================================================================
module carro() {
  difference() {
    union() {
      cylinder(d = tubo_di - 2 * 0.6, h = carro_h);
      cylinder(d = empuje_de, h = carro_h + empuje_l);
    }
    // interior hueco: aquí se mete la varilla M5 al avanzar
    translate([0, 0, -1]) cylinder(d = 5.6, h = carro_h + 2);
    translate([0, 0, carro_h - 0.01]) cylinder(d = empuje_di, h = empuje_l - 2);
    // tuercas M5 (hexágono) arriba y abajo del carro
    for (z = [-0.01, carro_h - 4.5]) translate([0, 0, z])
      cylinder(d = m5_tuerca / cos(30) + 0.4, h = 4.6, $fn = 6);
    // varilla guía
    translate([-guia_r, 0, -1]) cylinder(d = guia_d + 0.5, h = carro_h + 2);
    canal_cables(carro_h);
    // aligerado / ventilación de la cámara (deja salir el aire)
    for (a = [45, 135]) rotate([0, 0, a]) translate([11, 0, -1]) cylinder(d = 4, h = carro_h + 2);
  }
}

// ============================================================================
//  3) TAPA SUPERIOR + BRAZO A 45º + CABEZA CON SENSOR DE CONTACTO
//     Sujeta la jeringa por el hombro. Se fija al tubo con un tornillo M4 x 40
//     pasante + tuerca mariposa (para sacarla y cambiar la jeringa).
//     En la punta, la "cabeza" lleva la paleta flotante: la paleta desliza
//     3 mm sobre un muelle y, al apoyarla en la piel, aprieta un
//     microinterruptor estanco. Un tornillo M2 entra en una ranura del cuello
//     de la paleta: la retiene, no la deja girar y limita el recorrido.
// ============================================================================
brazo_d = 22;  brazo_r = 25;  brazo_recto = 18;  brazo_45 = 45;  canal_d = sil_de + 0.6;

// Cabeza y paleta flotante
cabeza_d = 38;  cabeza_l = 26;
zocalo_d = 12.4;  zocalo_prof = 22;    // agujero donde desliza el cuello de la paleta
hueco_reposo = 3;                      // separación paleta-cabeza sin apoyar (= recorrido)
muelle_l = 10;                         // muelle de compresión inox Øext ≤ 12, Øint ≥ 9,5
cuello_l = zocalo_prof + hueco_reposo - (muelle_l - 2);   // 2 mm de precarga
z_pasador = -8;                        // tornillo M2 que hace de pasador

// Microinterruptor ESTANCO IP67 con palanca y cables (mídelo):
ms_l = 20.0;  ms_e = 6.5;  ms_h = 10.3;  // largo, grueso, alto del cuerpo (sin palanca)
ms_r = 11.0;                             // a qué distancia del eje va
ms_hundido = 0.5;                        // el cuerpo queda 0,5 mm bajo la cara de la cabeza

cable_off = 7.3;                         // canal de los cables del sensor por el brazo
cable_d = 3.2;                           // 2 hilos de silicona 26 AWG

// Eje del brazo: tramo recto vertical, codo de 45º (curvado hacia -X) y tramo a 45º.
// Se construye como una cadena de "cápsulas" (esferas unidas): curva continua y
// sin caras coincidentes (mallas limpias para el laminador).
codo_pasos = 8;
function eje_brazo(off) = concat(
  [[0, -off, -0.5]],
  [for (i = [0 : codo_pasos]) let(a = i * 45 / codo_pasos)
     [-brazo_r + brazo_r * cos(a), -off, brazo_recto + brazo_r * sin(a)]],
  [[-brazo_r + brazo_r * cos(45) - brazo_45 * sin(45), -off,
    brazo_recto + brazo_r * sin(45) + brazo_45 * cos(45)]]);

// off: desplaza el trayecto hacia -Y (canal de cables); acortar: recorta el final
module trayecto_brazo(d, off = 0, acortar = 0) {
  p = eje_brazo(off);
  n = len(p);
  fin = p[n - 1] - acortar * [-sin(45), 0, cos(45)];
  for (i = [0 : n - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = 32);
    translate(i == n - 2 ? fin : p[i + 1]) sphere(d = d, $fn = 32);
  }
}

punta_brazo = [-brazo_r + brazo_r * cos(45) - brazo_45 * sin(45),
               0,
               tapa_sup_l + 6 + brazo_recto + brazo_r * sin(45) + brazo_45 * cos(45)];

// Sistema de la cabeza: Z hacia fuera por el eje del brazo, cara de la cabeza en z = 0
module en_punta() { translate(punta_brazo) rotate([0, -45, 0]) children(); }

assert(ms_r - ms_e / 2 > zocalo_d / 2 + 1, "el microinterruptor choca con el zócalo");
assert(sqrt(pow(ms_r + ms_e / 2, 2) + pow(ms_l / 2, 2)) < cabeza_d / 2 - 0.8, "el microinterruptor no cabe en la cabeza");
assert(cable_off + cable_d / 2 < brazo_d / 2 - 0.8 && cable_off - cable_d / 2 > canal_d / 2 + 0.6, "el canal de cables no cabe en el brazo");

module tapa_superior() {
  difference() {
    union() {
      tapon(tubo_di, tapa_sup_l);
      translate([0, 0, tapa_sup_l]) cylinder(d = tubo_de, h = 6);       // tope sobre el tubo
      translate([0, 0, tapa_sup_l + 6 - 0.01]) trayecto_brazo(brazo_d, 0, brazo_d / 2 + 2);   // acaba dentro de la cabeza
      en_punta() hull() {
        translate([0, 0, -cabeza_l]) cylinder(d = cabeza_d, h = cabeza_l);
        translate([0, 0, -cabeza_l - 12]) cylinder(d = brazo_d, h = 1);
      }
    }
    // alojamiento del cuerpo de la jeringa + cono del hombro + punta
    translate([0, 0, -1]) cylinder(d = jer_de + 2 * holg, h = tapa_sup_bore + 1);
    translate([0, 0, tapa_sup_bore - 0.01])
      cylinder(d1 = jer_de + 2 * holg, d2 = jer_punta_d + 1, h = jer_hombro);
    // canal del tubo de silicona por todo el brazo
    cylinder(d = max(canal_d, jer_punta_d + 1), h = tapa_sup_l + 6 + 0.02);
    translate([0, 0, tapa_sup_l + 6]) trayecto_brazo(canal_d);
    // canal de los cables del sensor: de la cabeza al collarín, y sale por un lado
    translate([0, 0, tapa_sup_l + 6]) trayecto_brazo(cable_d, cable_off, 4);   // acaba dentro del alojamiento del interruptor
    translate([0, -cable_off, tapa_sup_l + 3]) cylinder(d = cable_d, h = 3.1);
    translate([0, -cable_off, tapa_sup_l + 3]) rotate([90, 0, 0]) cylinder(d = cable_d, h = 20);
    en_punta() {
      // zócalo de la paleta (con el muelle al fondo)
      translate([0, 0, -zocalo_prof]) cylinder(d = zocalo_d, h = zocalo_prof + 1);
      // alojamiento del microinterruptor
      translate([-ms_l / 2 - 0.2, -ms_r - ms_e / 2 - 0.2, -ms_hundido - ms_h])
        cube([ms_l + 0.4, ms_e + 0.4, ms_h + ms_hundido + 1]);
      // los cables del microinterruptor bajan al canal
      translate([0, -cable_off, -cabeza_l - 13]) cylinder(d = cable_d, h = cabeza_l + 13 - ms_h);
      // agujero del tornillo-pasador M2 (autorroscante en PETG)
      translate([0, 0, z_pasador]) rotate([0, 90, 0]) cylinder(d = 1.8, h = cabeza_d);
    }
    // tornillo M4 pasante (cuerda desplazada para no cortar el canal)
    translate([0, 10, tapa_sup_l - 4]) rotate([0, 90, 0]) cylinder(d = 4.4, h = 60, center = true);
  }
}

// ============================================================================
//  4) PALETA APLICADORA (imprimir en TPU 95A, blanda y lavable)
//     El tubo de silicona entra 10 mm a presión por el extremo del cuello.
//     La ranura del cuello va hacia +X (donde entra el tornillo-pasador M2).
// ============================================================================
pal_l = 85;  pal_a = 60;  pal_e = 9;
cuello_d = zocalo_d - 0.5;

module paleta() {
  // posición del pasador en coordenadas de la paleta, en reposo
  zp = pal_e + hueco_reposo - z_pasador;
  difference() {
    union() {
      // cuerpo ovalado, más fino en los bordes; la trasera plana pisa el interruptor
      hull() {
        scale([pal_l / 2, pal_a / 2, 1]) cylinder(r = 1, h = 2.5, $fn = 96);
        scale([pal_l / 2 - 12, pal_a / 2 - 10, 1]) cylinder(r = 1, h = pal_e, $fn = 96);
      }
      // cuello que desliza en la cabeza
      translate([0, 0, pal_e - 0.01]) cylinder(d = cuello_d, h = cuello_l);
    }
    // tubo de silicona entra por el extremo del cuello
    translate([0, 0, pal_e + cuello_l - 10]) cylinder(d = sil_de - 0.4, h = 11);
    // canal hasta la cara de aplicación
    translate([0, 0, -1]) cylinder(d = 6, h = pal_e + cuello_l - 9);
    // abocardado de salida
    translate([0, 0, -0.01]) cylinder(d1 = 12, d2 = 6, h = 3);
    // 4 surcos poco profundos para repartir la crema
    for (a = [0, 90, 180, 270]) rotate([0, 0, a])
      translate([6, -1.5, -0.01]) cube([pal_l / 2 - 16, 3, 1.2]);
    // ranura del pasador: permite hundir la paleta hasta hueco_reposo mm
    translate([cuello_d / 2 - 1.0, -1.15, zp - hueco_reposo - 1.1])
      cube([2, 2.3, hueco_reposo + 2.2]);
  }
}

// ============================================================================
//  4c) PALETA DE SILICONA COLADA (alternativa recomendada a la de TPU)
//     Un "alma" rígida impresa en PETG (cuello + placa trasera + tubo de
//     salida) y alrededor silicona de platino apta para piel, colada en un
//     molde impreso de 2 piezas. La cara que toca la piel queda lisa, sin los
//     poros de la impresión, y el cuello sigue siendo rígido para deslizar.
// ============================================================================
alma_placa_e = 2;
alma_placa   = [pal_l / 2 - 15, pal_a / 2 - 12.5];   // semiejes de la placa trasera
alma_agujeros = [[21, 0], [-21, 0], [14, 9], [-14, 9], [14, -9], [-14, -9], [0, -12]];
molde_borde = 8;  molde_fondo = 4;  molde_tapa_e = 4;
molde_L = pal_l + 2 * molde_borde;  molde_A = pal_a + 2 * molde_borde;

module cuerpo_paleta(extra = 0) {
  hull() {
    scale([pal_l / 2, pal_a / 2, 1]) cylinder(r = 1, h = 2.5, $fn = 96);
    scale([pal_l / 2 - 12, pal_a / 2 - 10, 1]) cylinder(r = 1, h = pal_e + extra, $fn = 96);
  }
}

module alma_paleta() {
  zp = pal_e + hueco_reposo - z_pasador;
  difference() {
    union() {
      // placa trasera: queda vista y es la que pisa el microinterruptor
      translate([0, 0, pal_e - alma_placa_e])
        scale([alma_placa[0], alma_placa[1], 1]) cylinder(r = 1, h = alma_placa_e, $fn = 96);
      // cuello rígido que desliza en la cabeza
      translate([0, 0, pal_e - 0.01]) cylinder(d = cuello_d, h = cuello_l);
      // tubo de salida hasta 3 mm de la cara, con anillo de anclaje
      translate([0, 0, 3]) cylinder(d = 9, h = pal_e - 3);
      translate([0, 0, 4.5]) cylinder(d = 11.5, h = 1.2);
    }
    translate([0, 0, pal_e + cuello_l - 10]) cylinder(d = sil_de - 0.4, h = 11);
    translate([0, 0, 2]) cylinder(d = 6, h = pal_e + cuello_l - 9);
    // ranura del pasador (igual que en la paleta de TPU)
    translate([cuello_d / 2 - 1.0, -1.15, zp - hueco_reposo - 1.1]) cube([2, 2.3, hueco_reposo + 2.2]);
    // agujeros por los que pasa la silicona y la "remacha" a la placa
    for (h = alma_agujeros) translate([h[0], h[1], pal_e - alma_placa_e - 1]) cylinder(d = 3.5, h = 4);
  }
}

// Base del molde: la paleta con la cara de aplicación hacia abajo
module molde_paleta_base() {
  H = molde_fondo + pal_e;
  difference() {
    translate([-molde_L / 2, -molde_A / 2, 0]) cube([molde_L, molde_A, H]);
    translate([0, 0, molde_fondo]) cuerpo_paleta(1);
  }
  translate([0, 0, molde_fondo - 0.01]) {
    // los surcos de la cara son nervios en el molde
    for (a = [0, 90, 180, 270]) rotate([0, 0, a]) translate([6, -1.5, 0]) cube([pal_l / 2 - 16, 3, 1.2]);
    // abocardado de salida + pasador que tapona el tubo del alma (entra 3 mm)
    cylinder(d1 = 12, d2 = 6, h = 3);
    cylinder(d = 5.7, h = 6);
  }
  // pasadores de centrado de la tapa
  for (sx = [-1, 1]) translate([sx * (molde_L / 2 - 4), 0, H - 0.01]) cylinder(d = 4, h = 3.5);
}

// Tapa del molde: sujeta el alma centrada y a su altura; su cara de abajo es la
// trasera de la paleta. Los respiraderos dejan salir el aire y la silicona sobrante.
module molde_paleta_tapa() {
  difference() {
    translate([-molde_L / 2, -molde_A / 2, 0]) cube([molde_L, molde_A, molde_tapa_e]);
    translate([0, 0, -1]) cylinder(d = cuello_d + 0.3, h = molde_tapa_e + 2);
    for (sx = [-1, 1]) translate([sx * (molde_L / 2 - 4), 0, -1]) cylinder(d = 4.4, h = molde_tapa_e + 2);
    // respiraderos: en el anillo de silicona alrededor de la placa y sobre sus agujeros
    for (v = concat([[29, 0], [-29, 0], [0, 18.8], [0, -18.8], [20, 13], [-20, 13], [20, -13], [-20, -13]],
                    alma_agujeros))
      translate([v[0], v[1], -1]) cylinder(d = 2.5, h = molde_tapa_e + 2);
  }
}

// ============================================================================
//  4b) PINZA PARA EL CABLE DEL SENSOR (por fuera del tubo, imprimir 3)
// ============================================================================
module pinza_cable() {
  difference() {
    union() {
      cylinder(d = tubo_de + 4, h = 8);
      translate([0, -tubo_de / 2 - 3, 0]) cylinder(d = 7, h = 8);
    }
    translate([0, 0, -1]) cylinder(d = tubo_de + 0.3, h = 10);
    translate([0, -tubo_de / 2 - 3, -1]) cylinder(d = 3.6, h = 10);   // cable de 2 hilos
    // abertura para encajarla a presión en el tubo
    rotate([0, 0, 90]) translate([0, -tubo_de * 0.33, -1]) cube([tubo_de, tubo_de * 0.66, 10]);
  }
}

// ============================================================================
//  5) TRINEO DE ELECTRÓNICA (se desliza dentro del tubo)
//     De abajo a arriba: TP4056 -> portapilas 18650 -> placa con ESP32 y TB6612
// ============================================================================
module trineo() {
  y_base = -6;           // la bandeja va por debajo del centro (deja sitio a los botones)
  ancho = 2 * sqrt(pow(tubo_di / 2 - 0.5, 2) - pow(y_base, 2));
  difference() {
    union() {
      // bandeja plana
      translate([-ancho / 2, y_base - 2.5, 0]) cube([ancho, 2.5, trineo_l]);
      // costillas en arco que guían contra la pared
      for (z = [0, 55, 110, trineo_l - 4]) translate([0, 0, z])
        intersection() {
          difference() { cylinder(d = tubo_di - 2 * holg, h = 4); translate([0, 0, -1]) cylinder(d = tubo_di - 6, h = 6); }
          translate([-tubo_di, -tubo_di, -1]) cube([2 * tubo_di, tubo_di + y_base, 6]);
        }
      // topes del portapilas
      for (z = [tp_l + 4, tp_l + 6 + porta_l]) translate([-porta_a / 2, y_base, z]) cube([porta_a, 3, 2]);
      // tope del TP4056
      translate([-tp_a / 2, y_base, tp_l + 1]) cube([tp_a, 3, 1.5]);
    }
    // ranuras para bridas
    for (z = [tp_l + 20, tp_l + 60, trineo_l - 30]) for (s = [-1, 1])
      translate([s * (porta_a / 2 + 2) - 1.5, y_base - 4, z]) cube([3, 6, 4]);
    canal_cables(trineo_l);
  }
}

// ============================================================================
//  6) TAPA INFERIOR (USB-C de carga + interruptor general)
// ============================================================================
// Agujeros de la tapa (los mismos para la tapa impresa y para el tapón de PVC)
module agujeros_tapa(h) {
  // ventana del USB-C del TP4056 (va centrado sobre la bandeja)
  translate([-4.9, -6 - 1.6 + 2.5 + 1.2, -1]) cube([9.8, 3.9, h + 2]);
  // ventanilla para ver los LED de carga
  translate([4, -6 + 2.5, -1]) cylinder(d = 3, h = h + 2);
  // interruptor general de palanca mini (rosca Ø6) en la mitad de arriba
  translate([0, 9, -1]) cylinder(d = 6.4, h = h + 2);
}

// Plantilla para taladrar el TAPÓN DE PVC: se mete dentro del tapón, apoyada en
// el fondo, y se taladra desde dentro (agujeros guía de 2 mm; la ventana del
// USB-C se marca con sus 4 esquinas y se abre con broca de 3 mm y lima).
module plantilla_tapon() {
  e = 3;
  difference() {
    union() {
      cylinder(d = tubo_de - 0.3, h = e);
      translate([-3, tubo_de / 2 - 8, 0]) cube([6, 10, e + 8]);   // asa (marca el lado +Y)
    }
    translate([0, 9, -1]) cylinder(d = 2, h = e + 2);
    translate([4, -6 + 2.5, -1]) cylinder(d = 2, h = e + 2);
    for (x = [-4.9 + 1, 4.9 - 1]) for (y = [-6 - 1.6 + 2.5 + 1.2 + 0.8, -6 - 1.6 + 2.5 + 1.2 + 3.9 - 0.8])
      translate([x, y, -1]) cylinder(d = 1.5, h = e + 2);
  }
}

module tapa_inferior() {
  difference() {
    union() {
      translate([0, 0, 0]) cylinder(d = tubo_de, h = 4);
      translate([0, 0, 4 - 0.01]) tapon(tubo_di, 15 - 4);
    }
    agujeros_tapa(15);
    // hueco interior para cables y para la palanca
    translate([0, 9, 3]) cylinder(d = 13, h = 15);
    agujero_m3_radial(9, 90);
  }
}

// ============================================================================
//  7) PLANTILLA DE TALADRO (abrazadera que marca dónde agujerear el PVC)
// ============================================================================
z_boton_dosis   = z_soporte - 15;
z_led           = z_soporte - 28;
z_boton_retraer = z_soporte - 40;
z_cable_entrada = z_soporte - 6;     // agujero Ø4 por detrás (-Y) para el cable del sensor
echo(str("=== CABLE DEL SENSOR: agujero Ø4 por la cara trasera (opuesta a los botones) a ", z_cable_entrada, " mm"));

module plantilla_taladro() {
  // Se imprime, se pone alrededor del tubo apoyada en su extremo inferior
  // y se marcan los agujeros con un punzón.
  h = z_boton_dosis + 10;
  difference() {
    intersection() {
      difference() { cylinder(d = tubo_de + 4, h = h); translate([0, 0, 2]) cylinder(d = tubo_de + 0.6, h = h); }
      translate([-tubo_de, 0, -1]) cube([2 * tubo_de, tubo_de, h + 2]);   // media caña
    }
    for (z = [z_boton_dosis, z_boton_retraer]) translate([0, 0, z]) rotate([-90, 0, 0]) cylinder(d = 3, h = 40);
    translate([0, 0, z_led]) rotate([-90, 0, 0]) cylinder(d = 2, h = 40);
    translate([0, 0, 2]) cube([tubo_de * 0.5, tubo_de * 2, 1], center = true);
  }
  translate([0, 0, 0]) difference() { cylinder(d = tubo_de + 4, h = 2); cylinder(d = 10, h = 5, center = true); }
}

// ============================================================================
//  CONJUNTO (para comprobar que todo encaja)
// ============================================================================
module tubo_pvc() {
  color("white", 0.25) difference() {
    cylinder(d = tubo_de, h = tubo_largo);
    translate([0, 0, -1]) cylinder(d = tubo_di, h = tubo_largo + 2);
    for (z = [z_boton_dosis, z_boton_retraer]) translate([0, 0, z]) rotate([-90, 0, 0]) cylinder(d = 12.2, h = 40);
    translate([0, 0, z_led]) rotate([-90, 0, 0]) cylinder(d = 5, h = 40);
    translate([0, 0, z_cable_entrada]) rotate([90, 0, 0]) cylinder(d = 4, h = 40);
  }
}

module jeringa_fantasma() {
  color("lightblue", 0.45) translate([0, 0, z_aletas]) difference() {
    union() {
      cylinder(d = jer_de, h = jer_largo);
      translate([0, 0, jer_largo]) cylinder(d1 = jer_de, d2 = jer_punta_d, h = jer_hombro);
      translate([0, 0, jer_largo + jer_hombro]) cylinder(d1 = jer_punta_d, d2 = 5, h = 20);
      cylinder(d = tubo_di - 1, h = 2);    // aletas recortadas
    }
    translate([0, 0, -1]) cylinder(d = jer_di, h = jer_largo + 1);
  }
  // tapón de goma (jeringa llena)
  color("dimgray") translate([0, 0, z_aletas + 1]) cylinder(d = jer_di, h = tapon_largo);
  // crema
  color("wheat", 0.5) translate([0, 0, z_aletas + 1 + tapon_largo]) cylinder(d = jer_di - 0.2, h = jer_largo - tapon_largo - 1);
}

module electronica_fantasma() {
  translate([0, -6, tapa_inf_h]) {
    color("blue") translate([-tp_a / 2, 0, 2]) cube([tp_a, 1.6, tp_l]);
    color("black") translate([-porta_a / 2, 0, tp_l + 6]) cube([porta_a, porta_h, porta_l]);
    color("green") translate([-13, 0, tp_l + porta_l + 12]) cube([26, 1.6, 50]);
  }
  // motor y varillas
  color("gold") translate([-n20_ancho / 2, -n20_alto / 2, z_soporte]) cube([n20_ancho, n20_alto, n20_largo]);
  color("silver") translate([0, 0, varilla_bajo]) cylinder(d = 5, h = varilla_alto - varilla_bajo);
  color("silver") translate([-guia_r, 0, z_sop_top - 12]) cylinder(d = guia_d, h = varilla_alto - 1 - (z_sop_top - 12));
  // botones
  for (z = [z_boton_dosis, z_boton_retraer]) color("red") translate([0, tubo_de / 2 - 2, z]) rotate([-90, 0, 0]) cylinder(d = 12, h = 5);
}

module cortar(corte) {
  if (corte) difference() { children(); translate([-200, -400, -10]) cube([400, 400, 1000]); }
  else children();
}

module conjunto(corte = false) {
  cortar(corte) tubo_pvc();
  if (tapa_inferior_tipo == "impresa") color("orange") tapa_inferior();
  else color("dimgray") translate([0, 0, -tapon_pvc_fondo]) difference() {     // tapón de PVC
    cylinder(d = tubo_de + 4.4, h = tapon_pvc_fondo + 22);
    translate([0, 0, tapon_pvc_fondo]) cylinder(d = tubo_de + 0.2, h = 30);
  }
  color("orange") translate([0, 0, tapa_inf_h]) trineo();
  color("orange") translate([0, 0, z_soporte]) soporte_motor();
  color("tomato") translate([0, 0, z_carro0]) carro();
  jeringa_fantasma();
  electronica_fantasma();
  color("orange") translate([0, 0, z_tapa_sup]) tapa_superior();
  color("mediumseagreen") translate([0, 0, z_tapa_sup]) en_punta()
    translate([0, 0, hueco_reposo]) rotate([180, 0, 0]) translate([0, 0, -pal_e]) paleta();
  color("red") translate([0, 0, z_tapa_sup]) en_punta()
    translate([-ms_l / 2, -ms_r - ms_e / 2, -ms_hundido - ms_h]) cube([ms_l, ms_e, ms_h]);
  for (z = [z_cable_entrada + 30, (z_cable_entrada + tubo_largo) / 2, tubo_largo - 40])
    color("orange") translate([0, 0, z]) pinza_cable();
}

// ============================================================================
if (pieza == "conjunto") conjunto(false);
else if (pieza == "conjunto_corte") conjunto(true);
else if (pieza == "tapa_superior") tapa_superior();
else if (pieza == "paleta") paleta();
else if (pieza == "carro") carro();
else if (pieza == "soporte_motor") soporte_motor();
else if (pieza == "trineo") trineo();
else if (pieza == "tapa_inferior") tapa_inferior();
else if (pieza == "plantilla_taladro") plantilla_taladro();
else if (pieza == "pinza_cable") pinza_cable();
else if (pieza == "alma_paleta") alma_paleta();
else if (pieza == "molde_paleta_base") molde_paleta_base();
else if (pieza == "molde_paleta_tapa") molde_paleta_tapa();
else if (pieza == "plantilla_tapon") plantilla_tapon();
else if (pieza == "molde_montado") {      // solo para comprobar: molde cerrado con el alma dentro
  color("lightgray", 0.5) molde_paleta_base();
  color("orange") translate([0, 0, molde_fondo]) alma_paleta();
  color("lightgray", 0.5) translate([0, 0, molde_fondo + pal_e]) molde_paleta_tapa();
}
else if (pieza == "cabeza_corte") difference() {     // solo para documentación
  union() {
    tapa_superior();
    en_punta() translate([0, 0, hueco_reposo]) rotate([180, 0, 0]) translate([0, 0, -pal_e]) paleta();
    en_punta() translate([-ms_l / 2, -ms_r - ms_e / 2, -ms_hundido - ms_h]) cube([ms_l, ms_e, ms_h]);
  }
  translate([-200, corte_y - 400, -10]) cube([400, 400, 400]);
}
