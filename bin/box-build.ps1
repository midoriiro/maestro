. "./box-utils.ps1"

function Stage1()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$PackerArguments
    )
    try
    {
        ExecutePacker -Command "build -force" -Stage "stage1*" -Variant $Variant -PackerArguments $PackerArguments
    }
    catch
    {
        Write-Output "Error during packer build stage 1 execution"
        Write-Output $_
    }
}

function Stage2()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$PackerArguments
    )
    try
    {
        ExecutePacker -Command "build -force" -Stage "stage2*" -Variant $Variant -PackerArguments $PackerArguments
    }
    catch
    {
        Write-Output "Error during packer build stage 2 execution"
        Write-Output $_
    }
}

function Stage3()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$PackerArguments
    )
    try
    {
        ExecutePacker -Command "build -force" -Stage "stage3*" -Variant $Variant -PackerArguments $PackerArguments
    }
    catch
    {
        Write-Output "Error during packer build stage 3 execution"
        Write-Output $_
    }
}

function All()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Variant,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$PackerArguments
    )
    try
    {
        Stage1 -Variant $Variant -PackerArguments $PackerArguments -ErrorAction Stop
        Stage2 -Variant $Variant -PackerArguments $PackerArguments -ErrorAction Stop
        Stage3 -Variant $Variant -PackerArguments $PackerArguments -ErrorAction Stop
    }
    catch
    {
        Write-Output "Error during packer build stages execution"
        Write-Output $_
    }
}

function ShowUsage()
{
    $identation = ' ' * 4
    $variants = [string[]](GetVariants)
    Write-Output "Usage: maestro box build <subcommand> <variant> [<args>]"
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
$commands = "help", "stage1", "stage2", "stage3", "all"

if ($commands.Contains($command))
{
    $variant = $args[1]

    if($command -ne "help")
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

    $packerArguments = ""
    
    if($args.Length -gt 2)
    {
        $packerArguments = $args[2..($args.Length-1)] -join " "
    }

    switch($command)
    {
        "help" { ShowUsage }
        "stage1" { Stage1 -Variant $variant -PackerArguments $packerArguments }
        "stage2" { Stage2 -Variant $variant -PackerArguments $packerArguments }
        "stage3" { Stage3 -Variant $variant -PackerArguments $packerArguments }
        "all" { All -Variant $variant -PackerArguments $packerArguments }
    }
}
else
{
    ShowUsage
}