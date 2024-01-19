yosys -p 'synth_ice40 -top vga_test_2 -blif vga_test_2.blif' vga_test_2.v
arachne-pnr -d 1k -P vq100 -p constraints.pcf vga_test_2.blif -o vga_test_2.txt
icepack vga_test_2.txt vga_test_2.bin
sudo iceprog vga_test_2.bin