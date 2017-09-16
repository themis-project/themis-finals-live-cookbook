id = 'themis-finals-live'

node[id].to_h.fetch('hosts', []).each do |item|
  themis_finals_live_host item['fqdn'] do
    ip_addr item['ip_addr']
    secure item.fetch('secure', false)
    action :create
  end
end
