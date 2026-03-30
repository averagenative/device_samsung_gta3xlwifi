#!/vendor/bin/sh
# Generate Bluetooth address from Exynos SoC unique ID
# The SCSC BT kernel module exposes a fallback address derived from the
# chip's unique ID at /sys/module/scsc_bt/parameters/bluetooth_address_fallback
# This script writes it to the EFS file that Android's BT stack reads.

BT_ADDR_FILE="/mnt/vendor/efs/bluetooth/bt_addr"
BT_FALLBACK="/sys/module/scsc_bt/parameters/bluetooth_address_fallback"

# Only generate if bt_addr is empty or missing
if [ -s "$BT_ADDR_FILE" ]; then
    EXISTING=$(cat "$BT_ADDR_FILE" 2>/dev/null)
    if [ "$EXISTING" != "" ] && [ "$EXISTING" != "00:00:00:00:00:00" ]; then
        exit 0
    fi
fi

# Wait for the BT kernel module to be loaded
TRIES=0
while [ ! -f "$BT_FALLBACK" ] && [ $TRIES -lt 30 ]; do
    sleep 1
    TRIES=$((TRIES + 1))
done

if [ ! -f "$BT_FALLBACK" ]; then
    log -t bt_addr_gen -p e "BT fallback address sysfs not available"
    exit 1
fi

ADDR=$(cat "$BT_FALLBACK" 2>/dev/null)
if [ -z "$ADDR" ] || [ "$ADDR" = "00:00:00:00:00:00" ]; then
    log -t bt_addr_gen -p e "BT fallback address is empty or zero"
    exit 1
fi

# Ensure directory exists
mkdir -p /mnt/vendor/efs/bluetooth
chmod 0770 /mnt/vendor/efs/bluetooth
chown system:bluetooth /mnt/vendor/efs/bluetooth

# Write the address
echo "$ADDR" > "$BT_ADDR_FILE"
chmod 0660 "$BT_ADDR_FILE"
chown system:bluetooth "$BT_ADDR_FILE"

log -t bt_addr_gen -p i "Generated BT address: $ADDR"
