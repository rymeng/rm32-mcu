`timescale 1ns / 1ps

module gpio_core (
    input  wire         clk_i,
    input  wire         rst_n_i,
/* Pad signal */
    input  wire [15: 0] open_drain_enabled_i,
/* GPIO signal */
    input  wire [15: 0] gpio_output_enabled_i,
    input  wire [15: 0] gpio_output_data_i,
    output wire [15: 0] gpio_input_data_o,
/* AFIO signal */
    input  wire [15: 0] afio_enabled_i,
    input  wire [15: 0] afio_output_enabled_i,
    input  wire [15: 0] afio_output_data_i,
    output wire [15: 0] afio_input_data_o,
/* Pin */
    inout  wire [15: 0] pin_io
);

    reg [15: 0] io_output_enabled;
    reg [15: 0] io_output_data;
    reg [15: 0] io_input_data_sync1;
    reg [15: 0] io_input_data_sync2;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            /* Pad logic */
            always @ (*) begin
                if (afio_enabled_i[i]) begin
                    io_output_enabled[i] =
                        afio_output_enabled_i[i] | open_drain_enabled_i[i];
                    io_output_data[i]    = afio_output_data_i[i];
                end else begin
                    io_output_enabled[i] =
                        gpio_output_enabled_i[i] | open_drain_enabled_i[i];
                    io_output_data[i]    = gpio_output_data_i[i];
                end
            end

            assign pin_io[i] = io_output_enabled[i] ? io_output_data[i] : 1'bz;

            /* Input sampling logic */
            always @ (posedge clk_i or negedge rst_n_i) begin
                if (!rst_n_i) begin
                    io_input_data_sync1[i] <= 1'b0;
                    io_input_data_sync2[i] <= 1'b0;
                end else begin
                    io_input_data_sync1[i] <= pin_io[i];
                    io_input_data_sync2[i] <= io_input_data_sync1[i];
                end
            end

            assign gpio_input_data_o[i] = io_input_data_sync2[i];
            assign afio_input_data_o[i] = io_input_data_sync2[i];
        end
    endgenerate

endmodule
