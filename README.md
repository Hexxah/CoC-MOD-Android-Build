# Corruption of Champions (Revamp-Xianxia) Android Build

APKs can be found on the [Releases](https://github.com/Hexxah/CoC-MOD-Android-Build/releases) page.

This repo is for Android Builds of Corruption of Champions mods (Revamp and Xianxia):

Revamp: <https://github.com/Kitteh6660/Corruption-of-Champions-Mod>

Xianxia: <https://github.com/Ormael7/Corruption-of-Champions>

All copyrights belong to their respective owners.

## Building apk yourself

### PreRequisites

- Windows and PowerShell
- Java JRE: <https://www.java.com/en/download/>
- Flash Develop: <http://www.flashdevelop.org/>

### Building the APK

1. Launch Flash Develop and Install Flex + Air SDK (Tools -> Install Software).
1. Download the [source code](https://github.com/Hexxah/CoC-MOD-Android-Build/archive/master.zip)
1. Extract
1. Right Click Start.ps1 Run with Powershell

#### If Run with PowerShell does not work

PowerShell needs to have its execution policy either changed or bypassed.

For more info see <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy>

Open a command window in the extracted directory and use one of the below.

##### Single time bypass

```command
PowerShell -executionPolicy bypass .\Start.ps1
```

##### Change Execution policy

```powershell
powershell
Set-ExecutionPolicy unrestricted
```

#### If build with PowerShell does not work
If you get errors like "Error: Java heap space" or "dx tool failed", you probably have to allocate more Java memory:
- open the jvm.config file inside your Flex Air SDK directory and set at least 512 Mb
```
java.args=-Xmx512m
```
- create the _JAVA_OPTIONS system environment variable 
```
_JAVA_OPTIONS=-Xmx512m
```

## FAQ

Image Packs do not work on Android Builds, the only way I know to fix is this is to rewrite the code so that it embeds the image when compiling the swf, unfortunately that would mean the size of the file would increase quite considerable(100mb+) and might slow down the android version more :P

It is possible to install both mods and the official versions at the same time. Regular Saves should be fine, only Save to File might cause issues since all three would share the location and might cause issues if imported in the wrong version.

## Bug Reports + Others

If you find any bugs to do with the android version, crashes, not installing or the script feel free to open an issue here NOT on the Revamp or Xianxia page since the android builds aren't officially supported by them.

If you see issues with scenes or other game related error that can be replicated on the SWF (PC) those would belong on the official repos.

If you would like to help in someway or have any ideas feel free to contact me.
I have no idea about flash coding but can understand basic code and some languages (Python, Java). I do this on my free time so I might not be able to reply right away.

P.S. Username on COC Discord: Drack
