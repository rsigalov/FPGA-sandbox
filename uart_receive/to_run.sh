yosys -p 'synth_ice40 -top UART_receive_and_show -blif uart_receive.blif' uart_receive.v
arachne-pnr -d 1k -P vq100 -p uart_receive.pcf uart_receive.blif -o uart_receive.txt
icepack uart_receive.txt uart_receive.bin
sudo iceprog uart_receive.bin 