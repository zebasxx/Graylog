#!/bin/bash

#Create MongoDB script to query Notifications collection in Graylog DB

echo "var db = connect(\"127.0.0.1:27017/graylog\");">/var/lib/docker/volumes/graylog_mongo_data/_data/query_notifications.js
echo "var allNotifications = db.notifications.find();">>/var/lib/docker/volumes/graylog_mongo_data/_data/query_notifications.js
echo "while (allNotifications.hasNext()) {">>/var/lib/docker/volumes/graylog_mongo_data/_data/query_notifications.js
echo "   printjson(allNotifications.next());">>/var/lib/docker/volumes/graylog_mongo_data/_data/query_notifications.js
echo "};">>/var/lib/docker/volumes/graylog_mongo_data/_data/query_notifications.js

#Get Notifications about new version:

NewVer=$(docker exec Mongo_DB mongo /data/db/query_notifications.js|grep current_version)
NewVer=${NewVer:23:5}

if [[ $NewVer = "" ]];then echo "No New Version notification found, exiting";exit;fi;echo "New Version notification found, proceding with upgrade"

#Get current version from docker-compose.yml file
CurrVer=$(cat /graylog/docker-compose.yml|grep harbor.moravia.com/mirror/graylog/graylog:)
CurrVer=${CurrVer:53:5}

#Pull new image to save downtime
docker pull harbor.moravia.com/mirror/graylog/graylog:$NewVer

#Turn off Graylog
docker-compose -f /graylog/docker-compose.yml down

#Update docker-compose file with new version
sed -i "s|graylog:${CurrVer}|graylog:${NewVer}|g" /graylog/docker-compose.yml

#Turn on Graylog
docker-compose -f /graylog/docker-compose.yml up -d

#Clean up old image
docker image rm harbor.moravia.com/mirror/graylog/graylog:$CurrVer

