#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement, Microsoft.Graph.Beta.Groups, Microsoft.Graph.Beta.Devices.CorporateManagement, Microsoft.Graph.Beta.DeviceManagement.Enrollment

<#
.SYNOPSIS
    Retrieves all Intune Configuration Profile assignments.

.DESCRIPTION
    This script retrieves assignments for various Intune configuration types including:
    - Device Configuration Profiles
    - Compliance Policies
    - Security Baselines
    - Administrative Templates
    - App Protection Policies
    - App Configuration Policies
    - Windows Information Protection Policies
    - Remediation Scripts
    - Device Management Scripts
    - Autopilot Profiles

.PARAMETER OutputFile
    Path to export the results as CSV. If not specified, results will be displayed in console.

.PARAMETER GroupName
    Name of the Azure AD group to filter assignments. Only assignments that include or exclude this group will be returned.

.EXAMPLE
    Get-IntuneAssignments
    Returns all Intune configuration assignments and displays them in the console.

.EXAMPLE
    Get-IntuneAssignments -OutputFile "C:\temp\assignments.csv"
    Retrieves all assignments and exports them to the specified CSV file.

.EXAMPLE
    Get-IntuneAssignments -GroupName "Pilot Users"
    Returns assignments that include or exclude the specified group.

.NOTES
    Version:        1.0.0
    Author:         Amir Joseph Sayes
    Company:        amirsayes.co.uk
    Creation Date:  2025-04-30
    Requirements:   
    - PowerShell 5.1 or higher
    - Microsoft Graph PowerShell SDK modules
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName
)

# Check if the relevant modules are installed and if not install them
$modules = @(
    "Microsoft.Graph.authentication",
    "Microsoft.Graph.Beta.DeviceManagement",
    "Microsoft.Graph.Beta.Groups",
    "Microsoft.Graph.Beta.Devices.CorporateManagement",
    "Microsoft.Graph.Beta.DeviceManagement.Enrollment"
)

try {
    foreach ($module in $modules) {
        if (-not(Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
            Write-Verbose "Installing module $module..."
            Install-Module -Name $module -Force -Scope CurrentUser -RequiredVersion 2.25.0
        }
        if (-not (Get-Module -Name $module -ErrorAction SilentlyContinue)) {
            Write-Verbose "Importing module $module..."
            Import-Module -Name $module -Force -RequiredVersion 2.25.0
        }
    }
} catch {
    Write-Error "Failed to install or import required modules: $_"
    return
}

# Import the functions from IntuneConfigurationProfilesFunctions.ps1
try {
    . "$PSScriptRoot\IntuneConfigurationProfilesFunctions.ps1"
} catch {
    Write-Error "Failed to import functions from IntuneConfigurationProfilesFunctions.ps1: $_"
    return
}

# Connect to Microsoft Graph if not already connected
try {
    if (-not (Get-MgContext)) {
        Write-Verbose "Connecting to Microsoft Graph..."
        Connect-MgGraph -Scopes @(
            "DeviceManagementConfiguration.Read.All",
            "DeviceManagementApps.Read.All",
            "DeviceManagementManagedDevices.Read.All",
            "DeviceManagementServiceConfig.Read.All",
            "Group.Read.All",
            "Directory.Read.All"
        )
    }
} catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    return
}

# Initialize results array
$results = @()

# Get group ID if GroupName is provided
$groupId = $null
if ($GroupName) {
    try {
        $group = Get-MgBetaGroup -Filter "DisplayName eq '$GroupName'"
        if (-not $group) {
            Write-Error "Group '$GroupName' not found."
            return
        }
        $groupId = $group.Id
        Write-Host "Processing assignments for group: $GroupName" -ForegroundColor Green
    } catch {
        Write-Error "Failed to get group information: $_"
        return
    }
}

$processSteps = @(
    @{ Name = "App Protection Policies"; Function = "Get-IntuneAppProtectionAssignment" },
    @{ Name = "Managed Device App Configurations"; Function = "Get-IntuneManagedDeviceAppConfigurationAssignment" },
    @{ Name = "Security Baselines"; Function = "Get-IntuneDeviceManagementSecurityBaselineAssignment" },
    @{ Name = "Device Compliance Policies"; Function = "Get-IntuneDeviceCompliancePolicyAssignment" },
    @{ Name = "Device Configurations"; Function = "Get-IntuneDeviceConfigurationAssignment" },
    @{ Name = "Administrative Templates"; Function = "Get-IntuneDeviceConfigurationAdministrativeTemplatesAssignment" },
    @{ Name = "Remediation Scripts"; Function = "Get-IntuneRemediationScriptAssignment" },
    @{ Name = "Autopilot Profiles"; Function = "Get-IntuneAutopilotProfileAssignment" },
    @{ Name = "Device Management Scripts"; Function = "Get-IntuneDeviceManagementScriptAssignment" },
    @{ Name = "Windows Information Protection Policies"; Function = "Get-IntuneWindowsInformationProtectionPolicyAssignment" }
)

foreach ($step in $processSteps) {
    Write-Host "Processing $($step.Name)..." -ForegroundColor Cyan
    try {
        $stepResults = & $step.Function -groupId $groupId
        $results += $stepResults
    } catch {
        Write-Warning "Failed to process $($step.Name): $_"
    }
}

# Output results
$finalResults = @($results)
if ($finalResults.Count -gt 0) {
    # Always display results in console
    Write-Host "`nPolicy Assignments:" -ForegroundColor Green
    $finalResults | Format-Table -AutoSize DisplayName, ProfileType, 
        @{Name='IncludedGroups';Expression={$_.IncludedGroups -join '; '}},
        @{Name='ExcludedGroups';Expression={$_.ExcludedGroups -join '; '}}
    
    Write-Host "`nFound $($finalResults.Count) policies with assignments" -ForegroundColor Green

    # Export to CSV if OutputFile is specified
    if ($OutputFile) {
        try {
            # Ensure the directory exists
            $directory = Split-Path -Path $OutputFile -Parent
            if (-not (Test-Path -Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }
            
            $finalResults | Select-Object DisplayName, ProfileType, 
                @{Name='IncludedGroups';Expression={$_.IncludedGroups -join '; '}},
                @{Name='ExcludedGroups';Expression={$_.ExcludedGroups -join '; '}} |
            Export-Csv -Path $OutputFile -NoTypeInformation -Force
            Write-Host "Results exported to $OutputFile" -ForegroundColor Green
        } catch {
            Write-Error "Failed to export results to CSV: $_"
        }
    }
} else {
    Write-Host "No policies with assignments found" -ForegroundColor Yellow
}