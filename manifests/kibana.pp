#
#
#
class role_logging::kibana(
  $kibana_version = '4.3.1',
  $elasticsearch_host = '127.0.0.1',
  $kibana_password,
  $certificate,
  $private_key,
){

  $kibana_link = "https://download.elastic.co/kibana/kibana/kibana-${kibana_version}-linux-x64.tar.gz"

  staging::deploy { "kibana-${kibana_version}-linux-x64.tar.gz":
    source => $kibana_link,
    target => '/opt/'
  }

  file_line {'kibana_es_host_config':
    path  => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
    line  => "elasticsearch.url: http://${elasticsearch_host}:9200",
    match => '^elasticsearch.url'
  }

  file_line {'server_host_config':
    path  => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
    line  => 'server.host: 127.0.0.1',
    match => '^server.host'
  }

  file { 'kibana service init':
    content => template('role_logging/kibana/init.erb'),
    path    => '/etc/init.d/kibana',
    mode    => '0775',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  file {'kibana log directory':
    ensure => directory,
    path   => '/var/log/kibana',
    before => Service['kibana']
  }

  file {'kibana log rotate':
    content => template('role_logging/kibana/logrotate.erb'),
    path    => '/etc/logrotate.d/kibana',
  }

  file { '/etc/ssl/web_client_key.pem' :
    ensure  => present,
    content => $private_key,
    mode    => '0644',
  }

  file { '/etc/ssl/web_client_cert.pem' :
    ensure  => present,
    content => $certificate,
    mode    => '0644',
  }

  service {'kibana':
    ensure    => running,
    subscribe => File['kibana service init'],
  }


  class {'nginx': }

  nginx::resource::upstream { 'kibana_naturalis_nl':
    members => ['localhost:5601'],
  }

  httpauth { 'kibana':
    ensure    => present,
    file      => '/etc/nginx/.htpasswd',
    password  => $kibana_password,
    mechanism => basic,
    notify    => Service['nginx'],
  }
  # Set correct permissions on password file
  file { '/etc/nginx/.htpasswd':
    mode    => '0644',
    require => Httpauth['kibana']
  }


  nginx::resource::vhost { 'kibana.naturalis.nl':
    proxy                => 'http://kibana_naturalis_nl',
    ssl                  => true,
    listen_port          => 443,
    ssl_cert             => '/etc/ssl/web_client_cert.pem',
    ssl_key              => '/etc/ssl/web_client_key.pem',
    auth_basic           => 'Restricted Content',
    auth_basic_user_file => '/etc/nginx/.htpasswd',
    require              => [
      File['/etc/ssl/web_client_key.pem'],
      File['/etc/ssl/web_client_cert.pem'],
      Httpauth['kibana']],
  }




}
