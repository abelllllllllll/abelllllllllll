# 📝 Bitácora de cambios

Aquí se anota cada ajuste al analizador: **qué** se cambió y **por qué**.
Lo más nuevo va arriba.

---

## 13/11/2026 — Gráfica por mes: sumar o promediar según la columna

**Qué se hizo:** en la gráfica "por mes", las columnas como `precio_unitario`
ahora se **promedian** en vez de sumarse. El título de cada gráfica dice si es "suma" o "promedio".
Las palabras que activan el promedio están en `config.py` → `PALABRAS_PARA_PROMEDIAR`.

**Por qué:** sumar precios de todo un mes da un número que no significa nada.
El precio promedio del mes sí se entiende. Las ventas o piezas se siguen sumando.

---

## 07/11/2026 — Privacidad de los datos

**Qué se hizo:** los archivos en `datos/` y sus reportes en `resultados/` ya no se suben a GitHub.

**Por qué:** el repositorio es público y los datos reales (gastos, ingresos, ventas) son personales.
Solo se suben los datos de ejemplo, que son inventados.

---

## 07/11/2026 — Primera versión

**Qué se hizo:**
- Analizador que lee CSV y Excel y crea un reporte en `resultados/`.
- Limpieza automática: filas vacías, duplicados, espacios de más,
  números guardados como texto (`$1,200`) y fechas guardadas como texto.
- Hallazgos en español simple, estadísticas, valores más comunes y 4 tipos de gráficas.
- Datos de ejemplo (`ventas_ejemplo.csv`) para probarlo.
- Ajustes centralizados en `config.py`.

**Pendiente / ideas para siguientes versiones:**
- Probarlo con datos reales y ajustar según lo que haga falta.
- ~~La gráfica "por mes" suma todas las columnas numéricas~~ ✅ Resuelto el 13/11/2026.
