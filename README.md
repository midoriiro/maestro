# Maestro

Maestro is a set of powershell scripts that facilitate a HA (High Availability) Kubernetes cluster deployment. 
The cluster is intended to be used in a homelab environment.

## Requirements

- VMWare Workstation
- Vagrant 
- Packer
- Powershell

Maestro is subdivided in sub commands:
- box
- cluster
- firewall
- asset

### Getting started

Change directory to ```./bin```. First things first, you need to check if your environment is compliant.

#### Requirements

Run ```.\maestro.ps1 asset check-requirement```. This command will check if :
- Powershell modules are installed, 
- Vagrant and Packer are in Path environment variable
- Packer version is equal or greater than 1.7.x
- Vagrant plugins are installed
- Vagrant VMware Utility is installed

If this command generate no output, everything is set alright. Otherwise, output for each requirement will indicate which
commands to execute in order to meet requirements.

#### Firewall NAT rule

Depending how you have configured VMware Workstation Network NAT adapter. But you might need to add your NAT subnet in Windows 
Firewall. Maestro provide a set of command to do that (need elevated privilege).

Run ```.\maestro.ps1 firewall show```. If a rule does not exist you will be prompted to create one.
Enter your NAT subnet (e.g. 192.168.0.0/24).

You can disable rule by typing ```.\maestro.ps1 firewall disable``` or enable it by typing ```.\maestro.ps1 firewall enable```

#### SSH Keys and box user

You also need to generate a SSH key pair. That permit to Packer and Vagrant to connect through SSH and run Kubernetes scripts installation.
You can edit ```settings.yaml``` file at root project to change the ssh username, and public/private keys location.

#### Settings file
Has mentioned above, you can edit ```settings.yaml``` for other settings.
- root-folder is where boxes and intermediates images will be stored (if you want to use a SSD you should change this setting)
- headless can be set to true to avoid VMWare Workstation GUI popping
- guest-os-name should not be modified
- virtual-ip can be changed but keep in mind that all ip nodes should be in the same network subnet
- virtual-ip-network-interface should not be modified, currently very tied to Vagrant configuration file
- pod-network-cidr, should not be modified unless you know what you are doing
- nodes map can be modified, but keep in mind that the cluster require at least one node of each type. If you want to deploy a Kubernetes
without High Availability (HA) don't use this project. Find another solution. 

When everything is set alright you can start build your Vagrant boxes.

> Do not edit file named ```VERSION``` at root project

### Building boxes
Run ```.\maestro.ps1 box build help``` to see available sub commands.

Building boxes is done in three steps, or stages:
- Stage 1: create the base image with preseed and automated installation
- Stage 2: create one image for each type of cluster node
- Stage 3: export image to Vagrant box format

You can run each stage separately by typing ```.\maestro.ps1 box build stage<number> <variant>```. Or run all the stages in one command
```.\maestro.ps1 box build all <variant>```

Note ```<variant>``` argument. Currently, only debian 11.1.0 is supported, so this argument should be equal to ```debian-11``` 

Example of command: ```.\maestro.ps1 box build all debian-11```

Note about first stage, if you are using a VPN connection disable it during this stage. A VPN connection interfere with Packer HTTP server, 
meaning the preseed configuration file is not retrieved and installation process is stuck at this step.
in range that does

### Cluster initialisation and provisioning
Run ```.\maestro.ps1 cluster help``` to see available sub commands.

When your Vagrant boxes are built you need to initialise your cluster by typing ```.\maestro.ps1 cluster init```.
All nodes will be initialised but not provisioned. After that you can run ```.\maestro.ps1 cluster provision```.

When provisioning has finished you can stop your machines by typing ```.\maestro.ps1 cluster halt``` and resume them by typing 
```.\maestro.ps1 cluster resume```.

You can also destroy your cluster by typing ```.\maestro.ps1 cluster destroy```.

if you want an SSH access to a specific node, type ```.\maestro.ps1 ssh <node-hostname>``` (not working currently).

```.\maestro.ps1 cluster <command>``` is basically a wrapper around Vagrant command. On each command mentioned above, you can add 
specific vagrant command arguments, example ```.\maestro.ps1 cluster init k8s-deploy k8s-proxy-1``` to init only these two machines. 
See vagrant cli documentation.

## Linux distributions
Has mentioned above, at this moment only Debian 11.1.0 is currently supported. 

If you want another Debian-based distribution supported, you need to create an other preseed file.

Example ```./01-preparing-boxes/variants/debian-10```. Inside this folder you can copy from ```debian-11``` 
folder the files ```os.pkrvars.hcl``` and ```pressed.pkrtpl.hcl```. 
Edit and test them with ```.\maestro.ps1 box build stage1 debian-10```. 
You also need to edit key ```guest-os-name``` in ```settings.yaml``` accordingly.

You can submit a pull request when everything is set alright on your side in order to support other distributions.

> Do not edit file named ```VERSION``` at root project

## License

This repository is available under the MIT License 







