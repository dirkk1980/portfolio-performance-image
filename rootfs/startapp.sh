#!/bin/sh

echo '#!/bin/sh
# Check if .lock file exists
if [ -f /opt/portfolio/workspace/.sync.lock ]; then
    echo "Sync already in progress"
    return
fi
# Create .lock file to prevent multiple syncs
touch /opt/portfolio/workspace/.sync.lock
# Sync files to nextcloud
exec nextcloudcmd --non-interactive -h -s -u $NEXTCLOUD_USER -p $NEXTCLOUD_PASSWORD --path "$NEXTCLOUD_REMOTE_PATH" /opt/portfolio/workspace/nextcloud $NEXTCLOUD_URL &
# Wait for sync to finish
wait $!
# Remove .lock file
rm /opt/portfolio/workspace/.sync.lock
# Check if sync was successful
if [ $? -eq 0 ]; then
    echo "Sync successful"
else
    echo "Sync failed"
fi' >> /tmp/start_sync.sh
chmod +x /tmp/start_sync.sh


autocheck_filesystem_inotify() {
    inotifywait -m -r --exclude ".sync.*" -e modify,create,delete,move "/opt/portfolio/workspace/nextcloud" |
    while read path action file; do
        echo "The file '$file' at '$path' was $action"
        /tmp/start_sync.sh
    done
}

# Check if tint2 is installed and start
if command -v tint2 >/dev/null 2>&1; then
    # Start tint2 panel with preconfigured config
    exec tint2 -c /usr/share/tint2/vertical-neutral-icons.tint2rc &
    # Set DBUS_SESSION_BUS_ADDRESS (https://unix.stackexchange.com/a/647236)
    export DBUS_SESSION_BUS_ADDRESS=`dbus-daemon --fork --config-file=/usr/share/dbus-1/session.conf --print-address`
fi

# if nextcloudcmd is installed, start it
if command -v nextcloudcmd >/dev/null 2>&1; then
    # Create nextcloud folder in /root
    mkdir -p /opt/portfolio/workspace/nextcloud
    /tmp/start_sync.sh
    autocheck_filesystem_inotify &
    # add cronjob to sync every 1 minute
    #echo "*/1 * * * * /tmp/start_sync.sh" > /tmp/cronjob
    #crontab /tmp/cronjob
    #rm /tmp/cronjob
fi

# Set JAVA PATH variable for openjdk 17 jre
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# start portfolio performance
# change to workdpace dir, so that file open dialog in pp will show up mounted dir in left menu
cd /opt/portfolio/workspace
#start application
exec /opt/portfolio/PortfolioPerformance > /config/log/pp_out.log 2> /config/log/pp_err.log