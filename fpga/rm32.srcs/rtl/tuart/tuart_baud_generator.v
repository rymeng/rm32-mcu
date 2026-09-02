`timescale 1ns / 1ps

module tuart_baud_generator (
    input  wire         clk_i,
    input  wire         rst_n_i,
    input  wire  [5: 0] oversampling_rate_i,
    input  wire [15: 0] baud_divisor_i,
    output wire  [5: 0] oversampling_rate_calib_o,
    output wire [15: 0] baud_divisor_calib_o,
    output reg          sampling_tick_o,
    output reg          bit_tick_o
);

    reg [15: 0] sampling_limit;

    always @ (*) begin
        if (baud_divisor_i < 16'b1) begin
            sampling_limit = 16'b1;
        end else begin
            sampling_limit = baud_divisor_i;
        end
    end

    assign baud_divisor_calib_o = sampling_limit;

    reg [5: 0] bit_limit;

    always @ (*) begin
        if (oversampling_rate_i < 6'b001000) begin
            bit_limit = 6'b001000;
        end else if (oversampling_rate_i > 6'b100000) begin
            bit_limit = 6'b100000;
        end else begin
            bit_limit = oversampling_rate_i;
        end
    end

    assign oversampling_rate_calib_o = bit_limit;

    reg [15: 0] sampling_count;
    reg  [5: 0] bit_count;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            sampling_count  <= 16'h0;
            bit_count       <= 6'h0;
            sampling_tick_o <= 1'b0;
            bit_tick_o      <= 1'b0;
        end else begin
            if (sampling_count == sampling_limit - 16'h1) begin
                sampling_count  <= 16'h0;
                sampling_tick_o <= 1'b1;
                if (bit_count == bit_limit - 6'h1) begin
                    bit_count   <= 6'h0;
                    bit_tick_o  <= 1'b1;
                end else begin
                    bit_count   <= bit_count + 6'h1;
                    bit_tick_o  <= 1'b0;
                end
            end else begin
                sampling_count  <= sampling_count + 16'h1;
                sampling_tick_o <= 1'b0;
                bit_tick_o      <= 1'b0;
            end
        end
    end

endmodule
