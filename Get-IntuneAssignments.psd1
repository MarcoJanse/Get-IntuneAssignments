@{
    RootModule = 'Get-IntuneAssignments.ps1'
    ModuleVersion = '1.0.0'
    GUID = '3b9c9df5-3b5f-4c1a-9a6c-097be91fa292'
    Author = 'Amir Joseph Sayes'
    CompanyName = 'amirsayes.co.uk'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'PowerShell script to retrieve all Intune Configuration Profile assignments, including Device Configuration, Compliance Policies, Security Baselines, and more.'
    PowerShellVersion = '5.1'
    RequiredModules = @(
        @{ModuleName = 'Microsoft.Graph.Authentication'; RequiredVersion = '2.25.0'},
        @{ModuleName = 'Microsoft.Graph.Beta.DeviceManagement'; RequiredVersion = '2.25.0'},
        @{ModuleName = 'Microsoft.Graph.Beta.Groups'; RequiredVersion = '2.25.0'},
        @{ModuleName = 'Microsoft.Graph.Beta.Devices.CorporateManagement'; RequiredVersion = '2.25.0'},
        @{ModuleName = 'Microsoft.Graph.Beta.DeviceManagement.Enrollment'; RequiredVersion = '2.25.0'}
    )
    FunctionsToExport = @('Get-IntuneAssignments')
    PrivateData = @{
        PSData = @{
            Tags = @('Intune', 'Configuration', 'Management', 'Microsoft', 'Graph', 'Azure')
            LicenseUri = 'https://github.com/amirjs/Get-IntuneAssignments/LICENSE'
            ProjectUri = 'https://github.com/amirjs/Get-IntuneAssignments'
            ReleaseNotes = 'Initial release'
        }
    }
}