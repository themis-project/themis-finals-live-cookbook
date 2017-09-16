id = 'themis-finals-live'

resource_name :themis_finals_live_host

property :fqdn, String, name_property: true
property :ip_addr, String, required: true
property :secure, [TrueClass, FalseClass], default: false

default_action :create

action :create do
  vars = {
    fqdn: new_resource.fqdn,
    ip_addr: new_resource.ip_addr,
    access_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_access.log"),
    error_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_error.log")
  }

  if new_resource.secure
    tls_certificate new_resource.fqdn do
      action :deploy
    end

    tls_item = ::ChefCookbook::TLS.new(node).certificate_entry(new_resource.fqdn)
    is_development = node.chef_environment.start_with?('development')

    vars.merge!({
      ssl_certificate: tls_item.certificate_path,
      ssl_certificate_key: tls_item.certificate_private_key_path,
      hsts_max_age: node[id]['hsts_max_age'],
      oscp_stapling: !is_development,
      scts: !is_development,
      scts_dir: tls_item.scts_dir,
      hpkp: !is_development,
      hpkp_pins: tls_item.hpkp_pins,
      hpkp_max_age: node[id]['hpkp_max_age']
    })
  end

  nginx_site new_resource.fqdn do
    cookbook id
    template new_resource.secure ? 'secure.nginx.conf.erb' : 'insecure.nginx.conf.erb'
    variables vars
    action :enable
  end
end
