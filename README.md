# pAInting

App iOS (SwiftUI, iOS 26+) para generar pinturas con IA.

## Estructura

- `pAInting/App` – punto de entrada (`@main`).
- `pAInting/Features` – pantallas por funcionalidad: Root (TabView), Onboarding, Create, Gallery, Settings.
- `pAInting/Core` – modelos (SwiftData), servicios (red e IA simulada) y utilidades (ajustes, logger).
- `pAInting/Assets.xcassets` – AppIcon y AccentColor.
- `pAInting/Localizable.xcstrings` – textos en inglés y español.
- `pAIntingTests` – tests unitarios (Swift Testing).
- `pAIntingUITests` – tests de UI (XCTest).

El proyecto usa carpetas sincronizadas (Xcode 16+): los archivos que añadas a las carpetas se incluyen solos en el target.

## Siguientes pasos

1. Ajusta el *Bundle Identifier* (`com.alvaroexposito.pAInting`) y el equipo de firma en Signing & Capabilities.
2. Sustituye `MockImageGenerationService` por una implementación real usando `NetworkClient`.
3. Añade el icono de 1024×1024 en `AppIcon`.
