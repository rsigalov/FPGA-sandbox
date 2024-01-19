yosys -p 'synth_ice40 -top debounce_project -blif debounce.blif' debounce.v
arachne-pnr -d 1k -P vq100 -p debounce.pcf debounce.blif -o debounce.txt
icepack debounce.txt debounce.bin
sudo iceprog debounce.bin 