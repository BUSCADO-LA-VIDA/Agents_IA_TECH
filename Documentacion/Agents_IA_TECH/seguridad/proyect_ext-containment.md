# Contención de proyect_ext/ — Reglas de Seguridad

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Fuente:** Threat Model STRIDE Spec #011 (T-04, E-02, Guardrail 8 ADR-0007)  
**Estado:** Activo  

---

## 1. Principio de Contención Absoluta

> **`proyect_ext/` NUNCA puede escapar de `<project-root>/proyect_ext/`**

Esta es una frontera de seguridad **inviolable**. Cualquier violación es un hallazgo **CRITICAL** que bloquea el despliegue.

---

## 2. Reglas Obligatorias

### 2.1 Raíz Fija e Inmutable

```powershell
$ProyectExtRoot = Resolve-Path (Join-Path $ProjectRoot 'proyect_ext')
# NUNCA usar rutas relativas desde aquí: ../, ../../, ~/, etc.
```

### 2.2 Validación Realpath Antes de CADA Escritura

```powershell
function Assert-InContainment($ProjectRoot, $TargetPath) {
    $proyectExtRoot = Resolve-Path (Join-Path $ProjectRoot 'proyect_ext') -ErrorAction Stop
    $resolvedTarget = Resolve-Path $TargetPath -ErrorAction SilentlyContinue
    
    if (-not $resolvedTarget) {
        # Path no existe aún — validar que el directorio padre SÍ está en containment
        $parent = Split-Path $TargetPath -Parent
        $resolvedParent = Resolve-Path $parent -ErrorAction Stop
        if (-not $resolvedParent.Path.StartsWith($proyectExtRoot.Path)) {
            throw "CONTAINMENT VIOLATION: Parent directory $parent escapes proyect_ext/"
        }
        return
    }
    
    if (-not $resolvedTarget.Path.StartsWith($proyectExtRoot.Path)) {
        throw "CONTAINMENT VIOLATION: $TargetPath resolves to $($resolvedTarget.Path) outside proyect_ext/ ($proyectExtRoot.Path)"
    }
}
```

### 2.3 Prohibición Total de Symlinks

```powershell
function Assert-NoSymlinks($Path) {
    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $item -and $item.LinkType -notin @('HardLink', 'Junction', $null)) {
        throw "SYMLINK DETECTED: $($item.FullName) -> $($item.Target) — symlinks prohibited in proyect_ext/"
    }
    
    # Recursivo para directorios
    if ($item -is [System.IO.DirectoryInfo]) {
        Get-ChildItem $Path -Recurse -Force | ForEach-Object {
            if ($_.LinkType -notin @('HardLink', 'Junction', $null)) {
                throw "SYMLINK DETECTED (recursive): $($_.FullName) -> $($_.Target)"
            }
        }
    }
}
```

### 2.4 Git Clone Hardening (Contención en Origen)

```powershell
function Clone-IntoContainment($url, $version, $relativeTargetDir, $projectRoot) {
    $targetPath = Join-Path $projectRoot 'proyect_ext' $relativeTargetDir
    
    # Validar containment ANTES de clonar
    Assert-InContainment $projectRoot $targetPath
    
    # Parámetros de seguridad obligatorios
    git clone \
        --depth=1 \
        --no-recurse-submodules \
        --branch $version \
        --single-branch \
        $url \
        $targetPath
    
    # Validar post-clone
    Assert-InContainment $projectRoot $targetPath
    Assert-NoSymlinks $targetPath
    
    return $targetPath
}
```

### 2.5 uv tool install — Contención de Binarios

```powershell
function Install-UvToolContained($package, $version, $projectRoot) {
    # uv tool install instala en ~/.local/bin por defecto — NO en proyect_ext/
    # Estrategia: instalar globalmente (user), pero validar que binario no escribe fuera
    
    $env:UV_TOOL_DIR = Join-Path $projectRoot 'proyect_ext' '.uv-tools'  # Contenedor local
    $env:UV_TOOL_BIN_DIR = Join-Path $env:UV_TOOL_DIR 'bin'
    
    uv tool install $package --version $version
    
    # Verificar que binario instalado está en containment
    $binaryPath = Join-Path $env:UV_TOOL_BIN_DIR (Get-UvToolBinaryName $package)
    Assert-InContainment $projectRoot $binaryPath
}
```

---

## 3. Validación de Contención en Bootstrap

```powershell
# En plataformador-bootstrap.ps1, ANTES de tokenslayer build:
function Verify-ProyectExtContainment($ProjectRoot) {
    $proyectExtRoot = Join-Path $ProjectRoot 'proyect_ext'
    
    if (-not (Test-Path $proyectExtRoot)) {
        Write-Warn "proyect_ext/ no existe — saltando validación de contención"
        return
    }
    
    # 1. Verificar que no hay symlinks escapando
    Assert-NoSymlinks $proyectExtRoot
    
    # 2. Verificar que todos los paths resueltos están dentro
    Get-ChildItem $proyectExtRoot -Recurse -Force | ForEach-Object {
        $resolved = Resolve-Path $_.FullName -ErrorAction SilentlyContinue
        if ($resolved -and -not $resolved.Path.StartsWith((Resolve-Path $proyectExtRoot).Path)) {
            throw "CONTAINMENT VIOLATION in bootstrap: $($_.FullName) -> $($resolved.Path)"
        }
    }
    
    Write-OK "proyect_ext/ containment verified"
}
```

---

## 4. Tests de Contención (Obligatorios)

| Test ID | Descripción | Resultado Esperado |
|---------|-------------|-------------------|
| CT-01 | `git clone` con `../` en targetDir | **FAIL** — lanzamiento excepción |
| CT-02 | Symlink en repo clonado apuntando a `/etc/passwd` | **FAIL** — detección y rechazo |
| CT-03 | `targetDir` absoluto `/tmp/evil` | **FAIL** — validación rechaza |
| CT-04 | `uv tool install` con `--prefix` fuera de containment | **FAIL** — rechazo |
| CT-05 | Operaciones normales (clone válido, build válido) | **PASS** — sin errores |

---

## 5. Referencias

- Threat Model #011: `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` (T-04, E-02)
- ADR-0007: `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` (Guardrail 8)
- Supply Chain Guidelines: `seguridad/supply-chain-security-guidelines.md` (Sección 4)
- Manifest Security: `seguridad/manifest-security.md` (targetDir validation)

---

*Generado por security-auditor — spec #011 threat model*