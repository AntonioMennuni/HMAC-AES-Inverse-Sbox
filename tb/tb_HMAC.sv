module tb_HMAC_file;

    // Stimuli
    reg clk;
    reg reset_n = 1'b1;
    reg [7:0] message_byte = 8'h00;
    reg message_byte_valid = 1'b0;
    reg message_byte_start = 1'b0;
    reg message_byte_last = 1'b0;
    reg [63:0] key = 64'h00;
    reg digest_ready = 1'b0;

    // Probes
    wire ready_for_next_byte;
    wire [63:0] digest;
    wire digest_valid;

    // Internal elements used to perform the testbench operations
    integer messages_fd;
    integer digests_fd;
    integer character_read;
    integer scan_result;
    integer message_length;
    integer message_number;
    integer passed;
    integer failed;
    integer i;
    reg [7:0] message_buffer [0:255];
    reg [63:0] expected_digest = 64'h00;



    HMAC dut (
        .clk(clk),
        .reset_n(reset_n),
        .message_byte(message_byte),
        .message_byte_valid(message_byte_valid),
        .message_byte_start(message_byte_start),
        .message_byte_last(message_byte_last),
        .ready_for_next_byte(ready_for_next_byte),
        .key(key),
        .digest(digest),
        .digest_valid(digest_valid),
        .digest_ready(digest_ready)
    );

    // Clock generation
    initial clk = 1'b0;
    always #5ps clk = !clk; // 10 ps clock period
    
    // Reset generation
    initial #7.5 reset_n = 1'b0; // Reset on at 7.5 ps
    
    initial begin
        message_byte = 8'h00;
        message_byte_valid = 1'b0;
        message_byte_start = 1'b0;
        message_byte_last = 1'b0;
        key = 64'h0001020304050607;
        digest_ready = 1'b0;
        message_number = 0;
        passed = 0;
        failed = 0;

        // $fopen opens the file and positions the cursor at the beginning.
        messages_fd = $fopen("tv/messages.txt", "r");   // opening the message file
        digests_fd = $fopen("tv/digests_1.txt", "r");   // opening the digest file

        // Verify that the file opening has been carried out properly
        if ((messages_fd == 0) || (digests_fd == 0)) 
        begin
            $display("ERROR: Unable to open the test vector files!");
            $stop;  // end the simulation
        end

        #20ps;
        reset_n = 1'b1;//reset off at 20ps

        /* 
        $fgetc reads one character from the current cursor position and advances the cursor. Therefore, the first call reads the first 
        character of messages.txt The function returns -1 when the end of file is reached. 
        */
        character_read = $fgetc(messages_fd);

        /* 
        fscanf with %h option reads the next hexadecimal value and saves it in expected_digest. Whitespace, including a newline, is 
        treated as value separator. Since the digest file contains one hexadecimal digest per line, the call reads one digest. 
        scan_result is 1 when the value is read successfully, -1 when the end of file is reached. 
        */
        scan_result = $fscanf(digests_fd, "%h", expected_digest);

        // While there are still characters to read and digests to compare
        while ((character_read != -1) && (scan_result == 1)) 
        begin
            message_length = 0; // Used to count the number of characters of the current message

            // Read and store characters until the end of the message line.
            // While not end of line and not end of file
            while ((character_read != 10) && (character_read != -1)) 
            begin
                /* 
                If character is not carriage return (CR), store it in message_buffer, otherwise ignore it and read the next 
                one using $fgetc 
                */
                if (character_read != 13) 
                begin
                    message_buffer[message_length] = character_read[7:0];
                    message_length = message_length + 1;
                end

                // Read the next character; the cursor advances with every call.
                character_read = $fgetc(messages_fd);
            end

            message_number = message_number + 1;

            // Send the message bytes, one by one, to the module
            for (i = 0; i < message_length; i = i + 1)
            begin
                /* 
                testbench pauses at that line until the falling edge of the 
                clock is reached, then it continues executing the next lines of code 
                */
                @(negedge clk);
                message_byte = message_buffer[i];// Send the current byte to the input port of the module
                message_byte_valid = 1'b1;
                message_byte_start = (i == 0);
                message_byte_last = (i == message_length - 1);

                /* 
                Wait for the module to complete the computations on the previous byte, so that it is ready to accept a new byte 
                (ready_for_next_byte = 1'b1) 
                */
                while (ready_for_next_byte == 1'b0)
                    @(negedge clk);

                /* 
                On the next rising edge, the module accepts the byte, because message_byte_valid and ready_for_next_byte are 
                high, and the FSM transitions to the state S2_MESSAGE_ROUND 
                */
                @(posedge clk);
            end

            // Now the last byte of the message has been sent to the module, and the FSM is in state S2_MESSAGE_ROUND

            @(negedge clk);
            message_byte_valid = 1'b0;
            message_byte_start = 1'b0;
            /* 
            Set to 0 because the module uses the old value of message_byte_last, sampled on the rising edge of the clock 
            in the register final_message_byte, when the module accepts the last message byte, and the FSM is in state S1_BYTE_WAIT 
            (or S0_IDLE if the message is a single character message)
            */
            message_byte_last = 1'b0;

            /* 
            Now the last byte is being processed and the FSM will transition from S2 to S3 and then to S4. Until the FSM 
            doesn't transition in S4, the digest is not valid and the testbench waits for it to become valid 
            */
            while (digest_valid == 1'b0)
                @(negedge clk);

            // Output validation
            if (digest == expected_digest) 
            begin
                passed = passed + 1;
                $display("TEST %d PASSED: computed digest = %16h , expected digest = %16h", 
                        message_number, digest, expected_digest);
            end 
            else 
            begin
                failed = failed + 1;
                $display("TEST %d FAILED: computed digest = %16h , expected digest = %16h", 
                        message_number, digest,expected_digest);
            end

            // Accept the digest so that the circuit can process the next message.
            @(negedge clk);
            digest_ready = 1'b1;
            
            // The FSM transitions from S4 to S0 and the module is ready to accept a new message
            @(posedge clk);

            @(negedge clk);
            digest_ready = 1'b0;

            // Read the first character of a new message or, the end of file
            character_read = $fgetc(messages_fd);
            // Read the next hexadecimal digest; the newline separates it from the previous value
            scan_result = $fscanf(digests_fd, "%h", expected_digest);
        end



        /* 
        After the loop, at least one file may still contain data:
           - character_read != -1: messages_fd has another character.
           - scan_result == 1: digests_fd has another readable digest.           
        If one of the two is true, there is another string, either in messages.txt or digest.txt. This is not the expected situation because
        when this if instruction is reached, the two files should have been exhausted. An error message is printed.
        If both are false, both files are exhausted because this means that character_read = -1 
        and scan_result = -1 , so both files have been read completely. No error message.   
        Both being true cannot normally occur here, because the while loop would continue when both are true 
        */   
        if ((character_read != -1) || (scan_result == 1)) 
            $display("ERROR: the files contain different numbers of lines.");

        $display("Results: %0d passed, %0d failed", passed, failed);
        $fclose(messages_fd);
        $fclose(digests_fd);
        $stop;
    end
endmodule