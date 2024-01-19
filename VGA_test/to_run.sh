yosys -p 'synth_ice40 -top VGA_Test_Patterns_Top -blif VGA_Test_Patterns_Top.blif' *.v
arachne-pnr -d 1k -P vq100 -p VGA_Test_Patterns_Top.pcf VGA_Test_Patterns_Top.blif -o VGA_Test_Patterns_Top.txt
icepack VGA_Test_Patterns_Top.txt VGA_Test_Patterns_Top.bin
sudo iceprog VGA_Test_Patterns_Top.bin 