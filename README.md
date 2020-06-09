Azure Image Builder and Azure Shared Image Gallery Stuff

1. Start with DeployAIBImage.ps1 to set up AIB/SIG and then all commands to create SIG and an Image. 
This does eveything. It needs:
2. https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/aibRoleImageCreation.json to assign permission
3. https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MS.json to do the image build which includes
4. The PS Script to downlaod and install apps into the image: https://raw.githubusercontent.com/TomHickling/AzureImageBuilder/master/AIBWin10MSImageBuild.ps1 or variants thereof
