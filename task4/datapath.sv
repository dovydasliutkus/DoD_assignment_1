module datapath (
    input  logic        clk,
    input  logic        LDA, LDB,        // load enables
    input  logic [1:0]  FN,              // ALU function select
    input  logic        ABorALU,         // mux selects
    input  logic [15:0] AB,              // external input
    output logic [15:0] C,               // GCD result
    output logic        Z, N,            // ALU flags
    output logic        A_is_zero,       // NEW
    output logic        B_is_zero        // NEW
);

    // Internal wires
    logic [15:0] A_out, B_out;
    logic [15:0] alu_Y;
    logic [15:0] mux_out;

    // Registers
    c_reg regA (.clk(clk), .en(LDA), .data_in(mux_out), .data_out(A_out));
    c_reg regB (.clk(clk), .en(LDB), .data_in(mux_out), .data_out(B_out));

    // Input mux
    c_mux mux (.s(ABorALU), .data_in1(AB), .data_in2(alu_Y), .data_out(mux_out));

    // ALU
    c_alu alu (.A(A_out), .B(B_out), .fn(FN), .C(alu_Y), .Z(Z), .N(N));

    // Output result always comes from A (holds GCD at end)
    c_buf bufo (.data_in(A_out), .data_out(C));
    // Registered zero flags
    always_ff @(posedge clk) begin
        A_is_zero <= (A_out == 16'd0);
        B_is_zero <= (B_out == 16'd0);
    end

endmodule
