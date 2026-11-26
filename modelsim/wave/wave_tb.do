onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_HMAC_file/clk
add wave -noupdate -radix hexadecimal /tb_HMAC_file/reset_n
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_byte_valid
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_byte_start
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_byte_last
add wave -noupdate -radix hexadecimal /tb_HMAC_file/key
add wave -noupdate -radix hexadecimal /tb_HMAC_file/digest_ready
add wave -noupdate -radix hexadecimal /tb_HMAC_file/ready_for_next_byte
add wave -noupdate -radix hexadecimal /tb_HMAC_file/digest
add wave -noupdate -radix hexadecimal /tb_HMAC_file/digest_valid
add wave -noupdate -radix hexadecimal /tb_HMAC_file/messages_fd
add wave -noupdate -radix hexadecimal /tb_HMAC_file/digests_fd
add wave -noupdate -radix hexadecimal /tb_HMAC_file/character_read
add wave -noupdate -radix hexadecimal /tb_HMAC_file/scan_result
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_length
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_number
add wave -noupdate -radix hexadecimal /tb_HMAC_file/passed
add wave -noupdate -radix hexadecimal /tb_HMAC_file/failed
add wave -noupdate -radix hexadecimal /tb_HMAC_file/i
add wave -noupdate -radix hexadecimal /tb_HMAC_file/message_buffer
add wave -noupdate -radix hexadecimal /tb_HMAC_file/expected_digest
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13 ps} 0}
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
