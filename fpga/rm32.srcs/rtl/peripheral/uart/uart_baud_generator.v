`timescale 1ns / 1ps

module uart_baud_generator (
    input  wire        clock_i,
    input  wire        reset_n_i,
    input  wire  [5:0] oversampling_rate_i,
    input  wire [15:0] baud_divisor_i,
    output reg         sampling_tick_o,
    output reg         bit_tick_o
);

    reg  [15:0] sampling_count;
    reg   [5:0] bit_count;

    wire [15:0] sampling_period;
    wire  [5:0] bit_period;

    assign sampling_period = (baud_divisor_i < 16'b1) ? 16'b1 : baud_divisor_i;
    assign bit_period = (oversampling_rate_i < 6'b1000) ? 6'b1000 : ((oversampling_rate_i > 6'b100000) ? 6'b100000 : oversampling_rate_i);

    always @(posedge clock_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            sampling_count  <= 16'h0;
            sampling_tick_o <= 1'b0;
            bit_count       <= 6'h0;
            bit_tick_o      <= 1'b0;
        end else begin
            /* Default */
            sampling_tick_o <= 1'b0;
            bit_tick_o      <= 1'b0;

            /* Generate sampling tick & bit tick (baud tick) */
            if (sampling_count == sampling_period - 16'h1) begin
                sampling_count  <= 16'h0;
                sampling_tick_o <= 1'b1;
                if (bit_count == bit_period - 6'h1) begin
                    bit_count  <= 6'h0;
                    bit_tick_o <= 1'b1;
                end else begin
                    bit_count  <= bit_count + 6'h1;
                end
            end else begin
                sampling_count  <= sampling_count + 16'h1;
            end
        end
    end

endmodule
