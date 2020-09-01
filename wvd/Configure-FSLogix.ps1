New-Item -ItemType Directory -Path C:\Temp

Invoke-WebRequest -UseBasicParsing -Uri 'https://go.microsoft.com/fwlink/?linkid=2084562' -OutFile C:\Temp\FSLogix.zip

Expand-Archive -Path C:\Temp\FSLogix.zip -DestinationPath C:\Temp\

& 'C:\Temp\x64\Release\FSLogixAppsSetup.exe' /install /quiet

Remove-Item -Path C:\Temp -Recurse -Force

New-Item -Path HKCU:\software\FSLogix\Profiles

New-ItemProperty HKCU:\software\FSLogix\Profiles -Name Enabled -Value 1

New-ItemProperty HKCU:\software\FSLogix\Profiles -Name VHDLocations -PropertyType MultiString -Value $FileShare