yosys  # to launch yosys
read_verilog filename.v
hierarchy -top debounce_filter
proc
opt
fsm
opt
show -prefix debounce