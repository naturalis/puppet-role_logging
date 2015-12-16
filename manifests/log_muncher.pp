#
#
#
class role_logging::log_muncher(
    $elasticsearch_adresses = [],
    $logstash_link = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.1.1-1_all.deb',
    $filebeat_link = 'https://download.elastic.co/beats/filebeat/filebeat_1.0.0_amd64.deb',
    $filter = 'filter {}'
){

    include wget

    $input = template('role_logging/logstash/input.erb')
    $output = template('role_logging/logstash/output.erb')

    $logstash_filter = "### MANAGED BY PUPPET ###\n${input}\n${filter}\n${output}"


    class { '::java':
      distribution => 'jre',
    }

    wget::fetch { $logstash_link :
      destination => '/opt/logstash_2.1.1-1_all.deb',
      timeout     => 0,
      verbose     => false,
    }

    wget::fetch { $filebeat_link :
      destination => '/opt/filebeat_1.0.0_amd64.deb',
      timeout     => 0,
      verbose     => false,
    }

    exec { '/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb':
      subscribe   => Wget::Fetch[$logstash_link],
      refreshonly => true,
    }

    exec { '/usr/bin/dpkg -i /opt/filebeat_1.0.0_amd64.deb':
      subscribe   => Wget::Fetch[$filebeat_link],
      refreshonly => true,
    }

    service { 'logstash':
      ensure  => running,
      require => Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
    }


    file {'/etc/logstash/conf.d/logstash.conf':
      content   => $logstash_filter,
      mode      => '0660',
      owner     => 'logstash',
      group     => 'wheel',
      require   => [
        Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
        Exec['/usr/bin/dpkg -i /opt/filebeat_1.0.0_amd64.deb']],
      subscribe => Service['logstash'],
    }
}
