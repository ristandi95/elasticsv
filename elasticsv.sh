#!/bin/bash
# bash script with main purpose to get all fields in an index so you don't have to specify the fields anymore
# because Logstash CSV output plugin require you to specify the field you want to export
#
# You need to install these tools in order to run this script
# - Curl
# - jq
# - logstash


# Get The Args
while getopts u:i:b:o:d: option
do
 case "${option}"
 in
  u) ESURL=${OPTARG};;
  i) INDEX=${OPTARG};;
  b) BINLOGSTASH=${OPTARG};;
  o) OUTPUTFILE=${OPTARG};;
  d) DELIMITER=${OPTARG}
 esac
done

if [[ -z $OUTPUTFILE || -z $INDEX || ${#DELIMITER} -ge 2 ]]
then
 echo "Usage: $0  -i <Index_Name> -o <Output_File>"
 echo "           -u <Elasticsearch URL> (Optional)"
 echo "           -b <Logstash Binary> (Optional)"
 echo "           -d <Delimiter> (Optional, if used should be 1 Character only)"
 exit 1
fi

if [[ -z $ESURL ]]
then
 ESURL="http://localhost:9200"
fi

if [[ -z $BINLOGSTASH ]]
then
 BINLOGSTASH="/usr/share/logstash/bin/logstash"
fi

if [[ -z $DELIMITER ]]
then
 DELIMITER=","
fi

# A small preparation
rm -f $OUTPUTFILE
DIR=$(pwd)

# Getting Fields List in an Index
echo "[+] Get Fields Information from $ESURL/$INDEX"
FIELDS=$(curl $ESURL/$INDEX/_mapping?pretty -s | awk '/"doc" : {/,0' | awk '/"@timestamp" : {/,0' | sed ':a;N;$!ba;s/\n/~~~/g' | sed 's/^/{/g;s/~~~/\n/g' | jq -r '[paths | join(".")]' 2>/dev/null | sed -r 's/(\.properties|\.type|\.norms|\.fields|\.keyword|\.ignore_above)//g;s/,//g' | sed '/^\[$/d' | sed '/^\]$/d' | sed 's/ //g' | uniq | sed ':a;N;$!ba;s/\n/,/g')
echo "[+] Fields we can get for this index is"
echo $FIELDS

# Prepare Logstash Configuration File
cp $DIR/logstash2csv.conf.orig $DIR/logstash2csv.conf
chmod +w $DIR/logstash2csv.conf
sed -r "s/(^\s+hosts =>).*$/\1 [$(echo $ESURL|sed 's/\//\\\//g')]/g" -i $DIR/logstash2csv.conf
sed -r "s/(^\s+index =>).*$/\1 \"$INDEX\"/g" -i $DIR/logstash2csv.conf
sed -r "s/(^\s+fields =>).*$/\1 [$FIELDS]/g" -i $DIR/logstash2csv.conf
sed -r "s/(^\s+path =>).*$/\1 \"$(echo $DIR|sed 's/\//\\\//g')\/$OUTPUTFILE\"/g" -i $DIR/logstash2csv.conf
sed -r "s/(^\s+\"col_sep\" =>).*$/\1 \"$DELIMITER\"/g" -i $DIR/logstash2csv.conf

# Executing Logstash
echo "[+] Generating CSV Using Logstash"
$BINLOGSTASH -f $DIR/logstash2csv.conf --quiet 2>/dev/null
