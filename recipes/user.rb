# Copyright 2015 Sergey Bahchissaraitsev

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
Chef::Recipe.send(:include, Hops::Helpers)

group node['airflow']['group'] do
  gid node['airflow']['group_id']
  action :create
  not_if "getent group #{node['airflow']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['airflow']['user'] do
  comment "Airflow user"
  home node["airflow"]["user_home_directory"]
  uid node['airflow']['user_id']
  gid node['airflow']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['airflow']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

hopsworksUser = "glassfish"
if node.attribute? "hopsworks" and node["hopsworks"].attribute? "user"
   hopsworksUser = node['hopsworks']['user']
end

group node['airflow']['group'] do
  action :modify
  members [hopsworksUser]  
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
  only_if "getent passwd #{hopsworksUser}"
end

hops_hdfs_directory "/user/#{node['airflow']['user']}" do
  action :create_as_superuser
  owner node['airflow']['user']
  group node['hops']['group']
  mode "1777"
end

crypto_dir = x509_helper.get_crypto_dir(node['airflow']['user'])
kagent_hopsify "Generate x.509" do
  user node['airflow']['user']
  crypto_directory crypto_dir
  action :generate_x509
  not_if { node["kagent"]["enabled"] == "false" }
end


