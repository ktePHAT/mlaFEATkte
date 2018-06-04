[string] $a = "PROJ, E.ON SEE Development        (75273),  PSP 9914.P00341.003"
[string] $b = "PROJ, EEG SME Datensammler,                 PSP 9914.P00780.002.80"
[string] $c = "RUN, BI CZ,                       (79141),  PSP 9914.N10027.200.43.01.01"
[string] $d = "RUN, Digital E.ON DataLake,                 PSP 9914.C12991.100.01"
[string] $e = "PoC, Customer Datamart HU,       (78957),       9914.N10027.200.43.01.01"


$rePSP = [regex]"[0-9]{4}\.([A-Z0-9]*\.*)*"
$reITE = [regex]"\([0-9]*\)"

[String]$Iterationsplan
[String]$PSP

$PSP = $rePSP.Match($a).value
$Iterationsplan =$reITE.match($a).value

write-host $PSP -f Yellow
Write-Host $Iterationsplan -f yellow