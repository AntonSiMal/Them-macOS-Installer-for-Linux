<div align="center">

# 🍎 macOS Tahoe Installer for Linux

### Transforma tu escritorio Linux en una experiencia macOS auténtica

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GNOME](https://img.shields.io/badge/GNOME-46%20%E2%80%93%2051-green.svg)](https://www.gnome.org/)
[![Cinnamon](https://img.shields.io/badge/Cinnamon-5.4%20%2B-orange.svg)](https://linuxmint.com/)
[![XFCE](https://img.shields.io/badge/XFCE-4.18%20%2B-blue.svg)](https://www.xfce.org/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-black.svg)](https://www.gnu.org/software/bash/)

**Instalación 100% automatizada · Sin intervención manual · Compatible con GNOME, Cinnamon y XFCE**

[Instalación rápida](#-instalación-rápida) · [Características](#-características) · [Atajos](#-atajos-de-teclado) · [FAQ](#-faq)

</div>

---

## 📸 Vista previa

<div align="center">
  <img src="assets/preview.png" alt="macOS Tahoe en Linux" width="100%"/>
  <p><em>Escritorio Linux transformado con el tema macOS Tahoe, fuentes oficiales Apple, sonidos, wallpapers dinámicos y lanzador Spotlight.</em></p>
</div>

---

## ✨ ¿Qué hace este script?

Este script **automatiza por completo** la transformación de tu escritorio Linux en una experiencia macOS auténtica. Instala y configura **15 componentes** sin que tengas que hacer nada manualmente:

| # | Componente | Descripción |
|---|------------|-------------|
| 🎨 | **Tema MacTahoe GTK** | Tema visual estilo macOS Tahoe con ventanas redondeadas |
| 🖼️ | **Iconos MacTahoe** | Iconos oficiales estilo macOS (versión bold para 4K) |
| 🔤 | **Fuentes Apple oficiales** | SF Pro, SF Compact, SF Mono, New York (WWDC26 v27.0) |
| 🔊 | **Sonidos macOS Big Sur** | 44 eventos de sonido (startup chime, notificaciones, etc.) |
| 🌄 | **Wallpaper dinámico** | Mojave con 16 imágenes que cambian según la hora del día |
| 🖼️ | **Wallpapers Sonoma** | Fondo de respaldo con versión estática y dinámica |
| 🔍 | **Rofi Spotlight** | Lanzador estilo macOS con búsqueda de archivos y web |
| 🧩 | **Liquid Glass** | Extensión GNOME para efecto cristal líquido (solo GNOME) |
| 🚀 | **Plank Dock** | Dock estilo macOS con tema BigSur |
| 🖥️ | **Plymouth** | Pantalla de arranque con logo Apple |
| 🦊 | **Firefox Safari** | Tema de Firefox estilo Safari |
| 🔐 | **GDM** | Pantalla de login estilo macOS (solo GNOME) |
| ⌨️ | **Atajos macOS** | 50+ atajos de teclado configurados automáticamente |
| 📝 | **Documentación** | Guía de atajos generada en `~/.macos-keybindings.md` |
| 🌅 | **Dynamic Wallpaper** | Extensión para Cinnamon con wallpapers dinámicos |

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
- **Conexión a internet:** Para descargar los repositorios
- **Espacio en disco:** ~2 GB (incluyendo wallpapers y fuentes)
- **Permisos de `sudo`:** Para instalar dependencias y Plymouth/GDM

---

## 🚀 Instalación rápida

### Método recomendado (una sola línea)

```bash
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/install.sh | bash
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
| **GNOME (Wayland)** | Cierra sesión y vuelve a entrar |
| **GNOME (X11)** | El script reinicia GNOME Shell automáticamente |
| **Cinnamon** | El script reinicia Cinnamon automáticamente |
| **XFCE** | No se requiere ninguna acción |

---

## ⌨️ Atajos de teclado

El script configura **50+ atajos de teclado** estilo macOS. Aquí los principales:

### 🔍 Búsqueda y aplicaciones
| Atajo | Acción |
|-------|--------|
| `Ctrl + Espacio` | Abrir **Spotlight** (búsqueda global) |
| `Súper + E` | Abrir Explorador de Archivos |
| `Súper + A` | Abrir Configuración del Sistema |
| `Ctrl + Alt + T` | Abrir Terminal |

### 🪟 Gestión de ventanas
| Atajo | Acción |
|-------|--------|
| `Súper + Q` | Cerrar aplicación activa |
| `Súper + M` | Minimizar ventana |
| `Súper + X` | Maximizar / Restaurar |
| `Súper + C` | Centrar ventana |
| `Súper + F` | Fijar siempre al frente |
| `Súper + O` | Disminuir opacidad |
| `Súper + Ctrl + O` | Aumentar opacidad |
| `Ctrl + Q` | Cerrar app completamente (incluyendo procesos) |
| `Súper + ←/→/↑/↓` | Acoplar (snap) ventana |

### 🏢 Áreas de trabajo y Sistema
| Atajo | Acción |
|-------|--------|
| `Súper + 1/2/3` | Ir al área de trabajo 1, 2 o 3 |
| `Ctrl + Alt + ←/→` | Cambiar entre áreas de trabajo |
| `Súper + D` | Mostrar / Ocultar escritorio |
| `Súper + L` | Bloquear pantalla |
| `Alt + Ctrl + Esc` | Forzar cierre de app (xkill) |

> 📖 Consulta la guía completa en `~/.macos-keybindings.md` después de la instalación.

---

## 🗑️ Desinstalación

Para revertir todos los cambios, ejecuta:

```bash
rm -rf ~/.themes/MacTahoe* ~/.icons/MacTahoe* ~/.local/share/icons/MacTahoe*
rm -rf ~/.local/share/fonts/SF* ~/.local/share/fonts/NewYork*
rm -rf ~/.local/share/sounds/bigsur
rm -rf ~/.local/share/backgrounds/* /usr/share/backgrounds/macOS
rm -rf ~/.local/share/plank/themes/MacOS-*
rm -rf ~/.local/share/rofi-spotlight ~/.local/bin/rofi-spotlight-launcher
dconf reset -f /org/gnome/  # Solo para GNOME
```

---

## 🐛 Solución de problemas

<details>
<summary><strong>El wallpaper dinámico no cambia</strong></summary>
Verifica que el reloj del sistema esté sincronizado:
```bash
timedatectl
sudo timedatectl set-ntp true
```
</details>

<details>
<summary><strong>Liquid Glass no se activa en Wayland</strong></summary>
En Wayland, las extensiones requieren cerrar sesión y volver a entrar para activarse:
```bash
gnome-session-quit --logout
```
</details>

<details>
<summary><strong>Las fuentes Apple no se aplican</strong></summary>
Actualiza la caché de fuentes y verifica:
```bash
fc-cache -fv
fc-list | grep -i "SF Pro"
```
</details>

---

## 🙏 Créditos

Este proyecto utiliza el trabajo de muchos desarrolladores talentosos de la comunidad Linux:

| Proyecto | Autor | Licencia |
|----------|-------|----------|
| [MacTahoe GTK Theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | vinceliuice | MIT |
| [MacTahoe Icon Theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | vinceliuice | MIT |
| [SFWindows (Fuentes Apple)](https://github.com/bradleyhodges/SFWindows) | bradleyhodges | MIT |
| [Liquid Glass](https://github.com/ryohsuke1231/liquid-glass) | ryohsuke1231 | MIT |
| [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | vinceliuice | MIT |
| [Mojave Dynamic Wallpaper](https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave) | japamax | - |
| [macOS Big Sur Sound Theme](https://github.com/gxanshu/macos-bigsur-sound-theme-linux) | gxanshu | MIT |
| [Rofi Spotlight](https://github.com/eromatiya/rofi-spotlight) | eromatiya | MIT |
| [Rofi Themes Collection](https://github.com/newmanls/rofi-themes-collection) | newmanls | MIT |
| [Plank Themes](https://github.com/Macintosh98/MacOS-Mojave-Plank-themes) | Macintosh98 | - |
| [Apple Mac Plymouth](https://github.com/navisjayaseelan/apple-mac-plymouth) | navisjayaseelan | - |
| [Cinnamon Dynamic Wallpaper](https://github.com/TobiZog/cinnamon-dynamic-wallpaper) | TobiZog | GPL-3.0 |

---

## ⚖️ Licencia

Este script está licenciado bajo la [Licencia MIT](LICENSE).

> **Aviso legal:** Las fuentes **San Francisco** y **New York**, así como los sonidos del sistema, son propiedad intelectual de **Apple Inc.** Este proyecto las incluye únicamente por conveniencia para usuarios de plataformas no-Apple. El uso de estas fuentes está sujeto a los [términos de licencia de Apple](https://developer.apple.com/fonts/).

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! 
1. Haz un fork del repositorio.
2. Crea una rama para tu funcionalidad (`git checkout -b feature/AmazingFeature`).
3. Haz commit de tus cambios (`git commit -m 'Add some AmazingFeature'`).
4. Haz push a la rama (`git push origin feature/AmazingFeature`).
5. Abre un Pull Request.

Si encuentras un bug, por favor [abre un issue](https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/issues) indicando tu distribución, entorno de escritorio y los pasos para reproducirlo.

---

<div align="center">

**Hecho con ❤️ por [AntonSiMal](https://github.com/AntonSiMal) para la comunidad Linux**

[⬆️ Volver arriba](#-macos-tahoe-installer-for-linux)

</div>
