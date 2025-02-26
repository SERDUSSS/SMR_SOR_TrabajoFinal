function Game {
    # Set global variables for rendering
    $global:FOV = [math]::PI / 3  # Field of view (60 degrees)
    $global:maxDepth = 64  # Max raycasting depth
    # Expanded shading array with block characters for solid walls
    $global:shading = @(
        ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ":", ":", ":", ":", "*", "*", "*", "*", "o", "$", "#"#, "▓", "█", "▒", "░"
    )

    $exitChar = "`e"

    $global:map2 = ""

    $global:sleepTime = 0
    $Red    = "`e[31m"  # Red color
    $Green  = "`e[32m"  # Green color
    $Yellow = "`e[33m"  # Yellow color
    $Blue   = "`e[34m"  # Blue color
    $Reset  = "`e[0m"   # Reset color

    # Color mode
    $global:colorActive = $true

    # Debug mode
    $global:debugActive = $false

    # Example map (you can modify it)
    $global:mapActive = $false

    function Main-Menu {
        while ($done -ne $true) {
            Clear-Host
            Write-Host "Controls:"
            Write-Host "`tW`tWalk"
            Write-Host "`tA`tRotate Left"
            Write-Host "`tS`tWalk Backwards"
            Write-Host "`tD`tRotate Right"
            Write-Host "`tB`tOpen Debug"
            Write-Host "`tM`tOpen Map"
            Write-Host "`tC`tColor mode (on/off)"
            Write-Host
            Write-Host "Select map dimensions:"
            Write-Host "`t1.`t8x8       (Sandbox)"
            Write-Host "`t2.`t16x16     (Very Easy)"
            Write-Host "`t3.`t32x32     (Easy)"
            Write-Host "`t4.`t64x64     (Medium)"
            Write-Host "`t5.`t128x128   (Hard)"
            Write-Host "`t6.`t256x256   (Very Hard)"
            Write-Host "`t7.`t512x512   (Extreme)"
            Write-Host "`t8.`t1024x1024 (Brainfuck)"
            Write-Host "`t9.`tCustom"
            Write-Host "`t0.`tExit"
            Write-Host
            $choice = Read-Host "Select option (1, 2, 3...)"

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
                    [int]$inputWidth  = Read-Host "Enter width (Has to be a power of 2)"
                    if (($inputWidth -gt 0) -and (($inputWidth -band ($inputWidth - 1)) -eq 0)) {
                        if ($inputWidth -ge 8) {
                            $global:mapWidth = $inputWidth - 1
                        } else {
                            Write-Host "$Red[!] The minimum dimensions are 8x8$Reset"
                            Pause
                            Main-Menu
                        }
                    } else {
                        Write-Host "$Red[!] The number has to be a power of 2$Reset"
                        Pause
                        Main-Menu
                    }
                    
                    [int]$inputHeight = Read-Host "Enter height (Has to be a power of 2)"
                    if (($inputHeight -gt 0) -and (($inputHeight -band ($inputHeight - 1)) -eq 0)) {
                        if ($inputHeight -ge 8) {
                            $global:mapHeight = $inputHeight - 1
                        } else {
                            Write-Host "$Red[!] The minimum dimensions are 8x8$Reset"
                            Pause
                            Main-Menu
                        }
                    } else {
                        Write-Host "$Red[!] The number has to be a power of 2$Reset"
                        Pause
                        Main-Menu
                    }
                    $done = $true
                }
                "0" {
                    Exit
                }
                default {
                    Write-Host "$Red[!] Invalid option$Reset"
                    pause
                }
            }
        }
    }

    Main-Menu

    function Generate-Maze {
        param(
            [int]$width,  # Keep odd for symmetry
            [int]$height
        )

        Write-Host "$Green[+] Generating Map...$Reset"
        Write-Host "Generating canvas"

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
        Write-Host "Carving maze"
        Carve-Maze -x $startX -y $startY

        function Place-Exit {
            Write-Host "Placing exit"
            $exitX = $width - 1  
            $exitY = $height - 2

            $rowChars = $maze[$exitY].ToCharArray()
            $rowChars[$exitX] = "E"
            $maze[$exitY] = -join $rowChars

            $global:map2 = $maze

            return $maze -replace 'E', "$red`E$reset"
        }

        # **Remove 1 in 6 walls randomly (excluding outer walls)**
        Write-Host "Removing wall randomly"
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

    # Generate the maze
    $global:map = Generate-Maze -width $global:mapWidth -height $global:mapHeight

    # Global variables for player position and angle
    Write-Host "$Green[+] Calculating initial position...$Reset"
    $global:playerX = $global:mapWidth / 2
    $global:playerY = $global:mapHeight / 2

    # Function to calculate angle to a target point (x, y)
    function Calculate-Angle {
        param ($targetX, $targetY)

        Write-Host "Calculating angle"
        
        # Calculate the angle between the player and the target (in radians)
        $angle = [math]::Atan2($targetY - $global:playerY, $targetX - $global:playerX)

        # Round the angle to 1 decimal place (rounding correctly to the nearest 0.5)
        return $angle
    }

    # Function to find the first empty space around the player in cardinal directions (up, right, down, left)
    function Find-InitialAngle {
        # Cardinal direction offsets (right, down, left, up)
        $directions = @(
            [array]@(1, 0),  # Right
            [array]@(0, 1),  # Down
            [array]@(-1, 0), # Left
            [array]@(0, -1)  # Up
        )

        Write-Host "$Green[+] Calculating Initial Angle...$Reset"

        # Search for the first empty space around the player
        foreach ($dir in $directions) {
            $testX = $global:playerX + $dir[0]
            $testY = $global:playerY + $dir[1]
            Write-Host "Checking position: $([math]::Floor($testX)), $([math]::Floor($testY)) - Value: $($global:map[[math]::Floor($testY)][[math]::Floor($testX)])"

            # Ensure the new position is within bounds
            if ($testX -ge 0 -and $testX -lt $global:mapWidth -and $testY -ge 0 -and $testY -lt $global:mapHeight) {
                if ($global:map[[math]::Floor($testY)][[math]::Floor($testX)] -eq " ") {
                    # Found an empty space, calculate the angle and return it
                    Write-Host "Found empty space at $([math]::Floor($testX)), $([math]::Floor($testY))"
                    
                    $angle = Calculate-Angle -targetX $testX -targetY $testY
                    Write-Host "Initial Angle: $angle"
                    return $angle
                }
            }
        }

        # There's no empty space, rerun
        Write-Host "$Red[!] Could not find any open space, regenerating maze...$Reset"
        $map = Generate-Maze -width $global:mapWidth -height $global:mapHeight
        Find-InitialAngle
    }

    # Set the player's initial angle
    $global:playerAngle = Find-InitialAngle

    # Function to get terminal size
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

    # Function to render the 3D raycasting frame with minimap
    function Render-Frame {
        # Get the terminal size
        $terminalSize = Get-TerminalSize
        $screenWidth = $terminalSize.Width
        $screenHeight = $terminalSize.Height

        $frame = @()

        if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
            for ($x = 0; $x -lt $screenWidth; $x++) {
                # Ray angle based on field of view and screen position
                $rayAngle = ($global:playerAngle - $global:FOV / 2) + ($x / $screenWidth) * $global:FOV

                # Ray direction
                $rayDirX = [math]::Cos($rayAngle)
                $rayDirY = [math]::Sin($rayAngle)

                # Current player grid position
                $mapX = [math]::Floor($global:playerX)
                $mapY = [math]::Floor($global:playerY)

                # Length of ray from one x-side to next x-side
                $deltaDistX = [math]::Abs(1 / $rayDirX)
                $deltaDistY = [math]::Abs(1 / $rayDirY)

                # Step direction (+1 or -1) and initial side distance
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

                # Perform DDA (Digital Differential Analyzer) stepping
                $hit = $false
                $side = 0  # 0 for X-side, 1 for Y-side

                while (-not $hit -and $mapX -ge 0 -and $mapX -lt $global:mapWidth -and $mapY -ge 0 -and $mapY -lt $global:mapHeight) {
                    # Step in X or Y direction
                    if ($sideDistX -lt $sideDistY) {
                        $sideDistX += $deltaDistX
                        $mapX += $stepX
                        $side = 0
                    } else {
                        $sideDistY += $deltaDistY
                        $mapY += $stepY
                        $side = 1
                    }

                    # Check if we've hit a wall
                    if ($global:map[$mapY][$mapX] -eq "#") {
                        $hit = $true
                    }
                }

                # Calculate distance to wall
                if ($side -eq 0) {
                    $distance = ($mapX - $global:playerX + (1 - $stepX) / 2) / $rayDirX
                } else {
                    $distance = ($mapY - $global:playerY + (1 - $stepY) / 2) / $rayDirY
                }

                # Reverse shading for closer objects
                $shadingScale = ($shading.Length - 1) / $global:maxDepth
                $shadeIndex = [math]::Min([math]::Floor(($global:maxDepth - $distance) * $shadingScale), $shading.Length - 1)
                $wallChar = if ($hit) { $shading[$shadeIndex] } else { " " }

                # Calculate wall height
                $wallHeight = [math]::Floor($screenHeight / $distance)

                # Create an empty column
                $column = @(" " * $screenHeight) -split ""

                # Populate the column with the wall character
                for ($y = 0; $y -lt $screenHeight; $y++) {
                    if ($y -gt ($screenHeight / 2 - $wallHeight) -and $y -lt ($screenHeight / 2 + $wallHeight)) {
                        $column[$y] = $wallChar
                    }
                }

                # Add the column to the frame
                $frame += ($column -join "")
            }

            # Render frame
            $renderOutput = New-Object System.Text.StringBuilder
            for ($y = 0; $y -lt $screenHeight; $y++) {
                for ($x = 0; $x -lt $screenWidth; $x++) {
                    $renderOutput.Append($frame[$x][$y]) > $null
                }
                $renderOutput.Append("`n") > $null
            }
        }
        
        Clear-Host

        if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
            [System.Console]::Write($renderOutput.ToString())
        }

        # Display player information and map below the 3D view
        if ($debugActive -eq $true) {
            Write-Host "Player Position: X = $([math]::Round($global:playerX, 2)), Y = $([math]::Round($global:playerY, 2)), Angle = $([math]::Round($global:playerAngle, 2))"
        }

        function Get-PlayerArrow {
            # Normalize the angle to be between 0 and 2π (handles negative angles correctly)
            $normalizedAngle = $global:playerAngle % (2 * [math]::PI)

            # If the angle is negative, add 2π to bring it into the positive range
            if ($normalizedAngle -lt 0) {
                $normalizedAngle += 2 * [math]::PI
            }

            # Check if the player is facing down, left, up, or right (shifted clockwise)
            if (($normalizedAngle -lt [math]::PI / 4) -or ($normalizedAngle -ge 7 * [math]::PI / 4)) {
                return ">"  # Facing Right (0 to π/4 or 7π/4 to 2π)
            } elseif ($normalizedAngle -ge [math]::PI / 4 -and $normalizedAngle -lt 3 * [math]::PI / 4) {
                return "v"  # Facing Down (π/4 to 3π/4)
            } elseif ($normalizedAngle -ge 3 * [math]::PI / 4 -and $normalizedAngle -lt 5 * [math]::PI / 4) {
                return "<"  # Facing Left (3π/4 to 5π/4)
            } else {
                return "^"  # Facing Up (5π/4 to 7π/4)
            }
        }

        if ($global:mapActive -eq $true) {
            # Display map with player position and direction
            for ($y = 0; $y -lt $global:map.Length; $y++) {
                if ($colorActive) {
                    $row = $global:map[$y]
                } else {
                    $row = $global:map2[$y]
                }

                # Mark the player's position with the arrow depending on direction
                $mapRow = ""
                for ($x = 0; $x -lt $row.Length; $x++) {
                    if ($y -eq [math]::Floor($global:playerY) -and $x -eq [math]::Floor($global:playerX)) {
                        # Replace 'P' with the arrow for the player's facing direction
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
            Write-Host "$Red[!] Not enough space. Disable map, zoom out or make the screen bigger to display game frames.$Reset"
        }
    }

    # Move the player and check for walls
    function Move-Player {
        param($direction)
        $moveSpeed = 0.2  # Movement speed
        $turnSpeed = [math]::PI / 16  # Turn speed (angle change when turning)
        $collisionBuffer = 0.3  # Small buffer to prevent corner clipping

        # Calculate proposed new position
        $newX = $global:playerX
        $newY = $global:playerY

        if ($direction -eq "W") {
            # Move forward
            $newX += [math]::Cos($global:playerAngle) * $moveSpeed
            $newY += [math]::Sin($global:playerAngle) * $moveSpeed
        } elseif ($direction -eq "S") {
            # Move backward
            $newX -= [math]::Cos($global:playerAngle) * $moveSpeed
            $newY -= [math]::Sin($global:playerAngle) * $moveSpeed
        } elseif ($direction -eq "A") {
            # Turn left
            $global:playerAngle -= $turnSpeed
            return  # No need to check movement on turning
        } elseif ($direction -eq "D") {
            # Turn right
            $global:playerAngle += $turnSpeed
            return  # No need to check movement on turning
        }

        # Check collision for new X position
        $floorX = [math]::Floor($newX)
        $floorY = [math]::Floor($global:playerY)  # Keep Y the same for now

        if ($global:map[$floorY][$floorX] -ne "#") {
            $global:playerX = $newX  # Move in X direction only if no collision
        }

        # Check collision for new Y position
        $floorX = [math]::Floor($global:playerX)  # Keep new X from previous check
        $floorY = [math]::Floor($newY)

        if ($global:map[$floorY][$floorX] -ne "#") {
            $global:playerY = $newY  # Move in Y direction only if no collision
        }
    }

    # Start a stopwatch to track time
    Write-Host "$Green[+] Started timer$Reset"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host "$Green[+] Game ready$Reset"

    # Game loop
    while ($true) {
        # Render the current frame
        Render-Frame

        # Check if the player reached the exit
        $floorX = [math]::Floor($global:playerX)
        $floorY = [math]::Floor($global:playerY)
        if ($global:map[$floorY][$floorX] -eq $exitChar) {
            Clear-Host
            $stopwatch.Stop()
            $timeTaken = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            Write-Host "`n🎉 You Won! Time: $timeTaken seconds 🎉" -ForegroundColor Green
            Pause
            break
        }

        # Read input for movement
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

        switch -wildcard ($key) {
            '[WASDwasd]' { Move-Player -direction $key }
            '[Mm]'       { $global:mapActive = -not $global:mapActive }
            '[Bb]'       { $global:debugActive = -not $global:debugActive }
            '[Qq]' {
                Clear-Host
                Write-Host "`n$Green[+] Leaving game...$Reset"
                exit
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

        Start-Sleep -Milliseconds $global:sleepTime
    }
}

# Proyecto 02 ARCHIVOS: Sistemas Operativos en Red
# Sergio Barroso Ceballos

function Archivos {
    # Menú opción 1: Crear Directorio
    # Creará un directorio con el nombre introducido en la ruta actual
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

    # Menú opción 2: Borrar Directorio
    # Borrará el directorio con el nombre introducido en la ruta actual
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

    # Opción 3: Listar Directorio
    # Listará todos los directorios bajo la ruta actual
    function List-Dir {
        Get-ChildItem -Directory
    }

    # Opción 4: Crear Archivo
    # Creará un archivo con el nombre introducido en la ruta actual
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

    # Opción 5: Borrar Archivo
    # Borrará el archivo con el nombre introducido en la ruta actual
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

    # Opción 6: Mostrar Archivo
    # Mostrará el contenido de el archivo con el nombre introducido en la ruta actual
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

    # Creamos un bucle mientras que no se pulse la opción 7
    while ($menuinput -ne 7) {
        # Borramos la pantalla
        cls

        # Mostramos el Menú
        Write-Host "########################"
        Write-Host "##        MENÚ        ##"
        Write-Host "########################"
        Write-Host
        Write-Host "  1. Crear directorio"
        Write-Host "  2. Borrar directorio"
        Write-Host "  3. Listar directorios"
        Write-Host "  4. Crear archivo"
        Write-Host "  5. Borrar archivo"
        Write-Host "  6. Mostrar archivo"
        Write-Host "  7. Salir"
        Write-Host "-----------------------"

        # Recogemos la opción elegida
        [string] $menuinput = Read-Host " Elija una opción"

        Write-Host

        # LLamamos a las funciones respectivas según la opción
        switch ($menuinput) {
            1 {New-Dir}
            2 {Del-Dir}
            3 {List-Dir}
            4 {New-File}
            5 {Del-File}
            6 {Read-File}
            7 {exit}
            
            # En caso de introducir otra opción no definida avisar de esto
            default {
                Write-Host "Opción" $menuinput "invalida"
            }
        }

        # Esperar a que el usuario pulse enter para volver al menú
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
        Write-Host "===== MENU PRINCIPAL =====" -ForegroundColor Cyan
        Write-Host "  1 - Gestion de Usuarios"
        Write-Host "  2 - Gestion de Equipos"
        Write-Host "  3 - Gestion de Grupos"
        Write-Host "  4 - Salir del Programa"
        Write-Host
        return (Read-Host "Selecciona una opcion")
    }

    # Funcion para mostrar el menu de usuarios
    function MenuUsuarios {
        Clear-Host
        Write-Host "===== MENU DE USUARIOS =====" -ForegroundColor Cyan
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
        Write-Host "===== MENU DE EQUIPOS =====" -ForegroundColor Cyan
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
        Write-Host "===== MENU DE GRUPOS =====" -ForegroundColor Cyan
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
            Write-Host "  ultimo Cambio de Contraseña: $($usuario.PasswordLastSet)"
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

function Menu-Principal () {
    Write-Host "########################"
    Write-Host "###  MENU PRINCIPAL  ###"
    Write-Host "########################"
    Write-Host " 1 - Archivos"
    Write-Host " 2 - Cuentas AD"
    Write-Host " 3 - Recursos compartidos"
    Write-Host " 4 - Juego laberinto"
    Write-Host " 5 - Defensa"
    Write-Host " 6 - Salir"
    Write-Host
    
    $choice = Read-Host "Elige una opcion"

    switch ($choice) {
        "1" { Archivos }
        "2" { Cuentas-AD }
        "3" { Recursos-Compartidos }
        "4" { Game }
        "5" { 
            Write-Host "[!] Para la defensa" -ForegroundColor Red
            Pause
            Menu-Principal    
        }
        "6" {
            Write-Host "Saliendo del programa..."
            Exit
        }
        default {
            Write-Host "[!] Opcion invalida" -ForegroundColor Red
        }
    }
}

Menu-Principal
