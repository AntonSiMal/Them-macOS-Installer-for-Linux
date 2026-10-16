<div align="center">

# 🍎 macOS Tahoe Installer for Linux

### Transforma tu escritorio Linux en una experiencia macOS auténtica, robusta e inteligente

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Safe Rollback](https://img.shields.io/badge/Safety-Auto_Rollback-green.svg)](https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux)
[![GNOME](https://img.shields.io/badge/GNOME-46%20%E2%80%93%2051-orange.svg)](https://www.gnome.org/)
[![Cinnamon](https://img.shields.io/badge/Cinnamon-5.4%20%2B-green.svg)](https://linuxmint.com/)
[![XFCE](https://img.shields.io/badge/XFCE-4.18%20%2B-blue.svg)](https://www.xfce.org/)
[![Bash](https://img.shields.io/badge/Bash-Strict_Mode-black.svg)](https://www.gnu.org/software/bash/)

**Instalación 100% automatizada · Detección inteligente de entorno · Compatible con GNOME, Cinnamon y XFCE**

[Instalación rápida](#-instalación-rápida) · [Actualización](#-actualización) · [Características](#-qué-hace-este-script) · [Atajos](#-atajos-de-teclado) · [Desinstalación](#-desinstalación)

</div>

---

## 📸 Vista previa

<div align="center">
  <img src="assets/preview.png" alt="macOS Tahoe en Linux" width="100%"/>
  <p><em>Escritorio Linux transformado con el tema macOS Tahoe, fuentes oficiales Apple, sonidos, wallpapers dinámicos, efecto Magic Lamp, panel superior estilo macOS y lanzador Spotlight.</em></p>
</div>

---

## ✨ ¿Qué hace este script?

Este script **automatiza por completo** la transformación de tu escritorio Linux. Gracias a su arquitectura robusta, detecta tu entorno de escritorio y aplica *solo* las configuraciones necesarias, optimizando el tiempo y evitando conflictos. Incluye un **mecanismo de rollback automático** que protege tu sistema en caso de errores.

| # | Componente | Descripción |
|---|------------|-------------|
| 🛡️ | **Rollback Automático** | Si la instalación falla, el sistema se restaura automáticamente a su estado original. |
| 📦 | **Dependencias del sistema** | Instala automáticamente todas las herramientas, codecs y librerías necesarios. |
| 🔤 | **Fuentes Apple oficiales** | SF Pro, SF Compact, SF Mono, New York (WWDC26 v27.0). |
| 🧩 | **Liquid Glass** | Extensión GNOME para efecto cristal líquido (solo GNOME). |
| 🌅 | **Dynamic Wallpaper** | Fondos dinámicos Mojave/Sonoma que cambian con la hora real del sistema. |
| 🎨 | **Tema MacTahoe GTK** | Tema visual estilo macOS con ventanas redondeadas y modo oscuro/claro. |
| 🖼️ | **Iconos MacTahoe** | Iconos oficiales estilo macOS (versión bold automática para pantallas 4K). |
| 🔊 | **Sonidos macOS Big Sur** | 44 eventos de sonido, incluyendo el *Startup Chime* al iniciar sesión. |
| 🔍 | **Rofi Spotlight** | Lanzador estilo macOS con búsqueda global de archivos y web. |
| 🚀 | **Temas de Plank** | Dock estilo macOS inferior con ocultamiento inteligente (XFCE/Cinnamon). |
| 🖥️ | **Plymouth** | Pantalla de arranque con logo Apple. |
| 🦊 | **Navegador Safari** | Firefox personalizado con el nombre e icono oficial de Safari. |
| 🎵 | **Apple Music (Zuno)** | Cliente nativo de YouTube Music con codecs GStreamer preconfigurados. |
| 📡 | **LocalSend** | Alternativa open-source a AirDrop, con configuración automática del firewall (UFW). |
| 📺 | **Apple TV (IPTVnator)** | Reproductor IPTV con lista de canales en español y guía EPG preconfigurada. |
| 📝 | **Suite Office** | ONLYOFFICE Desktop Editors (Flatpak) renombrado visualmente como "Office". |
| 🔐 | **GDM (solo GNOME)** | Pantalla de login estilo macOS. |
| 🪟 | **Gestión de ventanas** | Scripts nativos para opacidad, centrado y cierre forzoso de procesos. |
| ⌨️ | **Atajos macOS** | 50+ atajos de teclado configurados automáticamente sin sobrescribir los tuyos. |
| ✏️ | **Renderizado de fuentes** | Optimización Fontconfig para que SF Pro se vea nítida y perfecta. |
| 💻 | **Terminal estilo macOS** | Perfil con SF Mono, colores auténticos y cursor I-Beam. |
| 🪔 | **Magic Lamp Effect** | Efecto "Genio" al minimizar ventanas (GNOME y Cinnamon). |
| 🎭 | **Tematización Qt** | VLC, OBS y apps Qt coinciden perfectamente con el tema GTK. |
| 👁️ | **Quick Look** | Vista previa de archivos con la barra espaciadora (Sushi/Gloobus). |
| 📜 | **Scroll Natural** | Desplazamiento invertido y "tap-to-click" activados a nivel de sistema. |
| 👆 | **Gestos Fusuma** | Deslizar con 3/4 dedos para espacios, zoom y arrastre. |
| 🍏 | **Acerca de este Mac** | Ventana real con specs del sistema y botón de *Actualización* funcional. |
| 💻 | **Identidad del Equipo** | Cambia el hostname a "MacBook-Pro", "MacBook-Air" o "MacBook-Neo". |
| 🌙 | **Modo Oscuro Automático** | Cambia entre tema claro y oscuro según la hora del día (6:00 - 18:00) vía systemd. |
| 📁 | **Sidebar estilo Finder** | Carpetas Desktop, Downloads, Documents, etc., en el explorador. |

---

## 🖥️ Compatibilidad

| Distro / Entorno | Estado | Notas |
|------------------|:------:|-------|
| **Ubuntu** (GNOME) | ✅ | Soporte completo |
| **Zorin OS** | ✅ | Soporte completo |
| **Fedora** (GNOME) | ✅ | Soporte completo |
| **Linux Mint** (Cinnamon) | ✅ | Soporte completo |
| **Linux Mint** (XFCE) | ✅ | Soporte completo |
| **Debian** (GNOME/Cinnamon/XFCE) | ✅ | Soporte completo |
| **Arch Linux / Manjaro** | ✅ | Soporte completo |
| **Pop!_OS** | ✅ | Soporte completo |
| **openSUSE** | ⚠️ | Requiere ajustes menores |
| **KDE Plasma** | ❌ | No soportado (usa su propio sistema de temas) |

---

## 📊 Comparativa por Entorno de Escritorio

Este script adapta inteligentemente la instalación según tu entorno. Aquí tienes un desglose de qué componentes y comportamientos específicos se aplican a cada uno:

| Categoría / Característica | 🟠 GNOME (incl. Zorin) | 🟢 Cinnamon (Linux Mint) | 🔵 XFCE |
| :--- | :--- | :--- | :--- |
| **Gestor de Ventanas y Efectos** | Mutter. Animaciones suaves y centrado nativo. | Muffin. Efectos personalizados aplicados. | xfwm4. Composición (`use_compositing`) forzada. |
| **Efecto "Magic Lamp"** | ✅ Sí (Extensión *Compiz Alike*). | ✅ Sí (Extensión *Cinnamon Magic Lamp*). | ❌ No (Limitaciones técnicas de xfwm4). |
| **Efecto "Liquid Glass" (Blur)** | ✅ Sí (Extensión *Liquid Glass*). | ❌ No. | ❌ No. |
| **Panel / Dock Principal** | **Dash to Dock** (abajo, auto-ocultable, opacidad dinámica). | **Panel Superior Nativo** (reconfigurado a 28px, applets específicos). | **Panel Superior Reconstruido** (28px, Whisker Menu, reloj macOS). |
| **Menú de Inicio** | Botón "Mostrar aplicaciones" de Dash to Dock. | Applet de menú nativo con icono `distributor-logo`. | **Whisker Menu** (se instala si falta) con icono de Apple. |
| **Explorador de Archivos** | **Nautilus**. CSS personalizado para emular sidebar de Finder. | **Nemo**. Vista de iconos, archivos ocultos desactivados. | **Thunar**. Doble clic para abrir, archivos ocultos desactivados. |
| **Terminal** | **GNOME Terminal**. Perfil nuevo "macOS Tahoe" (SF Mono, colores). | Configuración genérica de fuentes GTK. | **XFCE Terminal**. `terminalrc` sobrescrito con SF Mono y colores. |
| **Pantalla de Bloqueo** | Nativa de GNOME (wallpaper dinámico, reloj grande). | Nativa de Cinnamon (wallpaper y zoom). | Instala y configura **`light-locker`** (más ligero y estable). |
| **Indicadores OSD** | Extensión **Avatar** (OSD minimalista estilo macOS). | OSD nativo de Cinnamon habilitado. | **`xfce4-volumed-pulse`** + `xfce4-notifyd` (esquina superior derecha). |
| **Fondo Dinámico** | **Mojave Solar/Timed** (nativo vía `gsettings` y XML). | **Cinnamon Dynamic Wallpaper** (extensión). | Fondo estático **Sonoma Dark** (sin soporte XML nativo sencillo). |
| **Gestor de Portapapeles** | Extensión **Clipboard Indicator**. | **Clipit** (se sugiere iniciar desde el menú). | **xfce4-clipman-plugin** (pre-instalado, añadir al panel). |
| **Night Shift / Luz Nocturna** | ✅ Sí (Automático, 2700K). | ❌ No configurado explícitamente. | ❌ No configurado explícitamente. |

### 🌍 Componentes Universales (Se instalan en los 3 entornos)
- **Fuentes:** SF Pro, SF Compact, New York y SF Mono (con optimización `fontconfig`).
- **Temas Visuales:** MacTahoe-Dark (GTK), Iconos y Cursores a 32px.
- **Sonidos:** Tema "Big Sur" completo (incluye *Startup Chime* en autostart).
- **Transformación de Apps:** Firefox → "Safari", Zuno → "Apple Music", IPTVnator → "Apple TV", ONLYOFFICE → "Office", Gestor de archivos → "Finder", LocalSend (con regla UFW).
- **Scripts de Utilidad:** `macos-wm-actions` (centrar, forzar cierre), `about-this-mac.sh` (specs reales + botón de actualización), `auto-dark-mode.sh` (cambio claro/oscuro vía systemd).
- **Gestos Multitáctiles:** **Fusuma** (gestos de 3 y 4 dedos) + adición automática al grupo `input`.
- **Pantalla de Arranque:** Tema **Plymouth** "Apple Mac".
- **Aplicaciones Qt:** Configuración de `qt5ct` para que apps como VLC u OBS usen el tema GTK.

---

## 📋 Requisitos

- **Sistema operativo:** Linux con GNOME 46+, Cinnamon 5.4+ o XFCE 4.18+
- **Conexión a internet:** Para descargar repositorios, dependencias y aplicaciones (incluyendo Flatpak)
- **Espacio en disco:** ~4 GB (incluyendo entorno Flatpak, ONLYOFFICE, wallpapers, fuentes, sonidos y apps)
- **Permisos de `sudo`:** Para instalar dependencias, configurar el firewall y Plymouth/GDM

---

## 🚀 Instalación rápida

> ⚠️ **Importante:** No uses `sudo curl ... | bash`. Usa el método seguro de una línea o el manual para evitar problemas de permisos y variables de entorno.

### Método recomendado (una sola línea segura)

```bash
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/install.sh -o /tmp/mac-installer.sh && chmod +x /tmp/mac-installer.sh && sudo /tmp/mac-installer.sh
```

### Método manual (El más seguro)

```bash
# 1. Clonar el repositorio
git clone https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux.git
cd Them-macOS-Tahoe-Installer-for-Linux

# 2. Dar permisos de ejecución
chmod +x install.sh

# 3. Ejecutar el script con sudo
sudo ./install.sh
```

### Después de la instalación

| Entorno | Acción requerida |
|---------|------------------|
| **GNOME (Wayland)** | Cierra sesión y vuelve a entrar para activar extensiones y sonidos |
| **GNOME (X11)** | El script reinicia GNOME Shell automáticamente |
| **Cinnamon** | El script reinicia Cinnamon automáticamente |
| **XFCE** | Cierra sesión y vuelve a entrar para aplicar el cursor, panel y atajos |
| **Todos** | **REINICIO OBLIGATORIO** para activar los permisos del grupo `input` (Gestos Fusuma) y Plymouth. |

---

## 🔄 Actualización

¿Ya instalaste el tema y quieres obtener las últimas mejoras? El script de actualización inteligente detecta qué componentes han cambiado en GitHub y solo actualiza esos. Además, **verifica y repara automáticamente** las personalizaciones de Safari, Apple Music, LocalSend, Apple TV y Office por si una actualización del sistema las hubiera sobrescrito.

```bash
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/update.sh -o /tmp/mac-updater.sh && chmod +x /tmp/mac-updater.sh && sudo /tmp/mac-updater.sh
```

---

## ⌨️ Atajos de teclado

El script configura **50+ atajos de teclado** estilo macOS. Aquí los principales:

### 🔍 Búsqueda y aplicaciones
| Atajo | Acción |
|-------|--------|
| `Ctrl + Espacio` | Abrir **Spotlight** (búsqueda global de archivos y web) |
| `Súper + I` | Abrir **"Acerca de este Mac"** (incluye botón de Actualización real) |
| `Súper + E` | Abrir Explorador de Archivos (Finder) |
| `Ctrl + Alt + T` | Abrir Terminal |

### 🪟 Gestión de ventanas
| Atajo | Acción |
|-------|--------|
| `Súper + Q` | Cerrar aplicación activa **y sus procesos en segundo plano** |
| `Súper + M` | Minimizar ventana (con efecto Magic Lamp si está disponible) |
| `Súper + Flecha Arriba` | Maximizar / Restaurar |
| `Súper + C` | Centrar ventana en la pantalla |
| `Ctrl + Alt + Esc` | Forzar cierre de app congelada (xkill) |

### 🏢 Áreas de trabajo y Sistema
| Atajo | Acción |
|-------|--------|
| `Súper + 1/2/3` | Ir al área de trabajo 1, 2 o 3 |
| `Ctrl + Alt + ←/→` | Cambiar entre áreas de trabajo |
| `Súper + D` | Mostrar / Ocultar escritorio |
| `Súper + L` | Bloquear pantalla |

---

## 🗑️ Desinstalación

Para revertir **todos** los cambios de forma segura y restaurar tu sistema a su estado original (incluyendo el nombre del equipo, el tamaño del cursor, las reglas del firewall, las apps Flatpak y las personalizaciones de aplicaciones), utiliza el script de desinstalación:

```bash
# Método seguro recomendado:
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh -o /tmp/mac-uninstaller.sh && chmod +x /tmp/mac-uninstaller.sh && sudo /tmp/mac-uninstaller.sh
```
*Este script elimina archivos, restaura configuraciones de `gsettings`/`xfconf`, desactiva extensiones, revierte el hostname, limpia el firewall, elimina ONLYOFFICE y restaura los lanzadores originales de Firefox y otras aplicaciones.*

---

## 🐛 Solución de problemas

<details>
<summary><strong>Los gestos multitáctiles (Fusuma) no funcionan</strong></summary>
El script añade automáticamente tu usuario al grupo <code>input</code> para leer el touchpad. Este cambio <strong>requiere un reinicio completo del sistema</strong> (no solo cerrar sesión) para surtir efecto. Verifica con: <code>groups $USER</code>
</details>

<details>
<summary><strong>El wallpaper dinámico no cambia</strong></summary>
Verifica que el reloj del sistema esté sincronizado con la red:
<code>sudo timedatectl set-ntp true</code>
</details>

<details>
<summary><strong>Liquid Glass o Magic Lamp no se activan en Wayland</strong></summary>
En Wayland, las extensiones de GNOME Shell requieren cerrar sesión y volver a entrar para cargarse correctamente:
<code>gnome-session-quit --logout</code>
</details>

<details>
<summary><strong>Las fuentes Apple no se ven nítidas o no se aplican</strong></summary>
Actualiza la caché de fuentes del sistema y verifica que estén instaladas:
<code>fc-cache -fv && fc-list | grep -i "SF Pro"</code>
</details>

<details>
<summary><strong>LocalSend no descubre dispositivos en la red</strong></summary>
El script configura UFW automáticamente. Si usas un firewall de terceros o una red pública, asegúrate de que el puerto <strong>53317 (TCP/UDP)</strong> esté abierto y que la "Aislación AP" (AP Isolation) esté desactivada en tu router.
</details>

<details>
<summary><strong>Apple TV (IPTVnator) muestra pantalla gris o no reproduce</strong></summary>
El script aplica parches automáticos (<code>--no-sandbox</code> y <code>--ozone-platform=x11</code>) e instala <code>mpv</code>. Si el problema persiste en Wayland con Nvidia, asegúrate de que Xwayland esté instalado en tu sistema.
</details>

<details>
<summary><strong>El botón "Actualización de software" no hace nada</strong></summary>
Asegúrate de tener instalado <code>zenity</code> (el script lo instala). Abrirá una terminal para ejecutar <code>apt/dnf/pacman upgrade</code>. Necesitarás ingresar tu contraseña de sudo en esa terminal.
</details>

---

## 🙏 Créditos

Este proyecto es posible gracias al trabajo de muchos desarrolladores talentosos de la comunidad Linux de código abierto:

| Proyecto | Autor | Aporte al Proyecto | Licencia |
|----------|-------|--------------------|----------|
| [MacTahoe GTK Theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | vinceliuice | Tema visual principal para aplicaciones GTK (ventanas, controles, modo oscuro/claro). | MIT |
| [MacTahoe Icon Theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | vinceliuice | Iconografía del sistema, carpetas y aplicaciones estilo macOS. | MIT |
| [SFWindows (Fuentes Apple)](https://github.com/bradleyhodges/SFWindows) | bradleyhodges | Fuentes tipográficas oficiales de Apple (SF Pro, SF Mono, New York). | MIT |
| [Liquid Glass](https://github.com/ryohsuke1231/liquid-glass) | ryohsuke1231 | Efecto de desenfoque y transparencia (blur) en la interfaz de GNOME. | MIT |
| [Compiz Alike Magic Lamp (GNOME)](https://github.com/hermes83/compiz-alike-magic-lamp-effect) | hermes83 | Animación "Lámpara Mágica" (Magic Lamp) al minimizar ventanas en GNOME. | GPL-3.0 |
| [Cinnamon Magic Lamp](https://github.com/klangman/CinnamonMagicLamp) | klangman | Animación "Lámpara Mágica" al minimizar ventanas en Cinnamon. | GPL-3.0 |
| [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | vinceliuice | Colección de fondos de pantalla oficiales de macOS (Sonoma, Monterey, etc.). | MIT |
| [Mojave Dynamic Wallpaper](https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave) | japamax | Fondo de pantalla dinámico que cambia automáticamente según la hora del día. | - |
| [macOS Big Sur Sound Theme](https://github.com/gxanshu/macos-bigsur-sound-theme-linux) | gxanshu | Paquete de sonidos del sistema (incluye el icónico "Startup Chime" de arranque). | MIT |
| [Rofi Spotlight](https://github.com/eromatiya/rofi-spotlight) | eromatiya | Lanzador de aplicaciones y búsqueda global de archivos estilo Spotlight. | MIT |
| [Plank Themes](https://github.com/Macintosh98/MacOS-Mojave-Plank-themes) | Macintosh98 | Temas visuales para emular el Dock inferior de macOS usando Plank. | - |
| [Apple Mac Plymouth](https://github.com/navisjayaseelan/apple-mac-plymouth) | navisjayaseelan | Animación y logo de Apple durante la pantalla de arranque del sistema (Plymouth). | - |
| [Cinnamon Dynamic Wallpaper](https://github.com/TobiZog/cinnamon-dynamic-wallpaper) | TobiZog | Extensión para fondos de pantalla dinámicos por hora en Cinnamon. | GPL-3.0 |
| [Fusuma (Gestos Multitáctiles)](https://github.com/iberianpig/fusuma) | iberianpig | Motor de reconocimiento de gestos multitáctiles (deslizar con 3/4 dedos) en el trackpad. | MIT |
| [Sushi / Gloobus Preview (Quick Look)](https://github.com/GNOME/sushi) | GNOME Project | Vista previa rápida de archivos al presionar la barra espaciadora (Quick Look). | GPL-2.0+ |
| [Zuno (YouTube Music Client)](https://github.com/noFAYZ/zuno) | noFAYZ | Cliente nativo de YouTube Music, adaptado visualmente como "Apple Music". | MIT |
| [LocalSend](https://github.com/localsend/localsend) | localsend | Herramienta de transferencia de archivos en red local (alternativa open-source a AirDrop). | MIT |
| [IPTVnator](https://github.com/4gray/iptvnator) | 4gray | Reproductor de IPTV, adaptado visualmente como "Apple TV" con listas preconfiguradas. | MIT |
| [ONLYOFFICE Desktop Editors](https://github.com/ONLYOFFICE/DesktopEditors) | ONLYOFFICE | Suite ofimática de código abierto, integrada visualmente como "Office". | AGPL v3 / MPL v2 |

---

## ⚖️ Licencia y Aviso Legal

Este script está licenciado bajo la [Licencia MIT](LICENSE).

> **⚠️ Importante:** Las fuentes **San Francisco** y **New York**, así como los sonidos del sistema, son propiedad intelectual de **Apple Inc.** Este proyecto las incluye únicamente por conveniencia para usuarios de plataformas no-Apple, basándose en repositorios comunitarios de terceros. El uso de estos activos está sujeto a los [términos de licencia de Apple](https://developer.apple.com/fonts/). Asegúrate de cumplir con dichos términos.
> 
> **Nota sobre aplicaciones de terceros:** ONLYOFFICE es una suite ofimática de código abierto. Zuno e IPTVnator son reproductores de código abierto. Este proyecto no proporciona, aloja ni vende contenido multimedia, listas de reproducción o suscripciones. El usuario es responsable del contenido que decida reproducir o crear a través de estas herramientas.

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! 
1. Haz un fork del repositorio.
2. Crea una rama para tu funcionalidad (`git checkout -b feature/AmazingFeature`).
3. Haz commit de tus cambios (`git commit -m 'Add some AmazingFeature'`).
4. Haz push a la rama (`git push origin feature/AmazingFeature`).
5. Abre un Pull Request.

Si encuentras un bug, por favor [abre un issue](https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/issues) indicando:
- Tu distribución y versión.
- Tu entorno de escritorio (GNOME/Cinnamon/XFCE).
- Los pasos para reproducir el problema.

---

<div align="center">

**Hecho con ❤️ por [AntonSiMal](https://github.com/AntonSiMal) para la comunidad Linux**

[⬆️ Volver arriba](#-macos-tahoe-installer-for-linux)

</div>
