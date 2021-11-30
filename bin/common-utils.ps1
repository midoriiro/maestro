function GetSettings()
{
	try
	{
		$path = "$PSScriptRoot/../settings.yaml"
		$content = [string](Get-Content -Raw $path)
		return ConvertFrom-Yaml -Yaml $content
	}
	catch
	{
		Write-Output "Error during settings parsing"
		Write-Output $_
	}
}

function IsYAMLModuleInstalled()
{
	return (Get-Module -ListAvailable -Name powershell-yaml)
}

function IsPackerInPath()
{
	if(-not (Get-Command "packer" -ErrorAction SilentlyContinue))
	{
		Write-Error "Packer must be register in PATH environment variable" -ErrorAction Stop
	}
}

function IsPackerVersionCorrect()
{
	IsPackerInPath
	$processInfo = New-Object System.Diagnostics.ProcessStartInfo
	$processInfo.FileName = "packer"
	$processInfo.RedirectStandardOutput = $true
	$processInfo.RedirectStandardError = $true
	$processInfo.UseShellExecute = $false
	$processInfo.Arguments = "version"
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $processInfo
	$process.Start() | Out-Null
	$process.WaitForExit()
	$stdout = $process.StandardOutput.ReadToEnd()
	$stderr = $process.StandardError.ReadToEnd()
	
	if(![string]::IsNullOrEmpty($stderr))
	{
		Write-Error "An error occured during packer version verification"
		Write-Error $stderr -ErrorAction Stop
	}
	
	if($stdout -match "(?<major>\d+)\.(?<minor>\d+)\.(?<revision>\d+)")
	{
		$major = [int]$Matches.major
		$minor = [int]$Matches.minor
		$revision = [int]$Matches.revision
		
		if($major -ge 1 -and $minor -lt 7) # if version is under 1.7
		{
			Write-Error `
                "Packer v$major.$minor.$revision does not support HCL2 templates language" `
                -ErrorAction Stop
		}
	}
	else
	{
		Write-Error "Unable to parse packer version" -ErrorAction Stop
	}
}

function IsVagrantInPath()
{
	if(-not (Get-Command "vagrant" -ErrorAction SilentlyContinue))
	{
		Write-Error "Vagrant must be register in PATH environment variable" -ErrorAction Stop
	}
}

function IsVagrantPluginInstalled()
{
	IsVagrantInPath
	$processInfo = New-Object System.Diagnostics.ProcessStartInfo
	$processInfo.FileName = "vagrant"
	$processInfo.RedirectStandardOutput = $true
	$processInfo.RedirectStandardError = $true
	$processInfo.UseShellExecute = $false
	$processInfo.Arguments = "plugin list"
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $processInfo
	$process.Start() | Out-Null
	$process.WaitForExit()
	$stdout = $process.StandardOutput.ReadToEnd()
	$stderr = $process.StandardError.ReadToEnd()
	
	
	if (![string]::IsNullOrEmpty($stderr))
	{
		Write-Error "An error occured during vagrant plugin verification"
		Write-Error $stderr -ErrorAction Stop
	}
	
	return $stdout -match "vagrant-vmware-desktop"
}

function IsVagrantUtilityInstalled()
{
	$product = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall).Name | `
		ForEach-Object { $path = "Registry::$_"; Get-ItemProperty $path } | `
		Where-Object { $_.DisplayName -like "Vagrant VMware Utility" } | `
		Select-Object -Property DisplayName
	return $null -ne $product
}

function GetVagrantUtilityVersion()
{
	return "1.0.21"
}

function InstallVagrantUtility()
{
	$version = GetVagrantUtilityVersion
	Invoke-WebRequest `
            -Uri "https://releases.hashicorp.com/vagrant-vmware-utility/$version/vagrant-vmware-utility_$($version)_x86_64.msi" `
            -OutFile "$env:TEMP/vagrant-vmware-utility_$($version)_x86_64.msi"
	
	Start-Process "$env:TEMP/vagrant-vmware-utility_$($version)_x86_64.msi" -Wait
}