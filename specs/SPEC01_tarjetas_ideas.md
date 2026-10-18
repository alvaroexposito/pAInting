# Spec SPEC01_tarjetas_ideas

# Contexto y objetivo

Quiero que el usuario, cuando se abra la aplicación se le muestre un listado de tarjetas rectangulares de imágenes. El usuario pulse una de ellas y en ese punto se genere la imagen que vamos a dibujar posteriormente.

# Usuarios / actores

Niños pequeños que no tienen por que saber escribir y que quieren dibujar.

# Historias de usuario

RF-1: Cuando se abra la aplicación, el sistema mostrará 6 animales elegidos al azar de un catálogo con más de 6 animales (p.e. Perro, Gato, mariposa, etc...), sin repetir ninguno dentro de la tanda.
RF-2: Mientras se muestren las tarjetas de animales, cada tarjeta mostrará un emoji grande que represente al animal, sin ningún texto visible; el nombre del animal solo estará disponible para VoiceOver.
RF-3: Cuando el usuario seleccione uno de los 6 animales, el sistema mostrará 6 prendas de ropa elegidas al azar de un catálogo con más de 6 prendas (p.e. Vestido, Chubasquero, etc...), sin repetir ninguna dentro de la tanda.
RF-4: Mientras se muestren las tarjetas de prendas de ropa, cada tarjeta mostrará un emoji grande que represente la prenda, sin ningún texto visible; el nombre solo estará disponible para VoiceOver.
RF-5: Cuando el usuario seleccione una de las 6 prendas, el sistema mostrará 6 accesorios elegidos al azar de un catálogo con más de 6 accesorios (p.e. Paraguas, Sombrero, etc...), sin repetir ninguno dentro de la tanda.
RF-6: Mientras se muestren las tarjetas de accesorios, cada tarjeta mostrará un emoji grande que represente el accesorio, sin ningún texto visible; el nombre solo estará disponible para VoiceOver.
RF-7: Cuando el usuario seleccione el accesorio, el sistema generará con las 3 ideas seleccionadas el prompt que solicitará la generación de la imagen que luego dibujaremos.
RF-8: Cuando el prompt esté generado, el sistema solicitará la generación de la imagen sin que el usuario tenga que escribir texto. Si el dispositivo admite Image Playground, la hoja del sistema se abrirá con el prompt ya rellenado y bastará con elegir una imagen.
RF-9: Cuando la imagen esté generada, el sistema abrirá la pantalla de colorear con esa imagen.

# Requisitos no funcionales

- Las tandas de 6 se eligen al azar en cada apertura; no se garantiza que dos aperturas seguidas muestren tandas distintas.

# Casos límite

CL-1: Mientras haya al menos una idea seleccionada y no se haya completado la selección, el sistema ofrecerá un botón con icono para deshacer la última elección; al pulsarlo, mostrará una tanda nueva de esa categoría.
CL-2: Cuando estén seleccionadas las 3 ideas, el sistema ofrecerá un botón con icono para empezar de nuevo; al pulsarlo, borrará las 3 elecciones y volverá a mostrar 6 animales.
CL-3: Si falla la generación de la imagen, el sistema avisará con un icono, sin texto, y ofrecerá un botón con icono para reintentar sin perder las 3 elecciones.
CL-4: Si Apple Intelligence no está disponible, el sistema construirá el prompt con una plantilla fija y generará la imagen con el generador alternativo (silueta simulada).
CL-5: Cuando se abra la aplicación por primera vez, al terminar el onboarding el sistema mostrará directamente las tarjetas de animales.

# Fuera de alcance

Solo se generan las tarjetas y se pasa al estado de generación de la imagen.

# Criterios de finalización

- Desde la apertura de la app, el usuario llega a la pantalla de colorear con una imagen generada pulsando solo tarjetas, sin introducir texto (RF-1 a RF-9).
- Cada RF y CL tiene al menos un test automático que lo cubre y la suite completa pasa.
