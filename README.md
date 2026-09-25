# North — Mis finanzas

App web instalable (PWA) para llevar tarjetas de crédito, préstamos, pagos fijos, gastos e ingresos, con métricas y avisos antes de cada fecha de pago. No se conecta al banco: todo se captura a mano.

- Datos: Supabase (tablas `fz_*`, ver `supabase/schema.sql`), mismas cuentas que Nutri y Ritmo.
- Avisos: los manda el servidor de Ritmo (`hola-ritmo.vercel.app/api/tick`), gratis.
- Sin IA de pago: costo $0.
