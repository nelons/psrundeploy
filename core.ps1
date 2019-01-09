## Don't change this after the script has been deployed - you'll lose deployment history on
## workstations and packages might be redeployed.
$registry_root = "HKLM:\Software\PSRunDeploy\Packages\";
$package_location = "\\smb_server\Software\_Packages";

## Check the registry for a value.
function check_if_run {
    param ($registry_value_name, $advert_value)
    process {
        $result = $false;

        # Check
        if (Test-Path $registry_root) {
            $value = $(Get-Item -Path $registry_root).GetValue($registry_value_name);
            if ($value -ne $null) {
                # If the value is less than the advert value then run the package.
                if ($value -lt $advert_value) {
                    $result = $true;
                }
            } else {
                $result = $true;
            }
        } else {
            $result = $true;
        }

        return $result;
    }
}

function set_registry {
    param($registry_value_name)
    process {
        if ($(Test-Path $registry_root) -eq $false) {
            New-Item -Path $registry_root
        }

        $value = $(Get-Item -Path $registry_root).GetValue($registry_value_name);
        if ($value -eq $null) {
            #Create              
            New-ItemProperty -Path $registry_root -Name $registry_value_name -PropertyType "DWORD" -Value 1 | out-null;

        } else {
            # Update.
            Set-ItemProperty -Path $registry_root -Name $registry_value_name -Value 1
        }
    }
}

## Analyse a package.
function check_package {
    param($path)
    process {
        $run = $false;
        if (Test-Path "$($path.FullName)\package.json") {
            $config = Get-Content -Path "$($path.FullName)\package.json" | ConvertFrom-Json;

            $registry_value_name = $($path.Name);
            if ($config.info.registry -ne $null) {
                $registry_value_name = $config.info.registry;
            }

            ## Work out if this package applies to this workstation.
            foreach ($apply in $config.apply) {
                $advert_value = 0;
                if ($apply.value -ne $null) {
                    $advert_value = $apply.value;
                }

                if ($apply.all -ne $null) {
                    Write-Host "Package is to be applied to everything.";
                    $run = $true;
                }                
                elseif ($apply.regex -ne $null) {
                    #Write-Host "Applies to servers matching the regex $($apply.regex)";
                    if ($env:COMPUTERNAME -match $apply.regex) {
                        #Write-Host "This computer hostname matches the regex.";
                        if ($apply.run -ne "always") {
                            $run = check_if_run($registry_value_name, $advert_value);
                        } else {
                            $run = $true;
                        }
                    }
                } 
                elseif ($apply.hostnames -ne $null) {
                    #Write-Host "Package will be applied to hosts with names $($apply.hostnames)";
                    foreach ($hostname in $apply.hostnames) {
                        if ($env:COMPUTERNAME.toLower() -eq $hostname.toLower()) {
                            if ($apply.run -ne "always") {                            
                                $run = check_if_run($registry_value_name, $advert_value);
                                if ($run -eq $true) {
                                    break;                            
                                }  
                            } else {
                                $run = $true;
                            }
                        }
                    }
                }

                if ($run -eq $true) {
                    break;
                }
            }

            if ($run -eq $true) {
                Write-Host "Running the package $($path.Name)." -ForegroundColor Green;

                ## TODO run the package.
                switch ($config.run.type) {
                    "cmd" {
                        # TODO: should we specify this as being local/absolute ?
                        #$cmd = "$($path.FullName)\$($config.run.command)"
                        $cmd = $($config.run.command);
                        Write-Host "Running $cmd";
                        #$result = Invoke-Expression $config.run.command
                        $result = Start-Process $cmd -Wait;
                        Write-Host "Result was $result";
                    }
                }




                set_registry($registry_value_name);
            }
        }
        else {
            # There is no package file. What do we do ?
            Write-Host "There is no package file for $($path.Name)" -ForegroundColor Red
        }
    }
}

$packages = Get-ChildItem $package_location | Where-Object { $_.PSIsContainer };

foreach($package in $packages) {
    check_package($package);

}