# ¿Es viable? ¿Qué falta para producirlo?

## Veredicto

| Aspecto | Estado | Por qué |
|---|---|---|
| **Técnico** | ✅ Viable | La dosificación con sinfín es una técnica probada (dispensers de café y de alimento para mascotas). El asiento cónico resuelve que sirva para todos los mates. |
| **Limpieza** | ⚠️ Riesgo principal | No está probado que un rotor saque ≥ 90 % de la yerba húmeda y compacta, sobre todo en calabazas con forma irregular. Es lo primero que hay que probar. |
| **Económico** | ⚠️ A confirmar | Prototipo ≈ 100-135 €. En serie, el costo depende de los moldes de inyección (miles de euros) y de cuántas unidades se vendan. |
| **Producción** | ❌ Todavía no | Faltan pruebas reales, materiales aptos para alimentos y certificaciones. |

**Qué tiene el diseño para ser genérico:**
- **Asiento cónico de costillas**: cualquier boca o virola de **Ø40 a Ø124 mm** se apoya y se centra sola.
- **Plato con cono suave**: centra cualquier base, con o sin patas.
- **Dos sets de paletas** (larga y corta) de TPU flexible: se doblan para entrar por bocas chicas.
- **Alto máximo del mate: 130 mm** (cubre calabazas, camioneros, imperiales, torpedos, vidrio, acero y cerámica comunes).
- **Dosis configurable** desde el monitor serie (`d=30`), para mates chicos o grandes.

**Límites conocidos:**
- El usuario tiene que **dar vuelta el mate** entre limpieza y carga (único paso manual).
- La tolva alcanza para **~5 cebadas de 30 g**.
- Hay que **vaciar el cajón cada ~2-3 ciclos** (estimado).
- Mates de más de 130 mm o virolas de más de 124 mm no entran: hay que cambiar `H` o el asiento.

## Camino a producción

### Etapa 1 · Validar el prototipo (lo siguiente)
1. Banco del dosificador ([Fase 2](../fase2_banco_dosificador.md)): g/vuelta, CV < 15 %, atascos con 2-3 yerbas.
2. Rotor de limpieza con mates reales: % de yerba retirada, tiempo, ruido, que no raye la virola.
3. Equipo completo: 50 ciclos seguidos, autonomía, desmontaje en < 60 s.
4. Que lo usen 5-10 personas y anotar qué les molesta.

### Etapa 2 · Serie corta (10-50 unidades, impresas)
- Ajustar tolerancias con lo aprendido.
- Placa electrónica propia (PCB) en lugar del perforado: más barata, más chica y repetible.
- Manual de uso y limpieza.
- Sirve para vender a conocidos o hacer una preventa, **no** como producto final certificado.

### Etapa 3 · Producto
- **Materiales en contacto con yerba**: cambiar a **PP inyectado o silicona** de grado alimentario, con certificado del proveedor. Una pieza impresa en 3D tiene poros donde quedan restos: no se considera apta para alimentos solo por el tipo de filamento.
- **Carcasa**: inyección de plástico (o chapa plegada + inyección). Requiere rediseñar con ángulos de desmoldeo y espesores uniformes.
- **Certificaciones** (consultá con un laboratorio del país donde se venda): seguridad eléctrica y compatibilidad electromagnética, baterías de litio (incluido su transporte), y materiales en contacto con alimentos.
- **Propiedad intelectual**: buscá patentes parecidas **antes** de seguir publicando el diseño. Este repositorio es **público**.
- **Costos**: pedir cotización de moldes y de armado en 2-3 proveedores antes de fijar un precio.

## Qué decidir ahora

1. **¿Repositorio privado?** Si la idea es vender, conviene mover el proyecto a un repo privado.
2. **¿Primero el banco del dosificador o el rotor?** Recomiendo el **rotor**: es el riesgo más grande y el que define si el producto tiene sentido.
