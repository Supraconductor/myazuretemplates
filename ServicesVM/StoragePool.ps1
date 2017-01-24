Configuration StoragePool
{
  param ($MachineName)

  Node $MachineName
  {
	Script ConfigureStoragePool { 
		SetScript = { 
			$disks = (Get-PhysicalDisk -FriendlyName PhysicalDisk2)
			New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $disks | New-VirtualDisk -FriendlyName "DataDisk" -UseMaximumSize -ResiliencySettingName "Simple" -ProvisioningType Fixed | Initialize-Disk -Confirm:$False -PassThru | New-Partition -DriveLetter P -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -Confirm:$false			
		} 

		TestScript = { 
			Test-Path P:\ 
		} 
		GetScript = { <# This must return a hash table #> }          }   
  }
} 