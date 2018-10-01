#
# Cookbook:: managed-automate2
# Attributes:: default
#
# Copyright:: 2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# airgap_bundle recipe
# set location to copy the airgap installation bundle and chef-automate command
default['ma2']['aib']['dir'] = Chef::Config[:file_cache_path]
# path to the AIB file to be saved in the aib recipe and used in the default
default['ma2']['aib']['file_name'] = 'chef-automate-airgap.aib'

# default recipe
# non-root user for Chef Automate
default['ma2']['user'] = 'chefautomate'
# provide the file path or URL for the AIB file
default['ma2']['aib']['file'] = node['ma2']['aib']['dir'] + '/' + node['ma2']['aib']['file_name']
default['ma2']['aib']['url'] = nil

# set location of the chef-automate CLI
default['ma2']['chef-automate'] = node['ma2']['aib']['dir'] + '/chef-automate'

# sysctl settings to apply to make the preflight-check pass
default['ma2']['sysctl']['fs.file-max'] = 64000
default['ma2']['sysctl']['vm.max_map_count'] = 262144
default['ma2']['sysctl']['vm.dirty_ratio'] = 15
default['ma2']['sysctl']['vm.dirty_background_ratio'] = 35
default['ma2']['sysctl']['vm.dirty_expire_centisecs'] = 20000

default['ma2']['license']['string'] = nil
default['ma2']['license']['url'] = nil
