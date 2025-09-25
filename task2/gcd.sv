module gcd (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);
    // Package containing ALU state enumeration
    import alu_pkg::*; 

    typedef enum logic [2 : 0] {IDLE, ACK_A, WAIT_B, CHECK_A_NOT_ZERO, CHECK_B_NOT_ZERO, SUB_A_B,
                                SUB_B_A, DONE} state_t;

    logic   [15:0]  regA, regB, next_regA, next_regB;
    state_t state, next_state;

    logic   [15:0]  aluA_i, aluB_i, aluY_o;
    logic aluZ_o, aluN_o;
    alu_fn_t aluFN_i;

    // Instantiate the ALU
    alu u_alu(  .A(aluA_i),
                .B(aluB_i), 
                .FN(aluFN_i),
                .Y(aluY_o),
                .Z(aluZ_o),
                .N(aluN_o));

    // Registers are always connected to ALU inputs
    assign aluA_i = regA;
    assign aluB_i = regB;
    assign C = regA;

    always_comb begin
        // Initial values
        next_state  = state;
        ack         = 1'b0;
        next_regA   = regA;
        next_regB   = regB;
        aluFN_i     = SUB_AB;

        // FSM
        case (state)
            IDLE: begin
            // If req sample AB to regA
                if(req) begin
                    next_regA = AB;
                    next_state = ACK_A;
                end
            end
            ACK_A: begin
            // Assert ACK for 1 cycle
                if(req) // Need this to wait for req to go low before proceeding to next state
                    ack = 1'b1;
                else
                    next_state = WAIT_B;
            end
            WAIT_B: begin
            // Wait for 2nd req to be asserted, then sample AB to regB
                if(req) begin 
                    next_regB = AB;
                    next_state =  CHECK_A_NOT_ZERO;
                end
            end
            // If A is zero put B in regA and go to DONE (If one input zero GCD is always the other value)
            CHECK_A_NOT_ZERO: begin
                aluFN_i = PASS_A;
                if(aluZ_o) begin
                    next_state = DONE;
                    next_regA = regB;
                end
                else begin
                    next_state = CHECK_B_NOT_ZERO;
                end
            end
            // If B is zero go to DONE
            CHECK_B_NOT_ZERO: begin
                aluFN_i = PASS_B;
                if(aluZ_o) begin
                    next_state = DONE;
                end
                else begin
                    next_state = SUB_A_B;
                end
            end
// TODO Skip this state because SUB_AB is default FN if alu
            SUB_A_B: begin
            // Manipulate ALU to get A-B
                aluFN_i = SUB_AB;

            // Determine next state based on ALU Flags
                if(aluN_o) begin
                    // If result negative change order of subtraction
                    next_state = SUB_B_A;
                end 
                else if (aluZ_o) begin
                    // If result zero means GCD has been found
                    next_state = DONE;
                end
                else begin
                    // Else record ALU output in regA and repeat A-B
                    next_regA = aluY_o;
                    next_state = SUB_A_B;
                end
            end
            SUB_B_A: begin
            // Manipulate ALU to get B-A
                aluFN_i = SUB_BA;

            // Determine next state based on ALU Flags
                if(aluN_o) begin
                    // If result negative change order of subtraction
                    next_state = SUB_A_B;
                end 
                else if(aluZ_o)begin
                    // If result zero means GCD has been found
                    next_state = DONE;
                end 
                else begin
                    // Else record ALU output in regA and repeat B-A
                    next_state  = SUB_B_A;
                    next_regB   = aluY_o;
                end
            end
            DONE: begin
                // Calculation done assert ack for one cycle
                if(req) // Need this to wait for req to go low before proceeding to next state
                    ack = 1'b1;
                else
                    next_state = IDLE;
            end
            default:
                // Silently handle if the FSM goes out of defined state-space
                // In a robust system this would send a signal to the above module and the system
                // would handle partial reset
                next_state = IDLE;
        endcase
    end

// Registers for A, B and the FSM state
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
            regA <= '0;
            regB <= '0;
        end else begin
            regA <= next_regA;
            regB <= next_regB;
            state <= next_state;
        end
    end

endmodule


