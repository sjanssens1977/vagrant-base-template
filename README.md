# Vagrant template for Hyper-V

This is my `Vagrantfile` that I use to __quickly create__ one or more __*Ubuntu* VMs on Windows using Hyper-V__.

> NOTE: The template features are known to work with the following Vagrant boxes:
> * `generic/ubuntu2004`
> * `generic/ubuntu2204`
>
> WARN: You could try to use other boxes, but some features may not work as expected.

## Prerequisites

- Windows 10 Pro (or newer) with Hyper-V feature enabled
- [Vagrant](https://www.vagrantup.com/) installed
- [Vagrant Hostmanager plugin](https://github.com/devopsgroup-io/vagrant-hostmanager) installed

## Features

* Supports both dynamic and static ip address configuration

* Supports local hostname resolution

* Support for DNS aliasses

* Simplified creation of k3s cluster (server & agents)

## Before you jump in...

Lets first go through some first-time setup steps.

### Step 1. Create a SSH Key

The template uses a _custom ssh key_ for easy and secure SSH access to the provisioned VMs.  
The template looks for the private key named `id_ed25519` in the directory `$env:USERPROFILE\.ssh`.

To generate a new ssh key, open Powershell and execute the command `ssh-keygen -t ed25519`. Use the defaults.

### Step 2. Create the Hyper-V Virtual Switch "NAT Switch"

> NOTE: This is only required if you plan to use the static ip feature.

Open `Powershell` with __Administrator privileges__ and execute the following commands.  

```pwsh
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\vmswitch.ps1
```

## Usage

The template uses the `machines` _nested hash_ to retrieve its configuration information.  

```ruby
machines = {
  "k3s-server": {ip: "192.168.77.10", cpus: 2, memory: 4096, type: "k3s_server", aliases: "blog.#{domain},www.#{domain}"},
  "k3s-agent": {ip: "192.168.77.11", type: "k3s_agent"}
}
```

Each machine that needs to be provisioned, must be defined by a machine name (hash key) and a nested hash that contains key/value pairs.

The _nested hash_ supported keys are: `aliasses:`, `box:`, `cpus:`, `ip:`, `memory:`, `opts:`, `type:`.

* `aliasses`: DNS aliasses. __Optional__
* `box`: the Vagrant box to use for the VM. NOTE: some features may not work if you use a box that is not tested.
* `cpus`:  number of virtual cpus assigned to the VM. __Optional__: _default value_ is `1`.
* `ip`: used to assign a static ip address. __Optional__
* `memory`: maximum memory available for the VM, expressed in MB. __Optional__: _default value_ is `2048`.
* `opts:`: Define optional arguments, currently only used to specify additional `INSTALL_K3S_EXEC` options. __Optional__
* `type`: Allowed values are `server` and `agent`. __Optional__: default value is `generic/ubuntu2204`

> WARN: The structure of the `machines` _nested hash_ is important and should not be changed.

> It is recommended to make a copy of the [Vagrantfile](./Vagrantfile) before you make any modifications

### Using a dynamic ip address

Using a dynamic ip address for you VM is very easy.
Simply do not include the `ip:` key in the _nested hash_ for the machine.  

The Hyper-V "Default Switch" will be used for this machine.

> IMPORTANT: VMs using a static ip address are unable to communicate with VMs that use a dynamic ip address.

### Using a Static ip address

> Please make sure you have prepared the [first-time setup step](#step-2-create-the-hyper-v-virtual-switch-nat-switch) to create the Hyper-V virtual switch named `NAT Switch`. 

To assign a static ip address to a VM, simply add the _nested hash_ key `ip:` with the ip address as the value.

The `NAT Switch` ip address range is `192.168.77.0/24`.  
This means the static ip address must be in the range 192.168.77.2 - 192.168.77.254.

> The ip address 192.168.77.1 is used for the gateway, and can be used from within the VM to access service running on the host.

> NOTE: If you need a different ip range, simply update the Powershell [script](./scripts/vmswitch.ps1) to match your needs.  
> You should also update the `gateway` and `cidr` values in the [Vagrantfile](./Vagrantfile) to match your configuration.

> TIP: You could create different Hyper-V virtual switches if you required multiple ip ranges.

### Using support for local hostname resolution

This is done automatically.

The _Vagrant Hostname Plugin_ is used to automatically update the Windows `$env:windir\system32\drivers\etc\hosts` file and the guest VM's `/etc/hosts` file.

This means that after provision the guest VMs are addressable, from the host and between VMs, using the full qualified domain names (machine + domain).

### Using support for DNS aliasses

Some use cases require a VM to be addressable using different domain names.  
These use cases are supported by using the `aliasses:` key of the nested hash.

You can specify one or more aliasses for a VM.  
To use multiple domain names, simply provide a comma seperated list of names as a string value for the `aliasses:` key.

```ruby
machines = {
  "vm-website": {aliases: "blog.#{domain},www.#{domain}"}
}
```

> NOTE: The literal `#{domain}` is replaced by the value of the domain variable. Defaults to `example.com`

### Simplified creation of k3s cluster (server & agents)

The template allows simplified creation of a k3s single or multi node cluster.  

To use this feature, the machines _hash_ (see [configuration](#configuration)) must contain at least one machine with a key/value pair of `type: "k3s_server"`.

> IMPORTANT: When defining a multi node cluster that uses k3s agents, the first machine in the `machines` _hash_ is expected to be the k3s server

## Examples

### 1. The basic VM

This configuration will create a Ubuntu 22.04 VM using a dynamic ip address which is addressable by the name vm-helloWorld.example.com

```ruby
machines = {
  "vm-helloWorld": {}
}
```

### 2. Create a k3s single node cluster

This configuration will create a single node k3s cluster that runs on a Ubuntu 22.04 VM.  
The VM is assigned a dynamic ip address and is addressable by the names `vm-website.example.com`, `blog.example.com` and `www.example.com`.

```ruby
machines = {
  "vm-website": {cpus: 1, memory: 4096, type: "k3s_server", aliases: "blog.#{domain},www.#{domain}"}
}
```

### 3. Create a k3s 2 node cluster (server and agent)

This configuration will create 2 Ubuntu VMs, one using release 20.04 and the other 22.04.  
The first VM is assigned the static ip address 192.168.77.10 and is addressable by the names `vm-k3s-server.example.com`, `blog.example.com` and `www.example.com`. It hosts a k3s server process.  
The second VM is assigned the static ip address 192.168.77.11 and is addressable by the name `vm-k3s-agent.example.com`. It hosts a k3s agent process that connects to the k3s server process on the first VM.

```ruby
machines = {
  "vm-k3s-node1": {ip: "192.168.77.10", cpus: 2, memory: 4096, type: "k3s_server", aliases: "blog.#{domain},www.#{domain}", opts: "--disable traefik"},
  "vm-k3s-node2": {ip: "192.168.77.20", type: "k3s_agent", box: "generic/ubuntu2004"}
}
```

> The `opts: "--disable traefik"` key/value pair prevents the installation of the Traefik Ingress Controller on the k3s cluster.

## What's next

Some idea's that I might add in the future (when I need them).

1. Feature for "Simplified creation of a VM running Docker".
