# Instrucciones de Instalación · Palacio de Memoria XR

Este documento detalla los pasos para instalar y ejecutar el prototipo de **Palacio de Memoria XR** (Hito 2 · v0.2) en un iPhone físico.

---

## 1. Requisitos Previos

- **Dispositivo:** iPhone compatible con ARKit y con **iOS 27.0** o superior, que coincide con el *deployment target* configurado en el proyecto.
- **Hardware AR:** Cámara trasera funcional y soporte de ARKit / RealityKit (detección de superficies horizontales y verticales).
- **Entorno de compilación/transferencia:** Mac con una versión de Xcode compatible con el SDK de iOS 27.
- **Cuenta Apple ID:** Cuenta estándar gratuita (no requiere suscripción pagada al Apple Developer Program).
- **Cable de conexión:** Cable USB-C o Lightning a Mac.

> [!NOTE]
> **Nota sobre la distribución en iOS y ejecución en otro iPhone:**
> A diferencia de plataformas abiertas (como Android con `.apk`), Apple restringe la ejecución de binarios en hardware físico mediante perfiles de aprovisionamiento (`mobileprovision`) asociados a los identificadores únicos (UDID) de los dispositivos registrados en la cuenta de firma. Con una cuenta personal gratuita, la firma es válida por 7 días y solo autoriza los dispositivos vinculados a dicha cuenta.
> Por ello, para que un evaluador o usuario externo pruebe la app en **su propio iPhone**, se ofrecen dos caminos directos detallados a continuación.

---

## 2. Método Recomendado: Compilación y Despliegue en 1 Clic (Vía Xcode)

Este método es el más confiable y universal para probar la app en **cualquier iPhone**, ya que Xcode aprovisiona y firma automáticamente la aplicación para el dispositivo conectado en menos de 1 minuto:

1. **Abrir el proyecto en Xcode:**
   - Abre el archivo `PalacioMemoria.xcodeproj` ubicado en la raíz del repositorio.

2. **Configurar la firma de desarrollo (Firma Gratuita):**
   - En el navegador de proyectos (panel izquierdo), haz clic en el target raíz **PalacioMemoria**.
   - Dirígete a la pestaña **Signing & Capabilities**.
   - En **Team**, selecciona tu Apple ID personal (si no está agregada, agrégala en *Xcode > Settings > Accounts > +*).
   - Xcode generará automáticamente el perfil de aprovisionamiento para tu cuenta.

3. **Conectar y habilitar el iPhone de prueba:**
   - Conecta el iPhone a la Mac mediante el cable USB.
   - En el selector de destinos de ejecución (barra superior de Xcode), selecciona tu iPhone físico.
   - Si es la primera vez que se utiliza este iPhone para desarrollo, verificar que tenga el **Modo Desarrollador** activo:
     - En el iPhone: ve a **Ajustes > Privacidad y seguridad > Modo desarrollador** y actívalo (requiere reiniciar el dispositivo).

4. **Compilar y ejecutar:**
   - Presiona el botón **Play / Run** (o el atajo `Cmd + R`).
   - Xcode compilará `PalacioCore`, las vistas SwiftUI y la escena RealityKit, e instalará la app directamente en el iPhone.

5. **Confiar en el certificado en iOS (primer inicio):**
   - Si al abrir la app aparece el aviso de *Desarrollador no confiable*:
     - En el iPhone, ve a **Ajustes > General > VPN y gestión de dispositivos**.
     - Selecciona tu Apple ID bajo *Apps de desarrollador* y toca **Confiar**.
   - Abre la app **PalacioMemoria** desde la pantalla de inicio.

---

## 3. Método Alternativo: Instalación del Binario Precompilado en `Build/`

En esta carpeta se incluyen los artefactos listos para su distribución y archivo:
- `PalacioMemoria.app` (Bundle de aplicación precompilado)
- `PalacioMemoria.ipa` (Paquete empaquetado para distribución iOS)
- `PalacioMemoria-iOS-v0.2.zip` (Bundle comprimido)

### Opción A · Vía Xcode Devices Window (Dispositivos ya aprovisionados):
1. Abre Xcode y ve a **Window > Devices and Simulators** (`Cmd + Shift + 2`).
2. Selecciona el iPhone conectado en la lista izquierda.
3. En la sección **Installed Apps**, arrastra el archivo `Build/PalacioMemoria.app` o pulsa el botón `+` para seleccionarlo.

### Opción B · Vía Terminal (`devicectl`):
```bash
xcrun devicectl device install app --device <NOMBRE_O_IDENTIFICADOR_DE_TU_IPHONE> Build/PalacioMemoria.app
```

### Opción C · Sideloading en otro iPhone mediante herramientas de terceros:
Si el evaluador desea instalar el paquete sin abrir el código fuente en Xcode, puede utilizar herramientas estándar de carga lateral como **Sideloadly** o **AltStore** cargando el archivo `Build/PalacioMemoria.ipa`, el cual re-firmará la aplicación con su propio Apple ID al vuelo.

---

## 4. Primeros Pasos dentro de la App

1. Al abrir la app, acepta el permiso de acceso a la **Cámara** (requerido para ARKit).
2. Apunta la cámara hacia una superficie plana bien iluminada (mesa, suelo o escritorio).
3. Aparecerá la animación del **ARCoachingOverlay** guiando la calibración.
4. Una vez detectado el plano, toca la pantalla para anclar tu primer término de estudio.
