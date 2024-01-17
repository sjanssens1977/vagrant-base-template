New-VMSwitch -SwitchName "NAT Switch" -SwitchType Internal
$ifIndex = Get-NetAdapter | Where-Object Name -eq "vEthernet (NAT Switch)" | Select -ExpandProperty "ifIndex"
New-NetIPAddress -IPAddress 192.168.77.1 -PrefixLength 24 -InterfaceIndex $ifIndex
New-NetNat -Name InternalNATnetwork -InternalIPInterfaceAddressPrefix 192.168.77.0/24