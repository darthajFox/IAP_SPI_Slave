onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /programmer_tb/sys_clk
add wave -noupdate /programmer_tb/sys_nrst
add wave -noupdate /programmer_tb/fifo_empty
add wave -noupdate -radix hexadecimal /programmer_tb/fifo_rd_data
add wave -noupdate /programmer_tb/fifo_rd_en
add wave -noupdate /programmer_tb/command_reg
add wave -noupdate /programmer_tb/flag
add wave -noupdate /programmer_tb/cond
add wave -noupdate /programmer_tb/programmer_dut/start_program
add wave -noupdate /programmer_tb/program_done
add wave -noupdate /programmer_tb/verify_done
add wave -noupdate /programmer_tb/program_error
add wave -noupdate /programmer_tb/programmer_dut/fetch_error
add wave -noupdate /programmer_tb/spi_violation_err
add wave -noupdate /programmer_tb/spi_process_err
add wave -noupdate /programmer_tb/SCK
add wave -noupdate /programmer_tb/MOSI
add wave -noupdate /programmer_tb/NSS
add wave -noupdate /programmer_tb/MISO
add wave -noupdate -radix hexadecimal /programmer_tb/spi_cmd
add wave -noupdate -radix hexadecimal /programmer_tb/spi_data
add wave -noupdate /programmer_tb/spi_cmd_val
add wave -noupdate /programmer_tb/spi_cnt
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_rd_data
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_wr_req
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_wr_data
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_done
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_enable
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/spi_busy
add wave -noupdate /programmer_tb/programmer_dut/fetch_FSM
add wave -noupdate /programmer_tb/programmer_dut/fetch_FSM_next
add wave -noupdate /programmer_tb/programmer_dut/program_FSM
add wave -noupdate /programmer_tb/programmer_dut/program_FSM_next
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/calc_CRC
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/CRC_cnt
add wave -noupdate /programmer_tb/programmer_dut/step_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/block_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/byte_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/digest_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/component_size
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/component_num
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/component_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/fetch_size
#add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/image_header_size
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/fetch_cnt
add wave -noupdate -radix unsigned /programmer_tb/programmer_dut/delay_cnt
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/program_buffer
add wave -noupdate -radix hexadecimal /programmer_tb/programmer_dut/fetch_buffer
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {495793 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 320
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {203316 ps} {1618088 ps}
