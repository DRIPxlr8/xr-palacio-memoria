# Instalación · Anatomía Canina en RA

**Versión 0.2.6, compilación 8.** [Paquete de desarrollo iOS del Hito 3](AnatomiaCanina-v0.2.6.ipa).

## Requisitos

- iPhone compatible con ARKit y con iOS 27.
- Mac con Xcode 27 para instalar el paquete local. El iPhone debe estar desbloqueado, conectado y en modo desarrollador.
- Dispositivo registrado en el perfil de desarrollo incluido en el paquete. Si se usará otro dispositivo, el equipo debe registrarlo y generar una compilación firmada para ese destino.

## Instalar el paquete

Desde la raíz del repositorio, extrae el paquete, identifica el dispositivo en la lista y usa ese identificador en el comando de instalación.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
anatomia_install_dir="$(mktemp -d)"
ditto -x -k Build/AnatomiaCanina-v0.2.6.ipa "$anatomia_install_dir"
xcrun devicectl list devices
xcrun devicectl device install app --device IDENTIFICADOR_DEL_IPHONE \
  "$anatomia_install_dir/Payload/AnatomiaCanina.app"
```

Una vez instalada, abre **Anatomía Canina** en el iPhone y permite el acceso a la cámara. Pulsa **Abrir cámara**. Para verificar la versión, coloca y confirma Hombro, selecciona una estructura en Estudiar y abre Quiz.

**Verificación de este paquete.** Se comprobó la firma antes y después de extraerlo. El ejecutable extraído se instaló y abrió en el iPhone 16 Pro de prueba. El perfil de desarrollo incluido tiene vigencia hasta el 28 de noviembre de 2026 a las 23:44, hora de Chile.

## Ejecutar desde el código

Abre [el proyecto de Xcode](../AnatomiaCanina/AnatomiaCanina.xcodeproj), selecciona el esquema **AnatomiaCanina** y el dispositivo registrado. Usa la firma automática del equipo y pulsa Run. Para más detalles, consulta [la guía de la app](../AnatomiaCanina/README.md).

El paquete del prototipo anterior está documentado en el [respaldo de Palacio de Memoria](../archivo/PalacioMemoria/Build/INSTALL.md).
