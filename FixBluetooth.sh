#!/bin/bash

# CleanUp:
killall blueman-applet
killall blueman-tray
killall blueman-manager
killall dolphin-emu

sudo killall blueman-applet
sudo killall blueman-tray
sudo killall blueman-manager
sudo killall dolphin-emu

# Set vendor and product ID for your BT-Device (lsusb):
idVendor="0e8d"
idProduct="0616"

# Finding your BT-Device:
deviceInfo=$(lsusb | grep "ID $idVendor:$idProduct")

# Check device is there
if [ -n "$deviceInfo" ]; then
    # Extract the bus and device number:
    bus=$(echo "$deviceInfo" | awk '{print $2}')
    device=$(echo "$deviceInfo" | awk '{print $4}' | tr -d ':')
    
    # Print the results:
    echo "Bus: $bus"
    echo "Device: $device"
else
    echo "Device with idVendor $idVendor and idProduct $idProduct not found!"
    exit
fi

# Getting ProcessID
processID=$(fuser /dev/bus/usb/$bus/$device)

# Check if the processID is not equal to 0, 1, 2 (BOOT, SYS, PROBABLY IMPORTANT):
if [ "$processID" -ne 0 && "$processID" -ne 1 && "$processID" -ne 2 ]; then
    echo "The variable is not equal to 0, 1, 2 - OK."
    kill -9 "$processID"
    sudo kill -9 "$processID"
else
    echo "The variable is equal to 0, 1, 2! REBOOT PLS! CAN NOT FIX!"
    exit
fi

# Stop Stuff:
sleep 5
sudo systemctl stop bluetooth.service
sleep 1
sudo rmmod -f btusb
sleep 1
sudo modprobe -r -f btusb
sleep 1

# Restart Systems:
sudo modprobe btusb
sleep 1
sudo systemctl start bluetooth.service

# Exit:
echo "NOW WAIT AROUND 10 SECONDS! THIS WILL EXIT ITSELF!"
sleep 10

exit