$logFile = "routerjack_logs.txt";
function doLogFile() {
if(Test-Path -PathType Leaf $logFile) {
Write-Host "[#] File exists" -ForegroundColor yellow;
}
else {
Write-Host "[#] Creating File" -ForegroundColor yellow;
$f=New-Item -Path $logFile;
}
$global:useLogFile = 1;
Add-Content $logFile "[ USING LOG FILE $logFile ]";
Write-Host "[+] Using Log File $logFile" -ForegroundColor green;
}
function localProfileEnum {
if($useLogFile) {
Add-Content $logFile "======== LOCAL PROFILE ENUMERATION ========";
}
$y = $(netsh wlan show profile); foreach($a in $y.split("`n")) {try {$network = $a.substring(27).Trim();Write-Host $network; Write-Host "`n"; $password = $(netsh wlan show profile $network key=clear); foreach($m in $password.replace(" "," - ")) {$l = $m | Select-String "Key Content"; Write-Host $network,$m -ForegroundColor cyan; if($useLogFile) {Add-Content $logFile $network,$m} }} catch{};}
}
function canAccess($path) {
try {
$req = Invoke-WebRequest $path;
if($req.StatusCode -eq 200) {
return 1;
}
else {
return 0;
}
}
catch {
return 0;
}
}

function routerEnum($ipAddress) {
Write-Host "====== Testing for an optus router ======" -ForegroundColor cyan;
if($useLogFile) {
Add-Content $logFile "====== Router Enumeration On '$ipAddress' ======";
Add-Content $logFile "====== Testing for an optus router ======";
}
$optusPath = "$ipAddress/optusme.html";
$optusDevicePath = "$ipAddress/network.cmd?action=view";
if(canAccess($optusPath)) {
Write-Host "[+] '$optusPath' exists" -ForegroundColor green;
if($useLogFile) {
Add-Content $logFile "====== '$optusPath' exists ======";
}
}
else {
Write-Host "[-] '$optusPath' does not exist" -ForegroundColor red;
if($useLogFile) {
Add-Content $logFile "====== '$optusPath' does not exist ======";
}
}
if(canAccess($optusDevicePath)) {
Write-Host "[+] Can access '$optusDevicePath'; this can be used to enumerate devices" -ForegroundColor green;
if($useLogFile) {
Add-Content $logFile "====== Can access '$optusDevicePath'; this can be used to enumerate devices ======";
}
}
else {
Write-Host "[-] '$optusDevicePath' does not exist";
if($useLogFile) {
Add-Content $logFile "====== '$optusDevicePath' does not exist ======";
}
}
}

function doAnalytics($ipAddress) {
if($useLogFile) {
Add-Content $logFile "======== Running DNS Scan On $ipAddress ========";
}
$baseIpAddress = $ipAddress.split(".")[0] + "." + $ipAddress.split(".")[1] +"."+ $ipAddress.split(".")[2] + ".";
Write-Host "[#] Subnet IP Address :" $baseIpAddress -ForegroundColor yellow;
Write-Host "[#] Starting DNS Scan..." -ForegroundColor yellow ;
if($useLogFile) {
Add-Content $logFile "[#] Subnet IP Address : baseIpAddress";
Add-Content $logFile "[#] Starting DNS Scan...: $baseIpAddress";
}
foreach($suffix in 1..256) {
$fullIp = $baseIpAddress + $suffix;
$cmdOutput = nslookup $fullIp 2>routerjack_errors.txt;
$cmdOutput = $cmdOutput|Select-String "Name:" | Out-String;
$cmdOutput = $cmdOutput.replace("Name:","").replace(" ","").replace("`n","");
if($cmdOutput) {
Write-Host $fullIp -ForegroundColor cyan;
Write-Host $cmdOutput -ForegroundColor cyan;
Write-Host "===================" -ForegroundColor yellow;
if($useLogFile) {
Add-Content $logFile $fullIp;
Add-Content $logFile $cmdOutput;
Add-Content $logFile "===================";
}
}
}
}
function getAllInterfaces {
return Get-NetAdapter;
}
function printAllInterfaces {
$interfaces = getAllInterfaces;
Add-Content $logFile "======= ALL INTERFACE ENUMERATION =======";
foreach($interface in $interfaces) {
Write-Host "[#] Name : " $interface.Name;
Write-Host "[#] Description : " $interface.InterfaceDescription;
Write-Host "[#] MAC Address : " $interface.MacAddress;
Write-Host "[#] Status : " $interface.Status;
Write-Host "";
if($useLogFile) {
Add-Content $logFile "[#] Name :";
Add-Content $logFile $interface.Name;
Add-Content $logFile "[#] Description : ";
Add-Content $logFile $interface.InterfaceDescription;
Add-Content $logFile "[#] MAC Address : ";
Add-Content $logFile $interface.MacAddress;
Add-Content $logFile "[#] Status : ";
Add-Content $logFile $interface.Status;
Add-Content $logFile "";
}
}}
function getUpInterfaces {
$upInterfaces = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
return $upInterfaces;
}
function printAllUpInterfaces {
$interfaces = getUpInterfaces;
foreach($interface in $interfaces) {
Write-Host "[#] Name : " $interface.Name;
Write-Host "[#] Description " : $interface.InterfaceDescription;
Write-Host "[#] MAC Address " : $interface.MacAddress;
Write-Host "[#] Status " : $interface.Status;
Write-Host "";

if($useLogFile) {
Add-Content $logFile "[#] Name :";
Add-Content $logFile  $interface.Name;
Add-Content $logFile "[#] Description :";
Add-Content $logFile $interface.InterfaceDescription;
Add-Content $logFile "[#] MAC Address : ";
Add-Content $logFile $interface.MacAddress;
Add-Content $logFile "[#] Status :";
Add-Content $logFile $interface.Status;
Add-Content $logFile "";
}
}}
function printHelp {
Write-Host @"
help - show this command
await - wait for a router connection on interface and then run a dns scan
connected - show connected interfaces
interfaces - show all interfaces
dnsscan - DNS Scan Of Interface
routerenum - enumerate router
profiles - enumerate local adapter profiles (passwords)
logfile - save information to a log file
exit - quit the program
"@ -Foregroundcolor cyan;
}
function get_options {
$option = Read-Host "OPTION >>";
$option = $option.ToLower();
if($option -eq "help") {
printHelp;
}
elseif($option -eq "exit") {
break;
}
elseif($option -eq "routerenum") {

$routerIp = Read-Host "[ROUTERENUM] IP Address Of Router (default:mygateway.home) : ";
if($routerIp -eq "") {
$routerIp = "mygateway.home";
Write-Host "[#] Defaulted to mygateway.home" -ForegroundColor yellow;
}
else {
Write-Host "[#] Enumerating $routerIp" -ForegroundColor yellow;
}
routerEnum($routerIp);
}
elseif($option -eq "await") {
printAllInterfaces;
$nameToCheck = Read-Host "ADAPTER NAME >>: ";
if(Get-NetAdapter | where Name -eq $nameToCheck) {
Write-Host "[+] Valid Adapter Name" -ForegroundColor green;
if($useLogFile) {
Add-Content $logFile "[+] Valid Adapter Name: $nameToCheck";
}
}
else {
Write-Host "[-] Invalid Adapter Name" -Foregroundcolor red;
if($useLogFile) {
Add-Content $logFile "[-] Invalid Adapter Name: $nameToCheck";
}
break;
}
Write-Host "[%] Waiting for a connection" -ForegroundColor cyan;
if($useLogFile) {
Add-Content $logFile "[%] Waiting for a connection";
}
$interface_up = 0;
while($interface_up -ne 1) {
if((Get-NetAdapter | where Name -eq $nameToCheck).Status -eq "Up") {
$interface_up = 1;
}
sleep -s 1;
}

Write-Host "[+++] Adapter Up" -ForegroundColor green;
if($useLogFile) {
Add-Content $logFile "[+++] Adapter Up";
}
$ipAddress = (Get-NetIPAddress | where InterfaceAlias -eq $nameToCheck | where PrefixLength -ne 64).IPAddress;
Write-Host "[+] IP Address : " $ipAddress -ForegroundColor green;
Add-Content $logFile "[+] IP Address : $ipAddress";


doAnalytics($ipAddress);
}
elseif($option -eq "connected") {
printAllUpInterfaces;
}
elseif($option -eq "interfaces") {
printAllInterfaces;
}
elseif($option -eq "profiles") {
localProfileEnum;
}
elseif($option -eq "logfile") {
doLogFile;
}
elseif($option -eq "dnsscan") {
printAllUpInterfaces;
$nameToCheck = Read-Host "ADAPTER NAME >>: ";
if(Get-NetAdapter | where Name -eq $nameToCheck) {
Write-Host "[+] Valid Adapter Name" -ForegroundColor green;
}
else {
Write-Host "[-] Invalid Adapter Name" -ForegroundColor red;
break;
}
$ipAddress = (Get-NetIPAddress | where InterfaceAlias -eq $nameToCheck | where PrefixLength -ne 64).IPAddress;
Write-Host "[+] IP Address : " $ipAddress -ForegroundColor green;
doAnalytics($ipAddress);
}
else {
Write-Host "[-] Invalid Option" -ForegroundColor red;
printHelp;
}
}

function main() {
Write-Host @"
[ 	routerview               ]
[         A tool by puckblush          ]
[ https://github.com/puckblush/routerview/ ]
"@ -ForegroundColor cyan;
printHelp;
while($true) {
get_options;
}
}
main;
