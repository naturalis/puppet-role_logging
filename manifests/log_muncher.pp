#
#
#
class role_logging::log_muncher(
    $elasticsearch_adresses = [],
    $logstash_link = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.1.1-1_all.deb',
    $filter_repo = 'https://github.com/naturalis/logstash_filter',
    $filter_tag = 'master',
    $logstash_private_key,
    $logstash_certificate,
){

    include wget

    $input = template('role_logging/logstash/input.erb')
    $output = template('role_logging/logstash/output.erb')

    #$logstash_filter = "### MANAGED BY PUPPET ###\n${input}\n${filter}\n${output}"


    package {'git': }

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

    file { '/etc/ssl/logstash_key.key':
      ensure  => present,
      content => $logstash_private_key,
      mode    => '0644',
    }

    file { '/etc/ssl/logstash_cert.crt':
      ensure  => present,
      content => $logstash_certificate,
      mode    => '0644',
    }

    file {'/etc/logstash/conf.d/input.conf':
      content => "### MANAGED BY PUPPET ###\n${input}",
      mode    => '0660',
      owner   => 'logstash',
      group   => 'wheel',
      require => Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb']
    }

    file {'/etc/logstash/conf.d/output.conf':
      content => $output,
      mode    => '0660',
      owner   => 'logstash',
      group   => 'wheel',
      require => Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb']
    }

    file {'/etc/logstash/conf.d/filter.conf':
      ensure  => 'link',
      target  => '/opt/logstash-filter/filter.conf',
      require => Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb']
    }

    vcsrepo {'/opt/logstash-filter/':
      ensure   => latest,
      provider => git,
      source   => 'https://github.com/naturalis/logstash_filter',
      revision => $filter_tag,
      require  => [
        Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
        Package['git'],
      ]
    }

    service { 'logstash':
      ensure    => running,
      require   => [
        Exec['/usr/bin/dpkg -i /opt/logstash_2.1.1-1_all.deb'],
        Class['::java'],
        File['/etc/ssl/logstash_cert.crt'],
        File['/etc/ssl/logstash_key.key']
      ],
      subscribe => [
        File['/etc/logstash/conf.d/input.conf'],
        File['/etc/logstash/conf.d/output.conf'],
        Vcsrepo['/etc/logstash/conf.d']
        ],
    }

}
