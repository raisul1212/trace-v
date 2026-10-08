# picorv32 (PicoRV32, RV32I) on sky130_fd_sc_hd
# Clock: 8 ns (125 MHz), 0.25 ns uncertainty. Max fanout 10.
# I/O delays are half a period (4.0 ns): the testbench drives the inputs and
# samples the outputs on the falling clock edge. The look-ahead and
# co-processor/trace ports (mem_la_*, pcpi_*, eoi, trace_*) are not exercised by
# the testbench and are left unconstrained.
create_clock -name clk -period 8.0 [get_ports clk]
set_clock_uncertainty 0.25 [get_clocks clk]
set_max_fanout 10 [current_design]
set_input_delay 4.0 -clock clk [get_ports {resetn mem_ready mem_rdata[*] pcpi_wr pcpi_rd[*] pcpi_wait pcpi_ready irq[*]}]
set_output_delay 4.0 -clock clk [get_ports {trap mem_valid mem_instr mem_addr[*] mem_wdata[*] mem_wstrb[*]}]
