isim force add {/sreg_control/clock} 1 -radix bin -value 0 -radix bin -time 2 ns -repeat 4 ns 
isim force add {/sreg_control/reset} 0 -radix bin
run 1.00us
isim force add {/sreg_control/reset} 1 -radix bin
run 1.00us
isim force add {/sreg_control/reset} 0 -radix bin
run 1.00us
isim force add {/sreg_control/rx} 0 -radix bin
run 5.00us
isim force add {/sreg_control/spi_data} 1adadad5d1d6d3d1d5d1f1d0 -radix hex
run 1.00us
isim force add {/sreg_control/spi_data_load} 1 -radix bin
run 18.00ns
isim force add {/sreg_control/spi_data_load} 0 -radix bin

