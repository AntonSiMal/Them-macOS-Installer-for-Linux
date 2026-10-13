<div align="center">

# 🍎 macOS Tahoe Installer for Linux

### Transforma tu escritorio Linux en una experiencia macOS auténtica

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GNOME](https://img.shields.io/badge/GNOME-46%20%E2%80%93%2051-green.svg)](https://www.gnome.org/)
[![Cinnamon](https://img.shields.io/badge/Cinnamon-5.4%20%2B-orange.svg)](https://linuxmint.com/)
[![XFCE](https://img.shields.io/badge/XFCE-4.18%20%2B-blue.svg)](https://www.xfce.org/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-black.svg)](https://www.gnu.org/software/bash/)

**Instalación 100% automatizada · Sin intervención manual · Compatible con GNOME, Cinnamon y XFCE**

[Instalación rápida](#-instalación-rápida) · [Características](#-características) · [Atajos](#-atajos-de-teclado) · [Desinstalación](#-desinstalación)

</div>

---

## 📸 Vista previa

<div align="center">
  <img src="assets/preview.png" alt="macOS Tahoe en Linux" width="100%"/>
  <p><em>Escritorio Linux transformado con el tema macOS Tahoe, fuentes oficiales Apple, sonidos, wallpapers dinámicos, efecto Magic Lamp y lanzador Spotlight.</em></p>
</div>

---

## ✨ ¿Qué hace este script?

Este script **automatiza por completo** la transformación de tu escritorio Linux en una experiencia macOS auténtica. Ejecuta **24 pasos** de instalación y configuración sin que tengas que hacer nada manualmente:

| # | Componente | Descripción |
|---|------------|-------------|
| 📦 | **Dependencias del sistema** | Instala automáticamente todas las herramientas necesarias |
| 🔤 | **Fuentes Apple oficiales** | SF Pro, SF Compact, SF Mono, New York (WWDC26 v27.0) |
| 🧩 | **Liquid Glass** | Extensión GNOME para efecto cristal líquido (solo GNOME) |
| 🌅 | **Dynamic Wallpaper (Cinnamon)** | Extensión para wallpapers dinámicos en Cinnamon |
| 🎨 | **Tema MacTahoe GTK** | Tema visual estilo macOS Tahoe con ventanas redondeadas |
| 🖼️ | **Iconos MacTahoe** | Iconos oficiales estilo macOS (versión bold automática para 4K) |
| 🌄 | **Wallpaper dinámico Mojave** | 16 imágenes que cambian según la hora del día (horarios reales) |
| 🏞️ | **Wallpapers Sonoma** | Fondos de respaldo estáticos y dinámicos |
| 🔊 | **Sonidos macOS Big Sur** | 44 eventos de sonido (startup chime, notificaciones, etc.) |
| 🔍 | **Rofi Spotlight** | Lanzador estilo macOS con búsqueda de archivos y web |
| 🚀 | **Temas de Plank** | Dock estilo macOS con múltiples temas BigSur |
| 🖥️ | **Plymouth** | Pantalla de arranque con logo Apple |
| 🦊 | **Tema Firefox Safari** | Firefox con apariencia de Safari |
| 🔐 | **GDM (solo GNOME)** | Pantalla de login estilo macOS |
| 🪟 | **Script de ventanas avanzadas** | Gestión de opacidad, centrado, mover/redimensionar sin barra |
| ⌨️ | **Atajos macOS** | 50+ atajos de teclado configurados automáticamente |
| ✏️ | **Renderizado de fuentes** | Optimización Fontconfig para SF Pro nítida |
| 💻 | **Terminal estilo macOS** | Perfil con SF Mono y colores auténticos |
| 🎬 | **Animaciones suaves** | Activación de composición y transiciones fluidas |
| 🪔 | **Magic Lamp Effect** | Efecto "Genio" al minimizar (GNOME y Cinnamon) |
| ✅ | **Verificación automática** | Comprobación post-instalación de componentes |
| 🎭 | **Tematización Qt** | VLC, OBS y apps Qt coinciden con el tema macOS |
| 👁️ | **Quick Look** | Vista previa de archivos con barra espaciadora (Sushi/Gloobus) |
| 📜 | **Scroll Natural** | Desplazamiento estilo trackpad macOS universal |
| 👆 | **Gestos Fusuma + Arrastre 3 dedos** | Deslizar para espacios/zoom y arrastrar sin hacer clic |
| 📋 | **Gestor de Portapapeles** | Historial de portapapeles minimalista (Clipboard Indicator/Clipit) |

---

## 🖥️ Compatibilidad

| Distro / Entorno | Estado | Notas |
|------------------|:------:|-------|
| **Ubuntu** (GNOME) | ✅ | Soporte completo |
| **Zorin OS** | ✅ | Soporte completo |
| **Fedora** (GNOME) | ✅ | Soporte completo |
| **Linux Mint** (Cinnamon) | ✅ | Soporte completo |
| **Linux Mint** (XFCE) | ✅ | Soporte completo |
| **Debian** (GNOME/Cinnamon) | ✅ | Soporte completo |
| **Arch Linux** | ✅ | Soporte completo |
| **Manjaro** | ✅ | Soporte completo |
| **Pop!_OS** | ✅ | Soporte completo |
| **openSUSE** | ⚠️ | Requiere ajustes menores |
| **KDE Plasma** | ❌ | No soportado (usa su propio sistema de temas) |

---

## 📋 Requisitos

- **Sistema operativo:** Linux con GNOME 46+, Cinnamon 5.4+ o XFCE 4.18+
- **Conexión a internet:** Para descargar los repositorios y dependencias
- **Espacio en disco:** ~2 GB (incluyendo wallpapers, fuentes y sonidos)
- **Permisos de `sudo`:** Para instalar dependencias del sistema y Plymouth/GDM

---

## 🚀 Instalación rápida

### Método recomendado (una sola línea)

```bash
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/install.sh -o /tmp/mac-installer.sh && chmod +x /tmp/mac-installer.sh && sudo /tmp/mac-installer.sh
```

### Método manual

```bash
# 1. Clonar el repositorio
git clone https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux.git
cd Them-macOS-Tahoe-Installer-for-Linux

# 2. Dar permisos de ejecución
chmod +x install.sh

# 3. Ejecutar el script
./install.sh
```

### Después de la instalación

| Entorno | Acción requerida |
|---------|------------------|
| **GNOME (Wayland)** | Cierra sesión y vuelve a entrar para activar extensiones |
| **GNOME (X11)** | El script reinicia GNOME Shell automáticamente |
| **Cinnamon** | El script reinicia Cinnamon automáticamente |
| **XFCE** | No se requiere ninguna acción |

---

## ⌨️ Atajos de teclado

El script configura **50+ atajos de teclado** estilo macOS. Aquí los principales:

### 🔍 Búsqueda y aplicaciones
| Atajo | Acción |
|-------|--------|
| `Ctrl + Espacio` | Abrir **Spotlight** (búsqueda global de archivos y web) |
| `Súper + E` | Abrir Explorador de Archivos |
| `Súper + A` | Abrir Configuración del Sistema |
| `Ctrl + Alt + T` | Abrir Terminal |

### 🪟 Gestión de ventanas
| Atajo | Acción |
|-------|--------|
| `Súper + Q` | Cerrar aplicación activa |
| `Súper + M` | Minimizar ventana (con efecto Magic Lamp) |
| `Súper + X` | Maximizar / Restaurar |
| `Súper + C` | Centrar ventana en la pantalla |
| `Súper + F` | Fijar ventana siempre al frente |
| `Súper + O` | Disminuir opacidad de la ventana |
| `Súper + Ctrl + O` | Aumentar opacidad de la ventana |
| `Ctrl + Q` | Cerrar app completamente (incluyendo procesos en segundo plano) |
| `Súper + ←/→/↑/↓` | Acoplar (snap) ventana a los bordes |

### 🏢 Áreas de trabajo y Sistema
| Atajo | Acción |
|-------|--------|
| `Súper + 1/2/3` | Ir al área de trabajo 1, 2 o 3 |
| `Ctrl + Alt + ←/→` | Cambiar entre áreas de trabajo |
| `Súper + D` | Mostrar / Ocultar escritorio |
| `Súper + L` | Bloquear pantalla |
| `Alt + Ctrl + Esc` | Forzar cierre de app congelada (xkill) |

> 📖 Consulta la guía completa de atajos en `~/.macos-keybindings.md` después de la instalación.

---

## 🗑️ Desinstalación

Para revertir **todos** los cambios de forma segura y restaurar tu sistema a su estado original, utiliza el script de desinstalación incluido:

```bash
# Si clonaste el repositorio:
./uninstall.sh

# O si usaste el método de una línea:
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh | bash
```
*Este script elimina archivos, restaura configuraciones de `gsettings`/`xfconf`, desactiva extensiones y restaura el tema de arranque Plymouth automáticamente.*

---

## 🐛 Solución de problemas

<details>
<summary><strong>El wallpaper dinámico no cambia</strong></summary>
Verifica que el reloj del sistema esté sincronizado con la red:
```bash
timedatectl
sudo timedatectl set-ntp true
```
</details>

<details>
<summary><strong>Liquid Glass o Magic Lamp no se activan en Wayland</strong></summary>
En Wayland, las extensiones de GNOME Shell requieren cerrar sesión y volver a entrar para cargarse correctamente:
```bash
gnome-session-quit --logout
```
</details>

<details>
<summary><strong>Las fuentes Apple no se ven nítidas o no se aplican</strong></summary>
Actualiza la caché de fuentes del sistema y verifica que estén instaladas:
```bash
fc-cache -fv
fc-list | grep -i "SF Pro"
```
</details>

---

## 🙏 Créditos

Este proyecto es posible gracias al trabajo de muchos desarrolladores talentosos de la comunidad Linux de código abierto:

| Proyecto | Autor | Licencia |
|----------|-------|----------|
| [MacTahoe GTK Theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | vinceliuice | MIT |
| [MacTahoe Icon Theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | vinceliuice | MIT |
| [SFWindows (Fuentes Apple)](https://github.com/bradleyhodges/SFWindows) | bradleyhodges | MIT |
| [Liquid Glass](https://github.com/ryohsuke1231/liquid-glass) | ryohsuke1231 | MIT |
| [Compiz Alike Magic Lamp (GNOME)](https://github.com/hermes83/compiz-alike-magic-lamp-effect) | hermes83 | GPL-3.0 |
| [Cinnamon Magic Lamp](https://github.com/klangman/CinnamonMagicLamp) | klangman | GPL-3.0 |
| [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | vinceliuice | MIT |
| [Mojave Dynamic Wallpaper](https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave) | japamax | - |
| [macOS Big Sur Sound Theme](https://github.com/gxanshu/macos-bigsur-sound-theme-linux) | gxanshu | MIT |
| [Rofi Spotlight](https://github.com/eromatiya/rofi-spotlight) | eromatiya | MIT |
| [Rofi Themes Collection](https://github.com/newmanls/rofi-themes-collection) | newmanls | MIT |
| [Plank Themes](https://github.com/Macintosh98/MacOS-Mojave-Plank-themes) | Macintosh98 | - |
| [Apple Mac Plymouth](https://github.com/navisjayaseelan/apple-mac-plymouth) | navisjayaseelan | - |
| [Cinnamon Dynamic Wallpaper](https://github.com/TobiZog/cinnamon-dynamic-wallpaper) | TobiZog | GPL-3.0 |
| [Fusuma (Gestos Multitáctiles)](https://github.com/iberianpig/fusuma) | iberianpig | MIT |
| [Sushi / Gloobus Preview (Quick Look)](https://github.com/GNOME/sushi) | GNOME Project | GPL-2.0+ |

---

> **⚠️ Aviso legal:** Las fuentes **San Francisco** y **New York**, así como los sonidos del sistema, son propiedad intelectual de **Apple Inc.** Este proyecto las incluye únicamente por conveniencia para usuarios de plataformas no-Apple, basándose en repositorios comunitarios. El uso de estas fuentes está sujeto a los [términos de licencia de Apple](https://developer.apple.com/fonts/). Asegúrate de cumplir con dichos términos.

---

## ⚖️ Licencia

Este script está licenciado bajo la [Licencia MIT](LICENSE).

> **⚠️ Aviso legal:** Las fuentes **San Francisco** y **New York**, así como los sonidos del sistema, son propiedad intelectual de **Apple Inc.** Este proyecto las incluye únicamente por conveniencia para usuarios de plataformas no-Apple. El uso de estas fuentes está sujeto a los [términos de licencia de Apple](https://developer.apple.com/fonts/). Asegúrate de cumplir con dichos términos.

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
