#
# Cookbook:: managed-automate2
# Recipe:: default
#

a2user = node['ma2']['user']
a2dir = '/home/' + a2user
a2aibfile = a2dir + '/chef-automate-airgap.aib'
a2chef = a2dir + '/chef-automate'
licensefile = a2dir + '/automate.license'

# manage Automate with its own user
user a2user do
  manage_home true
  shell '/bin/false'
  system true
end

# copy over the local file or download it
if node['ma2']['aib']['url'].nil?
  execute "cp #{node['ma2']['aib']['file']} #{a2aibfile}" do
    not_if { ::File.exist?(a2aibfile) }
  end
else
  remote_file a2aibfile do
    source node['ma2']['aib']['url']
    not_if { ::File.exist?(a2aibfile) }
  end
end

file a2aibfile do
  owner a2user
end

# local copy of chef-automate
execute "cp #{node['ma2']['chef-automate']} #{a2chef}" do
  not_if { ::File.exist?(a2chef) }
end

file a2chef do
  mode '0755'
  owner a2user
end

# get the license from a URL
unless node['ma2']['license']['url'].nil?
  remote_file licensefile do
    source node['ma2']['license']['url']
    owner a2user
    not_if { ::File.exist?(licensefile) }
  end
end

# or get the license from a string
unless node['ma2']['license']['string'].nil?
  file licensefile do
    content node['ma2']['license']['string']
    owner a2user
    sensitive true
    not_if { ::File.exist?(licensefile) }
  end
end

# prepare for preflight-check

# OK |  running as root
# OK |  volume: has 40GB avail (need 5GB for installation)
# OK |  automate not already deployed
# OK |  initial required ports are available
# OK |  init system is systemd
# OK |  found required command useradd
# OK |  system memory is at least 2000000 KB (2GB)
# OK |  fs.file-max must be at least 64000
# OK |  vm.max_map_count is at least 262144
# OK |  vm.dirty_ratio is between 5 and 30
# OK |  vm.dirty_background_ratio is between 10 and 60
# OK |  vm.dirty_expire_centisecs must be between 10000 and 30000

# fs.file-max is at least 64000
fs_file_max = `sysctl -n fs.file-max`.strip.to_i
sysctl_param 'fs.file-max' do
  value node['ma2']['sysctl']['fs.file-max']
  not_if { fs_file_max > 64000 }
end

# vm.max_map_count must be at least 262144
vm_max_map_count = `sysctl -n vm.max_map_count`.strip.to_i
sysctl_param 'vm.max_map_count' do
  value node['ma2']['sysctl']['vm.max_map_count']
  not_if { vm_max_map_count > 262144 }
end

# vm.dirty_ratio is between 5 and 30
vm_dirty_ratio = `sysctl -n vm.dirty_ratio`.strip.to_i
sysctl_param 'vm.dirty_ratio' do
  value node['ma2']['sysctl']['vm.dirty_ratio']
  not_if { (vm_dirty_ratio > 5) && (vm_dirty_ratio < 30) }
end

# vm.dirty_background_ratio is between 10 and 60
vm_dirty_background_ratio = `sysctl -n vm.dirty_background_ratio`.strip.to_i
sysctl_param 'vm.dirty_background_ratio' do
  value node['ma2']['sysctl']['vm.dirty_background_ratio']
  not_if { (vm_dirty_background_ratio > 10) && (vm_dirty_background_ratio < 60) }
end

# vm.dirty_expire_centisecs must be between 10000 and 30000
vm_dirty_expire_centisecs = `sysctl -n vm.dirty_expire_centisecs`.strip.to_i
sysctl_param 'vm.dirty_expire_centisecs' do
  value node['ma2']['sysctl']['vm.dirty_expire_centisecs']
  not_if { (vm_dirty_expire_centisecs > 10000) && (vm_dirty_expire_centisecs < 30000) }
end

# Verify the installation is ready to run Automate 2
execute "#{a2chef} preflight-check --airgap" do
  not_if { ::File.exist?("#{a2dir}/config.toml") }
end

# create default configuration
execute "#{a2chef} init-config --upgrade-strategy none" do
  cwd a2dir
  not_if { ::File.exist?("#{a2dir}/config.toml") }
end

# deploy chef automate
execute 'chef-automate deploy' do
  command "#{a2chef} deploy config.toml --accept-terms-and-mlsa --skip-preflight --airgap-bundle #{a2aibfile}"
  cwd a2dir
  not_if { ::File.exist?("#{a2dir}/automate-credentials.toml") }
end

execute 'chef-automate license apply' do
  command "#{a2chef} license apply #{licensefile}"
  not_if "#{a2chef} license status | grep '^License ID'"
end

# should we push the contents of automate-credentials.toml into an attribute or
# log if we don't want logins on the box?
# should we push the admin-token for later? ruby-block to an attribute?
