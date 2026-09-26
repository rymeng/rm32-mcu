`timescale 1ns / 1ps

module tuart_baud_generator (
    input  wire        clk_i,
    input  wire        rst_n_i,
    input  wire  [5:0] osr_i,
    input  wire [15:0] div_i,
    output wire  [5:0] osr_calib_o,
    output wire [15:0] div_calib_o,
    output wire        sampling_tick_o,
    output wire        bit_tick_o
);

    /* Calibrate baud divisor */
    reg [15:0] sampling_limit;

    always @ (*) begin
        if (div_i < 16'b1) begin
            sampling_limit = 16'b1;
        end else begin
            sampling_limit = div_i;
        end
    end

    /* Output calibrated baud divisor */
    assign div_calib_o = sampling_limit;

    /* Calibrate oversampling rate */
    reg [5:0] bit_limit;

    always @ (*) begin
        if (osr_i < 6'b001000) begin
            bit_limit = 6'b001000;
        end else if (osr_i > 6'b100000) begin
            bit_limit = 6'b100000;
        end else begin
            bit_limit = osr_i;
        end
    end

    /* Output calibrated oversampling rate */
    assign osr_calib_o = bit_limit;

    reg [15:0] sampling_cnt;
    reg        sampling_tick;
    reg  [5:0] bit_cnt;
    reg        bit_tick;

    /* Generate sampling and bit ticks */
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            sampling_cnt <= 16'h0;
            sampling_tick  <= 1'b0;
            bit_cnt <= 6'h0;
            bit_tick <= 1'b0;
        end else begin
            if (sampling_cnt == sampling_limit - 16'h1) begin
                sampling_cnt <= 16'h0;
                sampling_tick <= 1'b1;
                if (bit_cnt == bit_limit - 6'h1) begin
                    bit_cnt <= 6'h0;
                    bit_tick <= 1'b1;
                end else begin
                    bit_cnt <= bit_cnt + 6'h1;
                    bit_tick <= 1'b0;
                end
            end else begin
                sampling_cnt <= sampling_cnt + 16'h1;
                sampling_tick <= 1'b0;
                bit_tick <= 1'b0;
            end
        end
    end

    /* Output sampling and bit ticks */
    assign sampling_tick_o = sampling_tick;
    assign bit_tick_o = bit_tick;

endmodule
