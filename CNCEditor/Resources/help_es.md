# CNC Editor 2D — Guía

Aplicación para preparar trabajos 2D para una fresadora CNC: dibuje o abra vectores, calcule las trayectorias de la fresa y guarde el programa NC para su máquina.
- **Weihong / NcStudio**: archivo **.tap**, un husillo.
- **Superstar (4 husillos)**: archivo **.nc**. El número de herramienta es el número de husillo.

## 1. Primeros pasos

### Pantalla de inicio
- **Crear modelo nuevo**: indique el tamaño de la hoja.
- **Abrir modelo**: DXF, SVG o un proyecto .cnc2d.
- **Modelo desde imagen / foto**: una foto de la cámara o de la galería se convierte en fondo.
- **Volver al modelo**: aparece si ya hay un modelo abierto.
- Arriba, la elección de **idioma** (🌐, 17 idiomas). Debajo: **Guía**, **Premium**, **Salir** y enlaces a otras apps de ARESTI Labs y al sitio web.

### Tamaño del modelo nuevo
- **Ancho (X)** y **Alto (Y)**: tamaño de la pieza en bruto. Los botones 1830×2750, 2070×2800, 1220×2440, 2050×3050 ponen hojas estándar.
- **Origen del modelo**: toque una esquina o el centro del esquema. Es el X0 Y0 de la máquina; normalmente la esquina inferior izquierda.
- **Unidades**: mm o pulgadas. Internamente todo se guarda en milímetros.
- **Espesor del material**: se usa para las profundidades.

## 2. Pantalla del editor

- **Barra de menús** (arriba): 🏠 — volver al inicio; luego Archivo, Editar, Modelo, Vectores, Trayectorias, Ayuda. Un elemento con ▸ abre un submenú; «← Atrás» vuelve.
- **Barra de vista** (bajo el menú):
  - ☰ — mostrar u ocultar el panel;
  - todo el modelo, acercar, alejar, cuadrícula;
  - deshacer, rehacer;
  - **Selección**, **Nodos**, **Añadir a la selección**;
  - ⟳ girar pantalla: horizontal → vertical → automático;
  - menú **Seleccionar ▾**, menú de acciones ⋮;
  - contador «Seleccionados: N».
- **Panel** con tres pestañas (abajo en vertical, a la izquierda en horizontal):
  - **Proyecto**: información, capas, consejos de selección, fondo;
  - **Asistente**: todas las herramientas de dibujo y edición; una herramienta abierta muestra aquí sus campos;
  - **Trayectorias**: lista, material, base de herramientas, cálculo y guardado del programa NC.
- **Hoja**: el rectángulo blanco es la pieza. Las marcas roja y verde son los ejes X e Y en el origen.
- La **pista** de abajo dice qué hacer ahora. Si se espera un punto, hay un botón «Cancelar».

Una pulsación larga sobre un icono muestra su nombre. Un icono con esquina ◢ es un grupo: al tocarlo se abre la lista de sus herramientas. La última elegida queda en el botón.

## 3. Gestos en la hoja

- **Un dedo sobre un vector**: seleccionarlo.
- **Arrastrar un vector seleccionado**: moverlo.
- **Tiradores cuadrados en las esquinas**: escalar proporcionalmente.
- **Tirador redondo sobre el marco**: girar de 1° en 1°.
- **Arrastrar en un espacio vacío**: marco de selección.
  - **De izquierda a derecha** (azul, continuo): selecciona los vectores que quedan totalmente dentro.
  - **De derecha a izquierda** (verde, discontinuo): selecciona todos los que el marco toca.
- **Tocar un espacio vacío**: quitar la selección.
- **Dos dedos**: desplazar y hacer zoom.
- **Pulsación larga sobre un vector**: activa la selección múltiple.
  - Cada toque siguiente añade o quita un vector.
  - Los números en círculos rosas muestran el orden. Importa: al alinear, la base es el último seleccionado; al restar, se resta el último.
- **Pulsación larga con vectores seleccionados** (en vacío) abre el menú de acciones.

Los vectores seleccionados se dibujan con una línea rosa gruesa y brillo; los cerrados, además, con un relleno suave.

## 4. Seleccionar varios vectores (en lugar de Mayús)

- Botón **Añadir a la selección**: mientras está activo, cada toque añade o quita; el marco también añade.
- **Pulsación larga sobre un vector** activa el mismo modo temporalmente. Se desactiva con «Añadir a la selección» o «Quitar selección».
- Menú **Seleccionar ▾**: todo; todos en la capa actual; solo cerrados, solo abiertos; tamaño similar (como la primera muestra); invertir selección; quitar selección; lista de seleccionados.
- **Lista de seleccionados** (o toque «Seleccionados: N»): vectores en orden con su tamaño. ✕ quita un vector de la selección.

## 5. Dibujar formas

Pestaña **Asistente** → «Herramientas de vectores». Cada forma se dibuja de dos maneras:
- **Con el dedo**: arrastre en la hoja; los campos muestran las medidas al instante.
- **Con números**: centro, ancho, alto, radios, etc., y pulse «Crear / Listo».

Mientras la forma está recién dibujada, cambiar un campo la modifica en la hoja. «Listo» la fija. «Centro tocando» permite indicar el centro con un toque.

- **Rectángulo**: ancho, alto, radio de esquinas; redondeadas o inversas (cóncavas).
- **Círculo**: centro y radio o diámetro.
- **Elipse**: centro, ancho, alto, ángulo.
- **Polígono**: número de lados, radio, giro.
- **Estrella**: número de puntas, radios exterior e interior.
- **Arco**, tres modos: por tres puntos; centro, inicio y fin; inicio, fin y radio.
- **Polilínea**: toque la hoja — cada toque añade un punto. El siguiente punto puede escribirse con números. «Cerrar» une con el primer punto.

**Editar una forma hecha**: selecciónela y ⋮ → «Editar forma / texto…».

## 6. Nodos

Botón **Nodos**: seleccione un vector y arrastre sus puntos.
- Cuadrados azules = puntos, verde = punto inicial, círculos = puntos de control Bézier.
- **Pulsación larga en un punto**: eliminar, suavizar, hacer inicial, introducir coordenadas.
- **Pulsación larga en un tramo**: convertir en línea, arco o curva Bézier; insertar punto; insertar punto inicial; eliminar el tramo (cortar el vector).

## 7. Editar vectores

Todos los comandos están en el menú **Vectores** y en la sección del Asistente «Posición, combinar, recortar».
- **Transformar**: mover con exactitud, tamaño (proporcional), girar, sesgar; con o sin copia.
- **Espejo**: horizontal o vertical, respecto a su centro o a la hoja.
- **Desfase (offset)**: hacia fuera o dentro una distancia; esquinas vivas o redondeadas.
- **Copia en bloque**: filas y columnas con separación o paso. **Circular**: N copias alrededor de un centro.
- **Alinear**: por bordes y centros respecto al último seleccionado; «Centro de la hoja» — respecto a la pieza.
- **Agrupar / Desagrupar**: un grupo se selecciona y mueve entero.
- **Combinar cerrados**: Weld (unir); Intersección; Restar (se resta el último seleccionado); excluir parte común.
- **Cerrar**: con línea, curva o moviendo el extremo. **Unir dos abiertos**: con línea, curva o moviendo extremos. **Puntos coincidentes**: une muchos trozos en cadenas con tolerancia.
- **Doctor de vectores**: encuentra puntos coincidentes, autointersecciones y bucles y los corrige.
- **Arcos en lugar de curvas**: sustituye las Bézier por arcos y líneas (programa NC más corto, corte más limpio).
- **Redondeo**: toque una esquina y fije el radio. Aquí también: prolongar dos vectores hasta su intersección.
- **Tijeras (recortar)**: tocar un tramo borra su trozo entre intersecciones.
- **Recorte por contorno (Clipping)**: conserva los vectores dentro o fuera del contorno elegido.
- **Seccionar**: corta vectores con una línea en X o Y.
- **Marco alrededor**: rectángulo alrededor de la selección con margen.
- **Convertir**: busca círculos o rectángulos entre los vectores y los convierte en «formas».
- **Invertir dirección**: importante para el orden y el lado del mecanizado.
- **Bloquear**: el vector no se puede mover por accidente.
- **Propiedades**: tamaño, longitud, área, número de puntos, líneas, arcos y curvas.

## 8. Texto

**Texto vectorial**:
- fuente: tipo Arial, Times, Courier, DejaVu o de una línea (para grabado de un solo trazo);
- altura, negrita, cursiva;
- alineación, espaciado de letras y líneas, interletraje;
- estirado, inclinación, giro;
- posición X/Y.

«Crear» añade el texto a la hoja. Después puede seleccionarlo y cambiarlo con ⋮ → «Editar forma / texto».

**Texto sobre curva**: elija una curva o círculo, abra «Texto sobre curva», fije el inicio, la separación y el lado. Las letras giran siguiendo la curva.

## 9. Envolvente y «Pegar a lo largo de curva»

- **Envolvente**: elija un dibujo o motivo y abra «Envolvente». Aparece un marco con nodos. Arrastre esquinas y puntos medios de los lados. O pulse «Curva superior…» / «Curva inferior…» y toque una curva existente (p. ej. un arco). «Aplicar» deforma el dibujo: así un motivo encaja en un arco o una onda.
- **Pegar a lo largo de curva**: copias del dibujo seleccionado se reparten por una curva — por cantidad o por paso, girando con la curva o no.

## 10. Placas y anidado

- **Multi-Plate**: una plantilla de placa (contorno + texto) se repite en la hoja con las líneas de un archivo de texto. Por ejemplo números de piso o nombres: una línea, una placa.
- **Anidado (Nesting)**: las piezas elegidas se colocan en hojas de tamaño dado con separación y margen. Se puede permitir el giro. Los agujeros se quedan con su pieza automáticamente.

## 11. Imágenes y fotos

- Menú **Archivo → Importar imagen / foto** o icono «Imagen». Origen: **galería** o **cámara**. La imagen se vuelve un **fondo** semitransparente.
- **Ajustes del fondo**: opacidad, mostrar, bloquear. El tamaño con números o **por dos puntos**: toque dos puntos de distancia conocida e introduzca la distancia real.
- **Calcar a mano**: dibuje con polilínea y formas sobre el fondo.
- **Vectorización** (icono «Vectorizar»):
  1. Elija modo: blanco y negro (silueta por umbral) o contornos.
  2. Ajuste umbral de brillo (o «auto»), suavizado, eliminación de manchas, invertir.
  3. «Vista previa» muestra los futuros vectores sobre la imagen.
  4. «Crear vectores» los añade al modelo.
- **Corregir perspectiva**: si la hoja se fotografió en ángulo, toque las cuatro esquinas e introduzca el tamaño real. La foto queda recta y a escala 1:1.
- **Puentes de plantilla**: pequeñas uniones para que no caigan las partes interiores de letras y piezas.

## 12. Trayectorias (mecanizado)

Pasos:
1. **Material** (pestaña Trayectorias → icono de material): espesor, Z segura, punto de reposo (adonde va la máquina al final).
2. **Base de herramientas**: fresas con número, diámetro, ángulo (fresas V), paso vertical y lateral, revoluciones, avance y velocidad de penetración. Avance en mm/s o mm/min. Puede añadir, copiar, editar y eliminar; la base se guarda en el teléfono.
3. **Seleccione vectores** en la hoja y pulse el tipo de mecanizado.

### Tipos de mecanizado
- **Perfil**: corte por fuera o por dentro del contorno (con el radio de la fresa) o sobre la línea. Ajustes: profundidad inicial y final; sobremedida; dirección (concordancia o oposición); orden.
- **Puentes (sujeciones)**: las piezas no se sueltan al cortar. Automáticos (por cantidad o distancia) o manuales tocando el contorno. Se fijan longitud y altura.
- **Penetración en rampa**: la fresa entra inclinada, no vertical — menos carga y marcas.
- **A lo largo de vectores**: la fresa va justo sobre la línea. Para grabado, ranuras, texto de una línea.
- **Vaciado de área**: bolsillo dentro de un contorno. Pasadas por desfase (siguiendo el contorno) o ráster (zigzag), con solapamiento elegido.
- **Grabado en V**: fresa en V; la profundidad sigue el ancho de la línea y da letras y motivos «tallados».
- **Taladrado**: agujeros en los centros de círculos, con picado (paso de picado).

En la sección «Herramienta», pulse **Elegir…** para tomar una fresa de la base. **Calcular** crea la trayectoria. Debajo se ven la longitud de corte, el número de penetraciones y el tiempo estimado.

Lista de trayectorias: tocar selecciona la trayectoria y sus vectores; casilla — mostrar/ocultar; «Cambiar…» — parámetros; «Recalcular» — tras cambiar vectores; «Eliminar».

### Simulación
Icono «Simulación»: vista superior de cómo avanza la fresa por el material. Iniciar/pausa, velocidad, «Resultado» (todo de golpe), «Desde el inicio». Útil para revisar puentes, esquinas interiores y huecos.

### Guardar el programa NC
**Trayectorias → Guardar trayectorias como…**:
1. Marque las trayectorias.
2. Elija el postprocesador: **Weihong (.tap)** para NcStudio; **Superstar (.nc)** de 4 husillos, número de fresa 1–4 = número de husillo; **su propio .con** — «Cargar su propio .con…», el archivo del postprocesador de su máquina (formato ArtCAM). Se recuerda.
3. Indique el nombre. «Vista previa» muestra el inicio del programa. «Guardar» — elija carpeta (p. ej. memoria USB).

**Gratis** se puede guardar 1 programa para la máquina al día. **Premium** (compra única) quita el límite y los anuncios.

**Consejo:** antes del primer corte compruebe el cero y la Z en la máquina y pruebe el programa «en el aire» (con la Z subida).

## 13. Guardar y exportar

- **Guardar (DXF)**: un DXF R12 normal se abre en cualquier programa CAD/CAM. Dentro se guarda de forma invisible todo el proyecto: capas, trayectorias, fresas, fondo. Al abrirlo aquí se recupera todo.
- **Guardar como**: DXF; SVG (las capas se abren como capas en Inkscape); proyecto .cnc2d.
- **Exportar**: PDF 1:1 (para imprimir una plantilla); PNG o JPG con la resolución elegida; PNG también con fondo transparente.
- **Importar vectores**: añada vectores de otro DXF o SVG al modelo actual.
- Los DXF con la antigua codificación Windows-1251 (cirílico de ArtCAM/AutoCAD) se abren correctamente.

## 14. Capas

Pestaña **Proyecto** → Capas, o **Editar → Capas…**: añadir capa; renombrar ✎; color; mostrar/ocultar 👁; bloquear 🔒; eliminar ✕.

Los vectores nuevos van a la capa **activa** (resaltada). «Mover» lleva los vectores seleccionados a la capa activa.

## 15. Deshacer y botón Atrás

- **Deshacer / Rehacer**: hasta 80 pasos.
- El botón **Atrás** del sistema, por orden: cancela la elección de punto; cierra la herramienta abierta; cierra una ventana; vuelve al inicio (pregunta si el modelo no está guardado).

## 16. Importar código G (.tap, .nc)

La app abre un programa de máquina ya hecho (.tap, .nc, .ngc, .gcode, etc.) y recupera de él el dibujo.
- Abra el archivo: **Abrir modelo** en la pantalla de inicio (modelo nuevo) o **Archivo → Importar vectores…** (añadir al actual).
- **Compensación de fresa**: el programa guarda la trayectoria del centro de la fresa.
  - «Ninguna» — vectores por el centro de la fresa (para grabado y mecanizado a lo largo de vectores);
  - «Auto» — las piezas se desplazan hacia dentro y los agujeros hacia fuera el radio de la fresa;
  - «Todos hacia dentro» / «Todos hacia fuera». Indique el diámetro de la fresa.
- **Unir pasadas de profundidad** — varias pasadas a distinta profundidad se convierten en un contorno.
- **Cada herramienta en su capa** — capas T1, T2… si el programa usa varias fresas.
- Luego guarde el dibujo: **Archivo → Guardar (DXF)**, edítelo o calcule nuevas trayectorias.

## 17. Preguntas frecuentes

- **No se calcula la trayectoria:** el perfil fuera/dentro y el vaciado necesitan vectores **cerrados** — use «Doctor de vectores» o «Unir puntos coincidentes»; la fresa puede ser más ancha que el bolsillo.
- **La pieza se corta por el lado equivocado:** revise fuera/dentro y la dirección del vector («Invertir dirección»).
- **Las letras se caen al cortar una plantilla:** use «Puentes de plantilla» o los puentes del perfil.
- **La máquina «se desplaza»:** revise el origen del modelo (Modelo → Posición del cero) y el punto de reposo en Material.
- **Es difícil tocar vectores pequeños:** acerque con dos dedos o use un marco de derecha a izquierda.
