# Corruption of Champions Mods APK Builder
$sdk = $env:USERPROFILE + "\AppData\Local\FlashDevelop\Apps\flexairsdk\4.6.0+25.0.0"
$library = "C:\Program Files (x86)\FlashDevelop\Library"
$fdbuild = "C:\Program Files (x86)\FlashDevelop\Tools\fdbuild\fdbuild.exe"

$progressPreference = 'silentlyContinue' #Hide log/verbose
$x = 0
$xml='revamp.xml'

switch -wildcard (Read-Host "What would you like to do `n1.Download and Build Revamp `n2.Download and Build Xianxia `n3.Build from Source folder `n4.Clean the Directory`n") 
    { 
        "1*" {
		$latestRelease = Invoke-WebRequest https://api.github.com/repos/Kitteh6660/Corruption-of-Champions-Mod/releases -Headers @{"Accept"="application/json"}
		$x = 1
		} 
        "2*" {
		$latestRelease = Invoke-WebRequest https://api.github.com/repos/Ormael7/Corruption-of-Champions/releases -Headers @{"Accept"="application/json"}
		$x = 2
		} 
        "3*" {
		$latestVersion = Read-Host "Enter a Version Number (eg:1.4.5):"
		if (!(Test-Path ".\Source")){
		"Sorry bud missing Source Directory".toString()
		exit
		}
		$x = 3
		}  
        default {
		"No idea what to do! Choose Something"
		exit
		}
		"4*" {
		"Keeping only base files....".toString()
		if ((Test-Path ".\Source")){rm -Recurse Source}
		if ((Test-Path "coc*")){rm -Recurse coc*}
		exit
		} 
    }
	
#check url for the latest release and version number if not building from source folder
if (!($x -eq 3)){
# The releases are returned in the format {"id":3622206,"tag_name":"hello-1.0.0.11",...}, we have to extract the the version number and url.
$json = $latestRelease.Content | ConvertFrom-Json
$latestVersion = $json.tag_name[0]
$latestUrl = $json.zipball_url[0]

if ($x=2){$xml = 'xianxia.xml'}
}

#Downloads stuff and sets up directory when called
function Setup
{
	"Downloading Latest Release ...".toString()
	Invoke-WebRequest $latestUrl -OutFile coc.zip
	
	"Extracting Archive ...".toString()
	Expand-Archive coc.zip
	
	# just renaming and moving stuff
	if ((Test-Path ".\Source")){rm -Recurse Source}
	mv coc\* Source
	rm coc,coc.zip
	
	Build
	}

#Builds the Stuff
function Build
{
	(Get-Content $xml) -replace '<versionNumber>(.*)</versionNumber>', ('<versionNumber>'+((${latestVersion}) -split "_")[-1]+'</versionNumber>')| Set-Content $xml
	
	"Compiling/Building SWF".toString()
	&($fdbuild) ".\Source\Corruption-of-Champions-FD-AIR.as3proj" -version "4.6.0; 25.0" -compiler $sdk -library $library
	cp Source\CoC-AIR.swf CoC-AIR.swf
	
	"Building Arm APK".toString()
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_arm.apk $xml CoC-AIR.swf icons
	
	"Building x86 APK".toString()
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -arch x86 -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_x86.apk $xml CoC-AIR.swf icons
}

#If not building from source setup everything
if (!($x -eq 3)){
	Setup
}
Else{Build}
