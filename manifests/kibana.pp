#
#
#
class role_logging::kibana(
  $kibana_link = 'https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz',
  $elasticsearch_host = '127.0.0.1'
){



  staging::deploy {'kibana-4.3.1-linux-x64.tar.gz':
    source => $kibana_link,
    target => '/opt/'
  }

  file_line {'kibana_es_host_config':
    path => '/opt/kibana-4.3.1-linux-x64/config/kibana.yml',
    line => "elasticsearch.url: ${elasticsearch_host}:9200",
  }

}
