#
# server-monitor - install from tarball
#

group "newrelic" do
  action :create
end

# Same method should work with other distro/platforms
tarname = 'nrp-sysmond.tar.gz'
sysmond_tar = "#{Chef::Config[:file_cache_path]}/#{tarname}"  
untardir = "#{Chef::Config[:file_cache_path]}/newrelic-sysmond-latest" 

remote_file sysmond_tar do
  source node['newrelic']['server_monitoring']['url_tar_linux'] 
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[newrelic-cleanup-sysmond]", :immediately
  notifies :run, "execute[newrelic-untar-sysmond]", :immediately
  action :create_if_missing
end

directory untardir do
  mode 0755
  action :create
end

execute "newrelic-cleanup-sysmond" do
  command "rm -rf #{untardir}"
  action :nothing
  notifies :create, "directory[#{untardir}]", :immediately
end

execute "newrelic-untar-sysmond" do
  command "tar xfz #{sysmond_tar} -C #{untardir}"
  notifies :run, "execute[newrelic-install-sysmond]", :immediately
#  notifies :run, "execute[newrelic-install-sysmondcfg]", :immediately
end

directory "/etc/newrelic" do
  action :create
end


# This stinks: we make sure not to reload on every run, but we may ends up
# not being able to overwrite (Text file busy error) our file if it indeed changes.
# Would need a big pile of stop-if-this-or-that resource... dammit
log("cp #{untardir}/*/daemon/nrsysmond.#{ node['kernel']['machine'] == "x86_64" ? "x64" : "x86" } /usr/local/sbin/nrsysmond ; cp #{untardir}/*/scripts/nrsysmond-config /usr/local/sbin") { level :warn}
execute "newrelic-install-sysmond" do
  not_if "diff -q #{untardir}/*/daemon/nrsysmond.#{ node['kernel']['machine'] == "x86_64" ? "x64" : "x86" } /usr/local/sbin/nrsysmond "
  # we use * so that we don't have to know the exact name of the tarball content
  command "cp #{untardir}/*/daemon/nrsysmond.#{ node['kernel']['machine'] == "x86_64" ? "x64" : "x86" } /usr/local/sbin/nrsysmond "
end

# Hum... that's what /etc/newrelic/nrsysmond.cfg is doing...
#execute "newrelic-install-sysmondcfg" do
#  #not_if "-e /usr/local/sbin/nrsysmond"
#  # we use * so that we don't have to know the exact name of the tarball content
#  command "cp #{untardir}/*/scripts/nrsysmond-config /usr/local/sbin/nrsysmond.cfg"
#end

# Use template name per-platform discovery to set correctly your platform
template "/etc/init.d/newrelic-sysmond" do
  source "newrelic-sysmond.init.erb"
  mode 0755
end

file "/etc/sysconfig/nrsysmond" do
  content "NRSYSMOND_CONFIG=/etc/newrelic/nrsysmond.cfg\n"
end

directory "/var/log/newrelic/" do
  action :create
end
