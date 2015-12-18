#
#
#
class role_logging::kibana(
  $kibana_version = '4.3.1',
  $elasticsearch_host = '127.0.0.1'
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

  file { 'kibana service init':
    content => template('role_logging/kibana/init.erb'),
    path    => '/etc/init.d/kibana',
    mode    => '0775',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  service {'kibana':
    ensure    => running,
    subscribe => File['kibana service init'],
  }

}
