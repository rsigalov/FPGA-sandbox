yosys -p 'synth_ice40 -top wiring_switches -blif wiring_switches.blif' wiring_switches.v
arachne-pnr -d 1k -P vq100 -p wiring_switches.pcf wiring_switches.blif -o wiring_switches.txt
icepack wiring_switches.txt wiring_switches.bin
sudo iceprog wiring_switches.bin 
