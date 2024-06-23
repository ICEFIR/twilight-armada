#!/bin/sh
echo -e "Bi-Syncing assets from b2 storage"
rclone bisync ./twilight-armada/assets twilight-armada:twilight-armada $@
