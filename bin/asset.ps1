. "./common-utils.ps1"
. "./cluster-utils.ps1"

function CheckRequirement()
{
    if(-not (IsYAMLModuleInstalled))
    {
        Write-Output "Powershell YAML module seem notinstalled. Execute: maestro asset install-modules"
    }

    try
    {
        IsPackerInPath
    }
    catch
    {
        Write-Output "Packer seem not to be registered in PATH environment variable"
    }

    try
    {
        IsPackerVersionCorrect
    }
    catch
    {
        Write-Output "Packer installed version should support HCL2 template language"
    }

    try
    {
        IsVagrantInPath
    }
    catch
    {
        Write-Output "Vagrant seem not to be registered in PATH environment variable"
    }

    if(-not (IsVagrantPluginInstalled))
    {
        Write-Output "Vagrant plugins seem not installed. Execute: maestro asset install-plugins"
    }
    
    if(-not (IsVagrantUtilityInstalled))
    {
        Write-Output "Vagrant VMware Utility seem not installed. Execute: maestro asset install-plugins"
    }
}

function InstallPlugins()
{
    try
    {
        if(IsVagrantInPath -and -not (IsVagrantPluginInstalled))
        {
            ExecuteVagrant -Arguments "plugin", "install", "vagrant-vmware-desktop"
        }

        if(-not (IsVagrantUtilityInstalled))
        {
            InstallVagrantUtility
        }
    }
    catch
    {
        Write-Output "Error during install plugins execution"
        Write-Host $_
    }
}

function InstallModules()
{
    try
    {
        if (IsYAMLModuleInstalled)
        {
            return
        }
        Write-Output "Installing powershell YAML module..."
        Start-Process powershell -Verb RunAs -ArgumentList {
            Install-Module powershell-yaml
        }
    }
    catch
    {
        Write-Output "Error during install modules execution"
        Write-Host $_
    }
}

function ShowUsage()
{
    Write-Output "Usage: maestro asset <subcommand> [<args>]"
    Write-Output "[<args>] Vagrant arguments"
    Write-Output "Available subcommands:"
    $identation = ' ' * 4
    foreach($command in $commands)
    {
        Write-Output "$identation$command"
    }
}

$command = [string]$args[0]
$commands = "help", "check-requirement", "install-plugins", "install-modules"

if($commands.Contains($command))
{
    switch($command)
    {
        "help" { ShowUsage }
        "check-requirement" { CheckRequirement }
        "install-plugins" { InstallPlugins }
        "install-modules" { InstallModules }
    }
}
else
{
    ShowUsage
}