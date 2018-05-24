<#
.SYNOPSIS
    Downloads files within the specified container from Azure Blob Storage.

.DESCRIPTION
    This cmdlet downloads files within the specified container from Azure Blob Storage.

.PARAMETER ContainerName
    Specifies the name of container.

.PARAMETER MappingPath
    Specifies the path of the mapping document. This is used to get the Service Name.

.PARAMETER DestinationPath
    Specifies the download destination path.

.INPUTS
    This cmdlet does not accept pipeline input.

.OUTPUTS
    This cmdlet does not produce any pipeline output.
#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerName,
	
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$MappingPath,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath
)
		
Begin
{
	Import-Module AzureRM.Storage -ErrorAction Ignore | Out-Null

	# Hides the progress bars
	$ProgressPreference="SilentlyContinue"
	
 	$DesktopPath = [Environment]::GetFolderPath("Desktop")
	# Path where this script resides
	$CurrentPath = $PSScriptRoot
	
	if (!($DestinationPath))
	{
		$DestinationPath = $DesktopPath + "\SystemLogExport"
	}
	$DestinationPath = $DestinationPath + '\' + $ContainerName
	
	if (!($MappingPath))
	{
		$MappingPath = "https://github.com/OfficeDev/O365-Cloud-Sec-Tooling/raw/master/STP/Microsoft%20DSR%20Export%20Service%20GUID%20Mapping%20Table%20v1%206.xlsx"
	}
	
	Logout-AzureRmAccount -ErrorAction Ignore | Out-Null
	Login-AzureRmAccount -ErrorAction Ignore | Out-Null

	# Check if logged in successfully
	if ((Get-AzureRmContext).Account -eq $Null) 
	{ Write-Host "Please provide valid credentials." -ForegroundColor Red; Exit; }
	
	Write-Output "Checking for subscriptions..."
	$Subscriptions = Get-AzureRmSubscription | Sort-Object -Property Name
	$SubscriptionName = ""
	switch(($Subscriptions).Count)
	{
		0 { Write-Host "You do not have any subscription." -ForegroundColor Red; Exit; }
		1 { $SubscriptionName = $Subscriptions[0].Name; 	Write-Output "Using your default subscription [$SubscriptionName]..." }
		default 
		{
			$Global:sequence = 0;
			$Subscriptions | Format-Table -AutoSize -Property `
				@{Label = "Option"; Expression = {$Global:sequence; $Global:sequence++;}}, `
				@{Label="Subscription Name";Expression={$_.Name}} 
			
			while ([string]::isnullorempty($SubscriptionName))
			{	
				$Result = 0
				$SubscriptionNameOption = Read-Host "Please enter [1-$(($Subscriptions).Count)] to select a subcription"
				[int]::TryParse($SubscriptionNameOption, [ref]$Result) | Out-Null
				$SubscriptionName = $Subscriptions[$Result-1].Name
				if(!$SubscriptionName -or $Result -le 0)
				{
					$SubscriptionName = ""
					Write-Host "Invalid option." -ForegroundColor Red
				}
			}			
		}
	}

	Set-AzureRmContext -SubscriptionName $SubscriptionName  | Out-Null
	
	Write-Output "Checking for storage accounts..."

	# Get the storage accounts that contain the container name
	$StorageAccounts = Get-AzureRmStorageAccount `
		| Foreach-Object { 
			$StorageAccountKey = (Get-AzureRmStorageAccountKey `
														-Name $_.StorageAccountName `
														-ResourceGroupName $_.ResourceGroupName).Value[0]
			$StorageContext = New-AzureStorageContext $_.StorageAccountName -StorageAccountKey $StorageAccountKey
			$Container = Get-AzureStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction Ignore
			$_ |	Add-Member -Type NoteProperty -Name ContainerExists -Value ($Container -ne $Null); $_
		} `
		| Where { $_.ContainerExists -eq $TRUE} `
		| Sort-Object -Property StorageAccountName

	$StorageAccount = $Null
	switch(($StorageAccounts).Count)
	{
		0 { Write-Host "Container [$ContainerName] not found in any of your storage accounts. Please provide a valid container name." -ForegroundColor Red;  Exit; }
		1 { $StorageAccount = $StorageAccounts[0] ; 
			# Write-Output "Using your default storage account [$($StorageAccount.StorageAccountName)]..." 
			}
		default 
		{
			$Global:sequence = 0;
			$StorageAccounts | Format-Table -AutoSize -Property `
				@{Label = "Option"; Expression = {$Global:sequence; $Global:sequence++;}}, `
				@{Label="Storage Account Name";Expression={$_.StorageAccountName}}
			
			while ($StorageAccount  -eq $Null)
			{	
				$Result = 0
				$StorageAccountOption = Read-Host "Please enter [1-$(($StorageAccounts).Count)] to select a storage account"
				[int]::TryParse($StorageAccountOption, [ref]$Result) | Out-Null
				$StorageAccount = $StorageAccounts[$Result-1]
				if(($StorageAccount  -eq $Null) -or $Result -le 0)
				{
					$StorageAccount= $Null
					Write-Host "Invalid option." -ForegroundColor Red
				}
			}
		}
	}
	
   # Track how long the overall operation takes.
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	
	Write-Output "Processing using [$($StorageAccount.StorageAccountName)]..."
	
	# Use Hashtable for the service name mapping
	$ServiceMapping = @{}
	# $StartRow,$ServiceNameColumn,$AssetGroupIdColumn,$ExportAgentIdColumn=2,11,16,64
	$StartRow,$ServiceNameColumn=2, 1
	[int32[]]$GuidColumns = 2, 3

	$Excel=new-object -com excel.application
	$Wb=$Excel.workbooks.open($MappingPath)

	$Sheet=$Wb.sheets.item(1)
	# $AssetGroupIdKey=$Sheet.cells.item($StartRow,$AssetGroupIdColumn).value2
	$IsEndOfList = $false
	
	Write-Output "Reading the mapping file..."

	while (!$IsEndOfList)
	{	
		$Value=$Sheet.cells.item($StartRow,$ServiceNameColumn).value2
		$IsEndOfList = $true

		foreach ($GuidColumn in $GuidColumns)
		{
			$Key = $Sheet.cells.item($StartRow,$GuidColumn).value2
			if (![string]::isnullorempty($Key))
			{
				if (![string]::isnullorempty($Value))
				{
					$ServiceMapping[$Key.Trim().replace('-','')] = $Value.Trim()
				}
				$IsEndOfList = $false
			}
		}

		$StartRow++
	}
	$Excel.workbooks.close()
}

Process
{
	Write-Output "Downloading files..."

	$StorageAccountKey = (Get-AzureRmStorageAccountKey `
												-Name $StorageAccount.StorageAccountName `
												-ResourceGroupName $StorageAccount.ResourceGroupName).Value[0]
	$StorageContext = New-AzureStorageContext $StorageAccount.StorageAccountName -StorageAccountKey $StorageAccountKey
	# Get all the blobs in the specified container
 	$Blobs = Get-AzureStorageBlob -Container $ContainerName -Context $StorageContext
	# Remove the destination path so we don't get prompts to overwrite files.
	Remove-Item $DestinationPath -Force -Recurse -ErrorAction Ignore
	# Create the destination path
	New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null

	# Download all the files
	foreach ($Blob in $Blobs)
	{
		Get-AzureStorageBlobContent `
		-Container $ContainerName -Blob $Blob.Name -Destination $DestinationPath `
		-Context $StorageContext | Out-Null
	}

	Write-Output "Renaming/Moving files..."
	# Get all the folders from the destination path
	$Dirs = dir -Path $DestinationPath -Directory 
	
	foreach($Dir in $Dirs)
	{
		$Key =$Dir.Name
		$ServiceName = $ServiceMapping[$Key]
		
		# Create the folder of the Service Name if there is a mapping
		if (![string]::isnullorempty($ServiceName))
		{
			$Value = $ServiceMapping[$Key]
			$NewPath = $DestinationPath + "\" + $Value

			# Check if directory already exists. If so, append "-[Count +1]" to the folder name. e.g. "Foldername-4"
			$CurrentDirs = dir -Path $DestinationPath -Directory | Where { $_.Name -like $Value + "*"}
			if ($CurrentDirs)
			{
				$NewPath = $NewPath + "-" + ($CurrentDirs.Count + 1)
			}

			New-Item -ItemType Directory -Force -Path $NewPath | Out-Null
			# Move the files
			Get-ChildItem -Path $Dir.Fullname -Recurse | Move-Item -destination $NewPath | Out-Null
			# Remove the directory
			Remove-Item $Dir.Fullname -Force -Recurse
		}
	}
}

End
{
	Logout-AzureRmAccount -ErrorAction Ignore | Out-Null
	Write-Output "Processing completed..."

    # Let the user know how long it took.
    $Stopwatch.Stop()
    Write-Output "Total download time $($Stopwatch.Elapsed.TotalMinutes.ToString("n1")) minute(s)"
	Write-Output "Successfully downloaded all the files to $DestinationPath"
}
