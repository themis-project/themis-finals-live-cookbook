id = 'themis-finals-live'

resource_name :themis_finals_live_host

property :fqdn, String, name_property: true
property :ip_addr, String, required: true
property :secure, [TrueClass, FalseClass], default: false
property :ec_certificates, [TrueClass, FalseClass], default: false

default_action :create

action :create do
  vars = {
    fqdn: new_resource.fqdn,
    secure: new_resource.secure,
    ip_addr: new_resource.ip_addr,
    access_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_access.log"),
    error_log: ::File.join(node['nginx']['log_dir'], "#{new_resource.fqdn}_error.log")
  }

  if new_resource.secure
    tls_rsa_certificate new_resource.fqdn do
      action :deploy
    end

    tls_rsa_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry(new_resource.fqdn)
    tls_ec_item = nil

    if new_resource.ec_certificates
      tls_ec_certificate new_resource.fqdn do
        action :deploy
      end

      tls_ec_item = ::ChefCookbook::TLS.new(node).ec_certificate_entry(new_resource.fqdn)
    end

    has_scts = tls_rsa_item.has_scts? && (tls_ec_item.nil? ? true : tls_ec_item.has_scts?)

    vars.merge!({
      ssl_rsa_certificate: tls_rsa_item.certificate_path,
      ssl_rsa_certificate_key: tls_rsa_item.certificate_private_key_path,
      hsts_max_age: node[id]['hsts_max_age'],
      oscp_stapling: node.chef_environment.start_with?('production'),
      scts: has_scts,
      scts_rsa_dir: tls_rsa_item.scts_dir,
      hpkp: node.chef_environment.start_with?('production'),
      hpkp_pins: tls_rsa_item.hpkp_pins,
      hpkp_max_age: node[id]['hpkp_max_age'],
      ec_certificates: new_resource.ec_certificates
    })

    if new_resource.ec_certificates
      vars.merge!({
        ssl_ec_certificate: tls_ec_item.certificate_path,
        ssl_ec_certificate_key: tls_ec_item.certificate_private_key_path,
        scts_ec_dir: tls_ec_item.scts_dir,
        hpkp_pins: (vars[:hpkp_pins] + tls_ec_item.hpkp_pins).uniq
      })
    end
  end

  nginx_site new_resource.fqdn do
    cookbook id
    template 'nginx.conf.erb'
    variables vars
    action :enable
  end
end
