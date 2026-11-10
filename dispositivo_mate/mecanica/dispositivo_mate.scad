// ============================================================================
//  DISPOSITIVO AUTOMÁTICO DE MATE · modelo paramétrico (OpenSCAD)
// ============================================================================
//  Uso:
//    - Abrí este archivo en OpenSCAD (gratis: openscad.org).
//    - Cambiá `pieza` para ver cada pieza o el conjunto. F6 = renderizar,
//      "Export as STL" para imprimir.
//    - Desde la línea de comandos:
//        openscad -D 'pieza="sinfin"' -o sinfin.stl dispositivo_mate.scad
//
//  Medidas exteriores tomadas del SketchUp original (aprox. 176 x 176 x 133 mm).
//  MEDÍ tus piezas (mate, motor, yerba) y corregí la sección MEDIDAS.
//
//  Piezas de la FASE 2 (banco de prueba del dosificador, se imprimen ya):
//    "cuerpo_dosificador"  tolva + tubo del sinfín en una sola pieza
//    "sinfin"              tornillo sinfín (imprimir vertical, con soportes)
//    "soporte_motor"       abrazadera del motor N20
//    "base_banco"          base para apoyar el dosificador sobre la mesa
//    "banco_prueba"        vista del banco armado (no se imprime)
//
//  Concepto del equipo completo (solo para ver la distribución):
//    "equipo"              vista general
//    "equipo_corte"        corte por el medio
// ============================================================================

pieza = "banco_prueba";

$fn = 64;

// ============================================================================
//  MEDIDAS
// ============================================================================

// --- Carcasa (del SketchUp original) ---
caja_ancho   = 176;   // X
caja_fondo   = 176;   // Y
caja_alto    = 200;   // el original mide 133. Con 133 no entra el tobogán de yerba
                      // y con 160 no entra un mate camionero (ver revisión técnica)   // Z
caja_r_esq   = 35;    // radio de las esquinas vistas desde arriba
pared        = 3;

// --- Mate (MEDÍ EL TUYO) ---
// Valores ESTIMADOS de las fotos (mate camionero con virola ancha y base con patas).
// Medilos con una regla y corregí.
mate_d_max   = 95;    // diámetro máximo (virola o panza, el que sea mayor)
mate_alto    = 130;   // alto total, de la base al borde de la virola
mate_boca_d  = 70;    // diámetro interior de la boca
mate_virola_alto = 25; // alto de la virola metálica
mate_base_d  = 65;    // ancho de la base con patas

// --- Motorreductor N20 ---
n20_ancho    = 12.2;  // cara de la reductora (Y)
n20_alto     = 10.2;  // (Z)
n20_largo    = 26.0;  // reductora + motor (sin eje)
n20_eje_d    = 3.0;   // eje con cara plana (D)
n20_eje_plano= 2.5;   // medida a través de la cara plana
n20_eje_largo= 10.0;

// --- Dosificador (sinfín) ---
tubo_di      = 23.0;  // interior del tubo donde gira el sinfín
tubo_pared   = 2.4;
sinfin_d     = 21.4;  // diámetro exterior del sinfín (1,6 mm de luz total)
nucleo_d     = 9.0;   // núcleo central del sinfín
paso         = 18.0;  // avance por vuelta
aleta_ang    = 40;    // grosor de la aleta en grados (=> paso*40/360 = 2 mm)
cubo_largo   = 8.0;   // tramo liso del lado del motor
sinfin_largo = 110.0; // largo total del sinfín

entrada_largo = 45;   // ventana bajo la tolva
salida_largo  = 24;   // agujero de salida (abajo, al final)
tolva_arriba  = [90, 70];  // boca superior de la tolva (X, Y)
tolva_alto    = 70;
tolva_pared   = 2.0;

brida_lado   = 36;    // brida del lado del motor
brida_esp    = 4;
tornillo_m3  = 3.3;   // agujero pasante M3
separ_m3     = 26;    // distancia entre los 2 tornillos de la brida

banco_alto_eje = 75;  // altura del eje sobre la mesa (vaso + balanza debajo)

holgura      = 0.3;

// ============================================================================
//  DERIVADAS (no tocar)
// ============================================================================
tubo_de      = tubo_di + 2*tubo_pared;
tubo_largo   = sinfin_largo + 2;            // + luz al fondo
cuerpo_largo = brida_esp + tubo_largo + 3;  // + pared del fondo
entrada_x0   = brida_esp + cubo_largo + 2;
ventana_ancho= tubo_di * 0.8;
salida_x0    = brida_esp + tubo_largo - salida_largo - 2;
apoyo2_x     = salida_x0 - 22;          // segundo apoyo, antes de la salida

// ============================================================================
//  CÁLCULOS QUE SE MUESTRAN EN LA CONSOLA
// ============================================================================
vol_vuelta_cm3 = PI/4*(sinfin_d*sinfin_d - nucleo_d*nucleo_d)*paso
                 *(1 - aleta_ang/360) / 1000;
echo(str("Volumen geométrico por vuelta: ", vol_vuelta_cm3, " cm3 ",
         "(el real es ~40-60 % de esto: medilo con la balanza)"));
alto_libre = caja_alto - 2*pared - 30 /*cajón*/ - 5 /*apoyo*/ - 28 /*sinfín y tobogán*/;
echo(str("Alto libre para el mate en el equipo: ", alto_libre, " mm. ",
         "Tu mate: ", mate_alto, " mm -> ",
         mate_alto <= alto_libre ? "ENTRA" : "NO ENTRA: subí caja_alto"));

// ============================================================================
//  UTILIDADES
// ============================================================================
// agujero en D (eje del N20) con holgura
module agujero_D(largo) {
    dd = n20_eje_d + holgura;
    intersection() {
        cylinder(d=dd, h=largo);
        translate([-dd/2, -dd/2, 0]) cube([n20_eje_plano + holgura, dd, largo]);
    }
}

module caja_redondeada(x, y, z, r) {
    hull() for (i=[r, x-r], j=[r, y-r]) translate([i, j, 0]) cylinder(r=r, h=z);
}

// ============================================================================
//  FASE 2 · PIEZAS DEL DOSIFICADOR
// ============================================================================

// Sinfín, de pie (Z) para imprimir. El lado del motor queda abajo.
module sinfin() {
    vueltas = (sinfin_largo - cubo_largo) / paso;
    difference() {
        union() {
            cylinder(d=nucleo_d, h=sinfin_largo);
            cylinder(d=sinfin_d - 4, h=cubo_largo);          // cubo
            translate([0, 0, cubo_largo])
                linear_extrude(height=sinfin_largo - cubo_largo,
                               twist=-360*vueltas, slices=ceil(vueltas*48),
                               convexity=10)
                    aleta_2d();
        }
        translate([0, 0, -0.1]) agujero_D(n20_eje_largo + 0.5);
        // agujero para un tornillo M3 que hace de eje del otro lado
        translate([0, 0, sinfin_largo - 8]) cylinder(d=2.6, h=8.2);
    }
}
module aleta_2d() {
    // sector de corona: al retorcerse da una aleta de espesor constante
    intersection() {
        difference() { circle(d=sinfin_d); circle(d=nucleo_d - 1); }
        polygon([[0,0], [sinfin_d, 0],
                 [sinfin_d*cos(aleta_ang), sinfin_d*sin(aleta_ang)]]);
    }
}

// Tolva + tubo + brida, en una pieza. Eje del tubo = eje X, en z = 0.
module cuerpo_dosificador() {
    difference() {
        union() {
            // tubo
            translate([brida_esp, 0, 0]) rotate([0, 90, 0])
                cylinder(d=tubo_de, h=cuerpo_largo - brida_esp);
            // brida del motor (abajo queda plana con el tubo, para imprimir)
            translate([0, -brida_lado/2, -tubo_de/2])
                cube([brida_esp, brida_lado, tubo_de/2 + brida_lado/2]);
            // tolva exterior
            tolva(0);
            // patitas para que se apoye derecho al imprimir y en la base
            for (x=[brida_esp + 10, apoyo2_x])
                translate([x, -tubo_de/2, -tubo_de/2 - 0.01]) cube([8, tubo_de, tubo_de/2]);
        }
        // interior del tubo (abierto del lado del motor para meter el sinfín)
        translate([-0.1, 0, 0]) rotate([0, 90, 0])
            cylinder(d=tubo_di, h=brida_esp + tubo_largo + 0.1);
        // interior de la tolva
        tolva(tolva_pared);
        // ventana de entrada
        translate([entrada_x0, -ventana_ancho/2, 0]) cube([entrada_largo, ventana_ancho, tubo_de]);
        // salida hacia abajo
        translate([salida_x0, -ventana_ancho/2, -tubo_de]) cube([salida_largo, ventana_ancho, tubo_de]);
        // agujero del eje M3 en el fondo
        translate([cuerpo_largo - 4, 0, 0]) rotate([0, 90, 0]) cylinder(d=tornillo_m3, h=10);
        // tornillos de la brida
        for (s=[-1, 1]) translate([-0.1, s*separ_m3/2, 0]) rotate([0, 90, 0])
            cylinder(d=tornillo_m3, h=brida_esp + 0.2);
    }
}
module tolva(e) {
    // e = 0: volumen exterior; e > 0: hueco interior
    base = [entrada_largo + 2*tolva_pared - 2*e, ventana_ancho + 2*tolva_pared - 2*e];
    arriba = [tolva_arriba[0] - 2*e, tolva_arriba[1] - 2*e];
    cx = entrada_x0 + entrada_largo/2;
    z0 = tubo_de/2 - 4;
    hull() {
        translate([cx - base[0]/2, -base[1]/2, e > 0 ? 0 : z0 - 2]) cube([base[0], base[1], 0.01]);
        translate([cx - arriba[0]/2, -arriba[1]/2, z0 + tolva_alto + (e > 0 ? 1 : 0)])
            cube([arriba[0], arriba[1], 0.01]);
    }
}

// Abrazadera del N20: se atornilla a la brida con 2 M3.
module soporte_motor() {
    largo = n20_largo + 3;
    tapa  = 3;                       // tapa que cierra el tubo del lado del motor
    difference() {
        union() {
            translate([-largo - tapa, -n20_ancho/2 - 3, -n20_alto/2 - 3])
                cube([largo, n20_ancho + 6, n20_alto + 6]);
            translate([-tapa, -brida_lado/2, -tubo_de/2])
                cube([tapa, brida_lado, tubo_de/2 + brida_lado/2]);
        }
        // alojamiento del motor (abierto atrás para los cables)
        translate([-largo - tapa - 1, -(n20_ancho + holgura)/2, -(n20_alto + holgura)/2])
            cube([largo + 1, n20_ancho + holgura, n20_alto + holgura]);
        // paso del eje
        translate([-tapa - 1, 0, 0]) rotate([0, 90, 0]) cylinder(d=5, h=tapa + 2);
        // tornillos a la brida
        for (s=[-1, 1]) translate([-tapa - 1, s*separ_m3/2, 0]) rotate([0, 90, 0])
            cylinder(d=tornillo_m3, h=tapa + 2);
    }
}

// Base: dos cunas que sostienen el tubo a `banco_alto_eje` sobre la mesa,
// con espacio debajo de la salida para un vaso sobre la balanza.
module base_banco() {
    largo = cuerpo_largo + 20;
    ancho = 70;
    difference() {
        union() {
            translate([-12, -ancho/2, 0]) cube([apoyo2_x + 26, ancho, 4]);
            for (x=[brida_esp + 6, apoyo2_x - 4])
                translate([x, -tubo_de/2 - 6, 0]) cube([16, tubo_de + 12, banco_alto_eje]);
        }
        // cuna (apoyo del tubo)
        translate([-20, 0, banco_alto_eje]) rotate([0, 90, 0])
            cylinder(d=tubo_de + holgura, h=largo + 40);
        // ranuras para precintos
        for (x=[brida_esp + 6, apoyo2_x - 4])
            translate([x + 5, -tubo_de/2 - 7, banco_alto_eje - tubo_de/2 - 6]) cube([6, tubo_de + 14, 3]);
    }
}

module banco_prueba() {
    color("SaddleBrown") base_banco();
    translate([0, 0, banco_alto_eje]) {
        color("Gainsboro", 0.85) cuerpo_dosificador();
        color("Orange") translate([0.5, 0, 0]) rotate([0, 90, 0]) sinfin();
        color("DimGray") soporte_motor();
        color("Silver") translate([-n20_largo - 3, -n20_ancho/2, -n20_alto/2])
            cube([n20_largo, n20_ancho, n20_alto]);
    }
}

// ============================================================================
//  CONCEPTO DEL EQUIPO COMPLETO (volúmenes, no piezas finales)
// ============================================================================
//  Idea de funcionamiento (resuelve "limpiar boca abajo / cargar boca arriba"):
//   1. El mate entra BOCA ABAJO en el pozo, sobre un aro de apoyo.
//   2. Un rotor con paletas de silicona sube por la boca y gira: la yerba cae
//      al cajón de residuos.
//   3. El LED pide dar vuelta el mate (único paso manual del MVP).
//   4. Con el mate BOCA ARRIBA, el sinfín inclinado lleva yerba desde la tolva
//      (atrás) hasta un tobogán que cae en la boca del mate.
// ============================================================================
pozo_d   = mate_d_max + 8;
pozo_c   = [caja_ancho/2, 72];    // centro del pozo (adelante)
fondo_y  = 128;                  // a partir de acá: franja trasera (tolva y electrónica)
cajon_h  = 30;

module equipo(corte=false) {
    {
        union() {
            // carcasa (transparente; en el corte se saca la mitad de la derecha)
            color("Black", corte ? 0.6 : 0.25) difference() {
                caja_redondeada(caja_ancho, caja_fondo, caja_alto, caja_r_esq);
                translate([pared, pared, pared])
                    caja_redondeada(caja_ancho - 2*pared, caja_fondo - 2*pared, caja_alto, caja_r_esq - pared);
                if (corte) translate([pozo_c[0] - 30, -1, -1]) cube([caja_ancho, caja_fondo + 2, caja_alto + 10]);
            }
            // cajón de residuos (extraíble por el frente)
            color("Peru", 0.8) translate([pozo_c[0] - pozo_d/2, pared, pared])
                cube([pozo_d, fondo_y - pared - 4, cajon_h]);
            // aro de apoyo del mate + rotor de limpieza
            color("DimGray") translate([pozo_c[0], pozo_c[1], pared + cajon_h])
                difference() { cylinder(d=pozo_d, h=5); translate([0,0,-1]) cylinder(d=mate_boca_d + 6, h=7); }
            color("Tomato") translate([pozo_c[0], pozo_c[1], pared + 2]) {
                cylinder(d=6, h=cajon_h + 45);
                for (a=[0, 120, 240]) rotate([0, 0, a])
                    translate([0, -1, cajon_h + 10]) cube([mate_boca_d/2 - 3, 2, mate_alto*0.55]);
            }
            // mate (fantasma, boca abajo)
            color("Sienna", 0.5) translate([pozo_c[0], pozo_c[1], pared + cajon_h + 5]) {
                // boca abajo: primero la virola, después la panza y arriba la base
                difference() { cylinder(d=mate_d_max, h=mate_virola_alto); translate([0,0,-1]) cylinder(d=mate_boca_d, h=mate_virola_alto + 2); }
                translate([0, 0, mate_virola_alto]) cylinder(d1=mate_d_max - 4, d2=mate_base_d*0.7, h=(mate_alto - mate_virola_alto)*0.75);
                translate([0, 0, mate_virola_alto + (mate_alto - mate_virola_alto)*0.75])
                    cylinder(d1=mate_base_d*0.7, d2=mate_base_d, h=(mate_alto - mate_virola_alto)*0.25);
            }
            // tolva (atrás, arriba)
            color("Gainsboro", 0.8) translate([30, fondo_y, 55])
                cube([caja_ancho - 60, caja_fondo - fondo_y - pared - 4, caja_alto - 55 - pared - 8]);
            // sinfín inclinado: de la base de la tolva al tobogán sobre la boca
            boca_z = pared + cajon_h + 5 + mate_alto;   // boca del mate cuando está boca arriba
            color("Orange") hull() {
                translate([caja_ancho/2, fondo_y + 15, 62]) sphere(d=tubo_de);
                translate([caja_ancho/2, pozo_c[1] + mate_boca_d/2 + 12, boca_z + 16]) sphere(d=tubo_de);
            }
            // tobogán hasta el centro de la boca
            color("Gold") hull() {
                translate([caja_ancho/2, pozo_c[1] + mate_boca_d/2 + 6, boca_z + 8]) cube([16, 2, 2], center=true);
                translate([caja_ancho/2, pozo_c[1], boca_z + 3]) cube([16, 2, 2], center=true);
            }
            // motores
            color("Silver") translate([caja_ancho/2 - 6, fondo_y + 22, 50]) cube([12, 26, 10]);
            // electrónica (ESP32-C3, TB6612, carga USB-C) y batería 18650
            color("SeaGreen") translate([22, fondo_y + 2, pared + 2]) cube([60, 40, 18]);
            color("RoyalBlue") translate([95, fondo_y + 20, pared + 11]) rotate([0, 90, 0]) cylinder(d=18.5, h=65);
            // botón con anillo LED (arriba al frente)
            color("White") translate([caja_ancho/2, 20, caja_alto]) cylinder(d=16, h=2);
            // compartimento lateral para la bombilla
            color("Khaki", 0.8) translate([caja_ancho - pared - 18, 50, pared]) cube([14, 70, 110]);
        }
    }
}

// ============================================================================
//  SELECCIÓN
// ============================================================================
if      (pieza == "sinfin")             sinfin();
else if (pieza == "cuerpo_dosificador") cuerpo_dosificador();
else if (pieza == "soporte_motor")      rotate([0, 90, 0]) translate([3, 0, 0]) soporte_motor();
else if (pieza == "base_banco")         base_banco();
else if (pieza == "banco_prueba")       banco_prueba();
else if (pieza == "equipo")             equipo(false);
else if (pieza == "equipo_corte")       equipo(true);
