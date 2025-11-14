#!/usr/bin/env pwsh

param(
    [string]$WindowsVersion = "2019",
    [string]$ChefVersion = "18.8.54",
    [string[]]$AdditionalArgs = @()
)

function Create-ChefImage {
    param(
        [string]$WindowsVersion,
        [string]$ChefVersion
    )
    
    $imageName = "chef-windows:$WindowsVersion-$ChefVersion"
    
    Write-Host "Creating Docker image: $imageName"
    
    # Create a temporary Dockerfile for Windows
    $dockerfileContent = @"
FROM mcr.microsoft.com/windows/servercore:ltsc$WindowsVersion

# Use PowerShell as the default shell
SHELL ["powershell", "-Command", "`$ErrorActionPreference = 'Stop'; "`$ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Chef using Chocolatey
RUN choco install chef-client --version=$ChefVersion -y

# Verify chef version
RUN chef-client --version

# Set PowerShell as the default command
CMD ["powershell"]
"@

    # Write Dockerfile to temporary file
    $dockerfilePath = "Dockerfile.chef.windows"
    $dockerfileContent | Out-File -FilePath $dockerfilePath -Encoding UTF8
    
    try {
        # Build the Docker image
        docker build -t $imageName -f $dockerfilePath .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully created $imageName" -ForegroundColor Green
        } else {
            Write-Error "Failed to build Docker image"
            return $false
        }
    }
    finally {
        # Clean up the temporary Dockerfile
        if (Test-Path $dockerfilePath) {
            Remove-Item $dockerfilePath
        }
    }
    
    return $true
}

# Default values
$DEFAULT_WINDOWS_VERSION = "2019"
$DEFAULT_CHEF_VERSION = "18.8.54"

# Use provided parameters or defaults
$windowsVersion = if ($WindowsVersion) { $WindowsVersion } else { $DEFAULT_WINDOWS_VERSION }
$chefVersion = if ($ChefVersion) { $ChefVersion } else { $DEFAULT_CHEF_VERSION }

# Create Chef image
$success = Create-ChefImage -WindowsVersion $windowsVersion -ChefVersion $chefVersion

if ($success) {
    $imageName = "chef-windows:$windowsVersion-$chefVersion"
    
    # Run the container
    if ($AdditionalArgs.Count -gt 0) {
        Write-Host "Running container with additional arguments: $($AdditionalArgs -join ' ')"
        docker run -it $imageName $AdditionalArgs
    } else {
        Write-Host "Running container with default PowerShell prompt"
        docker run -it $imageName
    }
} else {
    Write-Error "Failed to create Docker image"
    exit 1
}