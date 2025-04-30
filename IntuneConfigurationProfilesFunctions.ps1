# make sure the modules are installed

function Get-IntuneAppProtectionAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $AppProtectionPolicy = Get-MgBetaDeviceAppManagementManagedAppPolicy -Filter "displayName eq '$displayName'"
    } else {
        $AppProtectionPolicy = Get-MgBetaDeviceAppManagementManagedAppPolicy -All
    }

    foreach ($policy in $AppProtectionPolicy) {        
        $assignments = $null
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        if ($policy.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.androidManagedAppProtection") {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections('$($policy.Id)')/assignments"
        } elseif ($policy.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.iosManagedAppProtection") {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections('$($policy.Id)')/assignments"
        } elseif ($policy.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.windowsInformationProtectionAppLockerFileProtection") {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/windowsInformationProtectionAppLockerFileProtections('$($policy.Id)')/assignments"
        } elseif ($policy.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.windowsManagedAppProtections") {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/windowsManagedAppProtections('$($policy.Id)')/assignments"
        } elseif ($policy.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.targetedManagedAppConfiguration") {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/targetedManagedAppConfigurations('$($policy.Id)')/assignments"            
        } else {
            Write-Output "No App Protection Policy assignment found for $($policy.displayName)"
            continue
        }

        $assignments = Invoke-MgGraphRequest -Uri $uri -Headers @{ConsistencyLevel = "eventual"} -ContentType "application/json"

        foreach ($assignment in $assignments.value) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.target.groupId -ne $groupId) {
                continue
            }

            if ($assignment.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget") {
                $CurrentincludedGroup = (Get-MgBetaGroup -GroupId $($assignment.target.groupId)).DisplayName
                if ($($assignment.target.deviceAndAppManagementAssignmentFilterId) -and $assignment.target.deviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.target.deviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.target.'@odata.type' -eq "#microsoft.graph.exclusionGroupAssignmentTarget") {
                $excludedGroups += (Get-MgBetaGroup -GroupId $($assignment.target.groupId)).DisplayName
            } elseif ($assignment.target.'@odata.type' -eq "#microsoft.graph.allDevicesAssignmentTarget") {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.target.deviceAndAppManagementAssignmentFilterId) -and $assignment.target.deviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.target.deviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.target.'@odata.type' -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.target.deviceAndAppManagementAssignmentFilterId) -and $assignment.target.deviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.target.deviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $policy.DisplayName
                ProfileType = $policy.AdditionalProperties.'@odata.type' -replace '^#microsoft\.graph\.', ''
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneManagedDeviceAppConfigurationAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $AppConfiguration = Get-MgBetaDeviceAppManagementMobileAppConfiguration -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $AppConfiguration = Get-MgBetaDeviceAppManagementMobileAppConfiguration -All -ExpandProperty "assignments"
    }

    foreach ($config in $AppConfiguration) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $config.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allLicensedUsersAssignmentTarget') {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $config.DisplayName
                ProfileType = "Managed Device App Configuration"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneDeviceManagementSecurityBaselineAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $SecurityBaseline = Get-MgBetaDeviceManagementIntent -Filter "displayName eq '$displayName'" -ExpandProperty assignments
    } else {
        $SecurityBaseline = Get-MgBetaDeviceManagementIntent -All -ExpandProperty assignments
    }

    foreach ($baseline in $SecurityBaseline) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $baseline.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allLicensedUsersAssignmentTarget') {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $baseline.DisplayName
                TemplateName = (Get-MgBetaDeviceManagementTemplate -DeviceManagementTemplateId $baseline.TemplateId).DisplayName
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneDeviceCompliancePolicyAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $CompliancePolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $CompliancePolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy -All -ExpandProperty "assignments"
    }

    foreach ($policy in $CompliancePolicy) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $policy.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allLicensedUsersAssignmentTarget') {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $policy.DisplayName
                ProfileType = $policy.AdditionalProperties.'@odata.type' -replace '^#microsoft\.graph\.', ''
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneDeviceConfigurationAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $DeviceConfiguration = Get-MgBetaDeviceManagementDeviceConfiguration -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $DeviceConfiguration = Get-MgBetaDeviceManagementDeviceConfiguration -All -ExpandProperty "assignments"
    }

    foreach ($config in $DeviceConfiguration) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $config.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allLicensedUsersAssignmentTarget') {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $config.DisplayName
                ProfileType = $config.AdditionalProperties.'@odata.type' -replace '^#microsoft\.graph\.', ''
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneDeviceConfigurationAdministrativeTemplatesAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $AdministrativeTemplate = Get-MgBetaDeviceManagementGroupPolicyConfiguration -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $AdministrativeTemplate = Get-MgBetaDeviceManagementGroupPolicyConfiguration -All -ExpandProperty "assignments"
    }

    foreach ($template in $AdministrativeTemplate) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $template.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                $CurrentincludedGroup = "All Devices"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allLicensedUsersAssignmentTarget') {
                $CurrentincludedGroup = "All Users"
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $template.DisplayName
                ProfileType = "AdministrativeTemplates"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneRemediationScriptAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $RemediationScript = Get-MgBetaDeviceManagementDeviceHealthScript -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $RemediationScript = Get-MgBetaDeviceManagementDeviceHealthScript -All -ExpandProperty "assignments"
    }

    foreach ($script in $RemediationScript) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $script.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $script.DisplayName
                ProfileType = "Remediation Script"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneAutopilotProfileAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $AutopilotProfile = Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $AutopilotProfile = Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile -All -ExpandProperty "assignments"
    }

    foreach ($profile in $AutopilotProfile) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $profile.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $profile.DisplayName
                ProfileType = "Autopilot Profile"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneDeviceManagementScriptAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $DeviceManagementScript = Get-MgBetaDeviceManagementScript -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $DeviceManagementScript = Get-MgBetaDeviceManagementScript -All -ExpandProperty "assignments"
    }

    foreach ($script in $DeviceManagementScript) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $script.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $script.DisplayName
                ProfileType = "Device Management Script"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}

function Get-IntuneWindowsInformationProtectionPolicyAssignment {
    param (
        [Parameter(Mandatory = $false)]
        [string]$displayName,
        [Parameter(Mandatory = $false)]
        [string]$groupId
    )

    if ($displayName) {
        $WIPPolicy = Get-MgBetaDeviceAppManagementMdmWindowsInformationProtectionPolicy -Filter "displayName eq '$displayName'" -ExpandProperty "assignments"
    } else {
        $WIPPolicy = Get-MgBetaDeviceAppManagementMdmWindowsInformationProtectionPolicy -All -ExpandProperty "assignments"
    }

    foreach ($policy in $WIPPolicy) {
        $includedGroups = @()
        $excludedGroups = @()
        $FilterName = @()

        $assignments = $policy.Assignments
        foreach ($assignment in $assignments) {
            # Skip if we're looking for a specific group and this isn't it
            if ($groupId -and $assignment.Target.AdditionalProperties.groupId -ne $groupId) {
                continue
            }

            if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget') {
                $CurrentincludedGroup = (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
                if ($($assignment.Target.DeviceAndAppManagementAssignmentFilterId) -and $assignment.Target.DeviceAndAppManagementAssignmentFilterId -ne [guid]::Empty) {
                    $FilterName = " | Filter: " + (Get-MgBetaDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $($assignment.Target.DeviceAndAppManagementAssignmentFilterId)).DisplayName
                } else {
                    $FilterName = " | No Filter"
                }
                $includedGroups += $CurrentincludedGroup + $FilterName
            } elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.exclusionGroupAssignmentTarget') {
                $excludedGroups += (Get-MgbetaGroup -GroupId $($assignment.Target.AdditionalProperties.groupId)).DisplayName
            }
        }

        # Only return results if we found assignments (and they match our group filter if specified)
        if ($includedGroups.Count -gt 0 -or $excludedGroups.Count -gt 0) {
            [PSCustomObject]@{
                DisplayName = $policy.DisplayName
                ProfileType = "Windows Information Protection Policy"
                IncludedGroups = $includedGroups
                ExcludedGroups = $excludedGroups
            }
        }
    }
}