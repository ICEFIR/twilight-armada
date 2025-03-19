#!/bin/sh
echo -e "Bi-Syncing assets from b2 storage"
rclone sync ./godot/assets twilight-armada:twilight-armada $@
rclone sync ./godot/addons twilight-armada-godot-addon:twilight-armada-godot-addon $@
