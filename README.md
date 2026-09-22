# Vargas SPA Construcciones

Primera versión Flutter Web: portada responsive, administración de cotizaciones con ítems, cálculo de IVA y PDF imprimible con el logo proporcionado.

## Ejecutar

1. Instala Flutter estable y habilita web (`flutter config --enable-web`).
2. En esta carpeta ejecuta `flutter create . --platforms web` para generar los archivos de plataforma.
3. Ejecuta `flutter pub get` y `flutter run -d chrome`.

## Alcance actual

Las cotizaciones se guardan en el almacenamiento **local del navegador**. No hay inicio de sesión ni sincronización entre dispositivos; el botón de administración sirve para probar el flujo y **no debe publicarse así**. El botón público de contacto es una maqueta pendiente de datos de contacto reales. Para producción, el siguiente paso es conectar Supabase Authentication y PostgreSQL con políticas RLS, configurar los datos legales/comerciales de Vargas SPA, y después publicar.

Los precios se ingresan en pesos chilenos enteros; se calcula IVA de 19%. No hay descuentos ni vigencia configurables todavía. El PDF usa los datos disponibles y está preparado para impresión en A4.
