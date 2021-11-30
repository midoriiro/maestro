function ShowUsage()
{
    Write-Output "Usage: maestro <subcommand> [<args>]"
    Write-Output "Available subcommands:"
    foreach($command in $commands)
    {
        Write-Output "`t$command"
    }
}

$args = $args -split " "
$command = $args[0]
$commands = "help", "box", "cluster", "firewall", "asset"

if ($commands.Contains($command))
{
    $subcommand_args = $args[1..($args.Length-1)]

    switch($command)
    {
        "help" { ShowUsage }
        "box" {
            & "$PSScriptRoot\box.ps1" $subcommand_args
        }
        "cluster" {
            & "$PSScriptRoot\cluster.ps1" $subcommand_args
        }
        "firewall" {
            Start-Process powershell -Verb RunAs -ArgumentList "-file $PSScriptRoot/firewall.ps1 $subcommand_args"
        }
        "asset" {
            & "$PSScriptRoot\asset.ps1" $subcommand_args
        }
    }
}
else
{
    ShowUsage
}