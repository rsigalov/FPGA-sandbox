yosys -p 'synth_ice40 -top pattern_game_top -blif pattern_game.blif' pattern_game.v
arachne-pnr -d 1k -P vq100 -p pattern_game.pcf pattern_game.blif -o pattern_game.txt
icepack pattern_game.txt pattern_game.bin
sudo iceprog pattern_game.bin 