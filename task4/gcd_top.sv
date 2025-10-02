module gcd_struct (
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    input  logic [15:0] AB,
    output logic        ack,
    output logic [15:0] C
);

    // Control signals
    logic ABorALU;
    logic db_req;
    logic LDA, LDB;
    logic [1:0] FN;
    logic Z, N;
    logic A_is_zero, B_is_zero;   // NEW flags

    // Debounce req input
    debounce db (
        .clk     (clk),
        .reset   (reset),
        .sw      (req),
        .db_level(db_req),
        .db_tick ()
    );
    
    // Datapath
    datapath dp (
        .clk       (clk),
        .LDA       (LDA),
        .LDB       (LDB),
        .FN        (FN),
        .ABorALU   (ABorALU),
        .AB        (AB),
        .C         (C),
        .Z         (Z),
        .N         (N),
        .A_is_zero (A_is_zero),   // NEW connection
        .B_is_zero (B_is_zero)    // NEW connection
    );

    // FSM Controller
    fsm controller (
        .clk       (clk),
        .reset     (reset),
        .req       (db_req),
        .A_is_zero (A_is_zero),   // NEW connection
        .B_is_zero (B_is_zero),   // NEW connection
        .aluN_o    (N),           // still need negative flag
        .ack       (ack),
        .LDA       (LDA),
        .LDB       (LDB),
        .ABorALU   (ABorALU),
        .FN        (FN)
    );

endmodule
