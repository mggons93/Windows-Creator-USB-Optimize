<p align="center">
<a href=></a><img src="https://raw.githubusercontent.com/mggons93/Windows-Creator-USB-Optimize/refs/heads/main/windows-installer.ico"/>
</p>

## <p align="center">Windows Creator USB Optimize by Mggons</p>

Es una Herramienta que te permite generar una imagen de Windows Completa usando la base de una iso original y adaptandola
para que se cree la usb booteable, la optimize y le agregue los drivers SSD y NVMe dentro del mismo Boot.wim


## 🖼️ Imagen de Muestra
<p align="center">
<a href=></a><img src="https://raw.githubusercontent.com/mggons93/Windows-Creator-USB-Optimize/refs/heads/main/WindowsUSBCreator.png"/>
</p>

## 🎥 Video de Muestra  
👉 [Haz clic aquí para ver el video](https://github.com/mggons93/Windows-Creator-USB-Optimize/raw/main/Metodo%20de%20creacion%20de%20USB.mp4)


## Funciones del Windows USB Creator Optimize

### 💽 Listado y selección de discos USB

Permite visualizar y seleccionar los discos disponibles en el equipo para utilizarlos como destino de la creación del USB booteable.

La interfaz muestra información de las unidades detectadas, incluyendo su capacidad, siguiendo un funcionamiento similar al utilizado por **Rufus**.

### 💿 Búsqueda y selección de archivos ISO

Permite seleccionar una imagen ISO de Windows 10/11 mediante el botón de búsqueda identificado con un **icono de disco**.

La interfaz permite seleccionar fácilmente la ISO que será utilizada durante el proceso.

### 🚀 Creación del USB booteable

Al pulsar **Iniciar**, el programa verifica que se haya seleccionado una unidad de destino y una imagen ISO.

Antes de modificar el disco seleccionado, se solicita confirmación al usuario.

Durante la creación, la interfaz se bloquea para evitar modificaciones accidentales y el botón **Iniciar** cambia a **Cancelar**.

### 💾 Formateo del USB

Utiliza `diskpart` para preparar el disco seleccionado, incluyendo:

* Limpieza del disco.
* Conversión a MBR.
* Creación de una partición primaria.
* Activación de la partición.
* Formateo en FAT32.

### 📦 Montaje y procesamiento de la ISO

Monta la imagen ISO seleccionada y obtiene la letra de la unidad virtual para acceder a sus archivos.

Los archivos de instalación se procesan y copian al USB manteniendo la estructura necesaria para que la unidad sea booteable.

### ✂️ División de archivos `install.wim`

Cuando el archivo `install.wim` supera el límite de aproximadamente **4 GB** de FAT32, se divide utilizando **DISM** en varios archivos `.swm`.

El proceso muestra en el log el número de *splits* generados:

```text
1 split
2 splits
3 splits
...
```

### 📥 Drivers NVMe

Se habilitó la **descarga automática de drivers NVMe** necesarios para mejorar la compatibilidad durante la instalación de Windows.

Los controladores NVMe se gestionan automáticamente durante el proceso de creación del USB.

### 📁 Archivos NVMe en la raíz del USB

Se mantiene disponible la opción para colocar los archivos de soporte NVMe directamente en la **raíz del USB**.

Esta opción queda habilitada por defecto.

### ⚙️ Archivo de autoinstalación

Descarga el archivo `autounattend.xml` desde GitHub y lo incorpora al USB para automatizar determinadas partes del proceso de instalación de Windows.

### 🔒 Control de la interfaz durante el proceso

Mientras se está creando el USB, se bloquean temporalmente determinadas opciones de la interfaz para evitar interrupciones:

* Cerrar
* Minimizar
* Archivo
* Herramientas
* Buscar ISO

Al finalizar o cancelar el proceso, la interfaz vuelve a estar disponible.

### ❌ Cancelación del proceso

El botón **Cancelar** permite solicitar la interrupción del proceso.

Antes de cancelar se muestra una confirmación:

> **¿Desea cancelar la operación?**

### 🎨 Estado del botón de inicio

El botón principal cambia de estado según la operación:

* 🟢 **Iniciar** — disponible antes de comenzar.
* 🔴 **Cancelar** — aparece mientras el proceso está en ejecución.
* 🟢 **Iniciar** — vuelve a estar disponible al finalizar.

### 📊 Registro del proceso

El log muestra información sobre las diferentes etapas de creación del USB, incluyendo:

* Detección y selección del disco.
* Montaje de la ISO.
* Copia de archivos.
* División de `install.wim`.
* Descarga y gestión de drivers NVMe.
* Estado de la operación.
* Resultado final.

### 🖥️ Compatibilidad con Windows

El proyecto está diseñado para trabajar con imágenes de instalación de **Windows 10 y Windows 11**, incluyendo el procesamiento de imágenes `install.wim` y la preparación de medios USB compatibles con FAT32.

### ✅ Finalización

Al finalizar el proceso:

* Se desmonta la imagen ISO.
* Se restaura el estado de la interfaz.
* El botón **Cancelar** vuelve a **Iniciar**.
* Se muestran mensajes indicando si el proceso terminó correctamente o si ocurrió algún error.
* La información del proceso permanece disponible en el log para facilitar la revisión.
ente el botón de inicio y muestra mensajes de éxito o error en la interfaz gráfica.
