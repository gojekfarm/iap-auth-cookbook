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

ruby_block 'base64_decode_gcloud_credentials' do
  block do
    require 'base64'
    json_content = Base64.decode64("#{node['iap-auth']['service_account_credentials']}")
    File.open("#{node['iap-auth']['service_account_path']}", 'w') do |file|
      file.puts json_content
    end
  end
end

template "#{node['iap-auth']['iap_auth_dir']}/iap.conf.toml" do
  source 'iap.conf.toml.erb'
  owner 'root'
  group 'root'
  mode '0666'
  variables(
    iap_host: node['iap-auth']['iap_host'],
    service_account_credentials: node['iap-auth']['service_account_path'],
    client_id: node['iap-auth']['client_id'],
    port: node['iap-auth']['port'],
    refresh_time_seconds: node['iap-auth']['refresh_time_seconds']
  )
end

template '/etc/systemd/system/iap-auth.service' do
    source            'systemd.service.erb'
    owner             'root'
    group             'root'
    mode              '0644'
    variables(iap_auth_dir: node['iap-auth']['iap_auth_dir'])

    # reload daemon immediately
    notifies :run, 'execute[systemctl-daemon-reload]', :immediately
    notifies :restart, "service[iap-auth]", :delayed
end

execute 'systemctl-daemon-reload' do
    command '/bin/systemctl --system daemon-reload'
    action :nothing
end

service 'iap-auth' do
    action :enable
    supports :status => true, :start => true, :restart => true, :stop => true
    provider Chef::Provider::Service::Systemd
end
