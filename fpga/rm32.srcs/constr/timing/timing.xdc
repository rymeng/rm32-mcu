create_clock -period 20.000 -name xclk_i [get_ports xclk_i]
create_clock -period 200.000 -name swclk_i [get_ports swclk_i]
set_clock_groups -asynchronous -group [get_clocks xclk_i] -group [get_clocks swclk_i]
