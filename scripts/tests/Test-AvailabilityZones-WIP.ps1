
Function Get-K2ConnectionStringValue
{
	Param(
	[Parameter(Mandatory=$false)][string]$ConnectionString="Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555",
	[Parameter(Mandatory=$true)]$SettingName
	)
	
	
    $ConnectionString.Split(";")| ForEach {
    	Write-Debug "found setting with name value pair of: $_ "
		If($_.StartsWith("$SettingName"))
		{
			
    		Write-Debug "found setting: $_ "
			[int]$PosOfFirstEquals = $_.IndexOf("=")
			$_.substring($PosOfFirstEquals + 1)
			###continue;
		}
 	}
}

###Get-K2ConnectionStringValue -SettingName "Port"
###Get-K2ConnectionStringValue -SettingName "Host"

Function Add-K2AvailabilityHours
{
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)]$workflowManagementServer,
	$zone,
	[Parameter(Mandatory=$false)][xml]$availabilityHours
	)
	
    $zone.AvailabilityHoursList.Clear();

    ###[System.Collections.ArrayList] $timezonecollectionlist = New-Object System.Collections.ArrayList;
	#Loop through all the environments in the XML
	$nodelist = $availabilityHours.selectnodes("/AvailabilityHours/AvailabilityHour") # XPath is case sensitive
	foreach ($AvailabilityHoursNode in $nodelist)
	{
	
        [SourceCode.Workflow.Management.AvailabilityHours]$availabilityHours = New-Object SourceCode.Workflow.Management.AvailabilityHours;
		[int]$workDay = $AvailabilityHoursNode.workDay
		[int]$TimeOfDay = $AvailabilityHoursNode.TimeOfDay.hours
		[int]$duration = $AvailabilityHoursNode.Duration.hours
		[int]$TimeOfDayMinutes = $AvailabilityHoursNode.TimeOfDay.minutes
		[int]$durationMinutes = $AvailabilityHoursNode.Duration.minutes
		[System.TimeSpan]$TimeofDayTS = New-Object System.TimeSpan($TimeOfDay,$TimeOfDayMinutes,0)
		[System.TimeSpan]$durationTS = New-Object System.TimeSpan($duration,$durationMinutes,0)
		
        $availabilityHours.WorkDay = $workDay
        $availabilityHours.TimeOfDay = $TimeofDayTS ;
        $availabilityHours.Duration = $durationTS;
        $zone.AvailabilityHoursList.Add($AvailabilityHours);
    }
	
}

Function GetK2AvailabilityASXmlHarness
{
   [CmdletBinding()]
   Param([Parameter(Mandatory=$false)][string]$ConnectionString="Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555",
	[Parameter(Mandatory=$true)][string]$ZoneName,
	[Parameter(Mandatory=$false)][string]$type="hours"
	)

	if ($workflowManagementServer -eq $null)
	{
		[Reflection.Assembly]::LoadWithPartialName(“SourceCode.Workflow.Management”) | out-null
		$workflowManagementServer = New-Object SourceCode.Workflow.Management.WorkflowManagementServer
		$workflowManagementServer.Open($ConnectionString) | out-null
	}
	if($type -eq "hours")
	{
		Get-K2AvailabilityHoursASXml -workflowManagementServer $workflowManagementServer -ZoneName $ZoneName
	}
	else
	{
		Get-K2AvailabilityDatesASXml -workflowManagementServer $workflowManagementServer -ZoneName $ZoneName
	}
}

Function Get-K2AvailabilityHoursASXml
{
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)]$workflowManagementServer,
	[string]$ZoneName
	)
	[xml]$templateHours = @"
      <AvailabilityHours>
      </AvailabilityHours>
"@

	[string]$templateHour = @"
      <AvailabilityHour workDay="[[WORKDAY]]">
        <Duration days="0" hours="[[DURATION_HOURS]]" minutes="[[DURATION_MINUTES]]"></Duration>
        <TimeOfDay days="0" hours="[[TIME_OF_DAY_HOURS]]" minutes="[[TIME_OF_DAY_MINUTES]]"></TimeOfDay>
      </AvailabilityHour>
"@
		
    $thisZone = $workflowManagementServer.ZoneLoad($ZoneName);
	$zoneAvailabilityHoursList = $thisZone.AvailabilityHoursList
	

	#Loop through all the AvailabilityHours in the zone
	##$nodelist = $availabilityHours.selectnodes("/AvailabilityHours/AvailabilityHour") # XPath is case sensitive
	foreach ($AvailabilityHour in $zoneAvailabilityHoursList)
	{
		
		# Creation of a node and its text
		$xmlEltAH = $templateHours.CreateElement("AvailabilityHour")
		# Creation of a node and its text
		$xmlEltDur = $templateHours.CreateElement("Duration")
		# Creation of a node and its text
		$xmlEltToD = $templateHours.CreateElement("TimeOfDay")
		$xmlEltAH.AppendChild($xmlEltDur) | Out-Null
		$xmlEltAH.AppendChild($xmlEltToD) | Out-Null
	
		$xmlEltAH.SetAttribute("workDay", [int]$availabilityHour.WorkDay ) | Out-Null
		
		
		$xmlEltDur.SetAttribute("hours", $availabilityHour.Duration.Hours) | Out-Null
		$xmlEltDur.SetAttribute("minutes", $availabilityHour.Duration.Minutes) | Out-Null
				
		$xmlEltToD.SetAttribute("hours", $availabilityHour.TimeOfDay.Hours) | Out-Null
		$xmlEltToD.SetAttribute("minutes", $availabilityHour.TimeOfDay.Minutes) | Out-Null

		$templateHours.SelectSingleNode("/AvailabilityHours").AppendChild($xmlEltAH)  | Out-Null
	}
	$templateHours.OuterXML
}

Function Get-K2AvailabilityDatesASXml
{
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)]$workflowManagementServer,
	[string]$ZoneName
	)
	[xml]$templateDates = @"
      <AvailabilityDates>
    </AvailabilityDates>
"@


	[string]$templateDateExample = @"
      <AvailabilityDate description="Christmas Day" date="2013-12-25T00:00:00" isNonWorkDate="True">
      </AvailabilityDate>
      <AvailabilityDate description="Christmas Eve" date="2013-12-25T08:00:00" isNonWorkDate="False">
        <TimeOfDay days="0" hours="8" minutes="0"></TimeOfDay>
        <Duration days="0" hours="5" minutes="0"></Duration>
      </AvailabilityDate>
"@

	
    $thisZone = $workflowManagementServer.ZoneLoad($ZoneName);
	$zoneAvailabilityDatesList = $thisZone.AvailabilityDateList
	

	#Loop through all the AvailabilityDates in the zone
	foreach ($AvailabilityDate in $zoneAvailabilityDatesList)
	{
		
		# Creation of a node and its text
		$xmlEltAD = $templateDates.CreateElement("AvailabilityDate")
		
		if(-not $AvailabilityDate.IsNonWorkDate)
		{
			# Creation of a node and its text
			$xmlEltDur = $templateDates.CreateElement("Duration")
			# Creation of a node and its text
			$xmlEltToD = $templateDates.CreateElement("TimeOfDay")
			$xmlEltAD.AppendChild($xmlEltDur) | Out-Null
			$xmlEltAD.AppendChild($xmlEltToD) | Out-Null
			
			$xmlEltDur.SetAttribute("hours", $availabilityDate.Duration.Hours) | Out-Null
			$xmlEltDur.SetAttribute("minutes", $availabilityDate.Duration.Minutes) | Out-Null
					
			$xmlEltToD.SetAttribute("hours", $availabilityDate.TimeOfDay.Hours) | Out-Null
			$xmlEltToD.SetAttribute("minutes", $availabilityDate.TimeOfDay.Minutes) | Out-Null
		}
		$xmlEltAD.SetAttribute("isNonWorkDate", $availabilityDate.IsNonWorkDate ) | Out-Null
		$xmlEltAD.SetAttribute("description", $availabilityDate.Description ) | Out-Null
		$xmlEltAD.SetAttribute("date", $availabilityDate.WorkDate) | Out-Null
		
		$templateDates.SelectSingleNode("/AvailabilityDates").AppendChild($xmlEltAD) | Out-Null		
	}
	$templateDates.OuterXML
}

   
   
"Start"
GetK2AvailabilityASXmlHarness -ZoneName "Powershelltest"
GetK2AvailabilityASXmlHarness -ZoneName "Powershelltest" -type "dates"
"end"   
Function Add-K2AvailabilityDate
{
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)]$workflowManagementServer,
	$zone,
	[Parameter(Mandatory=$false)][xml]$availabilityDates
	)
	
    $zone.AvailabilityDateList.Clear();

    ###[System.Collections.ArrayList] $timezonecollectionlist = New-Object System.Collections.ArrayList;
	#Loop through all the environments in the XML
	$nodelist = $availabilityDates.selectnodes("/AvailabilityDates/AvailabilityDate") # XPath is case sensitive
	foreach ($AvailabilityDateNode in $nodelist)
	{
	
        [SourceCode.Workflow.Management.AvailabilityDate]$availabilityDate = New-Object SourceCode.Workflow.Management.AvailabilityDate;
		[Datetime]$AvailabilityDateDateTime = [System.DateTime]::Parse($AvailabilityDateNode.date)
		[String]$AvailabilityDateDescription = $AvailabilityDateNode.description
		
		
        $availabilityDate.WorkDate = $AvailabilityDateDateTime;
        $availabilityDate.Description = $AvailabilityDateDescription;
                        
		if (!([System.Convert]::ToBoolean($AvailabilityDateNode.isNonWorkDate)))
		{
			[int]$duration = $AvailabilityDateNode.Duration.hours
			[int]$TimeOfDay = $AvailabilityDateNode.TimeOfDay.hours
            $availabilityDate.IsNonWorkDate = $false;
			[System.TimeSpan]$TimeofDayTS = New-Object System.TimeSpan($TimeOfDay,0,0)
			[System.TimeSpan]$durationTS = New-Object System.TimeSpan($duration,0,0)
			
	        $availabilityDate.TimeOfDay = $TimeofDayTS ;
	        $availabilityDate.Duration = $durationTS;
        }
		else
		{
		    $availabilityDate.IsNonWorkDate = $true;
			
        	
		}
		
		$zone.AvailabilityDateList.Add($availabilityDate);
    }
	
}   
   
Function Add-K2AvailabilityZone
{
<#
   .Synopsis
    This function Adds an availability zone to the K2 working hours clock
   .Description
    This function Adds an availability zone to the K2 working hours clock
	.Example
        TODO
	.Parameter $ConnectionString
        If not provided, it defaults to "Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555"
    .Parameter $workflowManagementServer
        If not provided it is created by connecting using ConnectionString
    .Parameter $AvailabilityZoneName
        Required. the name of the zone. Cannot be blank.
    .Parameter $AvailabilityZoneDescription
        The zone's description. It can be blank
    .Parameter $IsDefault
        defaults to false. If the first zone will be made true anyway!
    .Parameter GMTOffset
        defaults to 0
    .Parameter $availabilityDates
        xml in the following format
		
    <AvailabilityDates>
      <AvailabilityDate description="Christmas Day" date="2013-12-25T00:00:00" isNonWorkDate="True">
      </AvailabilityDate>
      <AvailabilityDate description="Christmas Eve" date="2013-12-24T00:00:00" isNonWorkDate="False">
        <TimeOfDay days="0" hours="13" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
        <Duration days="0" hours="5" minutes="0" seconds="0" milliseconds="0"></Duration>
      </AvailabilityDate>
    </AvailabilityDates>
	
	
    <AvailabilityDates />
	
    .Parameter availabilityHours
        xml in the following format:

    <AvailabilityHours>
      <AvailabilityHour workDay="5">
        <Duration days="0" hours="10" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="4">
        <Duration days="0" hours="10" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="3">
        <Duration days="0" hours="10" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="2">
        <Duration days="0" hours="10" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="1">
        <Duration days="0" hours="10" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
    </AvailabilityHours>
   .Notes
        AUTHOR: Lee Adams, K2
      #Requires -Version 2.0
#>  
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)][string]$ConnectionString="Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555",
	[Parameter(Mandatory=$false)]$workflowManagementServer=$null,
	[Parameter(Mandatory=$true)][System.String]$AvailabilityZoneName,
	[Parameter(Mandatory=$false)][System.String]$AvailabilityZoneDescription="",
	[Parameter(Mandatory=$false)][bool]$IsDefault=$false,
	[Parameter(Mandatory=$false)][int]$GMTOffset=0,
	[Parameter(Mandatory=$false)][xml]$availabilityDates,
	[Parameter(Mandatory=$false)][xml]$availabilityHours )

	if ($workflowManagementServer -eq $null)
	{
		[Reflection.Assembly]::LoadWithPartialName(“SourceCode.Workflow.Management”) | out-null
		$workflowManagementServer = New-Object SourceCode.Workflow.Management.WorkflowManagementServer
		$workflowManagementServer.Open($ConnectionString) | out-null
	}
	if (-not ([System.String]::IsNullOrEmpty($AvailabilityZoneName)) -or (-not ($workflowManagementServer.ZoneExists($AvailabilityZoneName))))
    {
		[SourceCode.Workflow.Management.AvailabilityZone] $newAvZone = New-Object SourceCode.Workflow.Management.AvailabilityZone
		$newAvZone.ZoneName = $AvailabilityZoneName;
		$newAvZone.ZoneDescription = $AvailabilityZoneDescription;
		$newAvZone.DefaultZone = $IsDefault;
		$newAvZone.ZoneGMTOffset = $GMTOffset;
		
		Add-K2AvailabilityHours -availabilityHours $AvailabilityHours -Zone $newAvZone
		Add-K2AvailabilityDate -availabilityDate $availabilityDates -Zone $newAvZone
		
		
		$workflowManagementServer.ZoneCreateNew($newAvZone)
	}
	else
    {
        Write-Error "$AvailabilityZoneName Zone already Exists"
    }
}

Function Remove-K2AvailabilityZone
{
<#
   .Synopsis
    This function Removes an availability zone from the K2 working hours clock
   .Description
    This function Removes an availability zone from the K2 working hours clock
	.Example
        TODO
	.Parameter $ConnectionString
        If not provided, it defaults to "Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555"
    .Parameter $workflowManagementServer
        If not provided it is created by connecting using ConnectionString
    .Parameter $UserOrGroup
        Required. Must be either "User" or "Group". case sensitive.
    .Parameter $UserOrGroupName
        Required. The fully qualified name of the user or group. It must include the securtity label
    .Parameter $PermissionType
        Required. A bitwise Enum of type [K2SmartObjectPermission] valid text values are "None", "Publish", "Delete", "Publish, Delete"
   .Notes
        AUTHOR: Lee Adams, K2
      #Requires -Version 2.0
#>  
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)][string]$ConnectionString="Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555",
	[Parameter(Mandatory=$false)]$workflowManagementServer=$null,
	[Parameter(Mandatory=$true)][System.String]$AvailabilityZoneName)

	if ($workflowManagementServer -eq $null)
	{
		[Reflection.Assembly]::LoadWithPartialName(“SourceCode.Workflow.Management”) | out-null
		$workflowManagementServer = New-Object SourceCode.Workflow.Management.WorkflowManagementServer
		$workflowManagementServer.Open($ConnectionString) | out-null
	}
	if (-not ([System.String]::IsNullOrEmpty($AvailabilityZoneName)) -and (($workflowManagementServer.ZoneExists($AvailabilityZoneName))))
    {
				
		$workflowManagementServer.ZoneDelete($AvailabilityZoneName)
	}
	else
    {
        Write-Error "$AvailabilityZoneName Zone does not Exists"
    }
}

Function Get-K2AvailabilityZoneAsXML 
{
<#
   .Synopsis
    This function Gets an availability zone as XML
   .Description
    This function Gets an availability zone as XML in the following format:
	
  <AvailabilityZone name="Powershelltest" GMToffset="0" description="test to automate K2 working hours" isDefault="True">
    <AvailabilityDates>
      <AvailabilityDate description="Christmas Day" date="2013-12-25T00:00:00" isNonWorkDate="True">
      </AvailabilityDate>
      <AvailabilityDate description="Christmas Eve" date="2013-12-25T08:00:00" isNonWorkDate="False">
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
        <Duration days="0" hours="5" minutes="0" seconds="0" milliseconds="0"></Duration>
      </AvailabilityDate>
    </AvailabilityDates>
    <AvailabilityHours>
      <AvailabilityHour workDay="0">
        <Duration days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="1">
        <Duration days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="2">
        <Duration days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="3">
        <Duration days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="4">
        <Duration days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
    </AvailabilityHours>
  </AvailabilityZone>
	.Example
        TODO
	.Parameter $ConnectionString
        If not provided, it defaults to "Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555"
    .Parameter $workflowManagementServer
        If not provided it is created by connecting using ConnectionString
    .Parameter $AvailabilityZoneName
        Required. the name of the zone. Cannot be blank.
   .Notes
        AUTHOR: Lee Adams, K2
      #Requires -Version 2.0
#>  
   [CmdletBinding()]
   Param(
	[Parameter(Mandatory=$false)][string]$ConnectionString="Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555",
	[Parameter(Mandatory=$false)]$workflowManagementServer=$null,
	[Parameter(Mandatory=$true)][System.String]$AvailabilityZoneName )

	if ($workflowManagementServer -eq $null)
	{
		[Reflection.Assembly]::LoadWithPartialName(“SourceCode.Workflow.Management”) | out-null
		$workflowManagementServer = New-Object SourceCode.Workflow.Management.WorkflowManagementServer
		$workflowManagementServer.Open($ConnectionString) | out-null
	}
	if (-not ([System.String]::IsNullOrEmpty($AvailabilityZoneName)) -and (($workflowManagementServer.ZoneExists($AvailabilityZoneName))))
    {
		[SourceCode.Workflow.Management.AvailabilityZone] $avZone = $workflowManagementServer.ZoneLoad($AvailabilityZoneName);
		
		
		[xml]$templateZone = @"
      <AvailabilityZone>
	  	<AvailabilityHours />
		<AvailabilityDates />
    </AvailabilityZone>
"@
	$xmlEltAD
		$templateZoneNode = $templateZone.SelectSingleNode("/AvailabilityZone")
		$templateZoneNode.SetAttribute("name", $avZone.ZoneName) | Out-Null
		$templateZoneNode.SetAttribute("description", $avZone.ZoneDescription) | Out-Null
		$templateZoneNode.SetAttribute("GMTOffset", $avZone.ZoneGMTOffset) | Out-Null
		$templateZoneNode.SetAttribute("isDefault", $avZone.DefaultZone) | Out-Null
		
		$availabilityHours = $templateZoneNode.CreateElement("AvailabilityHours")
		
		$availabilityHours.InnerXML = Get-K2AvailabilityHoursASXml -workflowManagementServer $workflowManagementServer -ZoneName $AvailabilityZoneName
		[xml]$availabilityDates = Get-K2AvailabilityDatesASXml -workflowManagementServer $workflowManagementServer -ZoneName $AvailabilityZoneName
		
		$templateZoneAHNode = $templateZone.SelectSingleNode("/AvailabilityZone/AvailabilityHours")
		 $templateZoneNode.ReplaceChild($availabilityHours, $templateZoneAHNode)
		
		$templateZoneNode.AppendChild($availabilityHours) | Out-Null	
		$templateZoneNode.AppendChild($availabilityDates) | Out-Null		
	
		
		$templateZone.OuterXML
		
	}
	else
    {
        Write-Error "$AvailabilityZoneName Zone does not exists"
    }
}


[xml]$AvailabilityDatesBlank = "<AvailabilityDates />"

[xml]$AvailabilityDatesChristmas = @"
    <AvailabilityDates>
      <AvailabilityDate description="Christmas Day" date="2013-12-25T00:00:00" isNonWorkDate="True">
      </AvailabilityDate>
      <AvailabilityDate description="Christmas Eve" date="2013-12-24T00:00:00" isNonWorkDate="False">
        <TimeOfDay days="0" hours="13" minutes="0" seconds="0" milliseconds="0"></TimeOfDay>
        <Duration days="0" hours="5" minutes="0" seconds="0" milliseconds="0"></Duration>
      </AvailabilityDate>
    </AvailabilityDates>
"@
[xml]$AvailabilityHours = @"
    <AvailabilityHours>
      <AvailabilityHour workDay="5">
        <Duration days="0" hours="8" minutes="30" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="30" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="4">
        <Duration days="0" hours="9" minutes="30" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="00" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="3">
        <Duration days="0" hours="10" minutes="30" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="30" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="2">
        <Duration days="0" hours="10" minutes="30" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="8" minutes="30" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
      <AvailabilityHour workDay="1">
        <Duration days="0" hours="8" minutes="30" seconds="0" milliseconds="0"></Duration>
        <TimeOfDay days="0" hours="9" minutes="30" seconds="0" milliseconds="0"></TimeOfDay>
      </AvailabilityHour>
    </AvailabilityHours>
"@

"Start"
Remove-K2AvailabilityZone -AvailabilityZoneName "Powershelltest" 
Add-K2AvailabilityZone -AvailabilityZoneName "Powershelltest" -GMToffset "0" -AvailabilityZonedescription "this is a test to add a zone from powershell" -isDefault $true -availabilityDates $AvailabilityDatesChristmas -availabilityHours $AvailabilityHours

Remove-K2AvailabilityZone -AvailabilityZoneName "Powershelltest" 
Add-K2AvailabilityZone -AvailabilityZoneName "Powershelltest" -GMToffset "0" -AvailabilityZonedescription "this is a test to add a zone from powershell" -isDefault $true -availabilityDates $AvailabilityDatesBlank -availabilityHours $AvailabilityHours
[xml]$powershelltestAvailabilityTest = Get-K2AvailabilityZoneAsXML -AvailabilityZoneName "Powershelltest"
$powershelltestAvailabilityTest.AvailabilityZones.AvailabilityZone[0].SetAttribute("GMToffset", "-1")
Set-K2AvailabilityZone -AvailabilityZoneXML $powershelltestAvailabilityTest
[xml]$powershelltestAvailabilityTest = Get-K2AvailabilityZoneAsXML -AvailabilityZoneName "Powershelltest"
$powershelltestAvailabilityTest.AvailabilityZones.AvailabilityZone[0].GetAttribute("GMToffset")
Remove-K2AvailabilityZone -AvailabilityZoneName "Powershelltest"


New-AvailabilityHour
New-AvailabilityDay