. "./cluster-utils.ps1"

function InitBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "up", "--no-provision" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant starting boxes execution"
        Write-Output $_
    }
}

function ProvisionBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "provision" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant provisioning boxes execution"
        Write-Output $_
    }
}

function PackageBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "package" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant packaging boxes execution"
        Write-Output $_
    }
}

function ResumeBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "resume", "--no-provision" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant halting boxes execution"
        Write-Output $_
    }
}

function HaltBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "halt" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant halting boxes execution"
        Write-Output $_
    }
}

function DestroyBoxes()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "destroy", "--force" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant destroying boxes execution"
        Write-Output $_
    }
}

function SshConnection()
{
    Param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$VagrantArguments
    )
    try
    {
        ExecuteVagrant -Arguments "ssh" -VagrantArguments "$VagrantArguments"
    }
    catch
    {
        Write-Output "Error during vagrant destroying boxes execution"
        Write-Output $_
    }
}

function ShowUsage()
{
    Write-Output "Usage: maestro configure <subcommand> [<args>]"
    Write-Output "[<args>] Vagrant arguments"
    Write-Output "Available subcommands:"
    $identation = ' ' * 4
    foreach($command in $commands)
    {
        Write-Output "$identation$command"
    }
}

$args = $args -split " "
$command = $args[0]
$commands = "help", "init", "provision", "package", "resume", "halt", "destroy", "ssh"

if ($commands.Contains($command))
{
    $vagrantArguments = ""

    if($args.Length -gt 1)
    {
        $vagrantArguments = $args[1..($args.Length-1)] -join " "
    }

    switch($command)
    {
        "help" { ShowUsage -VagrantArguments $vagrantArguments }
        "init" { InitBoxes -VagrantArguments $vagrantArguments }
        "provision" { ProvisionBoxes -VagrantArguments $vagrantArguments }
        "package" { PackageBoxes -VagrantArguments $vagrantArguments }
        "resume" { ResumeBoxes -VagrantArguments $vagrantArguments }
        "halt" { HaltBoxes -VagrantArguments $vagrantArguments }
        "destroy" { DestroyBoxes -VagrantArguments $vagrantArguments }
        "ssh" { SshConnection -VagrantArguments $vagrantArguments }
    }
}
else
{
    ShowUsage
}