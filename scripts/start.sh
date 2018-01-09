#! /bin/bash

echo "mailhub=${SMARTHOST_ADDRESS}" > /etc/ssmtp/ssmtp.conf

sleep 10 # wait for the db to startup
PGPASSWORD=${POSTGRES_PASSWORD} psql -U ${POSTGRES_USER} -h db -t -d ${POSTGRES_DB} -c '\d' | cut -d \| -f 2 
PGPASSWORD=${POSTGRES_PASSWORD} psql -U ${POSTGRES_USER} -h db -qt -d ${POSTGRES_DB} -c '\d' | cut -d \| -f 2 | grep -qw 'member'

if [ $? -eq 1 ] ; then
    # table does not exists and we need to bootstrap the DB
    # $? is 1
    PGPASSWORD=${POSTGRES_PASSWORD} psql -U ${POSTGRES_USER} -h db -q -d ${POSTGRES_DB} -f /opt/lf/core.sql
    PGPASSWORD=${POSTGRES_PASSWORD} psql -U ${POSTGRES_USER} -h db -q -d ${POSTGRES_DB} -f /opt/lf/config_db.sql
fi

set -e

if [ ! -f /opt/lf/frontend/config/lfconfig.lua ] ; then
        echo "Config file '/opt/lf/frontend/config/lfconfig.lua' not found! Copying config template file to volume. Edit it for your needs!"
        cp /tmp/lfconfig.lua /opt/lf/frontend/config/lfconfig.lua
fi

if [ -z $1 ] ; then
        /opt/lf/bin/lf_updated &

        su -s /bin/bash www-data -c "
/opt/lf/moonbridge/moonbridge \
    /opt/lf/webmcp/bin/mcp.lua \
    /opt/lf/webmcp/ \
    /opt/lf/frontend/ \
    main lfconfig
"

else
        exec "$@"
fi

