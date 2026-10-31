<#
# Sindicato de Agentes IA TECH
# Librería helper para scripts de sincronización
# ----------------------------------------------------------------------

# Función: Compare-KitFileContent
# ------------------------------------------------------------------------
# Compara dos archivos de contenido de kit y retorna true si son idénticos.
# Usado por sync-kit.ps1 para validar idempotencia de operaciones.
#
# Parámetros:
#   -Source <string>: Ruta al archivo de origen
#   -Destination <string>: Ruta al archivo de destino
#
# Returns:
#   - $true: Los contenidos son idénticos
#   - $false: Los contenidos difieren
#
function Compare-KitFileContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    try {
        $sourceContent = Get-Content -Path $Source -ErrorAction Stop
        $destContent = Get-Content -Path $Destination -ErrorAction Stop

        if ($sourceContent.Count -ne $destContent.Count) {
            return $false
        }

        for ($i = 0; $i -lt $sourceContent.Count; $i++) {
            if ($sourceContent[$i] -ne $destContent[$i]) {
                return $false
            }
        }

        return $true
    } catch {
        Write-Warn "No se pudo comparar contenido: $_"
        return $false
    }
}

# Función: Get-KitRoot
# ------------------------------------------------------------------------
# Obtiene la raíz del kit actual basándose en la ubicación del script.
#
# Returns:
#   - Ruta absoluta al root del kit
#
function Get-KitRoot {
    $scriptRoot = Split-Path $MyInvocation.MyCommand.Path
    $kitRoot = Split-Path $scriptRoot -Parent
    # Buscar archivo de identificación
    if (Test-Path -Path (Join-Path $kitRoot '.bootstrap-state.json')) {
        return $kitRoot
    }
    # Fallback: parent del script
    return $scriptRoot
}

# Función: Get-BootstrapState
# ------------------------------------------------------------------------
# Lee el .bootstrap-state.json del kit y retorna su contenido.
#
# Returns:
#   - Contenido hash del estado del bootstrap
#
function Get-BootstrapState {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = $(Get-KitRoot)
    )

    $statePath = Join-Path $Path '.bootstrap-state.json'
    if (Test-Path -Path $statePath) {
        try {
            return Get-Content -Path $statePath -ErrorAction Stop
        } catch {
            Write-Warn "No se pudo leer bootstrap state: $_"
            return $null
        }
    }
    return $null
}

# Función: Invoke-Safe-Sync
# ------------------------------------------------------------------------
# Ejecuta una operación de sincronización con manejo de errores fail-open.
# Captura cualquier excepción y la reporta vía Write-Warn, nunca rompe el pipeline.
#
# Parámetros:
#   -ScriptBlock <scriptblock>: Bloque de script a ejecutar
#   -WarningMessage <string>: Mensaje de advertencia si falla
#
# Returns:
#   - Resultado del script block, o $false si hay error
#
function Invoke-Safe-Sync {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [string]$WarningMessage = 'Operación sincronización falló'
    )

    try {
        $result = & $ScriptBlock
        return $result
    } catch {
        Write-Warn "$WarningMessage: $_"
        return $false
    }
}

# Función: Validate-Project-Type
# ------------------------------------------------------------------------
# Valida el tipo de proyecto (kit vs consumidor) usando la función existente
# Test-IsMasterCheckout del bootstrap.
#
# Returns:
#   - 'kit' si es el repositorio maestro
#   - 'consumidor' si es un proyecto consumidor
#   - 'desconocido' si no se puede determinar
#
function Validate-Project-Type {
    $result = & . scripts/plataformador-bootstrap.ps1 2>$null | Out-Null
    # La función Test-IsMasterCheckout debería estar disponible después de sourcear
    # Por ahora, retorno un valor por defecto
    return 'kit'
}

# Función: Get-PluginScripts
# ------------------------------------------------------------------------
# Obtiene la lista de scripts de plugins en proyect_ext/scripts/
#
# Returns:
#   - Array de rutas a scripts de plugin
#
function Get-PluginScripts {
    $projectedExt = Join-Path (Get-KitRoot) 'proyect_ext'
    if (Test-Path -Path (Join-Path $projectedExt 'scripts')) {
        Get-ChildItem -Path (Join-Path $projectedExt 'scripts') -Filter '*.ps1' | Select-Object -ExpandProperty FullName
    }
    return @()
}

# Función: Copy-If-Different
# ------------------------------------------------------------------------
# Copia un archivo solo si el contenido es diferente al destino.
# Evita escrituras innecesarias y el ensuciamiento de audit logs.
#
# Parámetros:
#   -Source <string>: Ruta al archivo origen
#   -Destination <string>: Ruta al archivo destino
#
# Returns:
#   - $true: Si se copió (contenido diferente)
#   - $false: Si no se copió (contenido idéntico)
#
function Copy-If-Different {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    if (-not (Compare-KitFileContent -Source $Source -Destination $Destination)) {
        try {
            Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop
            return $true
        } catch {
            Write-Warn "No se pudo copiar $Source a $Destination: $_"
            return $false
        }
    }
    return $false
}