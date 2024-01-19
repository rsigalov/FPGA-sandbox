yosys -p 'synth_ice40 -top uart_loopback -blif uart_loopback.blif' uart_loopback.v
arachne-pnr -d 1k -P vq100 -p uart_loopback.pcf uart_loopback.blif -o uart_loopback.txt
icepack uart_loopback.txt uart_loopback.bin
sudo iceprog uart_loopback.bin