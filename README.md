# role_logging


## Description

This puppet role module configures a cluster for storing and analyzing logs. It is based on Elasticsearch, Logstash, Filebeat and Kibana.


### beats.pp configuration
Two important variables. `$logstash_servers` and `$log_files_to_follow`

`$logstash_servers`  
Should be a list of DNS records which are resolvable in the form of `<name>.logstash.naturalis.nl`

`$log_files_to_follow`  
This is a array of hashes that configures the log files to follow. And example is in `yaml`
```
---
- paths:
  - /var/log/syslog
  fields:
    type: syslog
- paths:
  - /var/log/apache2/*.log
  fields:
    type: apache
```
Keys under `fields` are free to use. This can be used add metadata to the logs which Logstash or Elasticsearch can use.
For geoip you can use the following configurations. For source ip:
```
- paths:
  - /var/log/apache2/*.log
  fields:
    type: apache
    geoip_src_field: source_ip_field
```
For destination ip you can use:
```
- paths:
  - /var/log/apache2/*.log
  fields:
    type: apache
    geoip_dest_field: destination_ip_field
```
This will add geo ip information in the fields `geoip_src / geoip_dest`   

For data that should be kept longer use
```
fields:
  longterm: true
```
For test data
```
fields:
  testdata: true
```

Note: `fields.<key>` can only contain a string.
### log_muncher.pp configuration
Two important variables `$elasticsearch_adresses` and `$filter_tag`.

`$elasticsearch_adresses`  
An array of ip adrresses of Elasticsearch nodes.

`$filter_tag`  
Git tag of repository where the Logstash `filter {}` part is hosted.
