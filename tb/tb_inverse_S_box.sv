module tb_inverse_S_box;

    // Stimuli
    reg [7:0] input_value;

    // Probes
    wire [7:0] output_value;


    inverse_S_box dut (
        .input_value(input_value),
        .output_value(output_value)
    );

    /*
    After changing input_value, wait 1 ps before checking output_value.
    This gives the always_comb block time to update the combinational 
    output.
    */
    initial begin
        // TEST 1 : value 0x00
        input_value = 8'h00;      
        #1ps;

        if(output_value == 8'h52)
            $display("Test 1 PASS: input: 0x00 , output: %h", output_value);
        else
            $display("Test 1 FAIL: input: 0x00 , expected: 0x52 , output: %h)", output_value);


        // TEST 2 : value 0xd3
        input_value = 8'hd3;
        #1ps;

        if(output_value == 8'ha9)
            $display("Test 2 PASS: input: 0xd3 , output: %h", output_value);
        else
            $display("Test 2 FAIL: input: 0xd3 , expected: 0xa9 , output: %h)", output_value);


        // TEST 3 : value 0xff
        input_value = 8'hff;
        #1ps;

        if(output_value == 8'h7d)
            $display("Test 3 PASS: input: 0xff , output: %h", output_value);
        else
            $display("Test 3 FAIL: input: 0xff , expected: 0x7d , output: %h", output_value);


        // TEST 4 : value 0x43
        input_value = 8'h43;
        #1ps;

        if(output_value == 8'h64)
            $display("Test 4 PASS: input: 0x43 , output: %h", output_value);
        else
            $display("Test 4 FAIL: input: 0x43 , expected: 0x64 , output: %h", output_value);

        $display("Test completed");
        $stop;
    end
    endmodule
