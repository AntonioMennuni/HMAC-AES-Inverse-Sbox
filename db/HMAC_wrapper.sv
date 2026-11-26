module HMAC_wrapper (
    input             clk,
    input             reset_n,
    input      [7:0]  message_byte,
    input             message_byte_valid,
    input             message_byte_start,
    input             message_byte_last,
    output reg        ready_for_next_byte,
    input      [63:0] key,
    output reg [63:0] digest,
    output reg        digest_valid,
    input             digest_ready
);

/*  
On each rising edge of the clock, the wrapper samples its input signals into internal registers whose names end in _q. The registered values are
then passed to the HMAC module. The _q suffix is commonly used because Q denotes a register's output in a register diagram.
*/
    reg [7:0]  message_byte_q;
    reg        message_byte_valid_q;
    reg        message_byte_start_q;
    reg        message_byte_last_q;
    reg [63:0] key_q;
    reg        digest_ready_q;

/*  
The hmac_ wires carry the HMAC module's output signals to the wrapper's output registers. Those registers sample the signals on each rising edge,
adding one clock cycle of latency relative to the HMAC module's outputs.
*/
    wire        hmac_ready_for_next_byte;
    wire [63:0] hmac_digest;
    wire        hmac_digest_valid;

// Instantiate HMAC with the registered wrapper inputs and connect its outputs to the internal wires. 

    HMAC u_hmac (
        clk,
        reset_n,
        message_byte_q,
        message_byte_valid_q,
        message_byte_start_q,
        message_byte_last_q,
        hmac_ready_for_next_byte,
        key_q,
        hmac_digest,
        hmac_digest_valid,
        digest_ready_q
    );

    // Register all wrapper inputs
    always_ff @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n) 
        begin
            message_byte_q <= 8'h00;
            message_byte_valid_q <= 1'b0;
            message_byte_start_q <= 1'b0;
            message_byte_last_q <= 1'b0;
            key_q <= 64'h0;
            digest_ready_q <= 1'b0;
        end 
        else 
        begin
            message_byte_q <= message_byte;
            message_byte_valid_q <= message_byte_valid;
            message_byte_start_q <= message_byte_start;
            message_byte_last_q <= message_byte_last;
            key_q <= key;
            digest_ready_q <= digest_ready;
        end
    end

    // Register the HMAC outputs into the wrapper's output registers
    always_ff @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n) 
        begin
            ready_for_next_byte <= 1'b0;
            digest <= 64'h0;
            digest_valid <= 1'b0;
        end 
        else 
        begin
            ready_for_next_byte <= hmac_ready_for_next_byte;
            digest <= hmac_digest;
            digest_valid <= hmac_digest_valid;
        end
    end
endmodule