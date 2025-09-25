package alu_pkg;
    typedef enum logic [1:0] {
        SUB_AB = 2'b00,   // A - B
        SUB_BA = 1'b01,   // B - A
        PASS_A = 2'b10,
        PASS_B = 2'b11
    } alu_fn_t;
endpackage
