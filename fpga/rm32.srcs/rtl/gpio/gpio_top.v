`timescale 1ns / 1ps

module gpio_top (
/* AHB slave interface */
    input  wire         hclk_i,
    input  wire         hreset_n_i,
    input  wire         hsel_i,
    input  wire [31: 0] haddr_i,
    input  wire [31: 0] hwdata_i,
    input  wire         hwrite_i,
    input  wire  [1: 0] htrans_i,
    input  wire  [2: 0] hsize_i,
    input  wire         hready_i,
    input  wire  [2: 0] hburst_i,
    input  wire  [3: 0] hprot_i,
    input  wire         hmastlock_i,
    output reg  [31: 0] hrdata_o,
    output wire         hreadyout_o,
    output wire         hresp_o,
/* Alternate number */
    output reg   [3: 0] pin00_alternate_number_o,
    output reg   [3: 0] pin01_alternate_number_o,
    output reg   [3: 0] pin02_alternate_number_o,
    output reg   [3: 0] pin03_alternate_number_o,
    output reg   [3: 0] pin04_alternate_number_o,
    output reg   [3: 0] pin05_alternate_number_o,
    output reg   [3: 0] pin06_alternate_number_o,
    output reg   [3: 0] pin07_alternate_number_o,
    output reg   [3: 0] pin08_alternate_number_o,
    output reg   [3: 0] pin09_alternate_number_o,
    output reg   [3: 0] pin10_alternate_number_o,
    output reg   [3: 0] pin11_alternate_number_o,
    output reg   [3: 0] pin12_alternate_number_o,
    output reg   [3: 0] pin13_alternate_number_o,
    output reg   [3: 0] pin14_alternate_number_o,
    output reg   [3: 0] pin15_alternate_number_o,
/* AFIO signals */
    input  wire [15: 0] afio_enabled_i,
    input  wire [15: 0] afio_output_enabled_i,
    input  wire [15: 0] afio_output_data_i,
    output wire [15: 0] afio_input_data_o,
/* IO pins */
    inout  wire [15: 0] pin_io
);

    /* Sample read_xfer / write_xfer signal at any time */
    reg read_xfer;
    reg write_xfer;

    always @ (*) begin
        read_xfer  = hsel_i & (!hwrite_i) & htrans_i[1] & hready_i;
        write_xfer = hsel_i & hwrite_i & htrans_i[1] & hready_i;
    end

    /* Write logic: generate write_valid signal */
    reg write_valid;

    always @(posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            write_valid <= 1'b0;
        end else begin
            write_valid <= write_xfer;
        end
    end

    /* Write logic: sample address & mask signal in address phase */
    reg [7: 0] write_reg_index;
    reg [3: 0] write_valid_byte_mask;

    always @(posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            write_reg_index       <= 8'h00;
            write_valid_byte_mask <= 4'b0000;
        end else begin
            if (write_xfer) begin
                write_reg_index <= haddr_i[9: 2];
                case (hsize_i)
                    3'b000: begin
                        case(haddr_i[1: 0])
                            2'b00: begin
                                write_valid_byte_mask <= 4'b0001;
                            end

                            2'b01: begin
                                write_valid_byte_mask <= 4'b0010;
                            end

                            2'b10: begin
                                write_valid_byte_mask <= 4'b0100;
                            end

                            2'b11: begin
                                write_valid_byte_mask <= 4'b1000;
                            end
                        endcase
                    end

                    3'b001: begin
                        case (haddr_i[1])
                            1'b0: begin
                                write_valid_byte_mask <= 4'b0011;
                            end

                            1'b1: begin
                                write_valid_byte_mask <= 4'b1100;
                            end
                        endcase
                    end

                    3'b010: begin
                        write_valid_byte_mask <= 4'b1111;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    /* Registers */
    reg  [31: 0] padr;
    reg  [31: 0] afr1;
    reg  [31: 0] afr2;
    reg  [31: 0] gpmoder;
    reg  [15: 0] idr;
    reg  [31: 0] odr;

    /* Write logic: write data at the end of data phase */
    always @(posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            padr    <= 32'h0000_0000;
            afr1    <= 32'h0000_0000;
            afr2    <= 32'h0000_0000;
            gpmoder <= 32'h0000_0000;
            odr     <= 32'h0000_0000;
        end else begin
            if (write_valid) begin
                case (write_reg_index)
                    8'h00: begin
                        if (write_valid_byte_mask[0]) begin
                            padr[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            padr[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            padr[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            padr[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h01: begin
                        if (write_valid_byte_mask[0]) begin
                            afr1[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            afr1[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            afr1[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            afr1[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h02: begin
                        if (write_valid_byte_mask[0]) begin
                            afr2[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            afr2[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            afr2[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            afr2[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h03: begin
                        if (write_valid_byte_mask[0]) begin
                            gpmoder[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            gpmoder[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            gpmoder[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            gpmoder[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h11: begin
                        if (write_valid_byte_mask[0]) begin
                            odr[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            odr[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            odr[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            odr[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h12: begin
                        if (write_valid_byte_mask[0]) begin
                            odr[7: 0]   <= odr[7: 0] | hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            odr[15: 8]  <= odr[15: 8] | hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            odr[23: 16] <= odr[23: 16] | hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            odr[31: 24] <= odr[31: 24] | hwdata_i[31: 24];
                        end
                    end

                    8'h13: begin
                        if (write_valid_byte_mask[0]) begin
                            odr[7: 0]   <= odr[7: 0] & (~hwdata_i[7: 0]);
                        end

                        if (write_valid_byte_mask[1]) begin
                            odr[15: 8]  <= odr[15: 8] & (~hwdata_i[15: 8]);
                        end

                        if (write_valid_byte_mask[2]) begin
                            odr[23: 16] <= odr[23: 16] & (~hwdata_i[23: 16]);
                        end

                        if (write_valid_byte_mask[3]) begin
                            odr[31: 24] <= odr[31: 24] & (~hwdata_i[31: 24]);
                        end
                    end

                    8'h14: begin
                        if (write_valid_byte_mask[0]) begin
                            odr[7: 0]   <= odr[7: 0] ^ hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            odr[15: 8]  <= odr[15: 8] ^ hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            odr[23: 16] <= odr[23: 16] ^ hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            odr[31: 24] <= odr[31: 24] ^ hwdata_i[31: 24];
                        end
                    end
                endcase
            end
        end
    end

    /* Read logic: read data at the beginning of data phase */
    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            hrdata_o = 32'h0000_0000;
        end else begin
            if (read_xfer) begin
                case (haddr_i[9: 2])
                    8'h00: begin
                        hrdata_o = {16'b0, padr[15: 0]};
                    end

                    8'h01: begin
                        hrdata_o = afr1[31: 0];
                    end

                    8'h02: begin
                        hrdata_o = afr2[31: 0];
                    end

                    8'h03: begin
                        hrdata_o = {16'b0, gpmoder[15: 0]};
                    end

                    8'h10: begin
                        hrdata_o = {16'b0, idr[15: 0]};
                    end

                    8'h11: begin
                        hrdata_o = {16'b0, odr[15: 0]};
                    end

                    default: begin
                        hrdata_o = 32'h0000_0000;
                    end
                endcase
            end
        end
    end

    /* hreadyout: always 0 wait state */
    assign hreadyout_o = 1'b1;

    /* hresp: always no error response */
    assign hresp_o     = 2'b00;

    /* Output alternate number signal to IOMUX */
    always @ (*) begin
        pin00_alternate_number_o = afr1[3: 0];
        pin01_alternate_number_o = afr1[7: 4];
        pin02_alternate_number_o = afr1[11: 8];
        pin03_alternate_number_o = afr1[15: 12];
        pin04_alternate_number_o = afr1[19: 16];
        pin05_alternate_number_o = afr1[23: 20];
        pin06_alternate_number_o = afr1[27: 24];
        pin07_alternate_number_o = afr1[31: 28];
        pin08_alternate_number_o = afr2[3: 0];
        pin09_alternate_number_o = afr2[7: 4];
        pin10_alternate_number_o = afr2[11: 8];
        pin11_alternate_number_o = afr2[15: 12];
        pin12_alternate_number_o = afr2[19: 16];
        pin13_alternate_number_o = afr2[23: 20];
        pin14_alternate_number_o = afr2[27: 24];
        pin15_alternate_number_o = afr2[31: 28];
    end

    wire [15: 0] gpio_input_data;

    always @ (*) begin
        idr = gpio_input_data;
    end

    gpio_core gpio_core_inst (
        .clk_i                 (hclk_i),
        .rst_n_i               (hreset_n_i),
        .open_drain_enabled_i  (padr[15: 0]),
        .gpio_output_enabled_i (gpmoder[15: 0]),
        .gpio_output_data_i    (odr[15: 0]),
        .gpio_input_data_o     (gpio_input_data),
        .afio_enabled_i        (afio_enabled_i),
        .afio_output_enabled_i (afio_output_enabled_i),
        .afio_output_data_i    (afio_output_data_i),
        .afio_input_data_o     (afio_input_data_o),
        .pin_io                (pin_io)
    );

endmodule
