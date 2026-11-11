// ============================================================================
//  DISPOSITIVO AUTOMÁTICO DE MATE · EQUIPO v1 (genérico, para todos los mates)
// ============================================================================
//  Arquitectura tipo "cafetera" con DOS estaciones:
//
//    IZQUIERDA (limpieza)          DERECHA (carga)
//    mate BOCA ABAJO sobre un      mate BOCA ARRIBA sobre un plato;
//    asiento cónico de costillas;  un sinfín inclinado trae yerba de
//    un rotor con paletas de TPU   la tolva (atrás) y la deja caer
//    gira adentro y la yerba cae   en la boca.
//    al cajón de residuos.
//
//  El asiento cónico centra solo cualquier boca de Ø40 a Ø120 mm, y el plato
//  centra cualquier base. Por eso sirve para calabazas, camioneros, imperiales,
//  torpedos, de vidrio, cerámica, acero, etc. (hasta 130 mm de alto).
//
//  Uso:
//    pieza = "ensamble" | "ensamble_corte" | "explotado"  -> vistas
//    pieza = nombre de una pieza (ver lista al final)      -> STL para imprimir
//    pieza = "pos_<nombre>"   -> la pieza en su lugar del ensamble (visor 3D)
//
//    openscad -D 'pieza="cajon"' -o cajon.stl equipo_v1.scad
// ============================================================================



pieza = "ensamble";
$fn = 64;

// ============================================================================
//  MEDIDAS GENERALES
// ============================================================================
W = 290;          // ancho total (X)
D = 230;          // fondo total (Y)
H = 220;          // alto total (Z)  -> cada módulo entra en impresoras de 220 mm de alto
pared = 3;
r_esq = 14;       // radio de las esquinas verticales
techo_h = 12;     // alto de la pieza del techo

// --- Diseño exterior ---
nicho_ancho = 118;   // abertura frontal de la estación de carga
nicho_r     = 18;    // radio de sus esquinas de arriba
tapa_limp_d = 134;   // tapa redonda de arriba (estación de limpieza)

modulo_ancho = W / 2;            // dos módulos de 145 mm que se atornillan
cy      = 75;                    // centro (Y) de las dos estaciones
cxL     = modulo_ancho / 2;      // centro (X) estación de limpieza
cxR     = modulo_ancho * 1.5;    // centro (X) estación de carga
torre_y = 140;                   // desde acá hacia atrás: torre (electrónica / tolva)

// --- Rango de mates soportado ---
boca_min = 40;    // boca más chica que apoya en el asiento
boca_max = 124;   // virola más grande que apoya en el asiento
mate_alto_max = 130;

// --- Estación de limpieza ---
col_d      = 32;   // columna que aloja el motor del rotor
col_alto   = 55;   // desde el piso
asiento_r0 = boca_min/2;   // radio interior de las costillas
asiento_r1 = boca_max/2;   // radio exterior
asiento_z0 = 64;           // altura del borde interior de las costillas
asiento_ang = 25;          // pendiente del cono (centra el mate)
costillas  = 6;
cajon_z    = 4;   cajon_h = 42;

// --- Rotor ---
cubo_d     = 36;   // "paraguas" que tapa la columna
cubo_h     = 10;
eje_rotor_d = 4.0; eje_rotor_plano = 3.5;   // JGA25-370: eje Ø4 con cara plana
paleta_esp = 2.6;
paleta_larga = 110;   // set largo: mates altos (camionero, imperial)
paleta_corta = 60;    // set corto: calabacitas y mates bajos

// --- Estación de carga ---
plato_d = 124;  plato_z = 32;

// --- Dosificador inclinado ---
// Sinfín HORIZONTAL arriba del mate (igual que el banco de prueba), de adelante hacia atrás.
// El motor queda adelante; la salida, justo sobre el centro del plato; la entrada, atrás bajo la tolva.
dos_z      = 192;            // eje del tubo
dos_y_brida = cy - 25;       // cara de la brida (lado motor)
dos_largo  = 168;            // hasta el fondo (atrás)
dos_salida = 25;             // centro de la salida, medido desde la brida (= centro del plato)
dos_entrada = [100, 145];    // ventana de entrada, medida desde la brida
// Tolva removible ARRIBA (como un molinillo de café): se saca para llenarla o lavarla.
tolva_socket = 8;            // encastre sobre el cuello del dosificador
tolva_embudo = 68;           // alto del cono: paredes a ~60° para que la yerba no haga puente
tolva_recta  = 55;           // alto del cilindro
tolva_d      = 96;           // diámetro del cilindro

// --- Bandeja de electrónica (torre izquierda) ---
band_x = [18, 138];  band_y = [torre_y + 6, D - 6];   // contorno
band_z = pared + 4;                                   // apoya sobre 4 tetones del piso
band_tornillos = [[24, torre_y + 10], [132, torre_y + 10], [24, D - 10], [132, D - 10]];
usb_x  = 118;                                         // centro del conector USB-C (atrás)
// Sinfín: medidas de la "receta" que sale de calculos/simulacion.py
tubo_di = 25.6; tubo_de = 30.4; sinfin_d = 24; nucleo_d = 8; paso = 30; aleta_ang = 40;
sinfin_largo = dos_largo - 8;

// ============================================================================
//  CHEQUEOS (consola)
// ============================================================================
function z_asiento(r) = asiento_z0 + (r - asiento_r0) * tan(asiento_ang);
echo(str("Mate boca abajo más alto: virola Ø", 105, " apoya a z=", z_asiento(52.5),
         " -> tope a ", z_asiento(52.5) + mate_alto_max, " mm (techo ", H - pared, ")"));
echo(str("Mate boca arriba más alto: tope a ", plato_z + 8 + mate_alto_max,
         " mm, salida de yerba a ", dos_z - tubo_de/2, " mm"));
echo(str("Sinfín v1: horizontal, largo ", dos_largo, " mm; tolva hasta z=", H + tolva_socket + tolva_embudo + tolva_recta, " mm"));

// ============================================================================
//  UTILIDADES
// ============================================================================
module caja_r(x, y, z, r) {
    hull() for (i=[r, x-r], j=[r, y-r]) translate([i, j, 0]) cylinder(r=r, h=z);
}
// esquinas redondeadas solo del lado exterior de cada módulo
module perfil(lado) {   // 2D. lado = -1 izquierdo, +1 derecho
    hull() {
        if (lado < 0) {
            translate([r_esq, r_esq]) circle(r=r_esq);
            translate([r_esq, D - r_esq]) circle(r=r_esq);
            translate([modulo_ancho - 1, 0]) square([1, D]);
        } else {
            square([1, D]);
            translate([modulo_ancho - r_esq, r_esq]) circle(r=r_esq);
            translate([modulo_ancho - r_esq, D - r_esq]) circle(r=r_esq);
        }
    }
}
module bloque_modulo(lado, alto=H) { linear_extrude(height=alto) perfil(lado); }
module agujero_D(d, plano, largo) {
    intersection() {
        cylinder(d=d, h=largo);
        translate([-d/2, -d/2, 0]) cube([plano, d, largo]);
    }
}

// ============================================================================
//  CARCASAS (se imprimen sin techo; el techo es otra pieza)
// ============================================================================
cajon_x0 = r_esq + 2;  cajon_x1 = modulo_ancho - pared - 2;
module carcasa(lado) {
    difference() {
        bloque_modulo(lado, H - techo_h);
        // hueco general (la pared sigue la curva de las esquinas)
        translate([0, 0, pared]) linear_extrude(height=H) offset(delta=-pared) perfil(lado);
        // derecha: nicho frontal con esquinas redondeadas
        if (lado > 0) hull() {
            // el borde de arriba queda justo debajo del tubo: tapa el sinfín y su motor
            for (sx=[-1, 1]) translate([cxL + sx*(nicho_ancho/2 - nicho_r), -1, dos_z - tubo_de/2 + 2 - nicho_r])
                rotate([-90, 0, 0]) cylinder(r=nicho_r, h=pared + 2);
            translate([cxL - nicho_ancho/2, -1, pared]) cube([nicho_ancho, pared + 2, 1]);
        }
        // izquierda: solo la boca del cajón (el mate entra por arriba)
        if (lado < 0) translate([cajon_x0 - 0.5, -1, cajon_z - 0.5])
            cube([cajon_x1 - cajon_x0 + 1, pared + 2, cajon_h + 1]);
        // unión entre módulos: agujeros M3
        for (y=[30, 100, 180], z=[20, 110, 195])
            translate([lado < 0 ? modulo_ancho - pared - 1 : -1, y, z]) rotate([0, 90, 0])
                cylinder(d=3.3, h=pared + 2);
        // USB-C atrás (módulo izquierdo), alineado con el cargador de la bandeja
        if (lado < 0) translate([usb_x - 5, D - pared - 1, band_z + 5]) cube([10, pared + 2, 4.5]);
        // rebajes para las patas de silicona Ø12
        for (y=[22, D - 22]) translate([lado < 0 ? 22 : modulo_ancho - 22, y, -0.01]) cylinder(d=12.6, h=1);
    }
    // pared entre estación y torre
    difference() {
        translate([pared, torre_y, pared]) cube([modulo_ancho - 2*pared, pared, H - techo_h - pared]);
        if (lado > 0) cuerpo_dos_hueco();  // paso del tubo
        if (lado < 0) {
            // cables del motor del rotor: pasan 11 mm sobre el piso (barrera contra la humedad)
            translate([cxL + 6, torre_y - 1, pared + 11]) cube([8, pared + 2, 8]);
            // cables de los sensores de la tapa (arriba)
            translate([cxL - 6, torre_y - 1, H - techo_h - 9]) cube([12, pared + 2, 10]);
        }
    }
    // repisas que sostienen el asiento / el plato
    if (lado < 0) for (a=[45, 135, 225, 315])
        translate([cxL + cos(a)*(asiento_r1 + 1), cy + sin(a)*(asiento_r1 + 1), z_asiento(asiento_r1) - 16])
            cylinder(d=10, h=4);
    if (lado > 0) for (a=[0, 90, 180, 270])
        translate([cxL + cos(a)*(plato_d/2 - 2), cy + sin(a)*(plato_d/2 - 2), plato_z - 4])
            cylinder(d=10, h=4);
    // tetones del piso donde se atornilla la bandeja de electrónica
    if (lado < 0) for (t=band_tornillos) translate([t[0], t[1], pared - 0.01]) difference() {
        cylinder(d=8, h=band_z - pared); cylinder(d=2.6, h=band_z - pared + 1);
    }
    // nervio que sostiene la columna del motor (va por la ranura del cajón)
    if (lado < 0) translate([cxL - 4, cy, pared]) cube([8, torre_y - cy, cajon_z + cajon_h - pared]);
}

// Techos (tapas de arriba de cada módulo)
module techo(lado) {
    difference() {
        translate([0, 0, H - techo_h]) bloque_modulo(lado, techo_h);
        translate([0, 0, H - techo_h - 1]) linear_extrude(height=techo_h - pared + 1) offset(delta=-pared) perfil(lado);
        if (lado > 0) {
            // botón + anillo LED
            translate([cxL, 28, H - pared - 1]) cylinder(d=32, h=pared + 2);
            // paso del cuello del dosificador (la tolva se apoya encima)
            en_eje_dos() translate([dos_entrada[0] - 3.5, -14.5, 0]) cube([dos_entrada[1] - dos_entrada[0] + 7, 29, 40]);
        } else {
            // boca redonda por donde entra el mate + rebaje para la tapa
            translate([cxL, cy, H - pared - 1]) cylinder(d=tapa_limp_d - 7, h=pared + 2);
            translate([cxL, cy, H - 1.6]) cylinder(d=tapa_limp_d + 0.6, h=2);
            // muesca para levantar la tapa con el dedo
            translate([cxL, cy - tapa_limp_d/2, H - 1.6]) cylinder(d=20, h=2);
            // porta-bombilla y cepillo
            for (x=[cxL - 14, cxL + 14]) translate([x, D - 28, H - pared - 1]) cylinder(d=16, h=pared + 2);
        }
    }
    if (lado < 0) soporte_sensores();
}
// Soporte de los sensores de la tapa (parte del techo izquierdo): queda bajo el borde
// de atrás de la tapa. Lleva el sensor Hall (ranura) y el microinterruptor (2 tornillos M2).
sens_y = cy + tapa_limp_d/2 - 12;      // debajo del imán de la tapa
module soporte_sensores() {
    zt = H - 1.6 - 5 - 0.8;            // justo debajo del reborde de la tapa
    difference() {
        hull() {
            translate([cxL - 13, torre_y - 2, zt - 3]) cube([26, 8, H - pared - zt + 3]);
            translate([cxL - 13, sens_y - 6, zt - 3]) cube([26, 1, 3]);
        }
        translate([cxL - 2.3, sens_y - 3, zt - 1.8]) cube([4.6, 4, 2]);                  // sensor Hall
        for (sx=[-1, 1]) translate([cxL + sx*4.75 + 8*0, sens_y + 6, zt - 4]) cylinder(d=1.8, h=6); // micro (M2)
    }
}
// Tapa redonda de la estación de limpieza (lleva el imán del sensor)
module tapa_limpieza() {
    translate([cxL, cy, H - 1.6]) cylinder(d=tapa_limp_d, h=1.6);
    translate([cxL, cy, H - 1.6 - 5]) difference() {
        cylinder(d=tapa_limp_d - 7.6, h=5);
        translate([0, 0, -1]) cylinder(d=tapa_limp_d - 12, h=7);
    }
    // alojamiento del imán Ø6x3
    translate([cxL, sens_y, H - 1.6 - 4]) difference() {
        cylinder(d=10, h=4); translate([0, 0, -0.1]) cylinder(d=6.2, h=3.1);
    }
}

// ============================================================================
//  ESTACIÓN DE LIMPIEZA
// ============================================================================
// Columna que aloja el motor JGA25-370 (cuelga de la placa superior)
module columna_motor() {
    difference() {
        union() {
            cylinder(d=col_d, h=col_alto);
            cylinder(d=col_d + 16, h=3);                         // base
        }
        translate([0, 0, -1]) cylinder(d=25.6, h=col_alto - 3 + 1);   // motor
        translate([0, 0, col_alto - 4]) cylinder(d=7.5, h=6);         // eje + buje
        for (s=[-1, 1]) translate([s*8.5, 0, col_alto - 4]) cylinder(d=3.3, h=6);
        for (a=[0, 120, 240]) rotate([0, 0, a]) translate([col_d/2 + 4, 0, -1]) cylinder(d=3.3, h=5);
        translate([-5, 0, -1]) cube([10, col_d, 10]);              // salida de cables hacia atrás
    }
}

// Asiento cónico de costillas: cualquier boca de Ø40 a Ø124 se apoya y se centra.
module asiento() {
    for (i=[0:costillas-1]) rotate([0, 0, i*360/costillas + 30])
        rotate([90, 0, 0]) linear_extrude(height=4, center=true)
            polygon([[asiento_r0, z_asiento(asiento_r0) - 12], [asiento_r0, z_asiento(asiento_r0)],
                     [asiento_r1, z_asiento(asiento_r1)], [asiento_r1 + 4, z_asiento(asiento_r1)],
                     [asiento_r1 + 4, z_asiento(asiento_r1) - 16]]);
    // aro exterior (apoya en las repisas de la carcasa)
    translate([0, 0, z_asiento(asiento_r1) - 16]) difference() {
        cylinder(r=asiento_r1 + 6, h=6);
        translate([0, 0, -1]) cylinder(r=asiento_r1 - 1, h=8);
    }
    // aro interior
    translate([0, 0, z_asiento(asiento_r0) - 12]) difference() {
        cylinder(r=asiento_r0 + 3, h=6);
        translate([0, 0, -1]) cylinder(r=asiento_r0, h=8);
    }
}

// Cubo del rotor: paraguas sobre la columna + 3 ranuras para las paletas
module cubo_rotor() {
    difference() {
        union() {
            cylinder(d=cubo_d, h=3);                 // paraguas
            cylinder(d=24, h=cubo_h);
            translate([0, 0, -6]) difference() {     // pollera (laberinto)
                cylinder(d=cubo_d, h=6);
                translate([0, 0, -1]) cylinder(d=col_d + 1.2, h=8);
            }
        }
        translate([0, 0, -7]) agujero_D(eje_rotor_d + 0.25, eje_rotor_plano + 0.2, cubo_h + 8);
        for (a=[0, 120, 240]) rotate([0, 0, a])
            translate([5, -(paleta_esp + 0.3)/2, 2]) cube([20, paleta_esp + 0.3, cubo_h]);
        // prisionero M3 contra la cara plana
        translate([0, 0, cubo_h - 4]) rotate([0, 90, 60]) cylinder(d=2.6, h=15);
    }
}

// Paleta flexible (TPU 85-95A). Angosta abajo para entrar por bocas chicas,
// ancha arriba: se dobla al pasar y raspa las paredes por dentro.
module paleta(alto) {
    rotate([90, 0, 0]) linear_extrude(height=paleta_esp, center=true)
        polygon([[5.5, -cubo_h + 2], [17, -cubo_h + 2], [17, 0], [16, alto*0.25],
                 [40, alto*0.55], [42, alto*0.9], [30, alto], [8, alto], [6, alto*0.3], [5.5, 0]]);
}

// Cajón de residuos en "U": sale por el frente rodeando la columna
module cajon() {
    x0 = cajon_x0; x1 = cajon_x1;
    y0 = 0; y1 = torre_y - 2;     // el frente queda al ras de la carcasa
    ranura = col_d + 6;
    difference() {
        translate([x0, y0, cajon_z]) cube([x1 - x0, y1 - y0, cajon_h]);
        translate([x0 + 2, y0 + 2, cajon_z + 2]) cube([x1 - x0 - 4, y1 - y0 - 4, cajon_h]);
        // ranura hacia atrás para la columna y su nervio
        translate([cxL - ranura/2, cy - ranura/2, cajon_z - 1]) cube([ranura, y1 - cy + ranura, cajon_h + 2]);
        translate([cxL, cy, cajon_z - 1]) cylinder(d=ranura, h=cajon_h + 2);
        // tirador: muesca para el dedo en el borde de arriba del frente
        hull() for (sx=[-1, 1]) translate([cxL + sx*14, -1, cajon_z + cajon_h]) rotate([-90, 0, 0]) cylinder(r=8, h=4);
    }
    // paredes de la ranura
    difference() {
        union() {
            translate([cxL - ranura/2 - 2, cy, cajon_z]) cube([ranura + 4, y1 - cy, cajon_h]);
            translate([cxL, cy, cajon_z]) cylinder(d=ranura + 4, h=cajon_h);
        }
        translate([cxL - ranura/2, cy, cajon_z - 1]) cube([ranura, y1 - cy + 1, cajon_h + 2]);
        translate([cxL, cy, cajon_z - 1]) cylinder(d=ranura, h=cajon_h + 2);
    }
}

// ============================================================================
//  ESTACIÓN DE CARGA
// ============================================================================
module plato() {
    difference() {
        union() {
            cylinder(d=plato_d, h=3);
            translate([0, 0, 3]) cylinder(d1=plato_d, d2=plato_d - 8, h=5);
        }
        // cono suave: centra la base del mate
        translate([0, 0, 3]) cylinder(d1=20, d2=plato_d - 14, h=5.01);
        // rejilla para que caiga lo que se derrame
        for (i=[-4:4], j=[-4:4]) if (i*i + j*j < 18 && (i != 0 || j != 0))
            translate([i*11, j*11, -1]) cylinder(d=5, h=10);
    }
}

// Dosificador: tubo horizontal + brida + cuello hacia la tolva (una pieza)
module en_eje_dos() {   // sistema local: X = a lo largo del tubo, desde la brida hacia atrás
    translate([cxL, dos_y_brida, dos_z]) rotate([0, 0, 90]) children();
}
module cuerpo_dos_hueco() {
    en_eje_dos() translate([-1, 0, 0]) rotate([0, 90, 0]) cylinder(d=tubo_de + 2, h=dos_largo + 2);
}
cuello_largo = dos_entrada[1] - dos_entrada[0] + 6;   // cuello: ventana + paredes de 3 mm
cuello_ancho = 18 + 8;
cuello_alto  = H + tolva_socket - dos_z;              // hasta el borde del encastre
module cuerpo_dosificador_v1() {
    difference() {
        en_eje_dos() union() {
            rotate([0, 90, 0]) cylinder(d=tubo_de, h=dos_largo);
            translate([0, -18, -18]) cube([4, 36, 36]);                                   // brida del motor
            translate([dos_entrada[0] - 3, -cuello_ancho/2, 0]) cube([cuello_largo, cuello_ancho, cuello_alto]);
            // orejas para atornillar a la pared de la torre (y = torre_y)
            translate([torre_y - dos_y_brida - 3, -22, -8]) cube([3, 44, 16]);
        }
        en_eje_dos() {
            translate([-1, 0, 0]) rotate([0, 90, 0]) cylinder(d=tubo_di, h=dos_largo - 3 + 1);
            translate([dos_entrada[0], -9, 0]) cube([dos_entrada[1] - dos_entrada[0], 18, cuello_alto + 1]); // entrada
            translate([dos_salida - 12, -9, -20]) cube([24, 18, 20]);                     // salida sobre el plato
            translate([dos_largo - 5, 0, 0]) rotate([0, 90, 0]) cylinder(d=3.3, h=10);    // eje M3 del fondo
            for (sx=[-1, 1]) translate([-1, sx*13, 0]) rotate([0, 90, 0]) cylinder(d=3.3, h=6);
            for (sx=[-1, 1]) translate([torre_y - dos_y_brida - 4, sx*17, 0]) rotate([0, 90, 0]) cylinder(d=3.3, h=5);
        }
    }
}
// Tolva removible cilíndrica: se encastra sobre el cuello y se apoya en el techo
tolva_c = [cxL, dos_y_brida + (dos_entrada[0] + dos_entrada[1])/2];
module tolva_vol(e) {
    z0 = H + tolva_socket;
    hull() {
        en_eje_dos() translate([dos_entrada[0] + e - (e > 0 ? 0 : 3), -9 + e - (e > 0 ? 0 : 3), z0 - dos_z - (e > 0 ? 1 : 0)])
            cube([dos_entrada[1] - dos_entrada[0] - 2*e + (e > 0 ? 0 : 6), 18 - 2*e + (e > 0 ? 0 : 6), 0.01]);
        translate([tolva_c[0], tolva_c[1], z0 + tolva_embudo]) cylinder(d=tolva_d - 2*e, h=0.01);
    }
    translate([tolva_c[0], tolva_c[1], z0 + tolva_embudo - 0.01]) cylinder(d=tolva_d - 2*e, h=tolva_recta + (e > 0 ? 1 : 0.01));
}
module tolva() {
    difference() {
        union() {
            tolva_vol(0);
            // encastre (pollera) que abraza el cuello
            en_eje_dos() translate([dos_entrada[0] - 5.3, -cuello_ancho/2 - 2.3, H - dos_z])
                cube([cuello_largo + 4.6, cuello_ancho + 4.6, tolva_socket + 2]);
        }
        tolva_vol(2);
        en_eje_dos() translate([dos_entrada[0] - 3.3, -cuello_ancho/2 - 0.3, H - dos_z - 1])
            cube([cuello_largo + 0.6, cuello_ancho + 0.6, tolva_socket + 1]);
    }
}
function tolva_tope() = H + tolva_socket + tolva_embudo + tolva_recta;
module tapa_tolva() {
    translate([tolva_c[0], tolva_c[1], tolva_tope()]) {
        cylinder(d=tolva_d, h=3);
        translate([0, 0, -5]) difference() {      // reborde que entra en la tolva
            cylinder(d=tolva_d - 4.5, h=5);
            translate([0, 0, -1]) cylinder(d=tolva_d - 9, h=7);
        }
    }
}

// ============================================================================
//  ELECTRÓNICA (volúmenes de referencia, no se imprimen)
// ============================================================================
// Bandeja: portapilas 2x18650, placa perforada 5x7 cm sobre 4 columnas y cargador USB-C
pcb_post = [[22, band_y[0] + 2], [88, band_y[0] + 2], [22, band_y[0] + 47.7], [88, band_y[0] + 47.7]];
module bandeja_electronica() {
    difference() {
        union() {
            translate([band_x[0], band_y[0], band_z]) cube([band_x[1] - band_x[0], band_y[1] - band_y[0], 2]);
            // marco del portapilas (77 x 41 mm)
            translate([24, band_y[0] + 4, band_z]) difference() {
                cube([81, 45, 8]); translate([1.6, 1.6, 2]) cube([77.8, 41.8, 7]);
                translate([-1, 14, 2]) cube([83, 17, 7]);       // salida de cables
            }
            // columnas de la placa (M3 autorroscante)
            for (q=pcb_post) translate([q[0], q[1], band_z]) cylinder(d=7, h=32);
            // cuna del cargador USB-C (28 x 17 mm), con el conector hacia atrás
            translate([usb_x - 16, band_y[1] - 22, band_z]) difference() {
                cube([32, 22, 7]); translate([1.8, 1.8, 3]) cube([28.4, 21, 5]);
            }
            // cuna del BMS y del regulador
            translate([usb_x - 16, band_y[0] + 4, band_z]) difference() {
                cube([32, 40, 5]); translate([1.6, 1.6, 2]) cube([28.8, 36.8, 4]);
            }
        }
        for (q=pcb_post) translate([q[0], q[1], band_z + 20]) cylinder(d=2.6, h=13);
        for (t=band_tornillos) translate([t[0], t[1], band_z - 1]) cylinder(d=3.3, h=12);
        // ranuras para precintos
        for (x=[40, 80]) translate([x, band_y[0] + 2, band_z - 1]) cube([6, 2.2, 4]);
    }
}
module electronica() {
    color("RoyalBlue") for (i=[0, 1]) translate([32, band_y[0] + 16 + i*21, band_z + 12]) rotate([0, 90, 0]) cylinder(d=18.5, h=65); // 2x18650
    color("SeaGreen") translate([19, band_y[0] - 1, band_z + 32]) cube([72, 51, 1.6]);       // placa: ESP32-C3 + drivers
    color("SeaGreen") translate([40, band_y[0] + 12, band_z + 33.6]) cube([18, 23, 5]);      // ESP32-C3
    color("DarkSlateGray") translate([usb_x - 14, band_y[1] - 20, band_z + 3]) cube([28, 17, 4]); // cargador 2S USB-C
    color("Silver") translate([cxL, cy, pared]) cylinder(d=25, h=col_alto - 3); // motor rotor JGA25
    color("White") translate([modulo_ancho + cxL, 28, H - 6]) cylinder(d=16, h=6); // botón
    color("DeepSkyBlue") translate([modulo_ancho + cxL, 28, H - 1]) difference() { cylinder(d=31, h=1.2); translate([0,0,-1]) cylinder(d=20, h=3); }
    color("Silver") translate([modulo_ancho, 0, 0]) en_eje_dos() translate([-30, -6, -5]) cube([26, 12, 10]); // N20
}

// ============================================================================
//  MATES DE EJEMPLO (fantasmas)
// ============================================================================
module mate_camionero(boca_abajo) {
    // virola Ø105, boca Ø70, alto 130
    module m() {
        difference() { cylinder(d=105, h=25); translate([0,0,-1]) cylinder(d=70, h=27); }
        translate([0, 0, 25]) cylinder(d1=100, d2=55, h=80);
        translate([0, 0, 105]) cylinder(d1=55, d2=70, h=25);
    }
    if (boca_abajo) m(); else translate([0, 0, 130]) mirror([0, 0, 1]) m();
}

// ============================================================================
//  ENSAMBLE
// ============================================================================
// Posición de cada pieza en el equipo. Las piezas se modelan ya en su lugar
// (salvo rotor, columna, asiento, plato) y se acuestan para imprimir.
module pos(nombre, ex=0) {
    if (nombre == "carcasa_izq")   carcasa(-1);
    if (nombre == "carcasa_der")   translate([modulo_ancho + ex*0.4, 0, 0]) carcasa(1);
    if (nombre == "techo_izq")     translate([0, 0, ex*1.3]) techo(-1);
    if (nombre == "techo_der")     translate([modulo_ancho + ex*0.4, 0, ex*1.3]) techo(1);
    if (nombre == "tapa_tolva")    translate([modulo_ancho + ex*0.4, 0, ex*2.2]) tapa_tolva();
    if (nombre == "tolva")         translate([modulo_ancho + ex*0.4, 0, ex*1.7]) tolva();
    if (nombre == "columna_motor") translate([cxL, cy, pared - ex*0.3]) columna_motor();
    if (nombre == "asiento")       translate([cxL, cy, ex*0.7]) asiento();
    if (nombre == "cubo_rotor")    translate([cxL, cy, pared + col_alto + 1 + ex*0.9]) cubo_rotor();
    if (nombre == "paletas")       translate([cxL, cy, pared + col_alto + 1 + cubo_h + ex*1.1])
                                       for (a=[0, 120, 240]) rotate([0, 0, a]) paleta(paleta_larga);
    if (nombre == "cajon")         translate([0, -ex*1.2, 0]) cajon();
    if (nombre == "tapa_limpieza") translate([0, 0, ex*2.0]) tapa_limpieza();
    if (nombre == "plato")         translate([modulo_ancho + cxL + ex*0.4, cy, plato_z + ex*0.3]) plato();
    if (nombre == "dosificador")   translate([modulo_ancho + ex*0.4, 0, ex*0.6]) cuerpo_dosificador_v1();
    if (nombre == "sinfin")        translate([modulo_ancho + ex*0.4, 0, ex*0.6]) en_eje_dos() translate([1, 0, 0]) rotate([0, 90, 0]) sinfin_v1();
    if (nombre == "electronica")   electronica();
    if (nombre == "bandeja")       translate([0, ex*1.2, 0]) bandeja_electronica();
    if (nombre == "mate_limpieza") translate([cxL, cy, z_asiento(52.5) + ex*1.5]) mate_camionero(true);
    if (nombre == "mate_carga")    translate([modulo_ancho + cxL + ex*0.4, cy, plato_z + 6]) mate_camionero(false);
}

// Primero las piezas opacas y al final las translúcidas (así se ve el interior)
piezas_ens = ["bandeja", "columna_motor", "asiento", "cubo_rotor", "paletas", "cajon",
              "plato", "dosificador", "sinfin", "electronica", "tapa_tolva",
              "mate_limpieza", "mate_carga", "tolva",
              "carcasa_izq", "carcasa_der", "techo_izq", "techo_der", "tapa_limpieza"];
colores = ["#8a8f8a", "#777777", "#555555", "#c0392b", "#e67e22", "#1c1c1e",
           "#3a3a3c", "#cfcfcf", "#f39c12", "#2e8b57", "#2c2c2e",
           "#1e4d8c", "#1e4d8c", "#7d8a8f",
           "#1c1c1e", "#1c1c1e", "#1c1c1e", "#1c1c1e", "#2c2c2e"];

// modo: "fantasma" (carcasa translúcida), "opaco" (como se ve de verdad) o "corte"
module ensamble(ex=0, modo="fantasma") {
    corte = modo == "corte";
    for (i=[0:len(piezas_ens)-1]) {
        n = piezas_ens[i];
        cascara = (n == "carcasa_izq" || n == "carcasa_der" || n == "techo_izq" || n == "techo_der" || n == "tapa_limpieza");
        esmate = (n == "mate_limpieza" || n == "mate_carga");
        alfa = n == "tolva" ? 0.55 : (modo == "opaco" ? 1 : (cascara ? 0.3 : (esmate ? 0.4 : 1)));
        if (!(corte && (n == "techo_izq" || n == "techo_der" || n == "tapa_limpieza")) &&
            !(modo == "opaco" && n == "mate_limpieza"))
            color(colores[i], alfa)
                difference() {
                    pos(n, ex);
                    // corte: se saca la mitad delantera de carcasas y cajón
                    if (corte && (cascara || n == "cajon"))
                        translate([-1, -50, -1]) cube([W + 2, cy + 50, H + 200]);
                }
    }
}

// sinfín del largo del v1
module sinfin_v1() {
    cubo = 8;
    vueltas = (sinfin_largo - cubo) / paso;
    difference() {
        union() {
            cylinder(d=nucleo_d, h=sinfin_largo);
            cylinder(d=sinfin_d - 4, h=cubo);
            translate([0, 0, cubo]) linear_extrude(height=sinfin_largo - cubo, twist=-360*vueltas,
                                                   slices=ceil(vueltas*48), convexity=10)
                intersection() {
                    difference() { circle(d=sinfin_d); circle(d=nucleo_d - 1); }
                    polygon([[0,0], [sinfin_d, 0], [sinfin_d*cos(aleta_ang), sinfin_d*sin(aleta_ang)]]);
                }
        }
        translate([0, 0, -0.1]) agujero_D(3.15, 2.8, 10.5);
        translate([0, 0, sinfin_largo - 8]) cylinder(d=2.6, h=8.2);
    }
}

// ============================================================================
//  SELECCIÓN
// ============================================================================
if (pieza == "ensamble")        ensamble();
else if (pieza == "ensamble_corte") ensamble(0, "corte");
else if (pieza == "ensamble_opaco") ensamble(0, "opaco");
else if (pieza == "explotado")  ensamble(60);
// --- piezas para imprimir (orientación de impresión) ---
else if (pieza == "carcasa_izq")   carcasa(-1);
else if (pieza == "carcasa_der")   carcasa(1);
else if (pieza == "techo_izq")     translate([0, 0, H]) mirror([0, 0, 1]) techo(-1);
else if (pieza == "techo_der")     translate([0, 0, H]) mirror([0, 0, 1]) techo(1);
else if (pieza == "tapa_tolva")    translate([0, 0, tolva_tope() + 3]) mirror([0, 0, 1]) tapa_tolva();
else if (pieza == "tolva")         translate([0, 0, tolva_tope()]) mirror([0, 0, 1]) tolva();   // boca de arriba sobre la cama
else if (pieza == "columna_motor") columna_motor();
else if (pieza == "asiento")       translate([0, 0, -z_asiento(asiento_r0) + 12]) asiento();
else if (pieza == "cubo_rotor")    translate([0, 0, cubo_h]) mirror([0, 0, 1]) cubo_rotor();
else if (pieza == "paleta_larga")  translate([0, 0, paleta_esp/2]) rotate([-90, 0, 0]) paleta(paleta_larga);
else if (pieza == "paleta_corta")  translate([0, 0, paleta_esp/2]) rotate([-90, 0, 0]) paleta(paleta_corta);
else if (pieza == "cajon")         translate([0, 0, -cajon_z]) cajon();
else if (pieza == "tapa_limpieza") translate([0, 0, H]) mirror([0, 0, 1]) tapa_limpieza();
else if (pieza == "plato")         plato();
else if (pieza == "bandeja")       translate([0, 0, -band_z]) bandeja_electronica();
else if (pieza == "dosificador")   translate([0, 0, -(dos_z - 18)]) cuerpo_dosificador_v1();   // con soportes bajo el tubo
else if (pieza == "sinfin_v1")     sinfin_v1();
// --- piezas en su posición, para el visor 3D ---
else if (len(pieza) > 4 && pieza[0] == "p" && pieza[1] == "o" && pieza[2] == "s" && pieza[3] == "_")
    pos(chop(pieza, 4));

function chop(s, n) = n >= len(s) ? "" : str(s[n], chop(s, n + 1));
