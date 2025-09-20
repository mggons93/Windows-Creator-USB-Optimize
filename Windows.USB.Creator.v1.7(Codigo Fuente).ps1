# Función para reiniciar el script con privilegios de administrador
function Start-ProcessAsAdmin {
    param (
        [string]$file,
        [string[]]$arguments = @()
    )
    Start-Process -FilePath $file -ArgumentList $arguments -Verb RunAs
}

# Comprobar si el script se está ejecutando como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Si no está ejecutándose como administrador, relanza el script con privilegios elevados
    Start-ProcessAsAdmin -file "powershell.exe" -arguments "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}


Add-Type -AssemblyName PresentationFramework,System.Windows.Forms,System.Drawing

# =========================
# XAML de interfaz gráfica
# =========================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows USB Creator by Mggons" Height="400" Width="400" Background="#8e77ab">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Selecciona el disco USB:" Margin="0,0,0,5" Grid.Row="0" FontWeight="Bold"/>

        <Grid Grid.Row="1" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*"/>
                <ColumnDefinition Width="1.5*"/>
            </Grid.ColumnDefinitions>
            <ComboBox x:Name="diskComboBox" Height="30" Width="Auto" Margin="0,0,10,0" Grid.Column="0" FontWeight="Bold"/>
            <Button x:Name="scanDisksBtn" Content="Escanear Discos" Height="30" Width="100" Grid.Column="1" ToolTip="Escanea las unidades y Selecciona tu unidad a instalar" FontWeight="Bold"/>
        </Grid>

        <TextBlock Text="Selecciona un archivo ISO:" Margin="0,10,0,5" Grid.Row="2" FontWeight="Bold"/>

        <Grid Grid.Row="3" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*"/>
                <ColumnDefinition Width="1.5*"/>
            </Grid.ColumnDefinitions>
            <TextBox x:Name="txtIsoPath" Height="30" Width="Auto" Margin="0,0,10,0" Grid.Column="0" FontWeight="Bold" IsReadOnly="True" IsEnabled="False"/>
            <Button x:Name="scanISO" Content="Buscar ISO" Height="30" Width="100" Grid.Column="1" ToolTip="Recuerde que solo es válido para ISO's de Windows 10/11" FontWeight="Bold"/>
        </Grid>

        <Grid Grid.Row="4" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Button x:Name="startBtn" Content="Iniciar" Height="40" Width="120" HorizontalAlignment="Center" Grid.Column="0" FontWeight="Bold"/>
            <TextBlock x:Name="versionText" Text="Version: 1.7" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="10,0,0,0" Grid.Column="1" FontWeight="Bold"/>
        </Grid>

        <TextBox x:Name="logTextBox" Grid.Row="5" Margin="0,0,0,0" VerticalScrollBarVisibility="Auto" IsReadOnly="True" TextWrapping="Wrap" FontWeight="Bold"/>
    </Grid>
</Window>
"@

[xml]$xml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xml.DocumentElement
$window = [Windows.Markup.XamlReader]::Load($reader)

# Supongamos que $window es tu ventana principal
$window.Add_Closed({
    # Cierra cualquier runspace o proceso que tú hayas lanzado
    if ($global:ps -and !$global:ps.HasExited) {
        try {
            $global:ps.Stop()
        } catch {}
        $global:ps.Dispose()
    }

    if ($global:runspace) {
        try { $global:runspace.Close(); $global:runspace.Dispose() } catch {}
    }

    # Forzar cierre del script completo si algo sigue abierto
    [System.Environment]::Exit(0)
})

# Controles
$diskComboBox = $window.FindName("diskComboBox")
$scanDisksBtn = $window.FindName("scanDisksBtn")
$txtIsoPath = $window.FindName("txtIsoPath")   # <-- Aquí cambió
$scanISO = $window.FindName("scanISO")
$startBtn = $window.FindName("startBtn")
$logTextBox = $window.FindName("logTextBox")

# Función para escribir log en el hilo de GUI
$syncHash = [hashtable]::Synchronized(@{})
$syncHash.Window = $window
$syncHash.LogBox = $logTextBox
function Add-Log {
    param($msg)
    $syncHash.LogBox.Dispatcher.Invoke([action]{
        $syncHash.LogBox.AppendText("$msg`r`n")
        $syncHash.LogBox.ScrollToEnd()
    })
}

# Escaneo de discos USB
$scanDisksBtn.Add_Click({
    $diskComboBox.Items.Clear()
    $disks = Get-Disk | Where-Object BusType -eq 'USB'
    if ($disks.Count -eq 0) {
        Add-Log "`n❌ No se encontraron discos USB."
        [System.Windows.MessageBox]::Show("No se encontraron discos USB.")
    } else {
        foreach ($disk in $disks) {
            $sizeGB = [math]::Round($disk.Size / 1GB)
            $item = "Disco $($disk.Number) - $sizeGB GB - $($disk.FriendlyName)"
            $diskComboBox.Items.Add($item)
            
        }
    }
    Add-Log "`n✅ Escaneando discos USB... OK"
})

# Evento clic para buscar archivo ISO y mostrar ruta en TextBox
$scanISO.Add_Click({
       
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Archivos ISO (*.iso)|*.iso"
    $ofd.Multiselect = $false
    $ofd.Title = "Selecciona un archivo ISO"
    
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedIsoPath = $ofd.FileName
        $txtIsoPath.Text = $selectedIsoPath
        #Add-Log "Archivo ISO seleccionado: $selectedIsoPath"
    } else {
        Add-Log "`n❌ Selección de archivo ISO cancelada."
    }
    Add-Log "`n✅ Seleccionar archivo ISO...OK"
})

# Crear USB con Runspace
$startBtn.Add_Click({
    if (-not $diskComboBox.SelectedItem -or [string]::IsNullOrWhiteSpace($txtIsoPath.Text)) {
        [System.Windows.MessageBox]::Show("Selecciona un disco y un archivo ISO.")
        return
    }

    # Deshabilitar botón para evitar múltiples clicks
    $startBtn.IsEnabled = $false

    $confirm = [System.Windows.MessageBox]::Show("¿Estás seguro de que deseas formatear el disco y crear el medio de instalación?", "Confirmar", "YesNo", "Warning")
    if ($confirm -ne "Yes") {
        Add-Log "Operación cancelada por el usuario."
        $startBtn.IsEnabled = $true
        return
    }

    $diskNumber = ($diskComboBox.SelectedItem -split ' ')[1]
	$isoPath = $txtIsoPath.Text

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $ps = [PowerShell]::Create()
    $ps.Runspace = $runspace

    $ps.AddScript({
        param($diskNumber, $isoPath, $syncHash, $startBtn)

        function Add-LogRun {
            param($msg)
            $syncHash.LogBox.Dispatcher.Invoke([action]{
                $syncHash.LogBox.AppendText("$msg`r`n")
                $syncHash.LogBox.ScrollToEnd()
            })
        }

        function Split-ImageFile {
            param (
                [string]$rutaCompleta,
                [string]$destino
            )
            $nombreBase = [System.IO.Path]::GetFileNameWithoutExtension($rutaCompleta)
            $output = Join-Path $destino "$nombreBase.swm"

            Add-LogRun "`n✅ Dividiendo archivo '$rutaCompleta' en '$output'..."
            $splitCommand = "Dism /Split-Image /ImageFile:`"$rutaCompleta`" /SWMFile:`"$output`" /FileSize:3800"
            Invoke-Expression $splitCommand 
            Add-LogRun "`n✅ Archivo dividido correctamente en archivos .swm."
        }

        try {
            Add-LogRun "`n✅ Iniciando creación de USB booteable..."
            Add-LogRun "`n✅ Formateando disco $diskNumber..."

            $diskpartScript = @"
select disk $diskNumber
clean
convert mbr
create partition primary
active
format fs=fat32 quick
assign
exit
"@
            $dpPath = "$env:TEMP\diskpart.txt"
            $diskpartScript | Out-File -Encoding ASCII -FilePath $dpPath
            diskpart /s $dpPath 

            Add-LogRun "`n✅ Montando ISO..."
            $mount = Mount-DiskImage -ImagePath $isoPath -PassThru
            $isoDrive = ($mount | Get-Volume).DriveLetter + ":"

            $usbDrive = (Get-Disk -Number $diskNumber | Get-Partition | Get-Volume).DriveLetter + ":"

            # Crear carpeta sources en USB si no existe
            $sourcesUsbPath = Join-Path $usbDrive "sources"
            if (-not (Test-Path $sourcesUsbPath)) {
                New-Item -ItemType Directory -Path $sourcesUsbPath | Out-Null
            }

            # Rutas del install.wim y derivados en ISO
            $installWimPathISO = Join-Path $isoDrive "sources\install.wim"
            $installSwmPathISO = Join-Path $isoDrive "sources\install*.swm"

            # Comprobar si install.wim existe y es mayor a 4GB para dividir
            if (Test-Path $installWimPathISO) {
                $fileSize = (Get-Item $installWimPathISO).Length
                if ($fileSize -gt 4GB) {
                    Add-LogRun "`n✅ Archivo install.wim mayor a 4GB detectado."
                    Split-ImageFile -rutaCompleta $installWimPathISO -destino $sourcesUsbPath
                } else {
                    Add-LogRun "n❌ Archivo install.wim menor a 4GB, no es necesaria la división."
                    # Copiar install.wim normalmente después
                }
            }

            # Comprobar si hay archivos install*.swm en ISO y copiarlos después
            $swmFiles = Get-ChildItem -Path (Join-Path $isoDrive "sources") -Filter "install*.swm" -ErrorAction SilentlyContinue
            if ($swmFiles) {
                Add-LogRun "`n✅ Archivos install*.swm detectados en ISO, serán copiados después."
            }

            # Archivos a excluir en la copia inicial: grandes .wim y fragmentos .swm, también install.esd si se quiere excluir
            $exclusion = @("install.wim", "install*.swm", "install.esd", "__chunk_data")

            $exclusionString = $exclusion -join " "
            #Add-LogRun "Excluyendo archivos: $exclusionString"
            Add-LogRun "`n✅ Copiando archivos..."

            # Copiar todo excepto archivos grandes y fragmentos
            robocopy "$isoDrive\" "$usbDrive\" /E /NDL /NC /NS /NP /XF $exclusion > $null

            # Copiar install.wim si es menor a 4GB
            if (Test-Path $installWimPathISO) {
                $fileSize = (Get-Item $installWimPathISO).Length
                if ($fileSize -le 4GB) {
                    Add-LogRun "`n✅ Copiando archivo install.wim..."
                    Copy-Item -Path $installWimPathISO -Destination $sourcesUsbPath -Force
                }
            }

            # Copiar fragmentos .swm si existen
            if ($swmFiles) {
                Add-LogRun "`n✅ Copiando archivos install*.swm..."
                foreach ($file in $swmFiles) {
                    Copy-Item -Path $file.FullName -Destination $sourcesUsbPath -Force
                }
            }

            Add-LogRun "`n✅ Desmontando ISO..."
            Dismount-DiskImage -ImagePath $isoPath

            #Add-LogRun "📂 Verificando existencia de $sourcesUsbPath\boot.wim..."

            if (-Not (Test-Path (Join-Path $sourcesUsbPath "boot.wim"))) {
                Add-LogRun "`n❌ No se encontró boot.wim en $sourcesUsbPath"
                return
            }

            $bootWimPath = Join-Path $sourcesUsbPath "boot.wim"
            $bootTipo = ""
            $tempOut = "$env:TEMP\dism_output.txt"
            $urlBase = "http://181.57.227.194:8001/files/bootDrivers"

            Add-LogRun "`n🛠️ Ejecutando DISM sobre: $bootWimPath"
            # Ejecutar DISM y guardar la salida
            DISM /Get-WimInfo /WimFile:$bootWimPath /index:1 | Out-File -Encoding UTF8 $tempOut

            Start-Sleep -Seconds 2

            if (-Not (Test-Path $tempOut)) {
                Add-LogRun "`n❌ DISM no generó el archivo de salida: $tempOut"
                return
            }

            # Leer el contenido del archivo
            $contenido = Get-Content $tempOut -Encoding UTF8

            if ($contenido.Length -gt 0) {
                # Buscar la línea que contiene solo la versión (ignora líneas como "Compilación del Service Pack")
                $versionLine = $contenido | Where-Object {
                    ($_ -match '^\s*Versi[óo]n:\s*\d+\.\d+\.\d+\s*$') -or ($_ -match '^\s*Version:\s*\d+\.\d+\.\d+\s*$')
                }

                if ($versionLine -and $versionLine -match '(\d+\.\d+\.\d+)') {
                    $version = $Matches[1]
                    Add-LogRun "`n✅ Versión detectada del boot.wim: $version"

                    # Determinar URL según versión
					switch ($version) {
						# Windows 11
						"10.0.22000" { $bootUrl = "$urlBase/boot-win11.wim"; $bootTipo = "Windows 11"; break }
						"10.0.22621" { $bootUrl = "$urlBase/boot-win11.wim"; $bootTipo = "Windows 11"; break }
						"10.0.22631" { $bootUrl = "$urlBase/boot-win11.wim"; $bootTipo = "Windows 11"; break }
						"10.0.26100" { $bootUrl = "$urlBase/boot-win11.wim"; $bootTipo = "Windows 11"; break }

						# Windows 10
						"10.0.19041" { $bootUrl = "$urlBase/boot-win10.wim"; $bootTipo = "Windows 10"; break }
						"10.0.19042" { $bootUrl = "$urlBase/boot-win10.wim"; $bootTipo = "Windows 10"; break }
						"10.0.19043" { $bootUrl = "$urlBase/boot-win10.wim"; $bootTipo = "Windows 10"; break }
						"10.0.19044" { $bootUrl = "$urlBase/boot-win10.wim"; $bootTipo = "Windows 10"; break }
						"10.0.19045" { $bootUrl = "$urlBase/boot-win10.wim"; $bootTipo = "Windows 10"; break }

						Default {
							Add-LogLine "Versión no reconocida: $version. No se descargará boot.wim."
							return
						}
					}

                    # Reemplazar el archivo boot.wim
                    Add-LogRun "`n🔁 Se reemplazará el boot.wim con controladores NVMe para $bootTipo..."
                    Remove-Item $bootWimPath -Force -ErrorAction SilentlyContinue
                    try {
                        Invoke-WebRequest -Uri $bootUrl -OutFile $bootWimPath -UseBasicParsing
                        Add-LogRun "`n✅ boot.wim actualizado exitosamente con controladores NVMe para $bootTipo."
                    } catch {
                        Add-LogRun "`n❌ Error al descargar el nuevo boot.wim: $_"
                    }
                } else {
                    Add-LogRun "`n⚠ No se pudo extraer la versión del boot.wim. Se descargará nuevo archivo..."
                    $bootUrl = "$urlBase/boot-win10.wim"
                    try {
                        Invoke-WebRequest -Uri $bootUrl -OutFile $bootWimPath -UseBasicParsing
                        Add-LogRun "`n✅ boot.wim descargado exitosamente."
                    } catch {
                        Add-LogRun "`n❌ Error al descargar archivo predeterminado: $_"
                    }
                }
            } else {
                Add-LogRun "`n⚠ El archivo de salida DISM está vacío."
            }
			
			# Ruta del archivo ei.cfg
            $sourcesUsbPath = Join-Path $usbDrive "sources"
            $unattendDest = Join-Path $sourcesUsbPath "ei.cfg"

            Add-LogRun "`n🔧 Preparando ei.cfg..."

            # Verificar si existe el archivo
            if (Test-Path $unattendDest) {
                try {
                    # Quitar atributo de solo lectura
                    Set-ItemProperty -Path $unattendDest -Name IsReadOnly -Value $false
                    Add-LogRun "✅ Atributo de solo lectura removido de ei.cfg."
                } catch {
                    Add-LogRun "⚠️ No se pudo modificar los atributos de ei.cfg: $_"
                }
            }

# Contenido del nuevo ei.cfg
$eiContent = @"
[EditionID]

[Channel]
Retail

[VL]
1
"@

            # Intentar escribir el nuevo contenido
            try {
                $eiContent | Set-Content -Path $unattendDest -Encoding UTF8
                Add-LogRun "✅ ei.cfg reemplazado exitosamente."
            } catch {
                Add-LogRun "❌ Error al escribir ei.cfg: $_"
            }


            # Descargar unattend.xml desde GitHub
            $unattendUrl = "https://raw.githubusercontent.com/mggons93/OptimizeUpdate/refs/heads/main/Programs/autounattend.xml"
            $unattendDest = Join-Path $usbDrive "autounattend.xml"
            Add-LogRun "`n✅ Descargando unattend.xml desde GitHub..."
            try {
                Invoke-WebRequest -Uri $unattendUrl -OutFile $unattendDest -UseBasicParsing
                Add-LogRun "`n✅ unattend.xml descargado correctamente."
            } catch {
                Add-LogRun "`n❌ Error al descargar unattend.xml: $_"
            }


            Add-LogRun "`n✅ USB booteable creado con éxito."

        }
        catch {
            Add-LogRun "`n❌ ERROR: $_"
        }
        finally {
    $syncHash.Window.Dispatcher.Invoke([Action]{ $startBtn.IsEnabled = $true })
}
    }).AddArgument($diskNumber).AddArgument($isoPath).AddArgument($syncHash).AddArgument($startBtn)

    $async = $ps.BeginInvoke()
    Register-ObjectEvent -InputObject $ps -EventName "InvocationStateChanged" -Action {
        if ($ps.InvocationStateInfo.State -eq 'Completed' -or $ps.InvocationStateInfo.State -eq 'Failed' -or $ps.InvocationStateInfo.State -eq 'Stopped') {
            $startBtn.Dispatcher.Invoke([action]{ $startBtn.IsEnabled = $true })

            Unregister-Event -SourceIdentifier $_.SourceIdentifier
            $ps.Dispose()
            $runspace.Close()
            $runspace.Dispose()
        }

    }

})

$window.ShowDialog() | Out-Null
