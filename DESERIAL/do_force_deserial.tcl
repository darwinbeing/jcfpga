isim force add {/deserial_tb/clock} 1 -radix bin -value 0 -radix bin -time 2 ns -repeat 4 ns 
isim force add {/deserial_tb/reset} 1 -radix bin 
run 1.00us
isim force add {/deserial_tb/reset} 0 -radix bin 
run 1.00us
