# Install IIS (Web-Server) and ASP.NET 4.5
Install-WindowsFeature -Name Web-Server, Web-Asp-Net45 -IncludeManagementTools

# Remove files in folder C:\inetpub\wwwroot
Remove-Item -Path "C:\inetpub\wwwroot\*" -Force -Recurse

# Get the name of the instance from the GCP metadata
$metadataUrl = "http://metadata.google.internal/computeMetadata/v1/instance/name"
$instanceName = Invoke-RestMethod -Uri $metadataUrl -Headers @{"Metadata-Flavor"="Google"}

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

