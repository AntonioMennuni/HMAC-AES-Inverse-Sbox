//NOTATION
/*
[W] -> wire : 
Element declared as a register and not sinthesized as a real hardware register but as a wire, because it is used in alwasy_comb block only. 
This is to avoid confusion, because sometimes elements declared as registers are updated in always_comb blocks and not in always_ff blocks. 
So they are not sinthesized as real hardware registers but as wires. All other elements declared as registers are updated in always_ff 
blocks and sinthesized as real hardware registers.
*/



module HMAC (
    input             clk,                 // Clock signal
    input             reset_n,             // Asynchronous active-low reset
    input      [7:0]  message_byte,        // Current input message byte to be processed
    input             message_byte_valid,  // Set to 1 when input message_byte is valid, otherwise set to 0
    input             message_byte_start,  // Set to 1 when the first input byte of the message is being processed, otherwise set to 0
    input             message_byte_last,   // Set to 1 when the last input byte of the message is being processed, otherwise set to 0
    output reg        ready_for_next_byte, // [W] Set to 1 when the module is ready to accept a new input message byte, otherwise set to 0
    input      [63:0] key,                 // 64-bit key used to produce the digest
    output reg [63:0] digest,              // [W] 64-bit output digest 
    output reg        digest_valid,        // [W] set to 1 when the output digest on the corresponding output port is ready and stable
    
    /* 
    Set to 1 when the digest has been accepted by the external environment so that the FSM can transition to the S0_IDLE state, 
    otherwise it remains in the S4_OUTPUT_DIGEST state. 
    */
    input digest_ready
);



    // State of the FSM
    localparam S0_IDLE = 3'b000;
    localparam S1_BYTE_WAIT = 3'b001;
    localparam S2_MESSAGE_ROUND = 3'b010;
    localparam S3_KEY_ROUND = 3'b011;
    localparam S4_OUTPUT_DIGEST = 3'b100;



    // Internal registers
    reg  [2:0]  current_state;          // Current state of the FSM
    reg  [2:0]  next_state;             // [W] Next state the FSM will transition to at the rising edge of the clock
    reg  [7:0]  hash_byte [0:7];        // The eight bytes of the internal hash state (H[i])
    reg  [7:0]  sbox_input [0:7];       // [W] Values before the S-box transformation
    wire [7:0]  sbox_output [0:7];      // [W] Values after the S-box transformation
    reg  [7:0]  current_message_byte;   // The current message byte being processed
    reg  [5:0]  round_counter;          // Used to count the number of rounds performed for the current message byte
    reg  [31:0] message_byte_counter;   // Used to count the number of message bytes processed so far
    reg         final_message_byte;     // Set to 1 when the current message byte being processed is the last byte of the message, otherwise set to 0
    reg  [63:0] key_reg;



    /* 
    Instantiate the inverse S-box module for each byte in order to get the corresponding value of the inverse S_box.
    sbox_output[i] are the 𝐻[𝑖] = 𝑆((𝐻[(𝑖 + 1) 𝑚𝑜𝑑 8] ⊕ 𝑀) ≫ 𝑖) values that have to be used in the next rounds 
    */
    inverse_S_box sbox0(sbox_input[0], sbox_output[0]);
    inverse_S_box sbox1(sbox_input[1], sbox_output[1]);
    inverse_S_box sbox2(sbox_input[2], sbox_output[2]);
    inverse_S_box sbox3(sbox_input[3], sbox_output[3]);
    inverse_S_box sbox4(sbox_input[4], sbox_output[4]);
    inverse_S_box sbox5(sbox_input[5], sbox_output[5]);
    inverse_S_box sbox6(sbox_input[6], sbox_output[6]);
    inverse_S_box sbox7(sbox_input[7], sbox_output[7]);
    
    
    
    always_comb 
    begin
        for (integer j = 0; j < 7; j = j + 1) 
        begin
            /* 
            ">> j" shifts the bits right and fills the empty positions on the left with zeros. 
            "<< (8 - j)" moves the bits that shifted out on the right back into those empty positions on 
            the left. The "|" (OR operation) combines the two shifted values to produce the result of the 
            circular right rotation. In the then branch it is used the key (K), while in the else branch 
            it is used the current message byte (M) 
            */
            if (current_state == S3_KEY_ROUND)
                sbox_input[j] =
                    ((hash_byte[j + 1] ^ key_reg[63 - (j * 8) -: 8]) >> j) |
                    ((hash_byte[j + 1] ^ key_reg[63 - (j * 8) -: 8]) << (8 - j));
            else
                sbox_input[j] =
                    ((hash_byte[j + 1] ^ current_message_byte) >> j) |
                    ((hash_byte[j + 1] ^ current_message_byte) << (8 - j));
        end
     
        /* 
        Special case for H[7]: (7 + 1) mod 8 wraps around to H[0]. The reference algorithm updates H[i] in ascending order, so H[0] has 
        already been updated when H[7] is calculated. In this implementation, the updated value of H[0] is represented by 
        sbox_output[0], while hash_byte[0] still holds the old value of H[0].
        */
        if (current_state == S3_KEY_ROUND)
            sbox_input[7] = ((sbox_output[0] ^ key_reg[7:0]) >> 7) |
                            ((sbox_output[0] ^ key_reg[7:0]) << 1);
        else
            sbox_input[7] = ((sbox_output[0] ^ current_message_byte) >> 7) |
                            ((sbox_output[0] ^ current_message_byte) << 1);
    end



    // Next state logic
    always_comb 
    begin
        next_state = current_state; // Used to avoid inferred latches
        case (current_state)
            S0_IDLE:
                if (message_byte_valid && ready_for_next_byte && message_byte_start)
                    next_state = S2_MESSAGE_ROUND;

            S1_BYTE_WAIT:
                /* 
                Update the next state to S2_MESSAGE_ROUND to let the computations be executed 
                only when the current input message byte is valid and the module is ready to accept it 
                */
                if (message_byte_valid && ready_for_next_byte)
                    next_state = S2_MESSAGE_ROUND;

            S2_MESSAGE_ROUND:
                /* 
                Update the next state to S3_KEY_ROUND if the current input message byte is the last one, so that the 
                computations involving the key can be performed; otherwise, update it to S1_BYTE_WAIT to wait for the 
                next message byte 
                */
                if (round_counter == 6'd35) 
                begin
                    if (final_message_byte)
                        next_state = S3_KEY_ROUND;
                    else
                        next_state = S1_BYTE_WAIT;
                end

            S3_KEY_ROUND:
                /* 
                Update the next state to S4_OUTPUT_DIGEST to output the final digest after the computations involving the key 
                have been performed
                */
                next_state = S4_OUTPUT_DIGEST;

            S4_OUTPUT_DIGEST:
                /* 
                Update the next state to S0_IDLE only when the external environment has accepted 
                the output digest, so that the module can be ready to accept a new input message 
                */
                if (digest_ready)
                    next_state = S0_IDLE;

            default:
                next_state = S0_IDLE;
        endcase
    end



    always_comb 
    begin
        // The digest is simply the concatenation of the hash bytes H[i]
        digest = {hash_byte[0], hash_byte[1], hash_byte[2], hash_byte[3],
                  hash_byte[4], hash_byte[5], hash_byte[6], hash_byte[7]};

        // The module is ready to accept a new input message byte only when it is in the S0_IDLE or S1_BYTE_WAIT states        
        ready_for_next_byte = (current_state == S0_IDLE) || (current_state == S1_BYTE_WAIT);
        
        // The output digest is valid only when the module is in the S4_OUTPUT_DIGEST state
        digest_valid = (current_state == S4_OUTPUT_DIGEST);
    end



    // Update only the FSM state register.
    always_ff @(posedge clk or negedge reset_n)
    begin
        if (!reset_n)
            current_state <= S0_IDLE;
        else
            current_state <= next_state;
    end



    // Update the datapath registers according to the current state.
    always_ff @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n) // if reset condition then initialization
            begin
                current_message_byte <= 8'h00;
                round_counter <= 6'd0;
                message_byte_counter <= 32'd0;
                final_message_byte <= 1'b0;
                key_reg <= 64'd0;
                hash_byte[0] <= 8'h09;
                hash_byte[1] <= 8'hc4;
                hash_byte[2] <= 8'hf3;
                hash_byte[3] <= 8'h22;
                hash_byte[4] <= 8'h71;
                hash_byte[5] <= 8'hd8;
                hash_byte[6] <= 8'h1e;
                hash_byte[7] <= 8'h53;
            end 
        else
            begin
                case (current_state)
                    S0_IDLE: 
                        begin
                            // If the first message byte is valid and the module is ready to accept it
                            if (message_byte_valid && ready_for_next_byte && message_byte_start) 
                            begin
                                //Initialize the hash_bytes with the initial values reported in the specification file
                                hash_byte[0] <= 8'h09;
                                hash_byte[1] <= 8'hc4;
                                hash_byte[2] <= 8'hf3;
                                hash_byte[3] <= 8'h22;
                                hash_byte[4] <= 8'h71;
                                hash_byte[5] <= 8'hd8;
                                hash_byte[6] <= 8'h1e;
                                hash_byte[7] <= 8'h53;
                                key_reg <= key;
                                current_message_byte <= message_byte;
                                final_message_byte <= message_byte_last;
                                message_byte_counter <= 32'd1;
                                round_counter <= 6'd0;
                            end
                        end

                    S1_BYTE_WAIT: 
                    /* 
                    Before starting the computations for the current message byte in 
                    state S2_MESSAGE_ROUND, make sure the current input byte is stable 
                    and the module accept it and then update some internal registers
                    */                
                        begin
                            if (message_byte_valid && ready_for_next_byte) 
                            begin
                                current_message_byte <= message_byte;
                                final_message_byte <= message_byte_last;
                                message_byte_counter <= message_byte_counter + 1'b1;
                                round_counter <= 6'd0;
                            end
                        end

                    S2_MESSAGE_ROUND: 
                        begin
                            for (integer i = 0; i < 8; i = i + 1)
                                hash_byte[i] <= sbox_output[i];

                            if (round_counter < 6'd35)
                                round_counter <= round_counter + 1'b1;
                            else begin end // Nothing
                        end

                    S3_KEY_ROUND: 
                        begin
                            for (integer i = 0; i < 8; i = i + 1) 
                                hash_byte[i] <= sbox_output[i];
                        end

                    S4_OUTPUT_DIGEST: 
                        begin
                            // The state transition is handled by next_state.
                        end

                    default: begin end
                endcase
            end
    end
endmodule