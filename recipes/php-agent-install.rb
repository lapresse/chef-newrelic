#
# This recipe install the PHP-agent on platform that 
# don't have proper package from tar.gz
#

# Handle generic installation with the tar.gz installer
# Only tested under SLES/Suse but should work with other distributions
# Other OS (BSD, mac) might work with similar actions
tarname = 'nrp-php5.tar.gz'
phpagent_tar = "#{Chef::Config[:file_cache_path]}/#{tarname}"  
untardir = "#{Chef::Config[:file_cache_path]}/newrelic-php5-latest" 

remote_file phpagent_tar do
  source node['newrelic']['phpagent']['url_tar_linux'] 
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[newrelic-cleanup-phpagent]", :immediately
  notifies :run, "execute[newrelic-untar-phpagent]", :immediately
  action :create_if_missing
end

directory untardir do
  mode 0755
  action :create
end

execute "newrelic-cleanup-phpagent" do
  command "rm -rf #{untardir}"
  action :nothing
  notifies :create, "directory[#{untardir}]", :immediately
end

execute "newrelic-untar-phpagent" do
  command "tar xfz #{phpagent_tar} -C #{untardir}"
  action :nothing
  notifies :run, "execute[newrelic-install-phpagent]", :immediately
end

# Installer needs more options to run silently in manual mode
execute "newrelic-untar-phpagent" do
  cwd untardir
  command "export NR_INSTALL_SILENT=1 NR_INSTALL_KEY=#{node['newrelic']['application_monitoring']['license']}; ./newrelic-install install"
  action :nothing
  notifies :restart, "service[apache2]", :delayed
end

