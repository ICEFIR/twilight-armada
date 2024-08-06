#!/bin/sh
echo -e "Bi-Syncing assets from b2 storage"
rclone bisync ./godot/assets twilight-armada:twilight-armada $@
rclone bisync ./godot/addons twilight-armada-godot-addon:twilight-armada-godot-addon $@
