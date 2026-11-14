
<div align="center">

# 🍎 macOS Tahoe Installer for Linux

Transforma tu escritorio Linux en una experiencia macOS auténtica, elegante y funcional.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GNOME](https://img.shields.io/badge/GNOME-46%20%E2%80%93%2051-orange.svg)](https://www.gnome.org/)
[![Cinnamon](https://img.shields.io/badge/Cinnamon-5.4%20%2B-green.svg)](https://linuxmint.com/)
[![XFCE](https://img.shields.io/badge/XFCE-4.18%20%2B-blue.svg)](https://www.xfce.org/)
[![Bash](https://img.shields.io/badge/Bash-Strict_Mode-black.svg)](https://www.gnu.org/software/bash/)

**Instalación automatizada · Detección del escritorio · Personalización específica para GNOME, Cinnamon y XFCE**

[Instalación](#instalacion) · [Compatibilidad](#compatibilidad) · [Características](#caracteristicas) · [Actualización](#actualizacion) · [Desinstalación](#desinstalacion)

</div>

---

## 📸 Vista previa

<div align="center">

<img src="assets/preview.png" alt="Escritorio Linux con apariencia macOS Tahoe" width="100%"/>

*Transformación visual inspirada en macOS Tahoe: temas, iconos, fuentes, sonidos, fondos de pantalla, paneles y herramientas de productividad.*

</div>

---

## ✨ Características

macOS Tahoe Installer for Linux automatiza la personalización del escritorio Linux mediante instaladores específicos para cada entorno gráfico.

El instalador principal identifica la distribución y el escritorio, valida la combinación detectada y ejecuta el instalador correspondiente.

### Características principales

- 🛡️ **Gestión de errores:** ejecución en modo estricto de Bash y comprobaciones antes de iniciar la instalación.
- 📦 **Dependencias:** instalación de herramientas, bibliotecas y aplicaciones necesarias según el instalador.
- 🔤 **Fuentes:** SF Pro, SF Compact, SF Mono y New York, obtenidas de fuentes externas.
- 🧩 **Liquid Glass:** extensión de GNOME para efectos de transparencia y desenfoque.
- 🌅 **Fondos dinámicos:** fondos inspirados en Mojave y Sonoma, según el escritorio.
- 🎨 **Tema GTK:** MacTahoe GTK con apariencia inspirada en macOS.
- 🖼️ **Iconos:** tema MacTahoe y personalización de iconos.
- 🔊 **Sonidos:** tema de sonidos inspirado en macOS Big Sur.
- 🔍 **Spotlight:** lanzador Rofi personalizado.
- 🚀 **Dock:** integración de Plank y sus temas en los escritorios correspondientes.
- 🖥️ **Plymouth:** pantalla de arranque personalizada.
- 🦊 **Firefox:** personalización visual con identidad de Safari.
- 🎵 **Zuno:** cliente de YouTube Music personalizado como Apple Music.
- 📡 **LocalSend:** transferencia de archivos en red local.
- 📺 **IPTVnator:** reproductor multimedia personalizado como Apple TV.
- 📝 **ONLYOFFICE:** integración visual de Desktop Editors.
- 🔐 **GDM:** personalización de la pantalla de inicio de sesión en GNOME, cuando corresponda.
- 🪟 **Gestión de ventanas:** utilidades para centrar ventanas y administrar aplicaciones.
- ⌨️ **Atajos:** configuraciones de teclado inspiradas en macOS.
- ✏️ **Fontconfig:** ajustes de renderizado tipográfico.
- 💻 **Terminal:** personalización de fuentes y colores.
- 🪔 **Magic Lamp:** efecto de minimización en GNOME y Cinnamon.
- 🎭 **Aplicaciones Qt:** ajustes visuales para aplicaciones compatibles.
- 👁️ **Quick Look:** vista previa de archivos mediante herramientas compatibles con cada entorno.
- 📜 **Configuración del touchpad:** desplazamiento natural y opciones de interacción.
- 👆 **Fusuma:** gestos multitáctiles cuando el hardware y los controladores lo permiten.
- 🍏 **Acerca de este Mac:** información del equipo y acceso a herramientas del proyecto.
- 🌙 **Modo oscuro automático:** programación del cambio de apariencia.
- 📁 **Finder:** personalización del explorador de archivos.

> **Importante:** la disponibilidad de cada característica depende del escritorio, la versión del sistema, las dependencias instaladas y las capacidades del hardware. No todas las funciones están disponibles en los tres entornos.

---

## 🖥️ Compatibilidad

El proyecto contempla las siguientes distribuciones y entornos gráficos:

| Distribución | Escritorio contemplado | Estado |
|---|---|---|
| Ubuntu | GNOME | Compatible según el proyecto |
| Zorin OS | GNOME | Compatible según el proyecto |
| Fedora | GNOME | Compatibilidad declarada; requiere validación del instalador |
| Linux Mint | Cinnamon | Compatible según el proyecto |
| Linux Mint | XFCE | Compatible según el proyecto |
| Debian | GNOME, Cinnamon y XFCE | Compatible según el proyecto |
| Arch Linux | GNOME, Cinnamon y XFCE | Compatibilidad declarada; requiere validación |
| Manjaro | GNOME, Cinnamon y XFCE | Compatibilidad declarada; requiere validación |
| Pop!_OS | GNOME | Compatible según el proyecto |
| openSUSE | GNOME, Cinnamon y XFCE | Soporte experimental; puede requerir ajustes |

### Entornos no admitidos

- KDE Plasma.
- LXQt.
- Otros escritorios que no estén contemplados en la lista de compatibilidad.

El instalador principal no ejecutará un instalador de escritorio si no puede identificar un entorno admitido o si la combinación de distribución y escritorio no está contemplada en su configuración.

> **Nota sobre compatibilidad:** que una distribución aparezca en esta lista no significa que todas sus versiones estén verificadas. La compatibilidad definitiva depende de las pruebas de los instaladores individuales y de sus gestores de paquetes.

---

## 📊 Diferencias entre escritorios

El proyecto utiliza un instalador independiente para cada entorno gráfico.

| Característica | GNOME | Cinnamon | XFCE |
|---|---|---|---|
| Gestor de ventanas | Mutter | Muffin | xfwm4 |
| Magic Lamp | Sí | Sí | No |
| Liquid Glass | Sí | No | No |
| Panel principal | Dash to Dock | Panel nativo personalizado | Panel personalizado |
| Explorador | Nautilus | Nemo | Thunar |
| Terminal | GNOME Terminal | Configuración GTK | XFCE Terminal |
| Pantalla de bloqueo | Nativa de GNOME | Nativa de Cinnamon | light-locker |
| OSD | Extensiones | OSD nativo | Herramientas XFCE |
| Fondo dinámico | Mojave | Extensión Cinnamon | Fondo estático |
| Portapapeles | Clipboard Indicator | Clipit | xfce4-clipman-plugin |
| Luz nocturna | Configuración automática | No configurada explícitamente | No configurada explícitamente |

### Componentes comunes

Los siguientes componentes forman parte de la personalización general del proyecto, aunque su integración puede variar:

- Fuentes y ajustes tipográficos.
- Tema GTK e iconos.
- Sonidos del sistema.
- Aplicaciones personalizadas.
- Herramientas de gestión de ventanas.
- Gestos multitáctiles.
- Plymouth.
- Configuración visual de aplicaciones Qt.
- Utilidades de actualización y personalización.

---

## 📋 Requisitos

Antes de iniciar la instalación, comprueba lo siguiente:

- Una distribución Linux contemplada en la sección de compatibilidad.
- GNOME 46 o superior, Cinnamon 5.4 o superior, o XFCE 4.18 o superior.
- Una sesión gráfica iniciada.
- Conexión a internet.
- Aproximadamente 4 GB de espacio disponible, como estimación.
- Bash.
- `sudo` y permisos de administrador.
- Git para clonar el repositorio.
- Una copia de seguridad de tus configuraciones personales.

### Recomendaciones importantes

1. Cierra las aplicaciones que puedan verse afectadas por la personalización.
2. Guarda tus documentos y trabajos abiertos.
3. Realiza una copia de seguridad de tus configuraciones.
4. Ejecuta el instalador desde tu sesión gráfica habitual.
5. No ejecutes el instalador desde una sesión root independiente.

---

## 🚀 Instalación

### Método recomendado: clonar el repositorio completo

Este método es el recomendado porque el instalador principal necesita acceder a los scripts específicos de cada escritorio.

Clona el repositorio:

```bash
git clone https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux.git
```

Entra al directorio:

```bash
cd Them-macOS-Tahoe-Installer-for-Linux
```

Concede permisos de ejecución:

```bash
chmod +x install.sh
```

Inicia el instalador:

```bash
sudo ./install.sh
```

El instalador realizará las siguientes comprobaciones:

1. Identificará la distribución Linux.
2. Comprobará que la distribución esté contemplada.
3. Identificará el usuario que inició la sesión.
4. Detectará el entorno gráfico.
5. Validará la combinación de distribución y escritorio.
6. Seleccionará el instalador correspondiente.
7. Solicitará confirmación antes de comenzar.
8. Ejecutará el script específico del escritorio.

### Instalación rápida mediante descarga

No descargues únicamente `install.sh` en `/tmp`. El instalador principal necesita tener disponibles `gnome.sh`, `cinnamon.sh` y `xfce.sh` en el mismo directorio.

Para utilizar el método rápido, clona el repositorio completo:

```bash
git clone https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux.git /tmp/macOS-Tahoe-Installer
```

Entra al directorio:

```bash
cd /tmp/macOS-Tahoe-Installer
```

Concede permisos:

```bash
chmod +x install.sh
```

Ejecuta:

```bash
sudo ./install.sh
```

---

## 🧭 Detección automática del escritorio

El instalador principal reconoce los siguientes entornos:

- GNOME.
- Cinnamon.
- XFCE.

La detección prioriza las variables de la sesión gráfica y utiliza procesos del usuario como mecanismo alternativo.

El instalador no debe ejecutarse desde una terminal root independiente, ya que necesita identificar correctamente al usuario original y acceder a su sesión gráfica.

### Instaladores individuales

| Archivo | Entorno |
|---|---|
| `gnome.sh` | GNOME |
| `cinnamon.sh` | Cinnamon |
| `xfce.sh` | XFCE |

No ejecutes los tres instaladores manualmente sobre el mismo escritorio.

---

## 🔄 Actualización

Para obtener las últimas mejoras del proyecto, utiliza el instalador de actualización.

Descarga el actualizador:

```bash
curl -fL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/update.sh -o /tmp/mac-updater.sh
```

Concede permisos:

```bash
chmod +x /tmp/mac-updater.sh
```

Ejecuta:

```bash
sudo /tmp/mac-updater.sh
```

> **Importante:** el actualizador debe comprobar las dependencias, la distribución y el escritorio antes de modificar archivos. Revisa las instrucciones que muestre durante su ejecución.

---

## ⌨️ Atajos de teclado

El proyecto configura atajos inspirados en macOS. La disponibilidad y las combinaciones exactas pueden variar según el escritorio y los atajos existentes.

### Búsqueda y aplicaciones

| Atajo | Acción |
|---|---|
| `Ctrl + Espacio` | Abrir Spotlight |
| `Super + I` | Acerca de este Mac |
| `Super + E` | Abrir el explorador de archivos |
| `Ctrl + Alt + T` | Abrir la terminal |

### Gestión de ventanas

| Atajo | Acción |
|---|---|
| `Super + Q` | Cerrar la aplicación activa |
| `Super + M` | Minimizar la ventana |
| `Super + Flecha arriba` | Maximizar o restaurar |
| `Super + C` | Centrar la ventana |
| `Ctrl + Alt + Esc` | Herramienta de cierre forzoso, si está configurada |

### Áreas de trabajo y sistema

| Atajo | Acción |
|---|---|
| `Super + 1/2/3` | Cambiar de área de trabajo, si está configurado |
| `Ctrl + Alt + ←/→` | Cambiar de área de trabajo |
| `Super + D` | Mostrar u ocultar el escritorio |
| `Super + L` | Bloquear la pantalla |

---

## 🔁 Después de la instalación

Algunos cambios requieren reiniciar componentes de la sesión o el sistema.

| Entorno | Acción recomendada |
|---|---|
| GNOME con Wayland | Cerrar sesión y volver a entrar |
| GNOME con X11 | Seguir las indicaciones del instalador |
| Cinnamon | Seguir las indicaciones del instalador |
| XFCE | Cerrar sesión y volver a entrar si es necesario |
| Todos | Reiniciar el equipo cuando se hayan modificado permisos de grupos o Plymouth |

**Reinicio recomendado:** si el instalador agrega tu usuario al grupo `input` para Fusuma, debes iniciar una nueva sesión o reiniciar el sistema para que se apliquen los nuevos permisos. Para cambios de Plymouth, normalmente también es necesario reiniciar.

---

## 🗑️ Desinstalación

El proyecto incluye un script de desinstalación para revertir las personalizaciones realizadas.

Descarga el script:

```bash
curl -fL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh -o /tmp/mac-uninstaller.sh
```

Concede permisos:

```bash
chmod +x /tmp/mac-uninstaller.sh
```

Ejecuta:

```bash
sudo /tmp/mac-uninstaller.sh
```

### Antes de desinstalar

- Realiza una copia de seguridad de tus archivos personales.
- Comprueba que existan los respaldos creados durante la instalación.
- Lee las confirmaciones que muestre el desinstalador.
- No elimines manualmente los directorios de respaldo antes de completar el proceso.

La restauración depende de los respaldos disponibles y de los cambios que haya realizado el instalador. No debe asumirse que las aplicaciones o configuraciones externas modificadas después de la instalación se restaurarán automáticamente.

---

## 🐛 Solución de problemas

### Los gestos multitáctiles no funcionan

Fusuma necesita que el usuario tenga los permisos adecuados para acceder a los dispositivos de entrada.

Comprueba los grupos:

```bash
groups "$USER"
```

Si el usuario fue agregado al grupo `input`, cierra sesión y vuelve a entrar o reinicia el equipo.

### El fondo dinámico no cambia

Comprueba que la hora del sistema esté sincronizada:

```bash
timedatectl status
```

Si el servicio de sincronización está disponible, puedes habilitarlo con:

```bash
sudo timedatectl set-ntp true
```

### Liquid Glass o Magic Lamp no funcionan

La disponibilidad depende de la versión del escritorio, la extensión y el tipo de sesión.

En GNOME Wayland, cierra sesión y vuelve a entrar después de instalar o modificar extensiones.

### Las fuentes no se aplican

Actualiza la caché:

```bash
fc-cache -fv
```

Comprueba si las fuentes están instaladas:

```bash
fc-list | grep -i "SF Pro"
```

### LocalSend no encuentra otros dispositivos

Comprueba que ambos dispositivos estén en la misma red y que el firewall permita la comunicación.

El puerto habitual de LocalSend es `53317` TCP y UDP. Verifica también que tu router no tenga activada la función de aislamiento entre clientes.

### IPTVnator presenta problemas de reproducción

Comprueba que las dependencias multimedia estén instaladas y que Xwayland esté disponible si tu sesión Wayland necesita compatibilidad con aplicaciones X11.

### El instalador no detecta el escritorio

Comprueba las variables de sesión:

```bash
echo "$XDG_CURRENT_DESKTOP"
echo "$XDG_SESSION_DESKTOP"
echo "$DESKTOP_SESSION"
```

Ejecuta el instalador desde una terminal abierta en tu sesión gráfica normal.

### El instalador indica que la distribución no es compatible

Comprueba la identificación de tu sistema:

```bash
cat /etc/os-release
```

El instalador solo acepta las distribuciones y combinaciones contempladas en su configuración.

---

## 📁 Estructura del proyecto

```text
Them-macOS-Tahoe-Installer-for-Linux/
│
├── install.sh
├── gnome.sh
├── cinnamon.sh
├── xfce.sh
├── update.sh
├── uninstall.sh
│
├── assets/
│   └── preview.png
│
├── README.md
└── LICENSE
```

Los instaladores individuales contienen la personalización específica de cada escritorio. El instalador principal se encarga de validar el entorno y seleccionar el script correspondiente.

---

## 🙏 Créditos

Este proyecto utiliza herramientas, temas y recursos desarrollados por terceros. Se reconoce el trabajo de sus respectivos autores y comunidades.

| Proyecto | Autor o comunidad | Aporte |
|---|---|---|
| [MacTahoe GTK Theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | vinceliuice | Tema GTK |
| [MacTahoe Icon Theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | vinceliuice | Iconos |
| [SFWindows](https://github.com/bradleyhodges/SFWindows) | bradleyhodges | Fuentes |
| [Liquid Glass](https://github.com/ryohsuke1231/liquid-glass) | ryohsuke1231 | Efectos para GNOME |
| [Compiz Alike Magic Lamp](https://github.com/hermes83/compiz-alike-magic-lamp-effect) | hermes83 | Efecto Magic Lamp para GNOME |
| [Cinnamon Magic Lamp](https://github.com/klangman/CinnamonMagicLamp) | klangman | Efecto Magic Lamp para Cinnamon |
| [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | vinceliuice | Fondos de pantalla |
| [Mojave Dynamic Wallpaper](https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave) | japamax | Fondos dinámicos |
| [macOS Big Sur Sound Theme](https://github.com/gxanshu/macos-bigsur-sound-theme-linux) | gxanshu | Sonidos |
| [Rofi Spotlight](https://github.com/eromatiya/rofi-spotlight) | eromatiya | Lanzador |
| [Plank Themes](https://github.com/Macintosh98/MacOS-Mojave-Plank-themes) | Macintosh98 | Temas para Plank |
| [Apple Mac Plymouth](https://github.com/navisjayaseelan/apple-mac-plymouth) | navisjayaseelan | Tema Plymouth |
| [Cinnamon Dynamic Wallpaper](https://github.com/TobiZog/cinnamon-dynamic-wallpaper) | TobiZog | Fondos dinámicos para Cinnamon |
| [Fusuma](https://github.com/iberianpig/fusuma) | iberianpig | Gestos multitáctiles |
| [GNOME Sushi](https://github.com/GNOME/sushi) | GNOME Project | Vista previa de archivos |
| [Zuno](https://github.com/noFAYZ/zuno) | noFAYZ | Cliente de YouTube Music |
| [LocalSend](https://github.com/localsend/localsend) | LocalSend | Transferencia de archivos |
| [IPTVnator](https://github.com/4gray/iptvnator) | 4gray | Reproductor IPTV |
| [ONLYOFFICE](https://github.com/ONLYOFFICE/DesktopEditors) | ONLYOFFICE | Suite ofimática |

---

## ⚖️ Licencia y aviso legal

Este proyecto está distribuido bajo la **Licencia MIT**. Consulta el archivo [LICENSE](LICENSE) para conocer sus términos.

### Marcas y recursos de terceros

macOS, Apple, Safari, Apple Music, Apple TV, Finder, SF Pro, SF Compact, SF Mono y New York son marcas o denominaciones asociadas a Apple Inc.

Este proyecto es independiente y no está afiliado, patrocinado ni respaldado por Apple Inc.

Las fuentes, sonidos, iconos, fondos y demás recursos de terceros conservan sus respectivas condiciones de licencia. El usuario es responsable de comprobar que su uso cumple los términos aplicables.

### Aplicaciones de terceros

Zuno, IPTVnator, LocalSend y ONLYOFFICE son proyectos independientes. Este instalador no proporciona servicios de suscripción, contenido audiovisual ni listas de reproducción de terceros.

El usuario es responsable del contenido y los servicios que utilice mediante estas aplicaciones.

---

## 🤝 Contribuir

Las contribuciones son bienvenidas.

1. Realiza un fork del repositorio.
2. Crea una rama para tu cambio:

   ```bash
   git checkout -b feature/mi-funcionalidad
   ```

3. Realiza tus modificaciones.
4. Guarda los cambios:

   ```bash
   git commit -m "Añade nueva funcionalidad"
   ```

5. Envía la rama:

   ```bash
   git push origin feature/mi-funcionalidad
   ```

6. Abre un Pull Request.

### Reportar problemas

Si encuentras un error, abre un [Issue](https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/issues) e incluye:

- Distribución y versión.
- Entorno de escritorio y versión.
- Tipo de sesión: Wayland o X11.
- Mensaje de error completo.
- Pasos para reproducir el problema.

---

<div align="center">

**Hecho con ❤️ por [AntonSiMal](https://github.com/AntonSiMal) para la comunidad Linux.**

[⬆️ Volver arriba](#macos-tahoe-installer-for-linux)

</div>
