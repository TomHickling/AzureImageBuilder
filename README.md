Azure Image Builder and Azure Shared Image Gallery to be used to create a WVD Host pool from.
This will use the AIB service to build an image with some applications in it, to effectively become out golden image. It will then distribute the image to two Azure regions. From here you can create a host pool in those regions using this image definition.

1. Start with DeployAIBImage.ps1 to set up AIB/SIG and then all commands to create SIG and an Image. 
This does everything. It needs:
2. https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/aibRoleImageCreation.json to assign permissions.
3. https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MS.json to do the image build which includes,
4. The PS Script to download and install apps into the image: https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MSImageBuild.ps1 or variants thereof. I.E. https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MSImageBuildTeamMedia.ps1 will install Teams with Media Optimisations and its pre-requisites
