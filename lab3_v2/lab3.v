module lab3 (
    input  wire       clk,
    input  wire       key1,      // S1: +1
    input  wire       key2,      // S2: reset to 0000
    output reg  [7:0] seg,
    output reg  [3:0] dig
);

// 4-digit counter 0000..9999 on the 7-segment display
// seg[0..7] = a b c d e f g dp, all active-low (0 = segment ON)
// dig[0..3] = DIG1..DIG4, active-low (0 = digit ON)

wire press1, press2;

debounce db1 (.clk(clk), .key(key1), .press(press1));
debounce db2 (.clk(clk), .key(key2), .press(press2));

// BCD digits: d3 = thousands ... d0 = units
reg [3:0] d0 = 0, d1 = 0, d2 = 0, d3 = 0;

always @(posedge clk) begin
    if (press2) begin
        d0 <= 0; d1 <= 0; d2 <= 0; d3 <= 0;
    end else if (press1) begin
        if (d0 == 9) begin
            d0 <= 0;
            if (d1 == 9) begin
                d1 <= 0;
                if (d2 == 9) begin
                    d2 <= 0;
                    d3 <= (d3 == 9) ? 4'd0 : d3 + 4'd1;
                end else begin
                    d2 <= d2 + 4'd1;
                end
            end else begin
                d1 <= d1 + 4'd1;
            end
        end else begin
            d0 <= d0 + 4'd1;
        end
    end
end

// multiplexing: one digit ON at a time, switched every 2^15 clocks
// (~1.5 kHz), fast enough that the eye sees all 4 digits lit
reg  [16:0] scan = 0;
wire [1:0]  sel  = scan[16:15];

always @(posedge clk)
    scan <= scan + 1'b1;

reg [3:0] n;

always @* begin
    case (sel)
        2'd0:    begin dig = 4'b1110; n = d3; end   // DIG1 = thousands
        2'd1:    begin dig = 4'b1101; n = d2; end   // DIG2 = hundreds
        2'd2:    begin dig = 4'b1011; n = d1; end   // DIG3 = tens
        default: begin dig = 4'b0111; n = d0; end   // DIG4 = units
    endcase
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


// button debounce, gives a 1-clock pulse on each press
module debounce (
    input  wire clk,
    input  wire key,      // active-low: pressed = 0
    output wire press
);

localparam DEBOUNCE = 500_000;   // 10 ms at 50 MHz

reg [18:0] cnt        = 0;
reg        key_sync   = 1;
reg        key_stable = 1;
reg        key_prev   = 1;

always @(posedge clk) begin
    key_sync <= key;

    if (key_sync != key_stable) begin
        if (cnt == DEBOUNCE - 1) begin
            key_stable <= key_sync;
            cnt        <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end else begin
        cnt <= 0;
    end

    key_prev <= key_stable;
end

assign press = key_prev & ~key_stable;

endmodule
