#
#
#
class role_logging::log_muncher(
    $elasticsearch_adresses = [],
    $logstash_link = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.1.1-1_all.deb',
    $filter = 'filter {}',
    $logstash_private_key,
    $logstash_certificate,
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

    exec { '/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb':
      subscribe   => Wget::Fetch[$logstash_link],
      refreshonly => true,
    }

    service { 'logstash':
      ensure    => running,
      require   => [
        Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
        Class['::java']],
      subscribe => File['/etc/logstash/conf.d/logstash.conf']
    }


    file { '/etc/ssl/logstash_key.key' :
      ensure  => present,
      content => $logstash_private_key,
      mode    => '0644',
    }

    file { '/etc/ssl/logstash_cert.crt' :
      ensure  => present,
      content => $logstash_certificate,
      mode    => '0644',
    }

    file {'/etc/logstash/conf.d/logstash.conf':
      content => $logstash_filter,
      mode    => '0660',
      owner   => 'logstash',
      group   => 'wheel',
      require => [
        Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
        File['/etc/ssl/logstash_cert.crt'],
        File['/etc/ssl/logstash_key.key']
        ],
    }


}
