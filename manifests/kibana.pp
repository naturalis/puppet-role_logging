#
#
#
class role_logging::kibana(
  $kibana_link = 'https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz'
){



  staging::deploy {'kibana-4.3.1-linux-x64.tar.gz':
    source => $kibana_link,
    target => '/opt/'
  }

}
