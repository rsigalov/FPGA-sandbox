yosys -p 'synth_ice40 -top mult_test -blif mult_test.blif' mult_test.v
arachne-pnr -d 1k -P vq100 -p mult_test.pcf mult_test.blif -o mult_test.txt
# icepack mult_test.txt mult_test.bin
# sudo iceprog mult_test.bin