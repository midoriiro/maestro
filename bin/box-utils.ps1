. "./common-utils.ps1"

function GetVariants()
{
	return @("debian-11")
}

function CheckVariant()
{
	Param(
		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$Variant
	)
	$variants = [string[]](GetVariants)
	if([string]::IsNullOrEmpty($Variant) -or -not $variants.Contains($Variant))
	{
		throw [System.Exception] "Variant verification failed"
	}
}

function SetPackerCacheFolder()
{
	$settings = GetSettings
	$rootFolder = Resolve-Path -Path $settings["root-folder"]
	$Env:PACKER_CACHE_DIR  = "$rootFolder/packer_cache"
}

function GetProjectRoot()
{
	return "$PSScriptRoot/../01-preparing-boxes"
}

function GetVarFile()
{
	Param(
		[Parameter(Mandatory=$true)]
		[string]$Variant
	)
	$projectRoot = GetProjectRoot
	return "$projectRoot/variants/$Variant/os.pkrvars.hcl"
}

function GetPreseedFile()
{
	Param(
		[Parameter(Mandatory=$true)]
		[string]$Variant
	)
	$projectRoot = GetProjectRoot
	return "$projectRoot/variants/$Variant/preseed.pkrtpl.hcl"
}

function ExecutePacker()
{
	Param(
		[Parameter(Mandatory=$true)]
		[string]$Command,
		[Parameter(Mandatory=$true)]
		[string]$Stage,
		[Parameter(Mandatory=$true)]
		[string]$Variant,
		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$PackerArguments
	)
	IsPackerVersionCorrect
	SetPackerCacheFolder
	$projecRoot = GetProjectRoot
	$varFile = GetVarFile -Variant $variant
	$preseedFile = GetPreseedFile -Variant $variant
	$settings = GetSettings
	$settingsRootFolder = Resolve-Path -Path $settings["root-folder"]
	$settingsHeadless = $settings["headless"].ToString().ToLower()
	$settingsSshUsername = $settings["ssh-username"]
	$settingsSshPublicKey = Resolve-Path -Path $settings["ssh-public-key"]
	$settingsSshPrivateKey = Resolve-Path -Path $settings["ssh-private-key"]
	Start-Process packer `
        -ErrorAction Stop `
        -PassThru `
        -Wait `
        -NoNewWindow `
        -ArgumentList `
            "$Command", `
            "-parallel-builds=1", `
            "-only=$Stage", `
            "-var-file=$varFile", `
            "-var guest-os-preseed-file=$preseedFile", `
            "-var root-folder=$settingsRootFolder", `
            "-var headless=$settingsHeadless", `
            "-var ssh-username=$settingsSshUsername", `
            "-var ssh-public-key=$settingsSshPublicKey", `
            "-var ssh-private-key=$settingsSshPrivateKey", `
            "$PackerArguments", `
            "$projecRoot/."
}