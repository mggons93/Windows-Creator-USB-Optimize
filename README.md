## <p align="center">Windows Creator USB Optimize by Mggons</p>
Es una Herramienta que te permite generar una imagen de Windows Completa usando la base de una iso original y adaptandola
para que se cree la usb booteable, la optimize y le agregue los drivers SSD y NVMe dentro del mismo Boot.wim


## 🖼️ Imagen de Muestra
<p align="center">
<a href=></a><img src="https://raw.githubusercontent.com/mggons93/Windows-Creator-USB-Optimize/refs/heads/main/CreatorFinal.png"/>
</p>

## 🎥 Video de Muestra  
👉 [Haz clic aquí para ver el video](https://github.com/mggons93/Windows-Creator-USB-Optimize/raw/main/Metodo%20de%20creacion%20de%20USB.mp4)


## Funciones del Windows USB Creator Optimize

**Escaneo de discos USB:**
Permite al usuario buscar y seleccionar un disco USB conectado al equipo para usarlo como destino. Muestra los discos detectados y su tamaño en la interfaz.

**Búsqueda de archivos ISO:**
Permite al usuario buscar y seleccionar un archivo ISO de Windows 10/11 desde una carpeta. Los archivos encontrados se listan para su selección.

**Inicio del proceso de creación del USB booteable:**
Al pulsar "Iniciar", el script verifica que se haya seleccionado un disco y un archivo ISO, y solicita confirmación al usuario antes de formatear el disco USB.

**Formateo del USB:**
Utiliza diskpart para limpiar el disco seleccionado, convertirlo a MBR, crear una partición primaria, activarla y formatearla en FAT32.

**Montaje de la ISO:**
Monta la imagen ISO seleccionada y obtiene la letra de la unidad virtual para acceder a sus archivos.

**Copia de archivos y manejo de archivos grandes:**
Si el archivo install.wim de la ISO es mayor a 4GB, lo divide en fragmentos .swm usando DISM, ya que FAT32 no soporta archivos mayores a 4GB. Copia todos los archivos de la ISO al USB, excluyendo los grandes inicialmente, y luego copia los fragmentos o el archivo install.wim si corresponde.

**Reemplazo de boot.wim con drivers NVMe:**
Verifica la versión de boot.wim usando DISM y descarga una versión personalizada con controladores NVMe adecuada para Windows 10 u 11, reemplazando el archivo en el USB.

**Descarga de archivo de autoinstalación:**
Descarga un archivo autounattend.xml desde GitHub al USB para automatizar la instalación de Windows.

**Finalización:**
Desmonta la ISO, habilita nuevamente el botón de inicio y muestra mensajes de éxito o error en la interfaz gráfica.
