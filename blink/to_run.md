yosys -p 'synth_ice40 -top blink -blif blink.blif' blink.v
arachne-pnr -d 1k -P vq100 -p blink.pcf blink.blif -o blink.txt
icepack blink.txt blink.bin
sudo iceprog blink.bin 
