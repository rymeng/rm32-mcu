create_clock -period 20.000 -name XCLK [get_ports XCLK]
create_clock -period 200.000 -name SWCLK [get_ports SWCLK]
set_clock_groups -asynchronous -group [get_clocks XCLK] -group [get_clocks SWCLK]
