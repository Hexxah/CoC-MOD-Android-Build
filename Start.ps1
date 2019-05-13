# Corruption of Champions Mods APK Builder
# Needed to avoid "Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$FlashDevelop = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*|Where-Object -p "displayname" -match "flashDevelop").uninstallstring
if($FlashDevelop -eq $null){
    $FlashDevelop = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*|Where-Object -p "displayname" -match "flashDevelop").uninstallstring
}
$FlashDevelop = $FlashDevelop -replace "uninstall.exe",''
$sdk = $env:FLEX_HOME
$airNameSpace = ([xml](get-content $sdk\airsdk.xml)).airSdk.applicationNamespaces.versionMap[0].descriptorNamespace
#$library = $FlashDevelop + "Library"
$fdbuild = $FlashDevelop + "Tools\fdbuild\fdbuild.exe"
$project = ".\Source\Corruption-of-Champions-FD-AIR.as3proj"

$progressPreference = 'silentlyContinue' #Hide log/verbose

#Downloads stuff and sets up directory when called
function Setup
{
	#check url for the latest release and version number if not building from source folder
	# The releases are returned in the format {"id":3622206,"tag_name":"hello-1.0.0.11",...}, we have to extract the the version number and url.
	$json = $latestRelease.Content | ConvertFrom-Json
	$Script:latestVersion = $json.tag_name[0]
	$latestUrl = $json.zipball_url[0]
	
	Write-Output "Downloading Latest Release ..."
	Invoke-WebRequest $latestUrl -OutFile coc.zip
	
	Write-Output "Extracting Archive ..."
	Expand-Archive coc.zip
	
	# just renaming and moving stuff
	if ((Test-Path ".\Source")){Remove-Item -Recurse Source}
	Move-Item coc\* Source
	Remove-Item coc,coc.zip
	
	# Edit xml to include mx swc from sdk ( otherwise gives ScrollControlBase not found error)
	$as3project = [xml](Get-Content $project)
	$as3project.project.libraryPaths.ChildNodes.Item(0).path = "lib\bin"
	$as3project.project.libraryPaths.ChildNodes.Item(1).path = $sdk+"\frameworks\libs\mx"
	$as3project.project.output.ChildNodes.Item(6).version = ([xml](get-content $sdk\airsdk.xml)).airSdk.applicationNamespaces.versionMap[0].swfVersion
	$as3project.Save((Resolve-Path $project))
	
	BuildSwf
}
	
#Builds the Stuff
function BuildSwf
{
	Write-Output "Compiling/Building SWF"
	&($fdbuild) $project -compiler $sdk -notrace #-library $library
	Copy-Item Source\CoC-AIR.swf CoC-AIR.swf
	
	BuildApk
}

function BuildApk
{
	#Remove all not numeric value from version and change in form of x.x.x
	$versionNumber = $latestVersion -split '[^.0-9]'  | ? {$_}
	if ($versionNumber.count > 1) {
		$versionNumber = $versionNumber[-1]
	}    
    
    	#sets air namespace and version
    	$myXml = [xml](Get-Content $xml)
    	$myxml.application.xmlns = $airNameSpace
	$myxml.application.versionNumber = [string]$versionNumber
    	$myXml.Save((Resolve-Path $xml))
	
	#Change Icons based on Build
	cp .\icons\$xml\* .\icons\ -force
	
	Write-Output "Building Arm APK"
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_arm.apk $xml CoC-AIR.swf icons
	
	Write-Output "Building x86 APK"
	java -jar ($sdk+"\lib\adt.jar") -package -target apk-captive-runtime -arch x86 -storetype pkcs12 -keystore cert.p12 -storepass coc CoC_${latestVersion}_x86.apk $xml CoC-AIR.swf icons
	
	cp .\icons\Default\* .\icons\ -force
	exit
}
#`n6.Export Android Save(.sol)?
switch -wildcard (Read-Host "What would you like to do `n1.Download and Build Revamp `n2.Download and Build Xianxia `n3.Download and Build EndlessJourney `n4.Build from Source folder `n5.Build apk using CoC-AIR.swf  `n6.Clean the Directory`n")
{ 
    	"1*" {
		$latestRelease = Invoke-WebRequest https://api.github.com/repos/Kitteh6660/Corruption-of-Champions-Mod/releases -Headers @{"Accept"="application/json"}
		$xml='revamp.xml'
		setup
	}
    	"2*" {
		$latestRelease = Invoke-WebRequest https://api.github.com/repos/Ormael7/Corruption-of-Champions/releases -Headers @{"Accept"="application/json"}
		$xml = 'xianxia.xml'
		setup
	}
	"3*" {
		$latestRelease = Invoke-WebRequest https://api.github.com/repos/Oxdeception/Corruption-of-Champions/releases -Headers @{"Accept"="application/json"}
		$xml = 'endless.xml'
		setup
	}
    	"4*" {
		if (!(Test-Path ".\Source")){
		    Write-Output "Sorry missing Source Directory"
		    exit
		}
		$latestVersion = Read-Host "Enter a Version Number (eg:1.4.5):"
		$xml = Read-Host "Which XML file to use? (*******.xml)"
		BuildSwf
	}
	"5*" {
		if (!(Test-Path ".\CoC-AIR.swf")){
		    Write-Output "Missing CoC-AIR.swf"
		    exit
		}
		$latestVersion = Read-Host "Enter a Version Number (eg:1.4.5):"
		$xml = Read-Host "Which XML file to use? (******.xml)"
		BuildApk
	}
	<#"6*" {
		"`nEnable Debugging mode on device and connect to PC".toString()
		if (Test-Path "Android"){
			$v= Read-Host "Which version save would you like to export?`n1.Revamp `n2.Xianxia `n3.Endless Journey `n4.Endless Journey `n"
			if ($v -eq 1){$Android = 'air.com.cocmod'}
			if ($v -eq 2){$Android = 'air.com.cocxian'}
			if ($v -eq 3){$Android = 'air.com.coc.EndlessJourney'}
			if ($v -eq 4){$Android = Read-Host "Enter app id (eg: air.com.coc)"}
			cd Android
			"Unlock your phone and select backup".toString()
			./adb backup -noapk $Android > "backup.txt" 2>&1
			if(!(Get-Content "backup.txt" -totalcount 1| %{$_ -match "no devices/emulators found"}))
			{
				java -jar abe.jar unpack backup.ab backup.tar
				./7z x -y backup.tar
				cd ..
				$dir = 'Android\apps\'+$Android+'\r\'+(($Android) -replace "air.","")+'\Local Store\#SharedObjects'
				if(Test-Path "Save") {rm -Recurse Save}
				mv $dir 'Save'
			}
			else{
			cd..
			"`nYour Phone Could not be found!".toString()}
			if(Test-Path "Android\app*") {rm -Recurse Android\app*}
			if(Test-Path "Android\backup*") {rm -Recurse Android\backup**}
			Start-Sleep -s 5
							
			}
		else{"Could not find Android folder at root. `nDownload Link on Hexxah Github".toString()
		Start-Sleep -s 5
		}
		exit
		}#>
	"6*" {
		Write-Output "Keeping only base files...."
		if ((Test-Path ".\Source")){Remove-Item -Recurse Source}
		if ((Test-Path "coc*")){Remove-Item -Recurse coc*}
		exit
	}
	default {
		"No idea what to do! Choose Something"
		exit
	}
}
