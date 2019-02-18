#
# Cookbook:: iap-auth
# Recipe:: setup
#
# Copyright:: 2019, The Authors, All Rights Reserved.
#

directory "#{node['iap-auth']['iap_auth_dir']}" do
  owner 'root'
  group 'root'
  action :create
  mode '0666'
end

remote_file "#{node['iap-auth']['iap_auth_dir']}/iap_auth.gz" do
  source "#{node['iap-auth']['github_release_url']}"
  owner 'root'
  group 'root'
  mode '0666'
  action :create
  not_if { File.exists?("#{node['iap-auth']['iap_auth_dir']}/iap_auth.gz") }
end

execute 'extract_iap_auth_gz' do
  command "tar xzvf iap_auth.gz"
  cwd "#{node['iap-auth']['iap_auth_dir']}"
  not_if { File.exists?("#{node['iap-auth']['iap_auth_dir']}/iap_auth") }
end

file "#{node['iap-auth']['iap_auth_dir']}/iap_auth" do
  mode '0755'
  owner 'root'
  group 'root'
end

bash 'base64_decode_gcloud_credentials' do
  cwd ::File.dirname("#{node['iap-auth']['iap_auth_dir']}")
  code <<-EOH
    base64 --decode #{['iap-auth']['service_account_credentials']} > #{node['iap-auth']['service_account_path'])}
  EOH
  not_if { ::File.exist?(node['iap-auth']['service_account_path']) }
end

file "#{node['iap-auth']['service_account_path']}" do
  content "#{node['iap-auth']['service_account_credentials']}"
  owner 'root'
  group 'root'
  mode '0666'
end

template "#{node['iap-auth']['iap_auth_dir']}/iap.conf" do
  source 'iap.conf.toml.erb'
  owner 'root'
  group 'root'
  mode '0666'
  variables(
    iap_host: node['iap-auth']['iap_host'],
    service_account_credentials: node['iap-auth']['service_account_credentials'],
    client_id: node['iap-auth']['client_id'],
    port: node['iap-auth']['port'],
    refresh_time_seconds: node['iap-auth']['refresh_time_seconds']
  )
end

systemd_unit 'iap-auth.service' do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=IAP auth service
  Documentation=https://github.com/gojekfarm/iap_auth
  ConditionPathExists="<%=node['iap-auth']['iap_auth_dir']/iap_auth%>"
  After=network.target

  [Service]
  ExecStart="<%=node['iap-auth']['iap_auth_dir']/iap_auth%> server"
  Restart=always

  [Install]
  WantedBy=multi-user.target

  EOU

  action [:create, :enable, :start]
end
