![Latest release](https://img.shields.io/github/v/release/aqur1n/repairIt?include_prereleases&label=Latest%20Release&logo=github&sort=semver&style=for-the-badge&logoColor=white)
![Lua version](https://img.shields.io/badge/LUA-5.2-green?style=for-the-badge&logo=lua&logoColor=white)

![image](https://github.com/user-attachments/assets/f95015d8-5555-4512-9878-65ea85b5ed48)

A utility that will help you manage your disks and check the integrity of your OS files.

## Features
* Running without an OS
* View information about the components of your computer
* View the contents of disks and change their properties (coming soon)
* Restore/reinstall BIOS
* Check the integrity of OpenOS files (and possibly others) and repair damage (coming soon)

## System requirements
|           | Minimal   | Recommended              |
|-----------|-----------|--------------------------|
| CPU       | Tier 1    | Tier 1                   |
| GPU       | Tier 1    | Tier 2                   |
| RAM       | 1x Tier 1 | 1x Tier 1.5 or 2x Tier 1 |
| Screen    | Tier 1    | Tier 2                   |
| Data Card | -         | Tier 1                   |

*As well as the keyboard*

## Table of information about different builds of repairIt
|                               | MINIMAL | LITE         | FULL                                                               |
|-------------------------------|---------|--------------|--------------------------------------------------------------------|
| Drive management              | Yes     | Yes          | Yes                                                                |
| Viewing the contents of disks | Yes     | Yes          | Yes                                                                |
| Console                       | Yes     | Yes          | Yes                                                                |
| Viewing components            | Not all | Not all      | All                                                                |
| Working with the bios         | No      | Vanilla only | Vanilla, [BetterBIOS](https://codeberg.org/KeyTwoZero/BetterBIOS)  |
| Working with OS               | No      | Vanilla only | Yes                                                                |


## Download and install
### OpenOS
* Run this command in the console:
```
wget -f https://raw.githubusercontent.com/aqur1n/repairIt/master/installer/openos.lua /tmp/repairit.lua && /tmp/repairit.lua
```

## Useful links
* [Discord server](https://discord.gg/v4hC2z4ZHh)
