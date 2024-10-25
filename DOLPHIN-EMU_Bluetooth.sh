#!/bin/bash

# Free BT:
sudo modprobe -r btusb
sleep 3

# Start:
dolphin-emu

# --- AFTER EXITING DOLPHIN-EMU:

# CleanUp and free and mount BT:
sudo modprobe btusb
sleep 3

# INFO:
echo 'Wait around 10 Seconds, the BT SHOULD work again!'
echo 'THIS WILL CLOSE ITSELF!'

# Wait:
sleep 10

# Exit:
exit
