# elasticsv
A bash script with the main purpose to get all fields in an index so you don't have to specify the fields anymore
because Logstash CSV output plugin requires you to specify the field you want to export


# Requirements
This script basically use curl to get the field lists available and still use logstash to get export to csv, so you need to make sure you have
- curl
- jq
- logstash


# Usage
elasticsv.sh -i <Index_Name> -o <Output_File>"

Additional Arguments:
 -u <Elasticsearch URL> (Optional)"
 -b <Logstash Binary> (Optional)"
 -d <Delimiter> (Optional, if used should be 1 Character only)"
  
Usage Example:
elasticsv.sh -i "logstash-YYYY.mm.dd" -o logstash.csv -u "http://127.0.0.1" -d ";"
