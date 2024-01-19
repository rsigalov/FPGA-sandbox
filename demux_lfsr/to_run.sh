yosys -p 'synth_ice40 -top demux_lfsr -blif demux_lfsr.blif' demux_lfsr.v
arachne-pnr -d 1k -P vq100 -p demux_lfsr.pcf demux_lfsr.blif -o demux_lfsr.txt
icepack demux_lfsr.txt demux_lfsr.bin
sudo iceprog demux_lfsr.bin 