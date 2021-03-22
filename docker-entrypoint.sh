#!/bin/sh
set -e

echo "Setting up MySQL database if it does not exists ..."
echo "Wait for MySQL server ..."
#mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" --password="$MYSQL_PASSWORD" --wait=10
echo "Create database schema if it does not exists ..."
#mysql -u $MYSQL_USER -h $MYSQL_HOST --password="$MYSQL_PASSWORD" -e "source /opt/shinobi/sql/framework.sql" $MYSQL_DATABASE || true

SSL_CONFIG='{}'
DATABASE_CONFIG='{"host": "'$DB_HOST'","user": "'$DB_USER'","password": "'$DB_PASSWORD'","database": "'$DB_DATABASE'","port":'$DB_PORT'}'
cronKey="$(head -c 1024 < /dev/urandom | sha256sum | awk '{print substr($1,1,29)}')"

cd /opt/shinobi
mkdir -p libs/customAutoLoad
if [ -e "/config/conf.json" ]; then
    cp /config/conf.json conf.json
fi
if [ ! -e "./conf.json" ]; then
    cp conf.sample.json conf.json
fi
sed -i -e 's/change_this_to_something_very_random__just_anything_other_than_this/'"$cronKey"'/g' conf.json
node tools/modifyConfiguration.js subscriptionId=$SUBSCRIPTION_ID cpuUsageMarker=CPU utcOffset=$utcOffset thisIsDocker=true pluginKeys="$PLUGIN_KEYS" db="$DATABASE_CONFIG" ssl="$SSL_CONFIG"
cp conf.json /config/conf.json

echo "============="
echo "Default Superuser : admin@shinobi.video"
echo "Default Password : admin"
echo "Log in at http://HOST_IP:SHINOBI_PORT/super"
if [ -e "/config/super.json" ]; then
    cp /config/super.json super.json
fi
if [ ! -e "./super.json" ]; then
    cp super.sample.json super.json
    cp super.sample.json /config/super.json
fi

if [ -e "/config/init.extension.sh" ]; then
    echo "Running extension init file ..."
    ( sh /config/init.extension.sh ) 
fi

# Execute Command
echo "Starting Shinobi ..."
exec "$@"
