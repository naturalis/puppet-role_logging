#
#
#
class role_logging::elasticsearch_node(){



  class { 'elasticsearch':
    package_url   => 'https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.1.0/elasticsearch-2.1.0.deb',
    java_install  => true,
    config        => {
      'node.name'                => $::hostname,
      'cluster.name'             => 'Naturalis Logging Cluster',
      'index.number_of_shards'   => 15,
      'index.number_of_replicas' => 1
    },
    init_defaults => {
      'ES_HEAP_SIZE' => '50%'
    }
  }

      #'ES_HEAP_SIZE' => ceiling($::memorysize_mb/2048)

  elasticsearch::instance { "logging-cluster-${::hostname}":

  }

  elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
    instances  => "logging-cluster-${::hostname}",
  }

  es_instance_conn_validator { "logging-cluster-${::hostname}" :
    server =>  'localhost',
    port   => '9200',
  }


  # set minimum number of master nodig to (number of nodes /2  + 1)
  # check https://www.elastic.co/guide/en/elasticsearch/guide/current/_important_configuration_changes.html#_minimum_master_nodes
  exec { 'set number of master nodes':
    command => '/usr/bin/curl -XPUT localhost:9200/_cluster/settings -d \'{ "persistent" : { "discovery.zen.minimum_master_nodes" : \'"$(( ($(/usr/bin/curl -s localhost:9200/_cat/nodes | grep elasticsearch | wc -l)/2) + 1))"\' } } \'',
    unless  => '/usr/bin/test "$(curl -s localhost:9200/_cat/nodes | grep elasticsearch | grep -v * | wc -l)" -eq "$(( ($(/usr/bin/curl -s localhost:9200/_cat/nodes | grep elasticsearch | wc -l)/2) + 1))" ',
    require => Es_instance_conn_validator["logging-cluster-${::hostname}"] ,
  }

}
