onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/clk
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/reset_n
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/message_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/message_byte_valid
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/message_byte_start
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/message_byte_last
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/ready_for_next_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/key
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/digest
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/digest_valid
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/digest_ready
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/current_state
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/next_state
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/sbox_output
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/current_message_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/round_counter
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/message_byte_counter
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/final_message_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/key_reg
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/j
add wave -noupdate -radix hexadecimal /tb_HMAC_file/dut/i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {43 ps}
