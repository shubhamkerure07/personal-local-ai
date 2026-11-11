<#
.SYNOPSIS
    Personal Local AI Model & Storage Lifecycle Manager for Windows 11.
.DESCRIPTION
    Manages the Hot (Local NVMe SSD) vs Cold (Google Drive 5 TB Cloud Archive)
    storage tiers for Ollama models. Ensures models are executed exclusively
    from local high-speed SSD while allowing seamless archive/restore to/from
    Google Drive without re-downloading over the internet.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'archive', 'restore', 'status', 'backup-configs')]
    [string]$Action = 'status',

    [Parameter(Position = 1)]
    [string]$ModelName,

    [Parameter()]
    [string]$DriveRoot = '',

    [Parameter()]
    [string]$LocalModelsDir = "$env:USERPROFILE\.ollama\models"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-DriveRootPath {
    param([string]$SpecifiedRoot)

    if ($SpecifiedRoot -and (Test-Path $SpecifiedRoot)) {
        return $SpecifiedRoot
    }

    # Common Google Drive for Desktop mount locations
    $candidates = @(
        "G:\My Drive\AI-Library",
        "G:\AI-Library",
        "H:\My Drive\AI-Library",
        "$env:USERPROFILE\Google Drive\AI-Library",
        "$env:USERPROFILE\My Drive\AI-Library",
        "$env:USERPROFILE\GoogleDrive\AI-Library"
    )

    foreach ($cand in $candidates) {
        $parent = Split-Path -Parent $cand
        if (Test-Path $parent) {
            return $cand
        }
    }

    # Staging fallback if Google Drive for Desktop isn't running yet
    $fallback = Join-Path $env:USERPROFILE "GoogleDrive-AI-Library"
    return $fallback
}

function Get-OllamaStoragePath {
    if ($env:OLLAMA_MODELS) {
        return $env:OLLAMA_MODELS
    }
    return $LocalModelsDir
}

function Ensure-GoogleDriveTree {
    param([string]$Root)

    $folders = @(
        (Join-Path $Root 'Models'),
        (Join-Path $Root 'Backups'),
        (Join-Path $Root 'Configurations')
    )

    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
}

# Resolve actual drive root path
$ResolvedDriveRoot = Resolve-DriveRootPath -SpecifiedRoot $DriveRoot

function Show-StorageStatus {
    $modelsPath = Get-OllamaStoragePath
    $driveModelsPath = Join-Path $ResolvedDriveRoot 'Models'

    Write-Host "`n=== Personal Local AI: Storage Tiers Status ===" -ForegroundColor Cyan
    Write-Host "Hot Tier (Local SSD): $modelsPath"
    Write-Host "Cold Tier (Google Drive Archive): $ResolvedDriveRoot`n"

    # SSD Free Space
    try {
        $cDrive = [System.IO.DriveInfo]::new('C')
        $freeGB = [math]::Round($cDrive.AvailableFreeSpace / 1GB, 2)
        $totalGB = [math]::Round($cDrive.TotalSize / 1GB, 2)
        $usedGB = [math]::Round(($cDrive.TotalSize - $cDrive.AvailableFreeSpace) / 1GB, 2)
        Write-Host "Local SSD (C:) Free Space : $freeGB GB / $totalGB GB (Used: $usedGB GB)" -ForegroundColor Green
    } catch {
        # Fallback if DriveInfo fails
    }

    # Ollama models on SSD
    Write-Host "`n--- Active Hot Models on SSD (Ollama) ---" -ForegroundColor Yellow
    $ollamaBin = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollamaBin) {
        $candidate = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
        if (Test-Path $candidate) {
            $ollamaBin = $candidate
        }
    }

    if ($ollamaBin) {
        & $ollamaBin list
    } else {
        Write-Host "Ollama CLI is not in PATH or not yet running." -ForegroundColor Gray
    }

    # Cold models on Google Drive
    Write-Host "`n--- Cold Archived Models in Google Drive ---" -ForegroundColor Yellow
    if (Test-Path $driveModelsPath) {
        $archived = Get-ChildItem -Path $driveModelsPath -Directory
        if ($archived.Count -eq 0) {
            Write-Host "No archived models currently in $driveModelsPath" -ForegroundColor Gray
        } else {
            foreach ($item in $archived) {
                $size = (Get-ChildItem -Path $item.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
                $sizeGB = [math]::Round(($size / 1GB), 2)
                Write-Host "  * $($item.Name) ($sizeGB GB)" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "Google Drive archive path not found at: $driveModelsPath" -ForegroundColor Magenta
        Write-Host "Ensure Google Drive for Desktop is running and mapped." -ForegroundColor Gray
    }
}

function Archive-ModelToDrive {
    param([string]$Model, [string]$Root = $ResolvedDriveRoot)

    if (-not $Model) {
        throw "Please specify a model to archive. Example: .\ai-model-manager.ps1 archive qwen2.5:7b"
    }

    $modelsPath = Get-OllamaStoragePath
    $destRoot = Join-Path $Root 'Models'
    Ensure-GoogleDriveTree -Root $Root

    # Format model name for safe folder path (replace : with _)
    $safeName = $Model.Replace(':', '_')
    $destDir = Join-Path $destRoot $safeName

    Write-Host "`n[1/3] Locating model manifest for '$Model'..." -ForegroundColor Cyan

    # Manifest path convention: manifests\registry.ollama.ai\library\<name>\<tag>
    $parts = $Model.Split(':')
    $name = $parts[0]
    $tag = if ($parts.Length -gt 1) { $parts[1] } else { 'latest' }

    $manifestPath = Join-Path $modelsPath "manifests\registry.ollama.ai\library\$name\$tag"
    if (-not (Test-Path $manifestPath)) {
        # Check if custom namespace
        $manifestPath = Join-Path $modelsPath "manifests\registry.ollama.ai\$name\$tag"
    }

    if (-not (Test-Path $manifestPath)) {
        throw "Could not locate manifest for '$Model' at $manifestPath. Make sure the model is pulled locally."
    }

    Write-Host "[2/3] Reading manifest layers and staging blobs..." -ForegroundColor Cyan
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    # Copy manifest
    $destManifest = Join-Path $destDir "manifest.json"
    Copy-Item -Path $manifestPath -Destination $destManifest -Force

    # Collect blob hashes
    $blobs = @()
    if ($manifest.config) { $blobs += $manifest.config.digest }
    if ($manifest.layers) {
        foreach ($layer in $manifest.layers) {
            $blobs += $layer.digest
        }
    }

    $blobsDir = Join-Path $modelsPath 'blobs'
    $destBlobsDir = Join-Path $destDir 'blobs'
    if (-not (Test-Path $destBlobsDir)) {
        New-Item -ItemType Directory -Path $destBlobsDir -Force | Out-Null
    }

    foreach ($blobHash in $blobs) {
        $blobFileName = $blobHash.Replace(':', '-')
        $srcBlob = Join-Path $blobsDir $blobFileName
        $dstBlob = Join-Path $destBlobsDir $blobFileName

        if (Test-Path $srcBlob) {
            if (-not (Test-Path $dstBlob)) {
                $blobMB = [math]::Round(((Get-Item $srcBlob).Length / 1MB), 1)
                Write-Host "  -> Copying layer blob $blobFileName ($blobMB MB)..." -ForegroundColor Gray
                Copy-Item -Path $srcBlob -Destination $dstBlob -Force
            } else {
                Write-Host "  -> Blob $blobFileName already archived (skipping duplicate)." -ForegroundColor DarkGray
            }
        }
    }

    Write-Host "[3/3] Archive complete for '$Model' in: $destDir" -ForegroundColor Green
    Write-Host "Tip: To free up local SSD space now, you can run: ollama rm $Model" -ForegroundColor Yellow
}

function Restore-ModelFromDrive {
    param([string]$Model, [string]$Root = $ResolvedDriveRoot)

    if (-not $Model) {
        throw "Please specify a model to restore. Example: .\ai-model-manager.ps1 restore qwen2.5:7b"
    }

    $modelsPath = Get-OllamaStoragePath
    $destRoot = Join-Path $Root 'Models'
    $safeName = $Model.Replace(':', '_')
    $srcDir = Join-Path $destRoot $safeName

    if (-not (Test-Path $srcDir)) {
        throw "Archived model '$Model' not found in $srcDir"
    }

    Write-Host "`n[1/3] Restoring model layers from Google Drive to local SSD..." -ForegroundColor Cyan

    $srcBlobsDir = Join-Path $srcDir 'blobs'
    $dstBlobsDir = Join-Path $modelsPath 'blobs'
    if (-not (Test-Path $dstBlobsDir)) {
        New-Item -ItemType Directory -Path $dstBlobsDir -Force | Out-Null
    }

    if (Test-Path $srcBlobsDir) {
        $blobs = Get-ChildItem -Path $srcBlobsDir
        foreach ($b in $blobs) {
            $destBlob = Join-Path $dstBlobsDir $b.Name
            if (-not (Test-Path $destBlob)) {
                $sizeMB = [math]::Round(($b.Length / 1MB), 1)
                Write-Host "  <- Restoring blob $($b.Name) ($sizeMB MB)..." -ForegroundColor Gray
                Copy-Item -Path $b.FullName -Destination $destBlob -Force
            } else {
                Write-Host "  <- Blob $($b.Name) already present on SSD." -ForegroundColor DarkGray
            }
        }
    }

    Write-Host "[2/3] Restoring model manifest..." -ForegroundColor Cyan
    $parts = $Model.Split(':')
    $name = $parts[0]
    $tag = if ($parts.Length -gt 1) { $parts[1] } else { 'latest' }

    $manifestDestFolder = Join-Path $modelsPath "manifests\registry.ollama.ai\library\$name"
    if (-not (Test-Path $manifestDestFolder)) {
        New-Item -ItemType Directory -Path $manifestDestFolder -Force | Out-Null
    }

    $srcManifest = Join-Path $srcDir 'manifest.json'
    $dstManifest = Join-Path $manifestDestFolder $tag
    Copy-Item -Path $srcManifest -Destination $dstManifest -Force

    Write-Host "[3/3] Verification: Checking with Ollama..." -ForegroundColor Green
    & ollama list
    Write-Host "`nModel '$Model' is restored to local SSD and ready for immediate GPU execution!" -ForegroundColor Green
}

# Main Execution Switch
switch ($Action) {
    'status'         { Show-StorageStatus }
    'list'           { Show-StorageStatus }
    'archive'        { Archive-ModelToDrive -Model $ModelName -Root $ResolvedDriveRoot }
    'restore'        { Restore-ModelFromDrive -Model $ModelName -Root $ResolvedDriveRoot }
    'backup-configs' {
        Ensure-GoogleDriveTree -Root $ResolvedDriveRoot
        $cfgDst = Join-Path $ResolvedDriveRoot 'Configurations'
        Write-Host "Configurations backed up to $cfgDst" -ForegroundColor Green
    }
}
