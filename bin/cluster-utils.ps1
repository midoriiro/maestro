. "./common-utils.ps1"

function GetVersion()
{
	$path = "$PSScriptRoot/../VERSION"
	return [string](Get-Content -Raw $path)
}

function SetVagrantDotFilePath()
{
	$settings = GetSettings
	$rootFolder = Resolve-Path -Path $settings["root-folder"]
	$version = GetVersion
	$Env:VAGRANT_DOTFILE_PATH = "$rootFolder/$version/stage-4"
}

function ExecuteVagrant()
{
	Param(
		[Parameter(Mandatory=$true)]
		[string[]]$Arguments,
		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$VagrantArguments
	)
	if(-not (IsVagrantPluginInstalled))
	{
		Write-Error "Vagrant not installed" -ErrorAction Stop
	}
	SetVagrantDotFilePath
	Start-Process vagrant `
        -ErrorAction Stop `
        -PassThru `
        -Wait `
        -NoNewWindow `
        -ArgumentList `
			"$Arguments",`
        	"$VagrantArguments" `
        -WorkingDirectory "$PSScriptRoot/../02-configuring-cluster/."
}