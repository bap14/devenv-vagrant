﻿
# Requirements
# Virtualbox
# Vagrant
# Ansible (inside WSL)
# Mutagen
# python git gitman
# Windows for OpenSSH



# Start Terminal Powershell (as administrator)

# Install NuGet
Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies

# Install chocolatey if it isn't installed yet
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Make sure Chocolatey is up to date
choco upgrade chocolatey




# List all Chocolatey installed packages
choco list --localonly

# List all Chocolatey packages that could be upgraded
choco upgrade all --noop

# Upgrade all Chocolatey packages
choco upgrade all -y

# List installed PowerShell modules
Get-InstalledModule

# List all available PowerShell modules that can be installed
Get-Module -ListAvailable




# Install VirtualBox and Vagrant
choco install virtualbox vagrant -y

#Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
choco install wsl -y

# Install SourceTree for git repo
choco install microsoft-windows-terminal -y

# Install Libraries/Language/CLI Tools, Development Apps, and editors.
choco install git jq -y

# Install VSCode as IDE and editor
choco install vscode --params "/NoDesktopIcon" -y

# ----------------------------
# Manual GUI Step
# ----------------------------
# Disable python and python3 in "Manage App Execution Aliases"
# ----------------------------

# Install Gitman 
choco install python -y

# Refresh env or restart terminal
refreshenv

# Confirm python version (3.x)
python --version

pip install gitman

# Use Built-In Official "Windows for OpenSSH"
# https://github.com/PowerShell/openssh-portable
# https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'
Add-WindowsCapability -Name "OpenSSH.Client~~~~0.0.1.0" -Online
# Remove-WindowsCapability -Name "OpenSSH.Client~~~~0.0.1.0" -Online
# Configure and Start the ssh-agent service
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent

# ----------------------------
# Manual GUI Step
# ----------------------------
# Reboot Windows
# ----------------------------

# Download CentOS8 WSL Distro Launcher and rootfs
#https://github.com/Microsoft/WSL-DistroLauncher
#https://github.com/yuk7/wsldl
# CentOS8 build based on official CentOS8 image distributions - repackaged with WSL Distribution Launcher
# See https://github.com/mishamosher/CentOS-WSL/blob/8/build.sh
$download = 'https://github.com/mishamosher/CentOS-WSL/releases/download/8.2-2004/CentOS8.zip'
$destination = "$Env:USERPROFILE\Downloads\CentOS8.zip"
Invoke-WebRequest -Uri $download -OutFile $destination -UseBasicParsing

# Extract and Install WSL Distro
$path = "$Env:USERPROFILE\WSL\CentOS8"
If(!(test-path $path)) { New-Item -ItemType Directory -Force -Path $path }
Expand-Archive $destination $path
Start-Process "$path\CentOS8.exe" -Verb runAs -Wait

# Initialize Distro User
wsl adduser $Env:UserName
wsl usermod -a -G wheel $Env:UserName
wsl echo "echo '$Env:UserName  ALL=(ALL)       NOPASSWD: ALL' > /etc/sudoers.d/wsl_user"
# Copy the results, launch wsl and paste the command in to allow passwordless sudo access
wsl
# or manually edit sudoers file to allow wheel group sudo access without password

# Change the default login user wsl will use
Start-Process -FilePath "$path\CentOS8.exe" -ArgumentList "config --default-user $Env:UserName"
#Start-Process -FilePath "$path\CentOS8.exe" -ArgumentList "config --default-user root"

# Launch CentOS8 WSL Container
wsl

# Run inside WSL Container
sudo -i
dnf -y install epel-release
dnf -y update
dnf -y install ansible
dnf -y install python-pip wget
dnf -y dos2unix
pip3 install --upgrade pip
pip3 install python-vagrant

# Get latest URLs from https://www.vagrantup.com/downloads
# https://releases.hashicorp.com/vagrant/2.2.9/vagrant_2.2.9_x86_64.msi
yum -y install https://releases.hashicorp.com/vagrant/2.2.9/vagrant_2.2.9_x86_64.rpm

vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-digitalocean

# ----------------------------
# Exit as root user inside WSL, but remain as your user in WSL
# ----------------------------
exit

# Include into user bash profile
ADD_TO_PROFILE=$(cat <<'HEREDOC_CONTENTS'
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH=$PATH:/mnt/c/Windows/System32
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
HEREDOC_CONTENTS
)
echo "${ADD_TO_PROFILE}" >> ~/.bash_profile

# Reload bash profile
source ~/.bash_profile 











# ----------------------------
# Configure
# ----------------------------

# Setup ssh keys
# Create new ssh keypair (ssh-keygen) or import existing keys in ~/.ssh/

# If generating a new keypair please use a password on your private key
# Consider using a password manager such as 1Password
# ssh-keygen

# Add private key to ssh-agent
# Use tab completion to resolve actual file path
ssh-add ~/.ssh/id_rsa

# Test SSH access to confirm if you have a machine you can use to test access
# ssh user@hostname

# Make sure git is configured to use the Windows for OpenSSH binaries
git config --global core.sshCommand (get-command ssh).Source.Replace('\','/')





# https://www.schakko.de/2020/01/10/fixing-unprotected-key-file-when-using-ssh-or-ansible-inside-wsl/
# WSL DrvFs https://devblogs.microsoft.com/commandline/chmod-chown-wsl-improvements/
# https://docs.microsoft.com/en-us/windows/wsl/file-permissions
#
# To temporarily test running mount options you can unmount and remount drvfs
#mount -l
# C:\ on /mnt/c type drvfs (rw,noatime,uid=1000,gid=1000,case=off)
#cd /
#sudo umount /mnt/c 
#sudo mount -t drvfs C: /mnt/c -o metadata,noatime,uid=1000,gid=1000
#mount -l
# C: on /mnt/c type drvfs (rw,noatime,uid=1000,gid=1000,metadata,case=off)

# Setting mount options to persist
# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
FILE_CONTENTS=$(cat <<'HEREDOC_CONTENTS'
[automount]
enabled = true
mountFsTab = false
root = /mnt/
options = "metadata,umask=007,fmask=007"

#[network]
#generateHosts = true
#generateResolvConf = true
HEREDOC_CONTENTS
)
echo "${FILE_CONTENTS}" >> /etc/wsl.conf

# Copy the private/public keypair from windows into the WSL environment
mkdir -p ~/.ssh/
chmod 700 ~/.ssh/
cp /mnt/c/Users/$(whoami)/.ssh/id_rsa ~/.ssh/
cp /mnt/c/Users/$(whoami)/.ssh/id_rsa.pub ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Add private key to ssh-agent (manually)
# NOTE: This will be needed each time you open a wsl session
# eval $(ssh-agent -s)
# ssh-add ~/.ssh/id_rsa

# To avoid having to enter your password for your key on each wsl session
# Install keychain and configure your bash profile to use it to manage the
# ssh-agent so that it persists between sessions.
sudo dnf install keychain -y
# Include into user bash profile
ADD_TO_PROFILE=$(cat <<'HEREDOC_CONTENTS'
### START-Keychain ###
# Let  re-use ssh-agent and/or gpg-agent between logins
/usr/bin/keychain $HOME/.ssh/id_rsa
source $HOME/.keychain/$HOSTNAME-sh
### End-Keychain ###
HEREDOC_CONTENTS
)
echo "${ADD_TO_PROFILE}" >> ~/.bash_profile

# Reload bash profile
source ~/.bash_profile 


# Exit WSL, Terminate container, Relaunch WSL
exit
wsl --list --verbose 
wsl --terminate CentOS8
wsl




# ----------------------------
# test
# ----------------------------
cd ~/projects
git clone git@github.com:classyllama/iac-test-lab.git
cd ~/projects/iac-test-lab/dev-laravel.lan
gitman install

# Run from within WSL
wsl
cd repo_sources/devenv/
# Ensure line endings aren't /r
dos2unix ./gitman_init.sh
./gitman_init.sh

# If you need to remove the symlinks
[[ -L provisioning/devenv_vars.config.yml ]] && rm provisioning/devenv_vars.config.yml
[[ -L persistent/Vagrantfile ]] && rm persistent/Vagrantfile
[[ -L persistent/devenv ]] && rm persistent/devenv
[[ -L persistent/source ]] && rm persistent/source
[[ -L persistent ]] && rm persistent

# From within wsl
vagrant up




# TODO:
# [ ] fix hosts entry IP address (host only interface used instead of nat interface)
#     10.0.2.15 dev-laravel.lan dev-laravel
#     vs
#     172.28.128.5 dev-laravel.lan dev-laravel
# [ ] Had to run dos2unix on demo install .sh files
#     Should look into git translating files to Windows line endings on checkout
# [ ] vagrant-hostmanager only modifying WSL hosts file
#     Need to get hosts updated on Windows
# [ ] simplify project setup
# [ ] add root ca key to windows
# [ ] test magento demo install
#     [ ] composer repo.magento.com credentials
# [ ] test persistent disk use
# [ ] test actual project setup

# From within wsl
cat /etc/hosts

# From Windows
code C:\Windows\System32\drivers\etc\hosts









# Install GUI SourceTree git repo client tool
choco install SourceTree -y









# Add to path this session
#Set-Item -Path Env:Path -Value ($Env:Path + ";C:\Python38")
# Add to path permanently
#Add-Path -String 'C:\Python38','bla' -Verbose

# Get session's path environment variable
Get-Content -Path Env:Path
# Get the global path environment variable
Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH 


# Extra Packages
choco install powershell-core putty jre8 openvpn terraform nmap rsync SublimeText3 notepadplusplus postman jmeter sqlyog -y
choco install firefox slack 1password curl ruby
choco install filezilla mysql.workbench beyondcompare -y



# Install WSL Ubuntu 1804
# This installs Ubuntu for use only as root user
# Install from Microsoft store for using as unprivileged user
#choco install wsl-ubuntu-1804 -y


# List Chocolatey installed packages
#choco list --localonly
#choco uninstall wsl-ubuntu-1804 -y


#$download = 'https://aka.ms/wsl-ubuntu-1804'
#$destination = "$Env:USERPROFILE\Downloads\Ubuntu-1804.appx"
#Invoke-WebRequest -Uri $download -OutFile $destination -UseBasicParsing
#Add-AppxPackage -Path $destination
#Rename-Item ./Ubuntu.appx ./Ubuntu.zip
#Expand-Archive ./Ubuntu.zip ./Ubuntu

#Get-AppxPackage *ubuntu*
#Get-AppxPackage CanonicalGroupLimited.Ubuntu18.04onWindows | Remove-AppxPackage




# Download CentOS7 WSL Distro Launcher and rootfs
#https://github.com/Microsoft/WSL-DistroLauncher
#https://github.com/yuk7/wsldl
#https://github.com/yuk7/CentWSL/releases/latest
$download = 'https://github.com/yuk7/CentWSL/releases/download/8.1.1911.1/CentOS8.zip'
$download = 'https://github.com/yuk7/CentWSL/releases/download/7.0.1907.3/CentOS7.zip'
$download = 'https://github.com/mishamosher/CentOS-WSL/releases/download/8.2-2004/CentOS8.zip'
$destination = "$Env:USERPROFILE\Downloads\CentOS7.zip"
Invoke-WebRequest -Uri $download -OutFile $destination -UseBasicParsing

# Extract and Install WSL Distro
$path = "$Env:USERPROFILE\WSL\CentOS7"
If(!(test-path $path)) { New-Item -ItemType Directory -Force -Path $path }
Expand-Archive $destination $path
Start-Process "$path\CentOS7.exe" -Verb runAs -Wait

# Initialize Distro User
wsl adduser $Env:UserName
wsl usermod -a -G wheel $Env:UserName
# Change sudoers file to allow wheel group sudo access without password
Start-Process -FilePath "$path\CentOS7.exe" -ArgumentList "config --default-user $Env:UserName"

# Start-Process -FilePath "$Env:USERPROFILE\WSL\CentOS7.exe" -Verb runAs -ArgumentList "run `"cat /etc/os-release && sleep 5`"" -Wait
# wsl cat /etc/os-release






# Launch Ubuntu to configure WSL Ubuntu 1804

# Launch CentOS to configure WSL CentOS 

# Run inside WSL Container
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y update
yum -y install ansible
yum -y install python-pip wget
pip install --upgrade pip
pip install python-vagrant

# https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.msi
yum -y install https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.rpm


yum -y install vagrant
#vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-digitalocean

# Include into user bash profile
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH=$PATH:/mnt/c/Windows/System32
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"








# Refresh environment variables
refreshenv

# System Info and WSL (Windows Subsystem for Linux) List
Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
wsl --list
Start-Process -FilePath "wsl" -ArgumentList "--list" -Wait -NoNewWindow | Write-Output

# Disable Hyper-V
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Check if using WSL v2
# Windows build 18917 or higher only
# This may only work with WSL v1 (WSL v2 may conflict with VirtualBox)
wsl --list --verbose 

# Launch WSL
Start-Process wsl

# Unregister WSL Distribution
wsl --unregister centos7





# install Win32-OpenSSH and setup ssh-agent (deprecated)
# https://github.com/PowerShell/Win32-OpenSSH
# Remove Windows Capability OpenSSH if it exists
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'
Remove-WindowsCapability -Name "OpenSSH.Client~~~~0.0.1.0" -Online
if (Get-Service ssh-agent -ErrorAction SilentlyContinue) 
{
   Stop-Service ssh-agent
   sc.exe delete ssh-agent 1>$null
}
choco install openssh -params "/SSHAgentFeature" -y

# Install Libraries/Language/CLI Tools, Development Apps, and editors.
choco install powershell-core putty jre8 git openssh python pip curl ruby jq openvpn terraform nmap
choco install notepadplusplus SublimeText3 filezilla postman mysql.workbench SourceTree beyondcompare jmeter sqlyog
choco install vscode --params "/NoDesktopIcon"
choco install xxxxxxxxxxx

# Refresh en
refreshenv

# Install Gitman 
pip install gitman




choco install firefox slack 1password





# Install Git VirtualBox and Vagrant
choco install vagrant 

# Install Vagrant Plugins
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-digitalocean





# Create profile and add git
#If (-Not (Test-Path $profile)) {New-Item -path $profile -type file –force}
#Set-ExecutionPolicy Unrestricted -Scope CurrentUser
#
#If ( ($profile | %{$_ -match [Regex]::Escape("$env:LOCALAPPDATA\GitHub\shell.ps1")} ) -contains $false) {
#    Add-Content $profile "`n. (Resolve-Path `"$env:LOCALAPPDATA\GitHub\shell.ps1`")"
#}
#If ( ($profile | %{$_ -match [Regex]::Escape("$env:github_posh_git\profile.example.ps1")} ) -contains $false) {
#    Add-Content $profile "`n. `"$env:github_posh_git\profile.example.ps1`"`n"
#}
#If ( ($profile | %{$_ -match [Regex]::Escape("C:\Program Files\Oracle\VirtualBox")} ) -contains $false) {
#    Add-Content $profile "`n`$env:Path += `";C:\Program Files\Oracle\VirtualBox`"`n"
#}
#. $profile

# Clone DevEnv Repository
$devEnvRepo = 'https://github.com/classyllama/devenv-vagrant.git'
git clone $devEnvRepo server
cd C:\server
git checkout develop





Find-PackageProvider

get-packageprovider
Get-Command -module PackageManagement | sort noun, verb
Get-Command Install-Package
find-package -provider psmodule psreadline -allversions
find-module xjea
# install-package psreadlin -MinimumVersion 1.0.0.13



# Download and install Mutagen
# https://mutagen.io/documentation/introduction/installation
# https://github.com/mutagen-io/mutagen/releases/latest
$download = 'https://github.com/mutagen-io/mutagen/releases/download/v0.11.2/mutagen_windows_amd64_v0.11.2.zip'
$destination = "$Env:USERPROFILE\Downloads\mutagen_windows_amd64_v0.11.2.zip"
$checksum = "D8AC387034F1DC5B2906E2158DAEE55FA2A8B96268D6C955F40D364F65F20CAB"
Invoke-WebRequest -Uri $download -OutFile $destination
if ((Get-FileHash $destination -Algorithm SHA256 | Select-Object -ExpandProperty Hash) -ne $checksum) { throw "Error: Downloaded file does not match known hash." }

# Copy exe binary to program directory
# add exe binary path to profile

#msiexec.exe /package $destination /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1



# Command line and URL for vscode Visual Studio Code
# https://code.visualstudio.com/docs/editor/command-line
# 
# code index.html style.css documentation\readme.md
# 
# vscode://file/{full path to file}:line:column
# vscode://file/c:/myProject/package.json:5:10


# https://github.com/alpacaglue/exp-vagrant-m2
# https://docs.ansible.com/ansible/latest/user_guide/windows_faq.html
# https://www.vagrantup.com/docs/other/wsl.html
# https://bitbucket.org/classyllama/rebaraccelerator-stage/src/1eccd01e45909d805d4b125060cb475e7c8b85d3/?at=feature%2Fdevenv

# https://www.powershellgallery.com/packages?q=mutagen
# https://chocolatey.org/packages?sortOrder=package-download-count&page=42&prerelease=False&moderatorQueue=False&moderationStatus=all-statuses

# https://devblogs.microsoft.com/commandline/sharing-ssh-keys-between-windows-and-wsl-2/
# https://devblogs.microsoft.com/commandline/integrate-linux-commands-into-windows-with-powershell-and-the-windows-subsystem-for-linux/

# https://alchemist.digital/articles/vagrant-ansible-and-virtualbox-on-wsl-windows-subsystem-for-linux/
# https://www.techdrabble.com/ansible/36-install-ansible-molecule-vagrant-on-windows-wsl

