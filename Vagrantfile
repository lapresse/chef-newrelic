hosts_defs = {
  "sles11sp2-chef11" => {
    "hostname" => "sles11sp2-chef11",
    "ipaddress" => "10.20.30.16",
    "run_list" => [
      "recipe[apache2]",
      "recipe[php::default]",
      "recipe[newrelic::php-agent]",
      "recipe[newrelic::server-monitor]"
    ]
  },
#  "ubuntu-precise-chef10" => {
#    "hostname" => "ubuntu-precise-chef10",
#    "ipaddress" => "10.20.30.17",
#    "environment" => "dev",
#    "run_list" => [
#      "recipe[chef-solo-search]",
#      "recipe[monitoring::linux]",
#      "recipe[monitoring::services]"
#    ]
#  },
  "ubuntu-precise-chef11" => {
    "hostname" => "ubuntu-precise-chef11",
    "ipaddress" => "10.20.30.18",
    "environment" => "qidc",
    "run_list" => [
      "recipe[php::default]",
      "recipe[newrelic::php-agent]",
      "recipe[newrelic::server-monitor]"
    ]
  }
}

Vagrant.configure("2") do |global_config|
  hosts_defs.each_pair do |name, options|
    global_config.vm.define name do |config|
      config.vm.box = name
      config.vm.box_url = "http://gustavo.lapresse.ca/vagrant/boxes/#{name}.box"
      config.vm.hostname = "newrelic-#{options['hostname']}"
      config.vm.network :private_network, ip: options["ipaddress"]
      #config.vm.provision :shell, :inline => "cp /vagrant/event.json /root"

      config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end

      if name == 'rhel64-64-chef11'
        config.vm.network :forwarded_port, guest: 8080, host: 8888
        config.vm.network :forwarded_port, guest: 443, host: 8443
      end

      # hack pas beau
      if name =~ /sles/
        config.vm.provision :shell, :inline => "test -L /usr/bin/chef-client || ln -s /opt/chef/bin/chef-client /usr/bin/chef-client"
        config.vm.provision :shell, :inline => "test -L /usr/bin/chef-solo || ln -s /opt/chef/bin/chef-solo /usr/bin/chef-solo"
      end

      if name =~ /chef11/
        config.omnibus.chef_version = :latest
      end

      config.vm.provision :chef_solo do |chef|
        chef.data_bags_path = "data_bags"
        chef.run_list = options['run_list']
        chef.json = {
          "php" => {
            "install_method" => "package"
          },
          "newrelic" => {
            #'php_recipe' => "zend-server",
            "server_monitoring" => {
              "license" => ENV['NEWRELIC_LICENSE_KEY']
            },
            "application_monitoring" => {
              "license" => ENV['NEWRELIC_LICENSE_KEY'],
              "enabled" => true,
              "appname" => "TEST_TEST"
            },
            "startup_mode" => "external"
          }
        }
      end
    end
  end
end
