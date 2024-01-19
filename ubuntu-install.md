# Steps to install icestorm tools on Ubuntu

Mostly following [this blogpost](https://eecs.blog/lattice-ice40-fpga-icestorm-tutorial/) but with a few changes:
1. Do not install `python` which tries to install `python2`
2. Instead of `qt5-default`, install the list of qt5 dependencies listed below

## Step0: Install dependencies:

```r
sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
```

```r
sudo apt-get install build-essential clang bison flex libreadline-dev \
                     gawk tcl-dev libffi-dev git mercurial graphviz   \
                     xdot pkg-config python3 libftdi-dev \
                     python3-dev libboost-all-dev cmake libeigen3-dev
```

Don't forget to install `git` to download repositories
```r
sudo apt install git-all
```

## Step 1: Install icestorm tools

Option `-j1` specifies using only one thread for installation

```r
git clone https://github.com/YosysHQ/icestorm.git icestorm
cd icestorm
make -j1
sudo make install
```

## Step 2: Install arachne pnr

```r
git clone https://github.com/cseed/arachne-pnr.git arachne-pnr
cd arachne-pnr
make -j1
sudo make install
```

## Step 3: Install next pnr

```r
git clone https://github.com/YosysHQ/nextpnr nextpnr
cd nextpnr
cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
make -j1
sudo make install
```

## Step 4: Install yosys

```r
git clone https://github.com/YosysHQ/yosys.git yosys
cd yosys
make config-gcc  # not exactly sure why this is needed. Otherwise, tries to use a different compiler...
make -j1
sudo make install
```

## Writing bitstream

The following sequence of commands generates a binary with a bitstream and writes it to FPGA. Make sure to use the correct `-P vq100` option corresponding to the version of `ice40` we are dealing with
```r
yosys -p 'synth_ice40 -top blink -blif blink.blif' blink.v
arachne-pnr -d 1k -P vq100 -p blink.pcf blink.blif -o blink.txt
icepack blink.txt blink.bin
sudo iceprog blink.bin 
```




