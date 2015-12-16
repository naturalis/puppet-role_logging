#
#
#
class role_logging::log_muncher(
    $elasticsearch_adresses = [],
    $logstash_link = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.1.1-1_all.deb',
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

    exec { 'dpkg -i /opt/logstash_2.1.1-1_all.deb':
      subscribe   => Wget::Fetch[$logstash_link],
      refreshonly => true,
    }

    service { 'logstash':
      ensure  => running,
      require => Exec['dpkg -i /opt/logstash_2.1.1-1_all.deb'],
    }

    service { 'logstash-web':
      ensure  => stopped,
      require => Exec['dpkg -i /opt/logstash_2.1.1-1_all.deb'],
    }

    file {'/etc/logstash/conf.d/logstash.conf':
      content   => $logstash_filter,
      mode      => '0660',
      user      => 'logstash',
      group     => 'wheel',
      require   => Exec['dpkg -i /opt/logstash_2.1.1-1_all.deb'],
      subscribe => Service['logstash'],
    }
}