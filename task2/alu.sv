module alu (
    input  logic [15:0] A, B,
    input  alu_pkg::alu_fn_t FN,
    output logic [15:0] Y,
    output logic        Z, N
);
    import alu_pkg::*;  

    always_comb begin
        case (FN)
            alu_pkg::SUB_AB: Y = A - B;
            alu_pkg::SUB_BA: Y = B - A;
            alu_pkg::PASS_A: Y = A;
            alu_pkg::PASS_B: Y = B;
            default: Y = 16'h0000;
        endcase
    end

    // Flags
    assign Z = (Y == 16'h0000);  // Zero flag
    assign N = Y[15];            // Negative flag (MSB of Y)

endmodule