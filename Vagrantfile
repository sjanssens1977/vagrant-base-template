# -*- mode: ruby -*-
# vi: set ft=ruby :


# DNS domain name
domain = "example.com"

# IMPORTANT: The ip address must match the configuration of the Virtual Switch
machines = {
  "vm-helloWorld": {box: "generic/ubuntu2004"}
}
#machines = {
#  "vm-k3s-node1": {ip: "192.168.77.10", cpus: 2, memory: 4096, type: "k3s_server", aliases: "blog.#{domain},www.#{domain}", opts: "--disable=traefik"},
#  "vm-k3s-node2": {ip: "192.168.77.20", type: "k3s_agent"}
#}

# IMPORTANT: The gateway ip address must match the configuration of the Virtual Switch
gateway = "192.168.77.1"

# IMPORTANT: The CIDR value must be equal to the '-PrefixLength' of the Virtual Switch
cidr = 24

# Key used to connect to the VM over SSH
# To generate a new key open a command prompt and type `ssh-keygen -t ed25519` or for a _traditional_ RSA key `ssh-keygen -t rsa -b 2048`
ssh_key = "~/.ssh/id_ed25519"

# K3S Shared token used to add servers and agents to the cluster
k3s_shared_token = "34bcd5fa-b844-45d9-b4ab-43fe798fbcf5"

Vagrant.configure("2") do |config|
  # Instruct Vagrant to use Hyper-V
  config.vm.provider "hyperv"

  # Synced folder require SmbV1 which is by default disabled on Windows 10 and higher
  # If you don't need it, disable it.
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Some Hyper-V specific
  config.vm.provider "hyperv" do |h|
    h.enable_virtualization_extensions = true
    h.linked_clone = true
  end

  # The Vagrant Host Manager Plugin is used to make name resolution work in a multi-machine deployment
  #
  # To install the plugin, open a Powershell with administrative privileges and type `vagrant plugin install vagrant-hostmanager`
  #
  # More info https://github.com/devopsgroup-io/vagrant-hostmanager
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = true
    config.hostmanager.include_offline = false
  end

  # Machine specific configuration
  machines.each do |name, params|
    config.vm.define name do |machine|
      # Specify the Vagrant box to use
      machine.vm.box = params.key?(:box) ? params[:box] : "generic/ubuntu2204"

      # Set the FQDN of the VM
      machine.vm.hostname = "#{name}" + "." + domain

      # Vagrant has no support to create and configure a network for Hyper-V; see https://www.vagrantup.com/docs/providers/hyperv/limitations
      # The Hyper-V "Default Switch" uses DHCP, but we want to assign a static ip-address.
      # Instruct Hyper-V to use the "NAT Switch"; use the Powershell script `vwmswitch.ps1` to create the virtual switch
      machine.vm.network "public_network", bridge: params.key?(:ip) ? "NAT Switch" : "Default switch"

      # Apply Hyper-V virtual machine specific settings
      machine.vm.provider "hyperv" do |h|
        h.cpus = params.key?(:cpus) ? params[:cpu] : 1
        h.maxmemory = params.key?(:memory) ? params[:memory] : 2048
        h.vmname = name
      end

      if Vagrant.has_plugin?("vagrant-hostmanager")
        if params.key?(:aliases)
          machine.hostmanager.aliases = params[:aliases].split(",")
        end
        if params.key?(:ip)
          # Define a custom ip address resolver for the Host Manager Plugin
          config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
            puts "#{vm.name}.#{domain}" + " " + machines[vm.name][:ip] 
            # lookup the ip address using the vm.name
            machines[vm.name][:ip]
          end
        end
      end

      # Increase security by replacing the insecure vagrant ssh key with your own key
      machine.ssh.private_key_path = ["~/.vagrant.d/insecure_private_key", ssh_key]
      machine.ssh.insert_key = false
      machine.vm.provision "file", source: ssh_key + ".pub", destination: "~/.ssh/authorized_keys"

      # Use shell script _hack_ to setup a static ip address for the VM
      if params.key?(:ip)
        machine.vm.provision "shell", path: "./scripts/network.sh", args: [params[:ip], cidr, domain, gateway]
      end

      if params.key?(:type)
        # Use shell script to install k3s https://docs.k3s.io/quick-start
        if "k3s_server".eql?(params[:type])
          k3s_exec = "server --token #{k3s_shared_token}" + (params.key?(:ip) ? " --node-external-ip #{params[:ip]}" : "") + (params.key?(:opts) ? " " + params[:opts] : "")
          machine.vm.provision "shell", path: "./scripts/install_k3s.sh", args: [k3s_exec]
        elsif "k3s_agent".eql?(params[:type])
          # NOTE: The first machine is expected to be a k3s server
          k3s_exec = "agent --token #{k3s_shared_token} --server https://#{machines.keys[0]}.#{domain}:6443" + (params.key?(:ip) ? " --node-external-ip #{params[:ip]}" : "") + (params.key?(:opts) ? " " + params[:opts] : "")
          machine.vm.provision "shell", path: "./scripts/install_k3s.sh", args: [k3s_exec]
        else
          puts "WARN: Unsupported type detected '#{params[:type]}' for machine #{name}."
          puts "WARN: Ignoring unsupported type."
        end
      end
    end
  end
end