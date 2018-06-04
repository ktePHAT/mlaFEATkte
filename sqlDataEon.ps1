param(
$RGSeSAMESubID = "049a0549-6017-4270-8bb3-adcf29211e23", 
$RGSeSAMENAME = "RG-SeSAME", 
$SQLServerName = "sesame-sqldb-server", 
$Database = "SeSAME-SQLDB-Subscriptions", 
$ServerInstance = "sesame-sqldb-server.database.windows.net", 
$Username = "AzuRA_DB_Admin", 
$Password = "2018Subscription", 
$TableName = "Subscriptions"
)

Import-Module AzureRM
Import-Module SqlServer
Login-AzureRMAccount

#new approach ist to set the primary key by the project name
#build a second table for azure and join the sql tables later, since skripting for findidng these infos is going to be differetn

##make available by azure automation and use a secret for credentials
<#

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID `
-ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint


#>
#investigate to azure authentication..
# tenant id as parmeter
#automation 
#run from azure automation account
# storign credentials in there( key vault etc...

# 1.Create Dataset Table in Format of SQL Table

$ds = new-object System.Data.DataSet
#clear table within powershell for reuse
$ds.Tables[$TableName].Clear()
$ds.Tables.Add($TableName)
[void]$ds.Tables[$TableName].Columns.Add("Subscription_ID",[string])
[void]$ds.Tables[$TableName].Columns.Add("Tenant_ID",[string])
[void]$ds.Tables[$TableName].Columns.Add("Subscription_Name",[string])
[void]$ds.Tables[$TableName].Columns.Add("Subscription_State",[string])
[void]$ds.Tables[$TableName].Columns.Add("Subscription_Owner",[string])
[void]$ds.Tables[$TableName].Columns.Add("Security_Contacts",[string])
[void]$ds.Tables[$TableName].Columns.Add("Business_Unit",[string])
[void]$ds.Tables[$TableName].Columns.Add("Business_IT",[string])
[void]$ds.Tables[$TableName].Columns.Add("COST_PSP_ELEMENT",[string])
[void]$ds.Tables[$TableName].Columns.Add("Iteraplan_ID",[string])
[void]$ds.Tables[$TableName].Columns.Add("IpAdress_RANGE",[string])
[void]$ds.Tables[$TableName].Columns.Add("AzSK_Status",[string])

#3.Connect to SQL Database in Azure 

$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;User Id=$Username;Password=$Password"
$conn.open()
$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.connection = $conn


#4.Get subscriptions from SQL Table

$Query = "Select Subscription_ID From Subscriptions"


$SQLQueryDataSet = New-Object "System.Data.DataSet" "DataSet"

$sql = New-Object "System.Data.SqlClient.SqlDataAdapter" ($Query, $conn)

$tmp = $sql.Fill($SQLQueryDataSet)

$SQLSubscriptions = $SQLQueryDataSet.Tables.subscription_id



# 2.Get Information out of Azure and add into Table

$Subscriptions = Get-AzureRmSubscription 

foreach ($sub in $Subscriptions) 
{
    $dr = $ds.Tables[$TableName].NewRow()

    
    $dr["Subscription_ID"] = $Sub.Id
    $dr["Tenant_ID"] = $Sub.TenantId
    $dr["Subscription_Name"] = $Sub.Name
    $dr["Subscription_State"] = $Sub.State

    ####get owner by extracting co-admin####
    Select-AzureRmSubscription -Subscription $Sub.supscriptionId
    $SubOwner = Get-AzureRmRoleAssignment -IncludeClassicAdministrators -RoleDefinitionName CoAdministrator
    $dr["Subscription_Owner"] = $SubOwner.DisplayName 
    ####################################


    <#
    $dr["Security_Contacts"] = $_.Security_Contacts


    $dr["Business_Unit"] = $_.Business_Unit  needs to be added manually
    $dr["Business_IT"] = $_.Business_IT needs to be added manually
    $dr["COST_PSP_ELEMENT"] = $_.COST_PSP_ELEMENT part of subscription name #> 

    #get string out of name of Subscription and get relevant data
    [string]$SubName = Get-AzureRmSubscription

    $EnviromentStatus = 
    $Projektname = 
    $Iteraplan = 
    $PSP_Element = 

    # otherwise find information out of Tags

#Example Name strings 
<#
PROJ, E.ON SEE Development        (75273),  PSP 9914.P00341.003
PROJ, EEG SME Datensammler,                 PSP 9914.P00780.002.80
RUN, BI CZ,                       (79141),  PSP 9914.N10027.200.43.01.01
RUN, Digital E.ON DataLake,                 PSP 9914.C12991.100.01
PoC, Customer Datamart HU,       (78957),       9914.N10027.200.43.01.01
#>


   <# $dr["Iteraplan_ID"] = $_.Iteraplan_ID part of subscription name
    $dr["IpAdress_RANGE"] = $_.IpAdress_RANGE
    $dr["AzSK_Status"] = $_.AzSK_Status check for AzSK RG within the supscription
    #>

##########check for azsk status by looking for resourcegroup named azsk#####
       Select-AzureRmSubscription -Subscription $sub.SubscriptionId
       $RG_Names = Get-AzureRmResourceGroup | select ResourceGroupName
       $RG_Names.ToString()
       [boolean]$azskStatus = $false
       $dr["AzSK_Status"] = "Disabled"

       foreach($RG in $RG_Names)
            {
               if ($RG -like '*azsk*') { $azskStatus = $true
               break
               }
            }

       if($azskStatus -eq $true) 
             {$dr["AzSK_Status"] = "Enabled"
             } 
#############################################################

    $ds.Tables[$TableName].Rows.Add($dr)

}

#3. Write Table from 1. into SQL-Database
    #check for already existing Subscription_IDs and update Data here

foreach ($_ in $ds.Tables[$TableName]) 
{
    if ($SQLSubscriptions.Contains($_.Subscription_ID))
    {
        $CmdText = "UPDATE Subscriptions SET Subscription_Name = '{1}',Tenant_ID = '{2}',Subscription_State = '{3}',Subscription_Owner = '{4}',Security_Contacts = '{5}',Business_Unit = '{6}',Business_IT = '{7}',COST_PSP_ELEMENT = '{8}',Iteraplan_ID = '{9}',IpAdress_RANGE = '{10}',AzSK_Status = '{11}' WHERE Subscription_ID= '{0}'" -f $_.Subscription_ID,$_.Subscription_Name,$_.Tenant_ID,$_.Subscription_State,$_.Subscription_Owner,$_.Security_Contacts,$_.Business_Unit,$_.Business_IT,$_.COST_PSP_ELEMENT,$_.Iteraplan_ID,$_.IpAdress_RANGE,$_.AzSK_Status
    }
    else
    {
        $CmdText = "INSERT INTO Subscriptions (Subscription_ID,Subscription_Name,Tenant_ID,Subscription_State,Subscription_Owner,Security_Contacts,Business_Unit,Business_IT,COST_PSP_ELEMENT,Iteraplan_ID,IpAdress_RANGE,AzSK_Status) VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}')" -f $_.Subscription_ID,$_.Subscription_Name,$_.Tenant_ID,$_.Subscription_State,$_.Subscription_Owner,$_.Security_Contacts,$_.Business_Unit,$_.Business_IT,$_.COST_PSP_ELEMENT,$_.Iteraplan_ID,$_.IpAdress_RANGE,$_.AzSK_Status
    }
    
    $cmd.commandtext = $CmdText
    $cmd.executenonquery()
}

# 4.Close open sql connection and clear dataset table

$conn.close()
$ds.Tables[$TableName].Clear()


<# TESTDATEN MOCKK-UP
$Subscriptions = @{
   # Subscription_ID = [guid]::NewGuid().tostring();
   Subscription_ID = "subID123";
    Subscription_Name = "MartinSub";
    # Tenant_ID = [guid]::NewGuid().tostring();
    Tenant_ID = "tenantID123";
    Subscription_State = "Healthy";
    Subscription_Owner = "Martin";
    Security_Contacts = "Post";
    Business_Unit = "Devteam";
    Business_IT = "IT-Team";
    COST_PSP_ELEMENT = "32424";
    Iteraplan_ID = "234324";
    IpAdress_RANGE = "Range";
    AzSK_Status = "Top"
}
#>

#adding data which comes not programtically --> add ways
#work on front end for sql table
#access
#visual studio
# check on options


