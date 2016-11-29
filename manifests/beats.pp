#
#
#
class role_logging::beats(
  $install_filebeat = true,
  $install_topbeat = false,
  $filebeat_version = '1.3.1',
  $log_files_to_follow = [

    {'paths' => ['/var/log/syslog'],
    'fields'=> {'type' => 'syslog'}},

    {'paths' => ['/var/log/cloud-init.log'],
    'fields'=> {'type' => 'cloud-init'}}

    ],
  $logstash_servers = ['piet.logstash.naturalis.nl'],
  $logstash_private_key,
  $logstash_certificate,
){

  $filebeat_link = "https://download.elastic.co/beats/filebeat/filebeat_${filebeat_version}_amd64.deb"

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


  if ($install_filebeat) {
    wget::fetch { $filebeat_link :
      destination => "/opt/filebeat_${filebeat_version}_amd64.deb",
      timeout     => 0,
      verbose     => false,
    }

    exec { "/usr/bin/dpkg --force-all -i /opt/filebeat_${filebeat_version}_amd64.deb" :
      subscribe   => Wget::Fetch[$filebeat_link],
      refreshonly => true,
    }

    file {'/etc/filebeat/filebeat.yml':
      content => template('role_logging/beats/filebeat_part.yml.erb','role_logging/beats/output.yml.erb'),
      require => Exec["/usr/bin/dpkg --force-all -i /opt/filebeat_${filebeat_version}_amd64.deb"],
    }

    service { 'filebeat':
      ensure    => running,
      subscribe => File['/etc/filebeat/filebeat.yml'],
      require   => [
        Exec["/usr/bin/dpkg --force-all -i /opt/filebeat_${filebeat_version}_amd64.deb"],
        File['/etc/ssl/logstash_cert.crt'],
        File['/etc/ssl/logstash_key.key'],
        File['/etc/filebeat/filebeat.yml']
        ],
    }


  }


}
