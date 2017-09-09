id = 'themis-finals-live'

resource_name :themis_finals_live_host

property :fqdn, String, name_property: true
property :ip_addr, String, required: true

default_action :create

action :create do
  nginx_site new_resource.fqdn do
    cookbook id
    template 'nginx.conf.erb'
    variables(
      fqdn: new_resource.fqdn,
      ip_addr: new_resource.ip_addr,
      access_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_access.log"),
      error_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_error.log")
    )
    action :enable
  end
end
