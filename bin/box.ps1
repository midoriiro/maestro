. "./box-utils.ps1"

function Inspect()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant
    )
    try
    {
        ExecutePacker -Command "inspect" -Stage "*" -Variant $Variant
    }
    catch
    {
        Write-Output "Error during packer build stage 1 execution"
        Write-Output $_
    }
}

function Validate()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant
    )
    try
    {
        ExecutePacker -Command "validate" -Stage "*" -Variant $Variant
    }
    catch
    {
        Write-Output "Error during packer build stage 1 execution"
        Write-Output $_
    }
}

function ShowUsage()
{
    $identation = ' ' * 4
    $variants = [string[]](GetVariants)
    Write-Output "Usage: maestro box <subcommand> <variant> [<args>]"
    Write-Output "[<args>] Packer arguments"
    Write-Output "Available subcommands:"
    foreach($command in $commands)
    {
        Write-Output "$identation$command"
    }
    Write-Output "Available variants:"
    foreach($variant in $variants)
    {
        Write-Output "$identation$variant"
    }
}

$args = $args[0] -split " "
$command = $args[0]
$commands = "help", "inspect", "validate", "build"

if ($commands.Contains($command))
{
    $variant = $args[1]

    if($command -ne "help" -and $command -ne "build")
    {
        try
        {
            CheckVariant -Variant $variant
        }
        catch
        {
            Write-Output $_ -ErrorAction SilentlyContinue
            ShowUsage
            Exit
        }
    }

    $subcommand_args = $args[1..($args.Length-1)]

    switch($command)
    {
        "help" { ShowUsage }
        "inspect" { Inspect -Variant $variant }
        "validate" { Validate -Variant $variant }
        "build" { & "$PSScriptRoot\box-build.ps1" $subcommand_args }
    }
}
else
{
    ShowUsage
}