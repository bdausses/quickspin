{
	"fqdn": "${chef_server}",
	"chef-server": {
		"configuration": "nginx['ssl_certificate'] = '/opt/chef-ssl/chef_server.pem'\nnginx['ssl_certificate_key'] = '/opt/chef-ssl/chef_server.key'\n\n# Chef Automate\ndata_collector['root_url'] = 'https://${a2_server}/data-collector/v0/'\n\n# Add for chef client run forwarding\ndata_collector['proxy'] = true\n\n# Add for compliance scanning\nprofiles['root_url'] = 'https://${a2_server}'",
		"accept_license": true
	}
}
