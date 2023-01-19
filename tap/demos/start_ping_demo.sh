#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setting up network and ping the echo demo device via SIL Kit Adapter TAP..."

# check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root / via sudo!"
    exit 1
fi

killall -w -q -15 SilKitAdapterTap &> /dev/null
echo "SilKitAdapterTap has been stopped"

echo "Recreating tap_demo_ns network namespace"
if test -f "/var/run/netns/tap_demo_ns"; then
    ip netns delete tap_demo_ns
fi

echo "Creating tap device silkit_tap"
ip tuntap add dev silkit_tap mode tap

echo "Starting SilKitAdapterTap..."
nohup bash -c "/"$SCRIPT_DIR"/../../build/bin/SilKitAdapterTap & disown %1" &> /$SCRIPT_DIR/../../build/bin/SilKitAdapterTap.out
sleep 2
echo "SilKitAdapterTap has been started"

# Hint: It is important to establish the connection to the the adapter before moving the tap device to its separate namespace
echo "Moving tap device 'silkit_tap' to network namespace 'tap_demo_ns'"
ip netns add tap_demo_ns
ip link set silkit_tap netns tap_demo_ns

echo "Configuring tap device 'silkit_tap'"
# Hint: The IP address can be set to anything as long as it is in the same network as the echo device which is pinged
ip -netns tap_demo_ns addr add 192.168.7.2/16 dev silkit_tap
ip -netns tap_demo_ns link set silkit_tap up


echo "Starting to ping the echo device..."
# Hint: The command 'ping -c4 192.168.7.35' can be replaced by any other command or application which should send/receive data to/from SIL Kit via silkit_tap
bash -c "nsenter --net=/var/run/netns/tap_demo_ns ping 192.168.7.35"