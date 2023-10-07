[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Ftankmek%2Ftokendrop&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%233A57E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

```

   ____                __             ___        __             __            
  / __/___  ___  ____ / /_ ___  ____ / _ \ ___  / /_ ___  ____ / /_ ___   ____
 _\ \ / _ \/ -_)/ __// __// -_)/ __// // // -_)/ __// -_)/ __// __// _ \ / __/
/___// .__/\__/ \__/ \__/ \__//_/  /____/ \__/ \__/ \__/ \__/ \__/ \___//_/   
    /_/                                                                       

```


## Description

The SpecterDetector PowerShell module is a versatile tool designed for deploying honey tokens, detecting suspicious activities, and configuring security settings on both local and remote Windows systems. This module utilizes PowerShell Remoting (WinRM) for seamless remote management.


## Features

- Deploy honey tokens (decoys) to remote machines.
- Configure audit settings on remote systems efficiently.
- **File and Folder Auditing**: Easily enable file and folder auditing to track access.


## Installation

```powershell
Install-Module -Name SpecterDetector -Scope CurrentUser
```

## Usage

```powershell
Install-Token -ConfigFile "C:\Path\To\Your\Config\config.json"
```
