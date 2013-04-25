#
# Cookbook Name:: newrelic
# Recipe:: php-agent
#
# Copyright 2012, Escape Studios
#

# Optionnaly execute apache2 recipe + mod_php5 recipe

if node['newrelic']['include_recipe_php'] 
  #  You need to set the attribute ['php']['ext_conf_dir'] 
  #  if you don't use the php recipe
  include_recipe "php"
end
if node['newrelic']['include_recipe_apache2']
  include_recipe "apache2"
  include_recipe "apache2::mod_php5"
else
  # extracted from apache2 cookbook
  service "apache2" do
    case node['platform_family']
    when "rhel", "fedora"
      service_name "httpd"
      # If restarted/reloaded too quickly httpd has a habit of failing.
      # This may happen with multiple recipes notifying apache to restart - like
      # during the initial bootstrap.
      restart_command "/sbin/service httpd restart && sleep 1"
      reload_command "/sbin/service httpd reload && sleep 1"
    when "suse"
      service_name "apache2"
      # If restarted/reloaded too quickly httpd has a habit of failing.
      # This may happen with multiple recipes notifying apache to restart - like
      # during the initial bootstrap.
      restart_command "/sbin/service apache2 restart && sleep 1"
      reload_command "/sbin/service apache2 reload && sleep 1"
    when "debian"
      service_name "apache2"
      restart_command "/usr/sbin/invoke-rc.d apache2 restart && sleep 1"
      reload_command "/usr/sbin/invoke-rc.d apache2 reload && sleep 1"
    when "arch"
      service_name "httpd"
    when "freebsd"
      service_name "apache22"
    end
    supports [:restart, :reload, :status]
    action :enable
  end
end

unless ::File.exists?('/usr/sbin/nrsysmond')
  case node[:platform]
  when "debian", "ubuntu", "redhat", "centos", "fedora", "scientific", "amazon"
    #the older version (3.0) had a bug in the init scripts that when it shut down the daemon it would also kill dpkg as it was trying to upgrade
    #let's remove the old packages before continuing
    package "newrelic-php5" do
      action :remove
      version "3.0.5.95"
    end

    #install/update latest php agent
    package "newrelic-php5" do
      action :install
    end

    #run newrelic-install
      execute "newrelic-install" do
        command "newrelic-install install"
        action :run
        notifies :reload, "service[apache2]", :delayed
      end
  when "suse" 
    # Handle generic installation with the tar.gz installer
    # Only tested under SLES/Suse but should work with other distributions
    # Other OS (BSD, mac) might work with similar actions
    include_recipe "newrelic::php-agent-install"
  end
end

service "newrelic-daemon" do
  supports :status => true, :start => true, :stop => true, :restart => true
  notifies :reload, "service[apache2]", :delayed
end

#https://newrelic.com/docs/php/newrelic-daemon-startup-modes
log "newrelic-daemon startup mode: #{node[:newrelic][:startup_mode]}"

unless ::File.exists?('/usr/sbin/nrsysmond')
  if node[:newrelic][:startup_mode] == "agent"
	  #agent startup mode

	  #ensure that the daemon isn't currently running
	  service "newrelic-daemon" do
		  action [:disable, :stop] #stops the service if it's running and disables it from starting at system boot time
	  end

	  #ensure that the file /etc/newrelic/newrelic.cfg does not exist if it does, move it aside (or remove it)
    execute "newrelic-backup-cfg" do
		command "mv /etc/newrelic/newrelic.cfg /etc/newrelic/newrelic.cfg.external"
		only_if do File.exists?("/etc/newrelic/newrelic.cfg") end
    end

	  #ensure that the file /etc/newrelic/upgrade_please.key does not exist if it does, move it aside (or remove it)
    execute "newrelic-backup-key" do
		command "mv /etc/newrelic/upgrade_please.key /etc/newrelic/upgrade_please.key.external"
		only_if do File.exists?("/etc/newrelic/upgrade_please.key") end
    end

	  #configure New Relic INI file and set the daemon related options (documented at /usr/lib/newrelic-php5/scripts/newrelic.ini.template)
	  #and restart apache in order to pick up the new settings
	  template "#{node[:php][:ext_conf_dir]}/newrelic.ini" do
		  source "newrelic.ini.php.erb"
		  owner "root"
		  group "root"
		  mode "0644"
		  variables(
			  :enabled => node[:newrelic][:application_monitoring][:enabled],
			  :license => node[:newrelic][:application_monitoring][:license],
			  :logfile => node[:newrelic][:application_monitoring][:logfile],
			  :loglevel => node[:newrelic][:application_monitoring][:loglevel],
			  :appname => node[:newrelic][:application_monitoring][:appname],
			  :daemon_logfile => node[:newrelic][:application_monitoring][:daemon][:logfile],
			  :daemon_loglevel => node[:newrelic][:application_monitoring][:daemon][:loglevel],
			  :daemon_port => node[:newrelic][:application_monitoring][:daemon][:port],
			  :daemon_max_threads => node[:newrelic][:application_monitoring][:daemon][:max_threads],
			  :daemon_ssl => node[:newrelic][:application_monitoring][:daemon][:ssl],
			  :daemon_ssl_ca_path => node[:newrelic][:application_monitoring][:daemon][:ssl_ca_path],
			  :daemon_ssl_ca_bundle => node[:newrelic][:application_monitoring][:daemon][:ssl_ca_bundle],
			  :daemon_proxy => node[:newrelic][:application_monitoring][:daemon][:proxy],
			  :daemon_pidfile => node[:newrelic][:application_monitoring][:daemon][:pidfile],
			  :daemon_location => node[:newrelic][:application_monitoring][:daemon][:location],
			  :daemon_collector_host => node[:newrelic][:application_monitoring][:daemon][:collector_host],
			  :daemon_dont_launch => node[:newrelic][:application_monitoring][:daemon][:dont_launch],
			  :capture_params => node[:newrelic][:application_monitoring][:capture_params],
			  :ignored_params => node[:newrelic][:application_monitoring][:ignored_params],
			  :error_collector_enable => node[:newrelic][:application_monitoring][:error_collector][:enable],
			  :error_collector_record_database_errors => node[:newrelic][:application_monitoring][:error_collector][:record_database_errors],
			  :error_collector_prioritize_api_errors => node[:newrelic][:application_monitoring][:error_collector][:prioritize_api_errors],
			  :browser_monitoring_auto_instrument => node[:newrelic][:application_monitoring][:browser_monitoring][:auto_instrument],
			  :transaction_tracer_enable => node[:newrelic][:application_monitoring][:transaction_tracer][:enable],
			  :transaction_tracer_threshold => node[:newrelic][:application_monitoring][:transaction_tracer][:threshold],
			  :transaction_tracer_detail => node[:newrelic][:application_monitoring][:transaction_tracer][:detail],
			  :transaction_tracer_slow_sql => node[:newrelic][:application_monitoring][:transaction_tracer][:slow_sql],
			  :transaction_tracer_stack_trace_threshold => node[:newrelic][:application_monitoring][:transaction_tracer][:stack_trace_threshold],
			  :transaction_tracer_explain_threshold => node[:newrelic][:application_monitoring][:transaction_tracer][:explain_threshold],
			  :transaction_tracer_record_sql => node[:newrelic][:application_monitoring][:transaction_tracer][:record_sql],
			  :transaction_tracer_custom => node[:newrelic][:application_monitoring][:transaction_tracer][:custom],
			  :framework => node[:newrelic][:application_monitoring][:framework],
			  :webtransaction_name_remove_trailing_path => node[:newrelic][:application_monitoring][:webtransaction][:name][:remove_trailing_path],
			  :webtransaction_name_functions => node[:newrelic][:application_monitoring][:webtransaction][:name][:functions],
			  :webtransaction_name_files => node[:newrelic][:application_monitoring][:webtransaction][:name][:files]
		  )
		  action :create
		  notifies :reload, "service[apache2]", :delayed
	  end
  else
	  #external startup mode

	  #configure proxy daemon settings
	  template "/etc/newrelic/newrelic.cfg" do
		  source "newrelic.cfg.erb"
		  owner "root"
		  group "root"
		  mode "0644"
		  variables(
			  :daemon_pidfile => node[:newrelic][:application_monitoring][:daemon][:pidfile],
			  :daemon_logfile => node[:newrelic][:application_monitoring][:daemon][:logfile],
			  :daemon_loglevel => node[:newrelic][:application_monitoring][:daemon][:loglevel],
			  :daemon_port => node[:newrelic][:application_monitoring][:daemon][:port],
			  :daemon_ssl => node[:newrelic][:application_monitoring][:daemon][:ssl],
			  :daemon_proxy => node[:newrelic][:application_monitoring][:daemon][:proxy],
			  :daemon_ssl_ca_path => node[:newrelic][:application_monitoring][:daemon][:ssl_ca_path],
			  :daemon_ssl_ca_bundle => node[:newrelic][:application_monitoring][:daemon][:ssl_ca_bundle],
			  :daemon_max_threads => node[:newrelic][:application_monitoring][:daemon][:max_threads],
			  :daemon_collector_host => node[:newrelic][:application_monitoring][:daemon][:collector_host]
		  )
		  action :create
	  end

	  service "newrelic-daemon" do
	  	action [:enable, :start] #starts the service if it's not running and enables it to start at system boot time
	  end
  end
end
