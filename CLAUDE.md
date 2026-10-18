# pAInting – contexto del proyecto

App iOS para uso infantil que permita que un niño pueda seleccionar, de un conjunto de temas que se le proponga los que le llamen más la atención y pueda colorear con el dedo las imágenes que más le llamen la atención.

## Stack
- Swift + SwiftUI, SwiftData para persistencia, Swift Testing / XCTest.
- **Mínimo: iOS 26.0** (`IPHONEOS_DEPLOYMENT_TARGET`). Requiere Xcode 26 o superior.
- **IA en el dispositivo con el framework Foundation Models de Apple** (`import FoundationModels`):
  - Modelo de lenguaje on-device de Apple Intelligence; funciona sin conexión y sin enviar datos a servidores.
  - Solo disponible en dispositivos compatibles con Apple Intelligence y con ésta activada. Comprobar siempre `SystemLanguageModel.default.availability` y ofrecer una alternativa si no está disponible.
  - Se usa mediante `LanguageModelSession`; para salidas estructuradas, `@Generable` y `@Guide`.
  - Genera **texto**, no imágenes: usarlo para mejorar/expandir prompts, sugerir títulos y estilos, etc. La generación de imagen sigue detrás de `ImageGenerationService` (hoy `MockImageGenerationService`).

## Arquitectura
- Arquitectura de la aplicación MVVM.
- `pAInting/App` – punto de entrada.
- `pAInting/Features/<Feature>` – una carpeta por pantalla/funcionalidad (Root, Onboarding, Create, Gallery, Settings).
- `pAInting/Core/Models` – modelos SwiftData (`Artwork`).
- `pAInting/Core/Services` – servicios detrás de protocolos (`ImageGenerationService`, `NetworkClient`). Futuro servicio de prompts con Foundation Models: `PromptAssistantService`.
- `pAInting/Core/Utilities` – ajustes (`AppSettings`), logger (`Logger.app/.network/.persistence`).
- Carpetas sincronizadas de Xcode: los archivos nuevos se añaden solos al target; no editar `project.pbxproj` a mano salvo para ajustes de build.

## Convenciones
- Textos de UI en `Localizable.xcstrings` (en + es); no usar strings sueltos sin localizar.
- Servicios inyectables y con implementación simulada para previews y tests.
- Usar `Logger` (OSLog), no `print`.
- Añadir `accessibilityIdentifier` a los controles usados en tests de UI.
- Tests unitarios en `pAIntingTests`, de UI en `pAIntingUITests`.


## Desarrollo
- Por cada nueva implementación, crear una rama a parte para realizarla y realizar un PR a la rama principal. Facilitar por consola la URL de acceso al PR