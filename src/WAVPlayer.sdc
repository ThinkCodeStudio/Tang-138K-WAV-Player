//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9 (64-bit) 
//Created Time: 2023-12-08 14:15:38
create_clock -name clk100m -period 10 -waveform {0 5} [get_nets {fifo_ram_module/clk100m}]
create_clock -name sysclk -period 20 -waveform {0 10} [get_ports {clk}]
create_clock -name clkout -period 20 -waveform {10 20} [get_pins {fifo_ram_module/ddr_module/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]
create_clock -name clk400m -period 2.5 -waveform {0 1.25} [get_nets {fifo_ram_module/clk400m}]
set_clock_groups -exclusive -group [get_clocks {clk100m}] -group [get_clocks {clk400m}]
set_clock_groups -exclusive -group [get_clocks {clk400m}] -group [get_clocks {clkout}]
