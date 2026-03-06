To run the scripts

Create a directory for your scripts
this avoids any issues with paths or if you changed the script you know the latest and greatest is where it needs to be

Run powershell as an admin
Run the following to avoid any policy issues

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
this is only for current session, does not change anything system wide

cd to directory
for me it looks like the following
cd C:\temp\scripts

enter this into power shell .\scriptname.ps1


