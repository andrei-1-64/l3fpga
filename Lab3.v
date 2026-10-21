module Lab3 (
    input  wire       clk,
    input  wire       key1,
    output reg  [7:0] seg,
    output wire [3:0] dig
);

// S1 counter on the 7-segment display: 0 -> 1 -> ... -> 9 -> 0
// seg[0..7] = a b c d e f g dp, all active-low (0 = segment ON)
// dig[0..3] = DIG1..DIG4, active-low (0 = digit ON)

localparam DEBOUNCE = 500_000;   // 10 ms at 50 MHz

reg [3:0]  n          = 0;       // digit shown (0..9)
reg [18:0] db_cnt     = 0;
reg        key_sync   = 1;
reg        key_stable = 1;
reg        key_prev   = 1;

// only DIG1 ON
assign dig = 4'b1110;

always @(posedge clk) begin
    key_sync <= key1;

    // debounce: accept a new key level only after it is stable for 10 ms
    if (key_sync != key_stable) begin
        if (db_cnt == DEBOUNCE - 1) begin
            key_stable <= key_sync;
            db_cnt     <= 0;
        end else begin
            db_cnt <= db_cnt + 1'b1;
        end
    end else begin
        db_cnt <= 0;
    end

    key_prev <= key_stable;

    // S1 is active-low: pressed = 0
    if (key_prev == 1 && key_stable == 0)
        n <= (n == 9) ? 4'd0 : n + 4'd1;
end

// active-low 7-segment patterns
always @* begin
    case (n)
        4'd0: seg = 8'hC0;
        4'd1: seg = 8'hF9;
        4'd2: seg = 8'hA4;
        4'd3: seg = 8'hB0;
        4'd4: seg = 8'h99;
        4'd5: seg = 8'h92;
        4'd6: seg = 8'h82;
        4'd7: seg = 8'hF8;
        4'd8: seg = 8'h80;
        4'd9: seg = 8'h90;
        default: seg = 8'hFF;    // all OFF
    endcase
end

endmodule
