#
#
#
class role_logging::elasticsearch_node(
  $nodes_ip_array = [],
  $longterm_term = 14,
  $testdata_term = 5,
  $default_term = 7,
  $parsefail_term = 2,
  ){

  $heapsize = ceiling($::memorysize_mb/2048)
  $minimum_master_nodes = count($nodes_ip_array)/2 + 1

  package {'python-pip':} -> class {'curator': }

  class { 'elasticsearch':
    package_url   => 'https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.1.0/elasticsearch-2.1.0.deb',
    java_install  => true,
    config        => {
      'node.name'                            => $::hostname,
      'node.master'                          => true,
      'node.data'                            => true,
      'cluster.name'                         => 'Naturalis Logging Cluster',
      'index.number_of_shards'               => 15,
      'index.number_of_replicas'             => 1,
      'network.host'                         => $::ipaddress,
      'discovery.zen.minimum_master_nodes'   => 1,
      'discovery.zen.ping.multicast.enabled' => false,
      'discovery.zen.ping.unicast.hosts'     => $nodes_ip_array,
      'discovery.zen.ping_timeout'           => '30s',
    },
    init_defaults => {
      'ES_HEAP_SIZE' => "${heapsize}g"
    }
  }

  elasticsearch::instance { "logging-cluster-${::hostname}":

  }

  elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
    instances  => "logging-cluster-${::hostname}",
  }

  curator::job { 'logterm_delete':
    bin_file    => '/usr/local/bin/curator',
    command     => 'delete',
    prefix      => 'logstash-longterm-',
    older_than  => $longterm_term,
    cron_hour   => 1,
    cron_minute => 1,
    master_only => true,
    host        => $::ipaddress,
  }

  curator::job { 'testdata_delete':
    bin_file    => '/usr/local/bin/curator',
    command     => 'delete',
    prefix      => 'logstash-testdata-',
    older_than  => $testdata_term,
    cron_hour   => 1,
    cron_minute => 5,
    master_only => true,
    host        => $::ipaddress,
  }

  curator::job { 'default_delete':
    bin_file    => '/usr/local/bin/curator',
    command     => 'delete',
    prefix      => 'logstash-',
    older_than  => $default_term,
    cron_hour   => 1,
    cron_minute => 10,
    master_only => true,
    host        => $::ipaddress,
  }

  curator::job { 'parsefailure_delete':
    bin_file    => '/usr/local/bin/curator',
    command     => 'delete',
    prefix      => 'logstash-parsefailure-',
    older_than  => $parsefail_term,
    cron_hour   => 1,
    cron_minute => 15,
    master_only => true,
    host        => $::ipaddress,
  }

}
