function Juego {
    # Configurar variables globales para el renderizado
    $global:FOV = [math]::PI / 3  # FOV (60 degrees)
    $global:maxDepth = 64  # maxima distancia de raycasting
    # Caracteres de distancia a objetos
    $global:shading = @(
        ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ":", ":", ":", ":", "*", "*", "*", "*", "o", "$", "#"
    )

    # Caracter que representa la salida
    $exitChar = "`e"

    # Copia del mapa sin colores
    $global:map2 = ""

    $global:sleepTime = 5 # Milisegundos

    $Red    = "`e[31m"  # Color Rojo
    $Green  = "`e[32m"  # Color Verde
    $Yellow = "`e[33m"  # Color Amarillo
    $Blue   = "`e[34m"  # Color Azul
    $Reset  = "`e[0m"   # Reset

    # Modo de color
    $global:colorActive = $true

    # Modo debug
    $global:debugActive = $false

    # Modo de mapa
    $global:mapActive = $false

    # Menu principal
    function Main-Menu {
        while ($done -ne $true) {
            Clear-Host
            Write-Host "Controles:"
            Write-Host "`tW`tCaminar"
            Write-Host "`tA`tGirar izquierda"
            Write-Host "`tS`tCaminar atras"
            Write-Host "`tD`tGirar derechas"
            Write-Host "`tB`tAbrir Debug"
            Write-Host "`tM`tAbrir Mapa"
            Write-Host "`tC`tModo color (on/off)"
            Write-Host
            Write-Host "Selecciona las dimensiones del mapa:"
            Write-Host "`t1.`t8x8       (Prueba)"
            Write-Host "`t2.`t16x16     (Muy Facil)"
            Write-Host "`t3.`t32x32     (Facil)"
            Write-Host "`t4.`t64x64     (Medio)"
            Write-Host "`t5.`t128x128   (Dificil)"
            Write-Host "`t6.`t256x256   (Muy Dificil)"
            Write-Host "`t7.`t512x512   (Extremo)"
            Write-Host "`t8.`t1024x1024 (Pesadilla)"
            Write-Host "`t9.`tCustom"
            Write-Host "`t0.`tExit"
            Write-Host
            $choice = Read-Host "Selecciona una opcion (1, 2, 3...)"

            switch ($choice) {
                "1" {
                    $global:mapWidth  = 7
                    $global:mapHeight = 7
                    $done = $true
                }
                "2" {
                    $global:mapWidth  = 15
                    $global:mapHeight = 15
                    $done = $true
                }
                "3" {
                    $global:mapWidth  = 31
                    $global:mapHeight = 31
                    $done = $true
                }
                "4" {
                    $global:mapWidth  = 63
                    $global:mapHeight = 63
                    $done = $true
                }
                "5" {
                    $global:mapWidth  = 127
                    $global:mapHeight = 127
                    $done = $true
                }
                "6" {
                    $global:mapWidth  = 255
                    $global:mapHeight = 255
                    $done = $true
                }
                "7" {
                    $global:mapWidth  = 511
                    $global:mapHeight = 511
                    $done = $true
                }
                "8" {
                    $global:mapWidth  = 1023
                    $global:mapHeight = 1023
                    $done = $true
                }
                "9" {
                    [int]$inputWidth  = Read-Host "Seleccionar ancho (Tiene que ser potencia de 2)"
                    if (($inputWidth -gt 0) -and (($inputWidth -band ($inputWidth - 1)) -eq 0)) {
                        if ($inputWidth -ge 8) {
                            $global:mapWidth = $inputWidth - 1
                        } else {
                            Write-Host "$Red[!] Las dimensiones minimas son 8x8$Reset"
                            Pause
                            Main-Menu
                        }
                    } else {
                        Write-Host "$Red[!] Tiene que ser potencia de 2$Reset"
                        Pause
                        Main-Menu
                    }
                    
                    [int]$inputHeight = Read-Host "Seleccionar altura (Tiene que ser potencia de 2)"
                    if (($inputHeight -gt 0) -and (($inputHeight -band ($inputHeight - 1)) -eq 0)) {
                        if ($inputHeight -ge 8) {
                            $global:mapHeight = $inputHeight - 1
                        } else {
                            Write-Host "$Red[!] Las dimensiones minimas son 8x8$Reset"
                            Pause
                            Main-Menu
                        }
                    } else {
                        Write-Host "$Red[!] Tiene que ser potencia de 2$Reset"
                        Pause
                        Main-Menu
                    }
                    $done = $true
                }
                "0" {
                    Exit
                }
                default {
                    Write-Host "$Red[!] Opcion invalida$Reset"
                    pause
                }
            }
        }
    }

    Main-Menu

    function Generate-Maze {
        param(
            [int]$width,  # Mantener impar y potencia de 2
            [int]$height
        )

        Write-Host "$Green[+] Generando mapa...$Reset"
        Write-Host "Generando canvas..."

        if ($width % 2 -eq 0) { $width++ }
        if ($height % 2 -eq 0) { $height++ }

        $maze = @()
        for ($y = 0; $y -lt $height; $y++) {
            $maze += ("#" * $width)
        }

        function Carve-Maze {
            param($x, $y)

            $directions = @( [array]@(2,0), [array]@(0,2), [array]@(-2,0), [array]@(0,-2) ) | Sort-Object { Get-Random }

            foreach ($dir in $directions) {
                $nx = $x + $dir[0]
                $ny = $y + $dir[1]

                if ($nx -gt 0 -and $ny -gt 0 -and $nx -lt ($width - 1) -and $ny -lt ($height - 1) -and $maze[$ny][$nx] -eq "#") {
                    $maze[$y] = $maze[$y].Substring(0, $x) + " " + $maze[$y].Substring($x + 1)
                    $maze[$ny] = $maze[$ny].Substring(0, $nx) + " " + $maze[$ny].Substring($nx + 1)

                    $wx = $x + ($dir[0] / 2)
                    $wy = $y + ($dir[1] / 2)
                    $maze[$wy] = $maze[$wy].Substring(0, $wx) + " " + $maze[$wy].Substring($wx + 1)

                    Carve-Maze -x $nx -y $ny
                }
            }
        }

        $startX = [math]::Floor($width / 2)
        $startY = [math]::Floor($height / 2)
        Write-Host "Escabando caminos"
        Carve-Maze -x $startX -y $startY

        function Place-Exit {
            Write-Host "Creando salida"
            $exitX = $width - 1  
            $exitY = $height - 2

            $rowChars = $maze[$exitY].ToCharArray()
            $rowChars[$exitX] = "E"
            $maze[$exitY] = -join $rowChars

            $global:map2 = $maze

            return $maze -replace 'E', "$red`E$reset"
        }

        # Eliminar 1/6 paredes aleatorias (que no sean externas)
        Write-Host "Eliminando paredes aleatorias"
        for ($y = 1; $y -lt $height - 1; $y++) {
            for ($x = 1; $x -lt $width - 1; $x++) {
                if ($maze[$y][$x] -eq "#" -and (Get-Random -Minimum 1 -Maximum 7) -eq 1) {
                    $maze[$y] = $maze[$y].Substring(0, $x) + " " + $maze[$y].Substring($x + 1)
                }
            }
        }

        $maze = Place-Exit

        return $maze
    }

    # Generando el camino
    $global:map = Generate-Maze -width $global:mapWidth -height $global:mapHeight

    # Variables globales para la posicion y angulo
    Write-Host "$Green[+] Calculando posicion inicial...$Reset"
    $global:playerX = $global:mapWidth / 2
    $global:playerY = $global:mapHeight / 2

    # Funcion para calcular el angulo a un punto (x, y)
    function Calculate-Angle {
        param ($targetX, $targetY)

        Write-Host "Calculando angulo"
        
        # Calcular el angulo del jugador al punto (en radianes)
        $angle = [math]::Atan2($targetY - $global:playerY, $targetX - $global:playerX)

        return $angle
    }

    # Funcion para calcular el angulo en puntos cardinales (arriba, derecha, abajo, izquierda)
    function Find-InitialAngle {
        # offsets de direcciones cardinales (arriba, derecha, abajo, izquierda)
        $directions = @(
            [array]@(1, 0),  # Derecha
            [array]@(0, 1),  # Abajo
            [array]@(-1, 0), # Izquierda
            [array]@(0, -1)  # Arriba
        )

        Write-Host "$Green[+] Calculando angulo inicial...$Reset"

        # Buscar el primer espacio vacio en sentido horario de la posicion del jugador
        foreach ($dir in $directions) {
            $testX = $global:playerX + $dir[0]
            $testY = $global:playerY + $dir[1]
            Write-Host "Comprobando posicion: $([math]::Floor($testX)), $([math]::Floor($testY)) - Valor: $($global:map[[math]::Floor($testY)][[math]::Floor($testX)])"

            if ($testX -ge 0 -and $testX -lt $global:mapWidth -and $testY -ge 0 -and $testY -lt $global:mapHeight) {
                if ($global:map[[math]::Floor($testY)][[math]::Floor($testX)] -eq " ") {
                    # Se encontro un espacio vacio, calcular el angulo del jugador a este
                    Write-Host "Se encontro un espacio en $([math]::Floor($testX)), $([math]::Floor($testY))"
                    
                    $angle = Calculate-Angle -targetX $testX -targetY $testY
                    Write-Host "Angulo inicial: $angle"
                    return $angle
                }
            }
        }

        # No se ha encontrado ningun espacio vacio, regenerar el mapa (en caso de error)
        Write-Host "$Red[!] No se ha encontrado ningun espacio, Regenerando mapa...$Reset"
        $map = Generate-Maze -width $global:mapWidth -height $global:mapHeight
        Find-InitialAngle
    }

    # Definir el angulo inicial del jugador
    $global:playerAngle = Find-InitialAngle

    # Conseguir el tama駉 de la terminal actual
    function Get-TerminalSize {
        $terminalHeight = $Host.UI.RawUI.WindowSize.Height
        if ($global:mapActive -eq $true) {
            $mapLength = $global:map.Length
            return @{
                Width  = $Host.UI.RawUI.WindowSize.Width
                Height = $terminalHeight - $mapLength - 1 - $debugActive
            }
        } else {
            return @{
                Width  = $Host.UI.RawUI.WindowSize.Width
                Height = $terminalHeight - 1 - $debugActive
            }
        }
    }

    # Funcion para renderizar los frames del juego, minimapa...
    function Render-Frame {
        # Definir tama駉 de la terminal
        $terminalSize = Get-TerminalSize
        $screenWidth = $terminalSize.Width
        $screenHeight = $terminalSize.Height

        $frame = @()

        if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
            for ($x = 0; $x -lt $screenWidth; $x++) {
                # Calcular rayos basados en el FOV y tama駉 de la pantalla
                $rayAngle = ($global:playerAngle - $global:FOV / 2) + ($x / $screenWidth) * $global:FOV

                # Direccion de los rayos
                $rayDirX = [math]::Cos($rayAngle)
                $rayDirY = [math]::Sin($rayAngle)

                # Posicion actual del jugador
                $mapX = [math]::Floor($global:playerX)
                $mapY = [math]::Floor($global:playerY)

                # Length of ray from one x-side to next x-side
                $deltaDistX = [math]::Abs(1 / $rayDirX)
                $deltaDistY = [math]::Abs(1 / $rayDirY)

                # Step (+1 o -1) y distancia inicial
                if ($rayDirX -lt 0) {
                    $stepX = -1
                    $sideDistX = ($global:playerX - $mapX) * $deltaDistX
                } else {
                    $stepX = 1
                    $sideDistX = ($mapX + 1 - $global:playerX) * $deltaDistX
                }

                if ($rayDirY -lt 0) {
                    $stepY = -1
                    $sideDistY = ($global:playerY - $mapY) * $deltaDistY
                } else {
                    $stepY = 1
                    $sideDistY = ($mapY + 1 - $global:playerY) * $deltaDistY
                }

                # DDA stepping
                $hit = $false
                $side = 0  # 0 X-side, 1 Y-side

                while (-not $hit -and $mapX -ge 0 -and $mapX -lt $global:mapWidth -and $mapY -ge 0 -and $mapY -lt $global:mapHeight) {
                    # Step en X o Y
                    if ($sideDistX -lt $sideDistY) {
                        $sideDistX += $deltaDistX
                        $mapX += $stepX
                        $side = 0
                    } else {
                        $sideDistY += $deltaDistY
                        $mapY += $stepY
                        $side = 1
                    }

                    # Comprobar si el rayo toco una pared
                    if ($global:map[$mapY][$mapX] -eq "#") {
                        $hit = $true
                    }
                }

                # Calcular distancia a una pared
                if ($side -eq 0) {
                    $distance = ($mapX - $global:playerX + (1 - $stepX) / 2) / $rayDirX
                } else {
                    $distance = ($mapY - $global:playerY + (1 - $stepY) / 2) / $rayDirY
                }

                # Shading inverso
                $shadingScale = ($shading.Length - 1) / $global:maxDepth
                $shadeIndex = [math]::Min([math]::Floor(($global:maxDepth - $distance) * $shadingScale), $shading.Length - 1)
                $wallChar = if ($hit) { $shading[$shadeIndex] } else { " " }

                # Calcular altura de las paredes
                $wallHeight = [math]::Floor($screenHeight / $distance / 1.2)

                # Crear columna vacia
                $column = @(" " * $screenHeight) -split ""

                # Sobreescribir la columna con los caracteres de la pared
                for ($y = 0; $y -lt $screenHeight; $y++) {
                    if ($y -gt ($screenHeight / 2 - $wallHeight) -and $y -lt ($screenHeight / 2 + $wallHeight)) {
                        $column[$y] = $wallChar
                    }
                }

                # A馻dir la columna al proximo frame
                $frame += ($column -join "")
            }

            # Renderizar el frame
            $renderOutput = New-Object System.Text.StringBuilder
            for ($y = 0; $y -lt $screenHeight; $y++) {
                for ($x = 0; $x -lt $screenWidth; $x++) {
                    $renderOutput.Append($frame[$x][$y]) > $null
                }
                $renderOutput.Append("`n") > $null
            }
        }
        
        # Borrar frame anterior
        Clear-Host

        # Mostrar el nuevo frame
        if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
            [System.Console]::Write($renderOutput.ToString())
        }

        # Mostrar informacion de Debug debajo del juego
        if ($debugActive -eq $true) {
            Write-Host "Player Position: X = $([math]::Round($global:playerX, 2)), Y = $([math]::Round($global:playerY, 2)), Angle = $([math]::Round($global:playerAngle, 2))"
        }

        function Get-PlayerArrow {
            # Normalizar el angulo entre 0 y PI
            $normalizedAngle = $global:playerAngle % (2 * [math]::PI)

            # Si el angulo es negativo a馻dir PI para hacerlo positivo
            if ($normalizedAngle -lt 0) {
                $normalizedAngle += 2 * [math]::PI
            }

            # Comprobar si el jugador esta mirando arriba, izquierda, abajo o derecha (Agujas del reloj)
            if (($normalizedAngle -lt [math]::PI / 4) -or ($normalizedAngle -ge 7 * [math]::PI / 4)) {
                return ">"  # Mirando a la derecha (0 a PI/4 o 7PI/4 a 2PI)
            } elseif ($normalizedAngle -ge [math]::PI / 4 -and $normalizedAngle -lt 3 * [math]::PI / 4) {
                return "v"  # Mirando hacia abajo (PI/4 a 3PI/4)
            } elseif ($normalizedAngle -ge 3 * [math]::PI / 4 -and $normalizedAngle -lt 5 * [math]::PI / 4) {
                return "<"  # Mirando a la izquierda (3PI/4 a 5PI/4)
            } else {
                return "^"  # Mirando hacia arriba (5PI/4 a 7PI/4)
            }
        }

        if ($global:mapActive -eq $true) {
            # Mostrar mapa y direccion del jugador
            for ($y = 0; $y -lt $global:map.Length; $y++) {
                if ($colorActive) {
                    $row = $global:map[$y]
                } else {
                    $row = $global:map2[$y]
                }

                # Marcar la posicion del jugador con las flechas segun hacia donde apunte
                $mapRow = ""
                for ($x = 0; $x -lt $row.Length; $x++) {
                    if ($y -eq [math]::Floor($global:playerY) -and $x -eq [math]::Floor($global:playerX)) {
                        # Reemplazar "P" con la flecha del angulo del jugador
                        $arrow = Get-PlayerArrow
                        $mapRow += "$green$arrow$reset"
                    } else {
                        $mapRow += $row[$x]
                    }
                }

                Write-Host $mapRow
            }
        }

        if ($mapActive -and $screenHeight -lt 0 -or $screenWidth -lt 0) {
            Write-Host "$Red[!] No hay espacio suficiente. Desactiva el mapa, Minimiza el zoom o haz la pantalla mas grande para renderizar el juego.$Reset"
        }
    }

    # Mover al jugador y comprobar paredes (fisicas)
    function Move-Player {
        param($direction)
        $moveSpeed = 0.2  # Velocidad de movimiento
        $turnSpeed = [math]::PI / 16  # Velocidad de giro (angulo)
        $collisionBuffer = 0.3  # Buffer para prevenir atravesar paredes

        # Calcular posible nueva posicion
        $newX = $global:playerX
        $newY = $global:playerY

        if ($direction -eq "W") {
            # Mover hacia delante
            $newX += [math]::Cos($global:playerAngle) * $moveSpeed
            $newY += [math]::Sin($global:playerAngle) * $moveSpeed
        } elseif ($direction -eq "S") {
            # Mover hacia atras
            $newX -= [math]::Cos($global:playerAngle) * $moveSpeed
            $newY -= [math]::Sin($global:playerAngle) * $moveSpeed
        } elseif ($direction -eq "A") {
            # Girar a la izquierda
            $global:playerAngle -= $turnSpeed
            return  # No es necesario comprobar fisicas
        } elseif ($direction -eq "D") {
            # Girar a la derecha
            $global:playerAngle += $turnSpeed
            return  # No es necesario comprobar fisicas
        }

        # Comprobar si hay colision entre la posible posicion y una pared
        $floorX = [math]::Floor($newX)
        $floorY = [math]::Floor($global:playerY)  # Mantener Y

        if ($global:map[$floorY][$floorX] -ne "#") {
            $global:playerX = $newX  # Mover X si no hay colisiones
        }

        # Comprobar colisiones Y
        $floorX = [math]::Floor($global:playerX)  # Mantener X (Anteriormente calculado)
        $floorY = [math]::Floor($newY)

        if ($global:map[$floorY][$floorX] -ne "#") {
            $global:playerY = $newY  # Mover Y si no hay colisiones
        }
    }

    # Comenzar un temporizador para puntos
    Write-Host "$Green[+] Temporizador iniciado$Reset"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host "$Green[+] Juego listo$Reset"

    # Bucle del juego
    $done = $false
    while (-not $done) {
        # Renderizar el frame
        Render-Frame

        # Comprobar si el jugador ha llegado a la salida
        $floorX = [math]::Floor($global:playerX)
        $floorY = [math]::Floor($global:playerY)
        if ($global:map[$floorY][$floorX] -eq $exitChar) {
            Clear-Host
            $stopwatch.Stop()
            $timeTaken = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            Write-Host "Has ganado! Tiempo: $timeTaken segundos" -ForegroundColor Green
            Pause
            break
        }

        # Leer teclas para mover al jugador y otras acciones
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

        switch -wildcard ($key) {
            '[WASDwasd]' { Move-Player -direction $key }
            '[Mm]'       { $global:mapActive = -not $global:mapActive }
            '[Bb]'       { $global:debugActive = -not $global:debugActive }
            '[Qq]' {
                Clear-Host
                Write-Host "`n$Green[+] Saliendo del juego...$Reset"
                $done = $true
            }
            '[Cc]' {
                $global:colorActive = -not $global:colorActive
                if ($global:colorActive) {
                    $Red    = "`e[31m"
                    $Green  = "`e[32m"
                    $Yellow = '`e[33m'
                    $Blue   = "`e[34m"
                    $Reset  = "`e[0m"
                } elseif (-not $global:colorActive) {
                    $Red    = ""
                    $Green  = ""
                    $Yellow = ""
                    $Blue   = ""
                    $Reset  = ""
                }
            }
        }

        # Paralizar ejecucion durante un tiempo para mejorar jugabilidad
        Start-Sleep -Milliseconds $global:sleepTime
    }
}

# Proyecto 02 ARCHIVOS: Sistemas Operativos en Red
# Sergio Barroso Ceballos

function Archivos {
    # Men煤 opci贸n 1: Crear Directorio
    # Crear谩 un directorio con el nombre introducido en la ruta actual
    function New-Dir {
        # Pregunta al usuario el nombre del directorio
        [string] $DirName = Read-Host "Nombre del directorio"
        
        Write-Host

        # Si ya existe un directorio con este nombre avisar de ello
        if (Test-Path -Path $DirName -PathType Container) {
            Write-Host "Un directorio con el nombre $DirName YA existe"
        }
        # Si ya existe un archivo con este nombre avisar de ello
        elseif (Test-Path -Path $DirName -PathType Leaf) {
            Write-Host "Un archivo con el nombre $DirName YA existe"
        }
        # En otro caso crear el nuevo directorio
        else {
            New-Item -ItemType Directory -Path $DirName
            Write-Host
            Write-Host "Se ha creado el directorio $DirName"
        }
    }

    # Men煤 opci贸n 2: Borrar Directorio
    # Borrar谩 el directorio con el nombre introducido en la ruta actual
    function Del-Dir {
        # Pregunta al usuario el nombre del directorio
        [string] $DirName = Read-Host "Nombre del directorio"
        
        Write-Host

        # Si existe el directorio lo borramos
        if (Test-Path -Path $DirName -PathType Container) {
            Remove-Item -Path $DirName -Recurse -Force
            Write-Host
            Write-Host "Se ha borrado el directorio $DirName"
        }
        # Si el nombre ya pertenece a un archivo avisamos de ello
        elseif (Test-Path -Path $DirName -PathType Leaf) {
            Write-Host "$DirName es un archivo, no un directorio"
        }
        # En otro caso avisamos de que NO existe
        else {
            Write-Host "El directorio $DirName NO existe"
        }
    }

    # Opci贸n 3: Listar Directorio
    # Listar谩 todos los directorios bajo la ruta actual
    function List-Dir {
        Get-ChildItem -Directory
    }

    # Opci贸n 4: Crear Archivo
    # Crear谩 un archivo con el nombre introducido en la ruta actual
    function New-File {
        # Pregunta al usuario el nombre del archivo
        [string] $FileName = Read-Host "Nombre del archivo"

        Write-Host
        
        # Si ya existe un directorio con este nombre avisar de ello
        if (Test-Path -Path $FileName -PathType Container) {
            Write-Host "Un directorio con el nombre $FileName YA existe"
        }
        # Si ya existe un arhchivo con este nombre avisar de ello
        elseif (Test-Path -Path $FileName -PathType Leaf) {
            Write-Host "Un archivo con el nombre $FileName YA existe"
        }
        # En otro caso creamos el archivo
        else {
            New-Item -ItemType File -Path $FileName
            Write-Host
            Write-Host "Se ha creado el archivo $FileName"
        }
    }

    # Opci贸n 5: Borrar Archivo
    # Borrar谩 el archivo con el nombre introducido en la ruta actual
    function Del-File {
        # Pregunta al usuario el nombre del archivo
        [string] $FileName = Read-Host "Nombre del archivo"

        Write-Host

        # Si el archivo existe lo borramos
        if (Test-Path -Path $FileName -PathType Leaf) {
            Remove-Item -Path $FileName -Force
            Write-Host "Se ha borrado el archivo $FileName"
        }
        # Si el nombre pertenece a un directorio y no a un archivo avisamos de ello
        elseif (Test-Path -Path $FileName -PathType Container) {
            Write-Host "$FileName es un directorio, no un archivo"
        }
        # En otro caso avisamos que NO existe
        else {
            Write-Host "El archivo $FileName NO existe"
        }
    }

    # Opci贸n 6: Mostrar Archivo
    # Mostrar谩 el contenido de el archivo con el nombre introducido en la ruta actual
    function Read-File {
        # Pregunta al usuario el nombre del archivo
        [string] $FileName = Read-Host "Nombre del archivo"

        Write-Host

        # Si el archivo existe mostramos su contenido
        if (Test-Path -Path $FileName -PathType Leaf) {
            Get-Content -Path $FileName
        }
        # Si es un directorio y no un archivo, avisar de ello
        elseif (Test-Path -Path $FileName -PathType Container) {
            Write-Host "$FileName es un directorio, no un archivo"
        }
        # En otro caso avisamos que el archivo NO existe
        else {
            Write-Host "El archivo $FileName NO existe"
        }
    }

    # Definimos la variable para asegurarnos que no se recicla de el entorno
    [string] $menuinput = 0

    # Creamos un bucle mientras que no se pulse la opci贸n 7
    while ($menuinput -ne 7) {
        # Borramos la pantalla
        cls

        # Mostramos el Men煤
        Write-Host "#####################"
        Write-Host "##  MENU ARCHIVOS  ##"
        Write-Host "#####################"
        Write-Host "  1. Crear directorio"
        Write-Host "  2. Borrar directorio"
        Write-Host "  3. Listar directorios"
        Write-Host "  4. Crear archivo"
        Write-Host "  5. Borrar archivo"
        Write-Host "  6. Mostrar archivo"
        Write-Host "  7. Salir"
        Write-Host "-----------------------"

        # Recogemos la opci贸n elegida
        [string] $menuinput = Read-Host " Elija una opci贸n"

        Write-Host

        # LLamamos a las funciones respectivas seg煤n la opci贸n
        switch ($menuinput) {
            1 {New-Dir}
            2 {Del-Dir}
            3 {List-Dir}
            4 {New-File}
            5 {Del-File}
            6 {Read-File}
            
            # En caso de introducir otra opci贸n no definida avisar de esto
            default {
                Write-Host "Opci贸n" $menuinput "invalida"
            }
        }

        # Esperar a que el usuario pulse enter para volver al men煤
        Write-Host
        Read-Host "Pulse enter para continuar"
    }
}

function Cuentas-AD {
    ####  Script Active Directory  #### 
    ## Sergio Barroso Ceballos

    # Funcion para mostrar el menu principal
    function MostrarMenuPrincipal {
        Clear-Host
        Write-Host "######################"
        Write-Host "##  MENU PRINCIPAL  ##"
        Write-Host "######################"
        Write-Host "  1. - Gestion de Usuarios"
        Write-Host "  2. - Gestion de Equipos"
        Write-Host "  3. - Gestion de Grupos"
        Write-Host "  4. - Salir del Programa"
        Write-Host
        return (Read-Host "Selecciona una opcion")
    }

    # Funcion para mostrar el menu de usuarios
    function MenuUsuarios {
        Clear-Host
        Write-Host "########################"
        Write-Host "##  MENU DE USUARIOS  ##"
        Write-Host "########################"
        Write-Host "  crear  - Crear Usuario"
        Write-Host "  borrar - Eliminar Usuario"
        Write-Host "  info   - Ver Informacion de Usuario"
        Write-Host "  volver - Volver al Menu Principal"
        Write-Host
        return (Read-Host "Selecciona una opcion")
    }

    # Funcion para mostrar el menu de equipos
    function MenuEquipos {
        Clear-Host
        Write-Host "#######################"
        Write-Host "##  MENU DE EQUIPOS  ##"
        Write-Host "#######################"
        Write-Host "  crear  - Crear Equipo"
        Write-Host "  borrar - Eliminar Equipo"
        Write-Host "  info   - Ver Informacion de Equipo"
        Write-Host "  volver - Volver al Menu Principal"
        Write-Host
        return (Read-Host "Selecciona una opcion")
    }

    # Funcion para mostrar el menu de grupos
    function MenuGrupos {
        Clear-Host
        Write-Host "######################"
        Write-Host "##  MENU DE GRUPOS  ##"
        Write-Host "######################"
        Write-Host "  crear  - Crear Grupo"
        Write-Host "  borrar - Eliminar Grupo"
        Write-Host "  info   - Ver Informacion de Grupo"
        Write-Host "  volver - Volver al Menu Principal"
        Write-Host
        return (Read-Host "Selecciona una opcion")
    }

    # Funcion para crear un usuario
    function CrearUsuario {
        $nombreUsuario = Read-Host "Introduce el nombre del usuario a crear"
        if (Get-ADUser -Filter { Name -eq $nombreUsuario }) {
            Write-Host "El usuario '$nombreUsuario' ya existe." -ForegroundColor Yellow
        } else {
            New-ADUser -Name $nombreUsuario
            Write-Host "El usuario '$nombreUsuario' ha sido creado correctamente." -ForegroundColor Green
        }
    }

    # Funcion para eliminar un usuario
    function EliminarUsuario {
        $nombreUsuario = Read-Host "Introduce el nombre del usuario a eliminar"
        $usuario = Get-ADUser -Filter { SamAccountName -eq $nombreUsuario }

        if ($usuario) {
            Remove-ADUser -Identity $usuario.SamAccountName -Confirm:$false
            Write-Host "El usuario '$nombreUsuario' ha sido eliminado." -ForegroundColor Green
        } else {
            Write-Host "El usuario '$nombreUsuario' no existe." -ForegroundColor Red
        }
    }

    # Funcion para obtener informacion de un usuario
    function InformacionUsuario {
        $nombreUsuario = Read-Host "Introduce el nombre del usuario"
        $usuario = Get-ADUser -Filter { SamAccountName -eq $nombreUsuario } -Properties *

        if ($usuario) {
            Write-Host "===== Informacion del Usuario =====" -ForegroundColor Cyan
            Write-Host "  Nombre Completo: $($usuario.Name)"
            Write-Host "  Nombre de Inicio de Sesion: $($usuario.SamAccountName)"
            Write-Host "  Correo Electronico: $($usuario.UserPrincipalName)"
            Write-Host "  Estado: $($usuario.Enabled)"
            Write-Host "  Creado el: $($usuario.WhenCreated)"
            Write-Host "  ultimo Cambio de Contrase帽a: $($usuario.PasswordLastSet)"
        } else {
            Write-Host "El usuario '$nombreUsuario' no existe." -ForegroundColor Red
        }
    }

    # Funcion para crear un equipo
    function CrearEquipo {
        $nombreEquipo = Read-Host "Introduce el nombre del equipo"
        if (Get-ADComputer -Filter { Name -eq $nombreEquipo }) {
            Write-Host "El equipo '$nombreEquipo' ya existe." -ForegroundColor Yellow
        } else {
            New-ADComputer -Name $nombreEquipo
            Write-Host "El equipo '$nombreEquipo' ha sido creado correctamente." -ForegroundColor Green
        }
    }

    # Funcion para eliminar un equipo
    function EliminarEquipo {
        $nombreEquipo = Read-Host "Introduce el nombre del equipo a eliminar"
        $equipo = Get-ADComputer -Filter { Name -eq $nombreEquipo }

        if ($equipo) {
            Remove-ADObject -Identity $equipo.DistinguishedName -Confirm:$false
            Write-Host "El equipo '$nombreEquipo' ha sido eliminado." -ForegroundColor Green
        } else {
            Write-Host "El equipo '$nombreEquipo' no existe." -ForegroundColor Red
        }
    }

    # Funcion para obtener informacion de un equipo
    function InformacionEquipo {
        $nombreEquipo = Read-Host "Introduce el nombre del equipo"
        $equipo = Get-ADComputer -Filter { Name -eq $nombreEquipo } -Properties *

        if ($equipo) {
            Write-Host "===== Informacion del Equipo =====" -ForegroundColor Cyan
            Write-Host "  Nombre: $($equipo.Name)"
            Write-Host "  Descripcion: $($equipo.Description)"
            Write-Host "  Distinguished Name: $($equipo.DistinguishedName)"
        } else {
            Write-Host "El equipo '$nombreEquipo' no existe." -ForegroundColor Red
        }
    }

    # Funcion para crear un grupo
    function CrearGrupo {
        $nombreGrupo = Read-Host "Introduce el nombre del grupo"
        if (Get-ADGroup -Filter { Name -eq $nombreGrupo }) {
            Write-Host "El grupo '$nombreGrupo' ya existe." -ForegroundColor Yellow
        } else {
            New-ADGroup -Name $nombreGrupo -GroupScope Global -GroupCategory Security
            Write-Host "El grupo '$nombreGrupo' ha sido creado correctamente." -ForegroundColor Green
        }
    }

    # Funcion para eliminar un grupo
    function EliminarGrupo {
        $nombreGrupo = Read-Host "Introduce el nombre del grupo a eliminar"
        $grupo = Get-ADGroup -Filter { Name -eq $nombreGrupo }

        if ($grupo) {
            Remove-ADObject -Identity $grupo.DistinguishedName -Confirm:$false
            Write-Host "El grupo '$nombreGrupo' ha sido eliminado." -ForegroundColor Green
        } else {
            Write-Host "El grupo '$nombreGrupo' no existe." -ForegroundColor Red
        }
    }

    # Funcion para obtener informacion de un grupo
    function InformacionGrupo {
        $nombreGrupo = Read-Host "Introduce el nombre del grupo"
        $grupo = Get-ADGroup -Filter { Name -eq $nombreGrupo } -Properties *

        if ($grupo) {
            Write-Host "===== Informacion del Grupo =====" -ForegroundColor Cyan
            Write-Host "  Nombre: $($grupo.Name)"
            Write-Host "  Descripcion: $($grupo.Description)"
            Write-Host "  Miembros: $($grupo.Member | Out-String)"
        } else {
            Write-Host "El grupo '$nombreGrupo' no existe." -ForegroundColor Red
        }
    }

    # Ejecucion del menu principal
    while ($opcionPrincipal -ne "4") {
        $opcionPrincipal = MostrarMenuPrincipal

        $cont = $true
        switch ($opcionPrincipal) {
            "1" {
                while ($cont) {
                    $opcionUsuario = MenuUsuarios
                    switch ($opcionUsuario) {
                        "crear"  { CrearUsuario       ; Pause }
                        "borrar" { EliminarUsuario    ; Pause }
                        "info"   { InformacionUsuario ; Pause }
                        "volver" { $cont = $false }
                        default  { Write-Host "Opcion no valida." -ForegroundColor Red; Pause }
                    }
                }
            }
            "2" {
                while ($cont) {
                    $opcionEquipo = MenuEquipos
                    switch ($opcionEquipo) {
                        "crear"  { CrearEquipo       ; Pause }
                        "borrar" { EliminarEquipo    ; Pause }
                        "info"   { InformacionEquipo ; Pause }
                        "volver" { $cont = $false }
                        default  { Write-Host "Opcion no valida." -ForegroundColor Red; Pause }
                    }
                }
            }
            "3" {
                while ($cont) {
                    $opcionGrupo = MenuGrupos
                    switch ($opcionGrupo) {
                        "crear"  { CrearGrupo       ; Pause }
                        "borrar" { EliminarGrupo    ; Pause }
                        "info"   { InformacionGrupo ; Pause }
                        "volver" { $cont = $false }
                        default  { Write-Host "Opcion no valida." -ForegroundColor Red; Pause }
                    }
                }
            }
            default {
                if ($opcionPrincipal -ne "4") {
                    Write-Host "Opcion no valida. Por favor selecciona una opcion valida." -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "Saliendo del programa..."
    Pause
}

function Recursos-Compartidos {
    function Menu-Recursos {
        $done = $false
        while (-not $done) {
            Clear-Host
            Write-Host "#################################"
            Write-Host "##  Menu Recursos Compartidos  ##"
            Write-Host "#################################"
            Write-Host "  1. -  Crear Carpeta Compartida"
            Write-Host "  2. -  Borrar Carpeta Compartida"
            Write-Host "  3. -  Modificar Carpeta Compartida"
            Write-Host "  4. -  Ver Carpeta Compartida"
            Write-Host "  5. -  Salir"
            Write-Host
            $opcion = Read-Host "Introduce una opcion"

            switch ($opcion) {
                "1" {
                    Crear-RecursoCompartido
                }
                "2" {
                    Borrar-RecursoCompartido
                }
                "3" {
                    Modificar-RecursoCompartido
                }
                "4" {
                    Ver-RecursoCompartido
                }
                "5" {
                    $done = $true
                }
                default {
                    Write-Host "Has introducido una opcion invalida"
                    Pause
                }
            }
        }
    }

    function Crear-RecursoCompartido {
        $ruta = Read-Host "Dame una ruta para la carpeta"
        if (-not (Test-Path -Path $ruta -PathType Container)) {
            Write-Host "La ruta especificada no existe"
            Pause
            return 1
        }

        $nombre = Read-Host "Dame el nombre del recurso compartido"
        if (Get-SmbShare -Name $nombre -ErrorAction SilentlyContinue) {
            Write-Host "Ya existe un recurso compartido con ese nombre"
            Pause
            return 1
        }

        $usuario = Read-Host "Dame un nombre de usuario"
        if (-not (Get-ADUser -Filter { Name -eq $usuario })) {
            if ((Get-ADGroup -Filter { Name -eq $usuario })) {
                Write-Host "El grupo especificado no existe"
                Pause
                return 1
            }
            Write-Host "El usuario especificado no existe"
            Pause
            return 1
        }

        New-SmbShare -Name $nombre -Path $ruta -FullAccess $usuario
        Write-Host "Se ha creado la carpeta compartida"
        Pause
    }

    function Borrar-RecursoCompartido {
        $nombre = Read-Host "Dame el nombre del recurso compartido"
        if (-not (Get-SmbShare -Name $nombre -ErrorAction SilentlyContinue)) {
            Write-Host "No existe un recurso compartido con ese nombre"
            Pause
            return 1
        }

        Remove-SmbShare -Name $nombre
        Write-Host "Se ha borrado la carpeta especificada"
        Pause
    }

    function Modificar-RecursoCompartido {
        $nombre = Read-Host "Dame el nombre del recurso compartido"
        if (-not (Get-SmbShare -Name $nombre -ErrorAction SilentlyContinue)) {
            Write-Host "No existe un recurso compartido con ese nombre"
            Pause
            return 1
        }

        $usuario = Read-Host "Dame un nombre de usuario"
        if (-not (Get-ADUser -Filter { Name -eq $usuario })) {
            if ((Get-ADGroup -Filter { Name -eq $usuario })) {
                Write-Host "El grupo especificado no existe"
                Pause
                return 1
            }
            Write-Host "El usuario especificado no existe"
            Pause
            return 1
        }

        $permiso = Read-Host "Que permisos conceder (lectura, escritura o todo)"

        switch ($permiso) {
            "lectura" {
                Grant-SmbShareAccess -Name $nombre -AccountName $usuario -AccessRight Read 
            }
            "escritura" {
                Grant-SmbShareAccess -Name $nombre -AccountName $usuario -AccessRight Change
            }
            "todo" {
                Grant-SmbShareAccess -Name $nombre -AccountName $usuario -AccessRight Full
            }
            default {
                Write-Host "No existe ese permiso, usa lectura, escritura o todo"
                Pause
                return 1
            }
        }

        Write-Host "Se ha concedido el permiso"
        Pause
    }

    function Ver-RecursoCompartido {
        $nombre = Read-Host "Dame el nombre del recurso compartido"
        if (-not (Get-SmbShare -Name $nombre -ErrorAction SilentlyContinue)) {
            Write-Host "No existe un recurso compartido con ese nombre"
            Pause
            return 1
        }

        Get-SmbShareAccess -Name $nombre
        Write-Host
        Pause
    }

    Menu-Recursos
}

function Menu-Principal () {
    $choice = 0
    while ($choice -ne "6") {
	Clear-Host
        Write-Host "########################"
        Write-Host "###  MENU PRINCIPAL  ###"
        Write-Host "########################"
        Write-Host "  1. - Archivos"
        Write-Host "  2. - Cuentas AD"
        Write-Host "  3. - Recursos compartidos"
        Write-Host "  4. - Juego laberinto"
        Write-Host "  5. - Defensa"
        Write-Host "  6. - Salir"
        Write-Host
    
        $choice = Read-Host "Elige una opcion"

        switch ($choice) {
            "1" { Archivos }
            "2" { Cuentas-AD }
            "3" { Recursos-Compartidos }
            "4" { Juego }
            "5" { 
                Write-Host "[!] Para la defensa" -ForegroundColor Red
                Pause
                Menu-Principal    
            }
            "6" {
                Write-Host "Saliendo del programa..."
            }
            default {
                Write-Host "[!] Opcion invalida" -ForegroundColor Red
            }
        }
    }
}

Menu-Principal
