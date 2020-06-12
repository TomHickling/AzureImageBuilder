ur﻿### 1. IF NOT ALREADY PRESENT REGISTER THE AZURE IMAGE BUILDER SERVICE WHILST IN PREVIEW###
#Register AIB
Install-Module Az -Force
Connect-AzAccount
Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
#Check Registration status
Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
#Check Provider Registration status
Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages | Select-Object RegistrationState
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | Select-Object RegistrationState

#If not "Registered" Then run these
Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVaul

##Once registered begin your AIB image deployment##

## 2. AIB - CREATE VARIABLES
# Get existing context
$currentAzContext = Get-AzContext
# Get your current subscription ID. 
$subscriptionID=$currentAzContext.Subscription.Id
# Destination image resource group
$imageResourceGroup="AzureImageBuilder3"
# Location
$location="northeurope"
# Image distribution metadata reference name
$runOutputName="aibCustWinManImg02ro"
# Image template name
$imageTemplateName="helloImageTemplateWin10ps"
# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$runOutputName="winclientR01"

# 2.1 Create a resource group for Image Template and Shared Image Gallery
New-AzResourceGroup `
   -Name $imageResourceGroup `
   -Location $location

##CREATE A USER ASSIGNED IDENTITY, THIS WILL BE USED TO ADD THE IMAGE TO THE SIG
# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
$identityName="aibIdentity"+$timeInt
$identityName="aibIdentity"

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# Create identity
# New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName
$identityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

## ASSIGN PERMISSIONS FOR THIS IDENTITY TO DISTRIBUTE IMAGES
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# Download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# Create the  role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# Grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
https://docs.microsoft.com/azure/role-based-access-control/troubleshooting

## 3. CREATE THE SHARED IMAGE GALLERY
# Set Image gallery name
$sigGalleryName= "AIBSIG2"

# Image definition name - define an appropriate name
# Server:
$imageDefName ="winSvrimage"
# Or Win 10 Client 
$imageDefName ="win10imageAppsTeams"

# Additional replication region, this is the secondary Azure region in addition to the $location above.
$replRegion2="westeurope"

# Create the gallery
New-AzGallery `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup  `
   -Location $location

# 3.1 Create the image "definition", Windows Server or Windows client below - choose one.
New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup `
   -Location $location `
   -Name $imageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'myCompany' `
   -Offer 'WindowsServer' `
   -Sku 'WinSrv2019'

   New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup `
   -Location $location `
   -Name $imageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'myCompany' `
   -Offer 'Windows-10-App-Teams' `
   -Sku '19h2-evd'


## 3.2 DOWNLOAD AND CONFIGURE THE TEMPLATE WITH YOUR PARAMS
   $templateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest `
   -Uri "https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MS.json" `
   -OutFile $templateFilePath `
   -UseBasicParsing

(Get-Content -path $templateFilePath -Raw ) `
   -replace '<subscriptionID>',$subscriptionID | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<rgName>',$imageResourceGroup | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<runOutputName>',$runOutputName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<imageDefName>',$imageDefName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<sharedImageGalName>',$sigGalleryName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region1>',$location | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region2>',$replRegion2 | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$identityNameResourceId) | Set-Content -Path $templateFilePath

##CREATE THE IMAGE VERSION
New-AzResourceGroupDeployment `
   -ResourceGroupName $imageResourceGroup `
   -TemplateFile $templateFilePath `
   -api-version "2019-05-01-preview" `
   -imageTemplateName $imageTemplateName `
   -svclocation $location

   ##BUILD THE IMAGE
   Invoke-AzResourceAction `
   -ResourceName $imageTemplateName `
   -ResourceGroupName $imageResourceGroup `
   -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
   -ApiVersion "2019-05-01-preview" `
   -Action Run


   #This has now kicked of a build into the AIB service which will do its stuff. To check the Image Build Process run the cmd below. 
   #It will go from Building, to Distributing to Complete, it will take some time.
   (Get-AzResource –ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $ImageTemplateName).Properties.lastRunStatus




   ## 4.CREATE A VM from this image
   # Test the image is ok - This will create a VM from this image - below. Or you can just do this via the portal.
   # You could also deploy a WVD host pool using this image in the Image gallery option in the WVD deployment process.


   #Get image version created
   $imageVersion = Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup -GalleryName $sigGalleryName -GalleryImageDefinitionName $imageDefName

   #Create the VM in the second region 
   $vmResourceGroup = "myResourceGroup"
   $vmName = "myVMfromImage"

   # Create user object
   $cred = Get-Credential -Message "Enter a username and password for the virtual machine."

   # Create a resource group
   New-AzResourceGroup -Name $vmResourceGroup -Location $replRegion2

   # Network pieces
   $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24
   $vnet = New-AzVirtualNetwork -ResourceGroupName $vmResourceGroup -Location $replRegion2 `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
   $pip = New-AzPublicIpAddress -ResourceGroupName $vmResourceGroup -Location $replRegion2 `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4
   $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow
   $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $vmResourceGroup -Location $replRegion2 `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP
   $nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $vmResourceGroup -Location $replRegion2 `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration using $imageVersion.Id to specify the shared image
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1_v2 | `
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzVMSourceImage -Id $imageVersion.Id | `
Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $vmResourceGroup -Location $replRegion2 -VM $vmConfig
   -GalleryImageDefinitionName $imageDefName

