module fsm (
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    input  logic        Z,   // NEW flag from datapath
    input  logic        N,      // still need negative flag for subtraction
    output logic        ack,
    output logic        LDA, LDB,
    output logic        ABorALU,
    output logic [1:0]  FN
);

    typedef enum logic [2:0] {
        IDLE,
        ACK_A,
        WAIT_B,
        CHECK_A_NOT_ZERO,
        CHECK_B_NOT_ZERO,
        SUB_A_B,
        SUB_B_A,
        DONE
    } state_t;

    state_t state, next_state;

    // Combinational control
    always_comb begin
        // defaults
        next_state = state;
        ack   = 0;
        LDA   = 0;
        LDB   = 0;
        ABorALU = 0;
        FN    = 2'b10; // pass A by default

        case (state)

            IDLE: begin
                if (req) begin
                    LDA = 1;        // Enable register
                    ABorALU = 1;    // Mux to AB
                    next_state = ACK_A;
                end
            end

            ACK_A: begin
                ack = 1;
                if (!req) next_state = WAIT_B;
            end

            WAIT_B: begin
                if (req) begin
                    LDB = 1;        // Enable B register
                    ABorALU = 1;    // Mux to AB
                    next_state = SUB_A_B;
                end
            end
            SUB_A_B: begin
                FN  = 2'b00; // A = A - B
                if (Z) begin
                    next_state = DONE;
                end else if (N) begin
                    next_state = SUB_B_A;
                end else begin
                    LDA = 1;
                    next_state = SUB_A_B;
                end
            end

            SUB_B_A: begin
                FN  = 2'b01; // B = B - A
                if (N) begin
                    next_state = SUB_A_B;
                end else if (Z) begin
                    next_state = DONE;
                end else begin
                    LDB = 1;
                    next_state = SUB_B_A;
                end
            end

            DONE: begin
                if(req) // Need this to wait for req to go low before proceeding to next state
                    ack = 1'b1;
                else
                next_state = IDLE;  // one-cycle pulse ack      
            end

            default: next_state = IDLE;
        endcase
    end

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            state <= IDLE;
        else       
            state <= next_state;
    end

endmodule
