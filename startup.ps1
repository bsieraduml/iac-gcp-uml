# Install IIS (Web-Server) and ASP.NET 4.5 
Install-WindowsFeature -Name Web-Server, Web-Asp-Net45 -IncludeManagementTools

# Remove files in folder C:\inetpub\wwwroot
Remove-Item -Path "C:\inetpub\wwwroot\*" -Force -Recurse

# Get the name of the instance from the GCP metadata
$metadataUrl = "http://metadata.google.internal/computeMetadata/v1/instance/name"
$instanceName = Invoke-RestMethod -Uri $metadataUrl -Headers @{"Metadata-Flavor"="Google"}

# Create a new index.html file with the instance name
# @"
# <!DOCTYPE html>
# <html>
# <head>
#     <title>Welcome to $instanceName</title>
# </head>
# <body>
#     <h1>Welcome to $instanceName</h1>
#     <p>This page is served by an IIS instance running on a Windows Server VM in Google Cloud Platform.</p>
# </body>
# </html>
# "@ | Set-Content -Path "C:\inetpub\wwwroot\index.html"


# Set the GCP project ID and GCS bucket name
$projectId = "bentest-415415"
$bucketName = "bsierad-uml-iac-windows-website"

# Set the local folder path where you want to download the files
$localFolderPath = "C:\inetpub\wwwroot"

#copy entire bucket in parallel threads
#$gsutilListCommand = "gsutil -m cp -r gs://$bucketName C:\inetpub\wwwroot"

#this command syncs all my files and folders in parallel threads and removes the bucket name which I don't want
#https://github.com/GoogleCloudPlatform/gsutil/issues/465
$gsutilListCommand = "gsutil -m rsync -r -x '^(?!.*\.*$).*' gs://$bucketName c:\inetpub\wwwroot"
$gsutilListOutput = Invoke-Expression -Command $gsutilListCommand

# # Create the local folder if it doesn't exist
# if (-not (Test-Path -Path $localFolderPath -PathType Container)) {
#     New-Item -Path $localFolderPath -ItemType Directory
# }

# # Use gsutil to list all files in the bucket and download them to the local folder
# $gsutilListCommand = "gsutil ls gs://$bucketName"
# $gsutilListOutput = Invoke-Expression -Command $gsutilListCommand

# foreach ($fileUri in $gsutilListOutput) {
#     $fileName = $fileUri.Substring($fileUri.LastIndexOf("/") + 1)
#     $localFilePath = Join-Path -Path $localFolderPath -ChildPath $fileName
#     gsutil cp $fileUri $localFilePath
# }