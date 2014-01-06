name             "newrelic"
maintainer       "Escape Studios"
#maintainer_email "dev@escapestudios.com"
maintainer_email "webops@lapresse.ca"
license          "MIT"
description      "Installs/Configures New Relic"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# Bumped the version from 0.x.y to 10.x.y to make sure we never switch accidentaly to upstream version
version          "10.5.6"

%w{ debian ubuntu redhat centos fedora scientific amazon windows smartos }.each do |os|
supports os
end

recommends "php"
recommends "python"
recommends "ms_dotnet4"
recommends "curl"
recommends "nodejs"

recipe "newrelic", "Adds the New Relic repository, installs & configures the New Relic server monitor package."
recipe "newrelic::repository", "Adds the New Relic repository."
recipe "newrelic::server-monitor", "Installs & configures the New Relic server monitor package."
recipe "newrelic::php-agent", "Installs the New Relic PHP agent."
recipe "newrelic::python-agent", "Installs the New Relic Python agent."
recipe "newrelic::dotnet", "Installs New Relic .NET Agent"
recipe "newrelic::nodejs", "Installs New Relic Node.js Agent"
