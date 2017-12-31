# Corruption of Champions Mods APK Builder
$FlashDevelop = "C:\Program Files (x86)\FlashDevelop\"
$sdk = $env:USERPROFILE + "\AppData\Local\FlashDevelop\Apps\flexairsdk\4.6.0+27.0.0"
$library = $FlashDevelop + "Library"
$fdbuild = $FlashDevelop + "Tools\fdbuild\fdbuild.exe"
$project = ".\Source\Corruption-of-Champions-FD-AIR.as3proj"

$progressPreference = 'silentlyContinue' #Hide log/verbose
$x = 0
$xml='revamp.xml'

switch -wildcard (Read-Host "What would you like to do `n1.Download and Build Revamp `n2.Download and Build Xianxia `n3.Build from Source folder `n4.Build apk using CoC-AIR.swf `n5.Clean the Directory`n") 
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
		if (!(Test-Path ".\Source")){
		    "Sorry bud missing Source Directory".toString()
		    exit
		}
		$latestVersion = Read-Host "Enter a Version Number (eg:1.4.5):"
		$xml = Read-Host "Which XML file to use? (revamp.xml or xianxia.xml)"
		$x = 3
	}  
	"4*" {
		if (!(Test-Path ".\CoC-AIR.swf")){
		    "Missing CoC-AIR.swf".toString()
		    exit
		}
		$latestVersion = Read-Host "Enter a Version Number (eg:1.4.5):"
		$xml = Read-Host "Which XML file to use? (revamp.xml or xianxia.xml)"
		$x = 4
	}
	"5*" {
		"Keeping only base files....".toString()
		if ((Test-Path ".\Source")){rm -Recurse Source}
		if ((Test-Path "coc*")){rm -Recurse coc*}
		exit
	}
	default {
		"No idea what to do! Choose Something"
		exit
	}
}
	
#check url for the latest release and version number if not building from source folder
if (($x -eq 1 -Or $x -eq 2)){
# The releases are returned in the format {"id":3622206,"tag_name":"hello-1.0.0.11",...}, we have to extract the the version number and url.
    $json = $latestRelease.Content | ConvertFrom-Json
    $latestVersion = $json.tag_name[0]
    $latestUrl = $json.zipball_url[0]

    if ($x -eq 2){$xml = 'xianxia.xml'}
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
	
	# Edit xml to include mx swc from sdk ( otherwise gives ScrollControlBase not found error)
	$as3project = [xml](Get-Content $project)
	$as3project.project.libraryPaths.ChildNodes.Item(0).path = "lib\bin"
	$as3project.project.libraryPaths.ChildNodes.Item(1).path = $sdk+"\frameworks\libs\mx"
	$as3project.project.output.ChildNodes.Item(6).version = "27"
	$as3project.project.output.ChildNodes.Item(7).minorVersion = "0"
	$as3project.Save((Resolve-Path $project))
	
	BuildSwf
}
	
#Builds the Stuff
function BuildSwf
{
	(Get-Content $xml) -replace '<versionNumber>(.*)</versionNumber>', ('<versionNumber>'+((${latestVersion}) -split "_")[-1]+'</versionNumber>')| Set-Content $xml
	
	"Compiling/Building SWF".toString()
	&($fdbuild) ".\Source\Corruption-of-Champions-FD-AIR.as3proj" -version "4.6.0; 27.0" -compiler $sdk -library $library
	cp Source\CoC-AIR.swf CoC-AIR.swf
	
	BuildApk
}

function BuildApk
{
	"Building Arm APK".toString()
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_arm.apk $xml CoC-AIR.swf icons
	
	"Building x86 APK".toString()
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -arch x86 -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_x86.apk $xml CoC-AIR.swf icons
	
	exit
}

#If not building from source setup everything
if ($x -eq 4){
	BuildApk
}
elseif ($x -eq 3){
	BuildSwf
}
Else{Setup}
