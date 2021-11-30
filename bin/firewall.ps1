function IsRuleExist()
{
    try
    {
        Get-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        return $true
    }
    catch
    {
        return $false
    }
}

function CreateOrUpdateRule()
{
    $cidr = ""

    while($true)
    {
        $cidr = Read-Host "Please enter your VMWare Nat CIDR (e.g. 192.168.0.0/24)"
        if($cidr -match "^(\d{1,3}\.){3}(\d{1,3})\/(\d{1,2})$")
        {
            break
        }
    }

    if(IsRuleExist)
    {
        Set-NetFirewallRule -LocalAddress $cidr -DisplayName $ruleName -Direction Inbound -Profile Any -Action Allow
    }
    else
    {
        New-NetFirewallRule -LocalAddress $cidr -DisplayName $ruleName -Direction Inbound -Profile Any -Action Allow

    }
}

function Enable()
{
    if(IsRuleExist)
    {
        Set-NetFirewallRule -DisplayName $ruleName -Enabled True
    }
    Show
}

function Disable()
{
    if(IsRuleExist)
    {
        Set-NetFirewallRule -DisplayName $ruleName -Enabled False
    }
    Show
}

function Show()
{
    try
    {
        $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        $ruleObject = $rule | Select-Object -Property DisplayName,Enabled,Direction,Action,Profile
        $filterObject = $rule | Get-NetFirewallAddressFilter | Select-Object -Property LocalAddress
        $ruleObject | Add-Member -NotePropertyName LocalAddress -NotePropertyValue $filterObject.LocalAddress
        Write-Output $ruleObject
        Read-Host "`nPress any key to continue..."
    }
    catch
    {
        Write-Output "Nat firewall rule doest not exist !"
        CreateOrUpdateRule
        Show
    }
}

function ShowUsage()
{
    Write-Output "Usage: maestro firewall <subcommand>"
    Write-Output "Create or enable/disable firewall rule for nat networking. Elevated shell needed."
    Write-Output "Available subcommands:"
    $identation = ' ' * 4
    foreach($command in $commands)
    {
        Write-Output "$identation$command"
    }
    Read-Host "`nPress any key to continue..."
}

$args = $args[0] -split " "
$command = $args[0]
$commands = @("help", "enable", "disable", "show")
$ruleName = "VMWare NAT"

if ($commands.Contains($command))
{
    $subcommand_args = $args[1..($args.Length-1)]

    switch($command)
    {
        "help" { ShowUsage }
        "enable" { Enable }
        "disable" { Disable }
        "show" { Show }
    }
}
else
{
    ShowUsage
}