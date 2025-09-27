# Get-IntuneAssignments

PowerShell script to retrieve all Intune Configuration Profile assignments, including Device Configuration, Compliance Policies, Security Baselines, and more.

## Installation

```powershell
Install-Script -Name Get-IntuneAssignments
```

## Requirements

- PowerShell 7.1 or higher
- Microsoft Graph PowerShell SDK modules (will be automatically installed if missing):
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Beta.DeviceManagement
  - Microsoft.Graph.Beta.Groups
  - Microsoft.Graph.Beta.Devices.CorporateManagement
  - Microsoft.Graph.Beta.DeviceManagement.Enrollment

## API Permissions


The following Microsoft Graph API permissions are required:

- DeviceManagementConfiguration.Read.All
- DeviceManagementApps.Read.All
- DeviceManagementManagedDevices.Read.All
- DeviceManagementServiceConfig.Read.All
- DeviceManagementScripts.Read.All
- Group.Read.All
- Directory.Read.All

These permissions will be requested automatically when connecting to Microsoft Graph.

## Usage

```powershell
# Get all assignments
Get-IntuneAssignments

# Export assignments to CSV
Get-IntuneAssignments -OutputFile "C:\temp\assignments.csv"

# Get assignments for specific group
Get-IntuneAssignments -GroupName "Pilot Users"

# Get assignments for a specific group and export to CSV
Get-IntuneAssignments -GroupName "Pilot Users" -OutputFile "C:\temp\Pilot Users Assignments.csv"

# Authenticate using certificate thumbprint (App registration with certificate in certificate store)
Get-IntuneAssignments -AuthMethod Certificate -TenantId "contoso.onmicrosoft.com" -ClientId "<app-client-id>" -CertificateThumbprint "<thumbprint>"
```

## Features

- Retrieves assignments for:
  - Device Configuration Profiles
  - Compliance Policies
  - Security Baselines
  - Administrative Templates
  - App Protection Policies
  - Managed Device App Deployments (W32, LOB, Store, etc)
  - Windows Information Protection Policies
  - Remediation Scripts
  - Device Management Scripts
  - Autopilot Profiles
- Shows included and excluded groups for each assignment
- Displays filter information if configured
- Export results to CSV
- Filter by specific Azure AD group

## Output Format

The script returns objects with the following properties:
- DisplayName: Name of the policy/profile
- ProfileType: Type of configuration (e.g., Device Configuration, Compliance Policy)
- IncludedGroups: Groups included in the assignment (with filter information if applicable)
- ExcludedGroups: Groups excluded from the assignment


## Authentication Methods

Supported authentication methods:

- **Interactive** (default): Prompts for user login interactively.
- **Certificate**: Uses a certificate in the local certificate store, specified by thumbprint. Only the `-CertificateThumbprint` parameter is supported. `-CertificatePath` is not supported.
- **ClientSecret**: Uses a client secret via a PSCredential object.
- **UserManagedIdentity**: Uses a user-assigned managed identity.
- **SystemManagedIdentity**: Uses a system-assigned managed identity.

**Note:** For certificate authentication, the certificate must be installed in the local certificate store and accessible by thumbprint. The script does not support loading certificates from file paths.

## Contributing

Contributions are welcome! Please submit a pull request.

## License

[MIT License](./LICENSE)