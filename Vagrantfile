# VMの台数
NUM_VMS = 1

Vagrant.configure("2") do |config|

	###
	# 各VM共通の設定
	###
	config.vm.box = "generic/ubuntu2004"

	config.vm.provider "virtualbox" do |v|
		v.memory = 1024
		v.cpus = 1
	end

	config.vm.synced_folder "./vm_share", "/vm_share"

	config.vm.provision "shell" do |s|
		s.path = "provisioner.sh"
		s.args = [NUM_VMS]
	end


	###
	# 各VM固有の設定
	###
	1.upto(NUM_VMS) do |i|
		config.vm.define vm_name = "node#{i}" do |config|
			config.vm.hostname = vm_name
			ip = "192.168.56.#{100+i}"
			config.vm.network "private_network", ip: ip, virtualbox__intnet: "intranet"
			if i == 1 then
				config.vm.network "forwarded_port", guest: 8080, host: 8080
			end
		end
	end

end
