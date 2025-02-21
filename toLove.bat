@echo off
if exist output.love del output.love
powershell -command "Compress-Archive -Path .\* -DestinationPath .\output.zip -Force"
ren output.zip output.love
echo Love file created successfully!