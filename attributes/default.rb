#
# Cookbook:: iap-auth
# Attributes:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.
#

default['iap-auth']['version'] = ENV['IAP_AUTH_VERSION'] || '0.1.0'

default['iap-auth']['release_gz_file'] = "iap_auth_#{node['iap-auth']['version']}_Linux_x86_64.tar.gz"
default['iap-auth']['github_release_url'] = "https://github.com/gojekfarm/iap_auth/releases/download/v#{node['iap-auth']['version']}/#{node['iap-auth']['release_gz_file']}"
default['iap-auth']['iap_auth_dir'] = '/opt/iap_auth'
default['iap-auth']['service_account_path'] = "#{node['iap-auth']['iap_auth_dir']}/service_account_credentials.json"

default['iap-auth']['iap_host'] = ENV['IAP_HOST']
default['iap-auth']['service_account_credentials'] = ENV['SERVICE_ACCOUNT_CREDENTIALS']
default['iap-auth']['client_id'] = ENV['CLIENT_ID']
default['iap-auth']['port'] = ENV['PORT'] || '8080'
default['iap-auth']['refresh_time_seconds'] = ENV['REFRESH_TIME_SECONDS'] || '3600s'
