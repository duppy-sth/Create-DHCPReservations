<#
.SYNOPSIS
    Creates DHCP Reservations from a CSV file
.DESCRIPTION
    CSV File to be exported from Intune & needs to be in the following format:
        ScopeID,DeviceName,MACAddress
		
	NOTE: This script adds reservations using a free IP address in the scope, so you'll need to have
	enough IP addresses free for the amount of devices you're adding.
.EXAMPLE
    
#>

# SCRIPT NAME: Create-DHCPReservations.ps1
# CREATOR: DU
# DATE: 15-11-23
# UPDATED: 9-2-2024
# VERSION: 1.1
# REFERENCES:
<# VERSION HISTORY:
    1.0.0 	: Quick 'n'dirty script
	1.1.0 	: Added sanity checks
	1.2.0 	: Added creation of CSV file containing the reservations created
	1.2.1	: Corrections
#>

# PREFERENCES

# VARIABLES

$OutputArray = @()

# START OF CODE

# Sanity checks

$NeededFree = Get-Content .\DHCP-Reservations.csv | Measure-Object -line | Select-Object -ExpandProperty Lines
$ActualFree = Get-DhcpServerv4ScopeStatistics -ComputerName $env:computername | Select-Object -ExpandProperty Free

if ($NeededFree -lt $ActualFree) {

	Write-Host "Backing up DHCP..."

	netsh dhcp server export .\dhcp.txt  all

	Write-Host "Creating reservations..."

	Import-Csv .\DHCP-Reservations.csv | foreach {
		$FreeIP = Get-DhcpServerv4FreeIPAddress -ScopeId $_.ScopeID
		Add-DhcpServerv4Reservation -ScopeId $_.ScopeID -IPAddress $FreeIP -ClientId $_.MACAddress -Name $_.DeviceName -Type Dhcp
		$OutputArray += Get-DhcpServerv4Reservation -ScopeId $_.ScopeID -ClientId $_.MACAddress | Select IPAddress, Name, ClientID
		}
		$OutputArray | Export-Csv -Path .\created-reservations.csv -NoTypeInformation
	Write-Host "Its done! (Providing you didn't get a load of errors just then :) "
	Write-Host "Newly created reservations have been saved to ""created-reservations.csv"""
	} else {
		Write-Host "There's not enough free IP addresses in the scope to make these reservations."
		Write-Host "Number of IP addresses required : $NeededFree"
		Write-Host "Number of IP addresses available : $ActualFree"
	}

