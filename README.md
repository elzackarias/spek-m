# Spek para Apple Silicon (M1, M2, M3, M4...)

Port nativo de [Spek](https://www.spek.cc/) para Macs con chips Apple de la serie M.

Spek es un analizador de espectro acústico escrito en C++. Usa FFmpeg para
decodificar audio y wxWidgets para la interfaz. Sirve, por ejemplo, para
comprobar si un archivo "lossless" es realmente sin pérdida o es un MP3
reconvertido.

## ¿Por qué este port?

La última versión oficial de Spek para macOS (0.8.2) solo existe para Macs
Intel. En Macs Apple Silicon funciona únicamente a través de Rosetta 2, y Apple
ya anunció que Rosetta dejará de estar disponible. Este fork compila Spek de
forma nativa para arm64, así que corre sin Rosetta y más rápido.

## Descarga e instalación

Requisitos: **Mac con Apple Silicon** y **macOS 27.0 o posterior**.

1. Descarga `Spek-0.8.5-arm64.dmg` desde
   [Releases](https://github.com/elzackarias/spek-m/releases).
2. Ábrelo y arrastra Spek a **Aplicaciones**.
3. La app no está notarizada por Apple, así que la primera vez macOS la
   bloquea. Para permitirla:
   - Abre Spek. macOS mostrará un aviso de que no puede verificar la app; pulsa
     **OK**.
   - Ve a **Ajustes del Sistema → Privacidad y seguridad**, baja hasta el
     mensaje sobre Spek, pulsa **Abrir de todos modos** y confirma con tu
     contraseña.

   Solo hace falta una vez. Alternativa por Terminal:

       xattr -dr com.apple.quarantine /Applications/Spek.app

## Qué cambió respecto al original

- **Compilación nativa arm64**, con Homebrew en `/opt/homebrew`. Los scripts
  siguen funcionando en Intel.
- **Compatibilidad con FFmpeg 8 y 9**: la FFT se migró de la API `avfft`
  (eliminada en FFmpeg 8) a `av_tx`.
- **Empaquetado autocontenido**: todas las librerías van dentro de la app, así
  que no hace falta tener Homebrew instalado para usarla.
- **Firma ad-hoc**, obligatoria para ejecutar binarios arm64.
- **Mínimo macOS 27.0**: las librerías cuyos paquetes de Homebrew exigen una
  versión más nueva se recompilan con `dist/osx/build-deps.sh`.
- **Pruebas actualizadas** para FFmpeg 9; pasan las 480.

## Compilar desde el código

Las instrucciones están en [dist/osx/README.md](dist/osx/README.md). En
resumen:

    brew install autoconf automake libtool pkgconf gettext git
    brew install ffmpeg wxwidgets meson ninja cmake nasm
    ./dist/osx/build-deps.sh
    ./dist/osx/bundle.sh

El resultado queda en `dist/osx/Spek.dmg`.

## Créditos y licencia

Spek fue creado por Alexander Kojevnikov y sus colaboradores
([proyecto original](https://github.com/alexkay/spek), [CREDITS.md](CREDITS.md)).
Este fork solo añade el port a Apple Silicon.

Distribuido bajo la licencia GPL v3; consulta [LICENSE](LICENSE).
