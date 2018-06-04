<# $dr["Iteraplan_ID"] = $_.Iteraplan_ID part of subscription name
    $dr["IpAdress_RANGE"] = $_.IpAdress_RANGE
    $dr["AzSK_Status"] = $_.AzSK_Status check for AzSK RG within the supscription
    # otherwise find information out of Tags

#Example Name strings 
<#
PROJ, E.ON SEE Development        (75273),  PSP 9914.P00341.003
PROJ, EEG SME Datensammler,                 PSP 9914.P00780.002.80
RUN, BI CZ,                       (79141),  PSP 9914.N10027.200.43.01.01
RUN, Digital E.ON DataLake,                 PSP 9914.C12991.100.01
PoC, Customer Datamart HU,       (78957),       9914.N10027.200.43.01.01
#>

    #variables upon which substrings are to be cast
    $EnviromentStatus  
    $Projektname  
    $Iteraplan 
    $PSP_Element 

    # Functions
    #region functions

    #
    #
    function parse-data{
        
        param(
            [string][Parameter(Mandatory=$true)] $AzureRmSubscriptionId ,
            [string]$delimiter = "," 
        )

        #$EnviromentStatus
        $EnviromentStatus = $AzureRmSubscriptionId.Split($delimiter)[0]
        write-host "EnviromentStatus :"$EnviromentStatus 

        #$Projektname
        $Projektname = $AzureRmSubscriptionId.Split($delimiter)[1]
        if($Projektname.Contains("(")){
            $Projektname = $Projektname.Substring(0,$Projektname.IndexOf("("))
        }
        $ProjektName = $Projektname.Trim()
        write-host "Projektname :"$Projektname
    
        #Iteraplan
        #durch regex ersetzen? anzahl fest? mit oder ohne klammern?
        if($AzureRmSubscriptionId.contains("(")){
            [int]$posAlpha = $AzureRmSubscriptionId.IndexOf("(")+1
            $Iteraplan = $AzureRmSubscriptionId.Substring($posAlpha,5)
        }
        else{
            $Iteraplan = $null
        }
        if($Iteraplan -ne $null){
            write-host "Iteraplan :"$Iteraplan
        }

        #immer 4 zahlen vor punkt?
        #must be non-null?
        #PSP_Element
        $rePSP = [regex]"[0-9]{4}\.([A-Z0-9]*\.*)*"
        $PSP_Element = $rePSP.match($AzureRmSubscriptionId).Value
        write-host "PSP_Element :"$PSP_Element
    }

    #endregion

    #string values,our test data
    [string] $a = "PROJ, E.ON SEE Development        (75273),  PSP 9914.P00341.003"
    [string] $b = "PROJ, EEG SME Datensammler,                 PSP 9914.P00780.002.80"
    [string] $c = "RUN, BI CZ,                       (79141),  PSP 9914.N10027.200.43.01.01"
    [string] $d = "RUN, Digital E.ON DataLake,                 PSP 9914.C12991.100.01"
    [string] $e = "PoC, Customer Datamart HU,       (78957),       9914.N10027.200.43.01.01"

    #array holding our string test data
    [string[]] $testData = @($a,$b,$c,$d,$e)

    #foreach loop iterating over $testData
    foreach($element in $testData){
        write-host "Element :"$element -f green
        parse-data $element
    }