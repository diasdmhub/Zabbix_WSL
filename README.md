# Zabbix WSL for Ubuntu/Debian based distributions

#### Zabbix Sources Installation script for Windows WSL Ubuntu/Debian based distributions
<BR>

### REQUIREMENTS
- IF UPGRADING FROM A PACKAGES INSTALLATION, REMOVE ALL ZABBIX PACKAGES FIRST
- THIS IS AN **APACHE2** AND **MYSQL/MARIADB** STANDALONE INSTALLATION
- IF RUNNING FOR THE FIRST TIME, **ZABBIX DB MUST BE PREVIOUSLY INSTALLED AND CREATED**, BUT NOT POPULATED!
- MOST COMMANDS REQUIRE ELEVATED PRIVILEGES, IT IS SUGGESTED TO **START THE SCRIPT AS ROOT**
- INTERNET ACCESS IS REQUIRED TO DOWNLOAD ZABBIX AND GO LANG (Go enviroment as well)
- IT IS SUGGESTED TO UPDATE MANUALLY ZABBIX, GO LINKS AND PHP DIRECTORY WHEN NEW VERSIONS ARE RELEASED. THESE VALUES ARE SET INTO VARIABLES AT THE BEGINNING OF THE SCRIPT
---
<BR>

### INSTRUCTIONS

**1. A Windows WSL Distribution must be installed**
>  - Usually *`wsl --install`* at PowerShell prompt
>  - Check **[Microsoft guide](https://learn.microsoft.com/en-us/windows/wsl/install)**
<BR>

**2. Install your prefered MySQL like DBMS.**
>  - Usually distros repositorys offer MySQL like DBMS. Eg: *`apt install mariadb-server`*
>  - Check **[Zabbix DB requirements](https://www.zabbix.com/documentation/current/en/manual/installation/requirements)**
>  - Check **[Zabbix DB configuration](https://www.zabbix.com/download?zabbix=6.2&os_distribution=debian&os_version=10_buster&db=mysql)**
<BR>

**3. Clone this repository and start the script as root**
>  - Switch to your root account: `sudo -i`
>  - Clone with Git: `git clone https://github.com/diasdmhub/Zabbix_WSL.git`
>  - Start the script: `~/Zabbix_WSL/main/zabbix_wsl<N>.sh`
>    - `<N>` is your chosen version
---
<BR>

### OBSERVATIONS
- MADE FOR DEBIAN/UBUNTU BASED WSL DISTRIBUTIONS
- RE-EXECUTION OF THIS SCRIPT IS CAPABLE OF UPDATING ZABBIX
---
<BR>

### TESTED ON
- WSL Debian 11 (Bullseye)
- WSL Ubuntu 20.04 (Focal Fossa)
- WSL Ubuntu 22.04 (Jammy Jellyfish)
