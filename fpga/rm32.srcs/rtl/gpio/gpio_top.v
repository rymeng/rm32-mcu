`timescale 1ns / 1ps

module gpio_top (
/* AHB slave device interface */
    input  wire        hclk_i,
    input  wire        hreset_n_i,
    input  wire        hsel_i,
    input  wire [31:0] haddr_i,
    input  wire [31:0] hwdata_i,
    input  wire        hwrite_i,
    input  wire  [1:0] htrans_i,
    input  wire  [2:0] hsize_i,
    input  wire        hready_i,
    input  wire  [2:0] hburst_i,
    input  wire  [3:0] hprot_i,
    input  wire        hmastlock_i,
    output reg  [31:0] hrdata_o,
    output reg         hreadyout_o,
    output reg         hresp_o,
/* Alternate number */
    output wire  [3:0] pin00_alternate_number_o,
    output wire  [3:0] pin01_alternate_number_o,
    output wire  [3:0] pin02_alternate_number_o,
    output wire  [3:0] pin03_alternate_number_o,
    output wire  [3:0] pin04_alternate_number_o,
    output wire  [3:0] pin05_alternate_number_o,
    output wire  [3:0] pin06_alternate_number_o,
    output wire  [3:0] pin07_alternate_number_o,
    output wire  [3:0] pin08_alternate_number_o,
    output wire  [3:0] pin09_alternate_number_o,
    output wire  [3:0] pin10_alternate_number_o,
    output wire  [3:0] pin11_alternate_number_o,
    output wire  [3:0] pin12_alternate_number_o,
    output wire  [3:0] pin13_alternate_number_o,
    output wire  [3:0] pin14_alternate_number_o,
    output wire  [3:0] pin15_alternate_number_o,
/* AFIO signals */
    input  wire [15:0] afio_enabled_i,
    input  wire [15:0] afio_output_enabled_i,
    input  wire [15:0] afio_output_data_i,
    output wire [15:0] afio_input_data_o,
/* IO pins */
    inout  wire [15:0] pin_io
);
    /* Generate address phase valid flag */
    wire addr_valid;

    assign addr_valid = hsel_i & htrans_i[1] & hready_i;

    /* Generate transfer size valid flag */
    wire size_valid;

    assign size_valid = ~hsize_i[2];

    /* Generate transfer address valid (aligned) flag */
    wire addr_aligned;

    assign addr_aligned =
        (hsize_i == 3'b000) ? 1'b1 :
        (hsize_i == 3'b001) ? ~(haddr_i[0]) :
        (hsize_i == 3'b010) ? ~(|haddr_i[1:0]) : 1'b0;

    /* Generate read address phase occurrence flag */
    wire read_addr_phase;

    assign read_addr_phase =
        hsel_i & htrans_i[1] & size_valid & addr_aligned & ~hwrite_i;

    /* Generate transfer valid / error flags */
    wire xfer_valid;
    wire xfer_error;

    assign xfer_valid = addr_valid & size_valid & addr_aligned;
    assign xfer_error = addr_valid & ~xfer_valid;

    /* Generate read / write transfer flags */
    wire read_xfer_valid;
    wire write_xfer_valid;

    assign read_xfer_valid = xfer_valid & ~hwrite_i;
    assign write_xfer_valid = xfer_valid & hwrite_i;

    /* Generate byte lanes mask */
    reg [3:0] byte_mask;

    always @ (*) begin
        case (hsize_i)
            3'b000: begin
                byte_mask = 4'b0001 << haddr_i[1:0];
            end

            3'b001: begin
                byte_mask = 4'b0011 << haddr_i[1:0];
            end

            3'b010: begin
                byte_mask = 4'b1111;
            end

            default: begin
                byte_mask = 4'b0000;
            end
        endcase
    end

    /* Latch the index and byte mask at the end of address phase */
    reg       write_valid;
    reg [3:0] write_mask;
    reg [7:0] write_index;

    always @ (posedge hclk_i) begin
        write_valid <= write_xfer_valid;

        if (write_xfer_valid) begin
            write_mask <= byte_mask;
            write_index <= haddr_i[9:2];
        end
    end

    /* Generate read-write collision flag */
    wire read_write_xfer_collision;

    assign read_write_xfer_collision =
        read_addr_phase & write_valid & (write_index == haddr_i[9:2]);

    /* Registers */
    reg [31:0] padr;
    reg [31:0] afr1;
    reg [31:0] afr2;
    reg [31:0] gpmoder;
    reg [15:0] idr;
    reg [31:0] odr;

    /* Store the data at the end of data phase */
    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            padr <= 32'h0000_0000;
            afr1 <= 32'h0000_0000;
            afr2 <= 32'h0000_0000;
            gpmoder <= 32'h0000_0000;
            odr <= 32'h0000_0000;
        end else begin
            if (write_valid) begin
                case (write_index)
                    8'h00: begin
                        if (write_mask[0]) begin
                            padr[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            padr[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            padr[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            padr[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h01: begin
                        if (write_mask[0]) begin
                            afr1[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            afr1[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            afr1[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            afr1[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h02: begin
                        if (write_mask[0]) begin
                            afr2[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            afr2[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            afr2[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            afr2[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h03: begin
                        if (write_mask[0]) begin
                            gpmoder[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            gpmoder[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            gpmoder[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            gpmoder[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h11: begin
                        if (write_mask[0]) begin
                            odr[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            odr[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            odr[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            odr[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h12: begin
                        if (write_mask[0]) begin
                            odr[7:0] <= odr[7:0] | hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            odr[15:8] <= odr[15:8] | hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            odr[23:16] <= odr[23:16] | hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            odr[31:24] <= odr[31:24] | hwdata_i[31:24];
                        end
                    end

                    8'h13: begin
                        if (write_mask[0]) begin
                            odr[7:0] <= odr[7:0] & (~hwdata_i[7:0]);
                        end
                        if (write_mask[1]) begin
                            odr[15:8] <= odr[15:8] & (~hwdata_i[15:8]);
                        end
                        if (write_mask[2]) begin
                            odr[23:16] <= odr[23:16] & (~hwdata_i[23:16]);
                        end
                        if (write_mask[3]) begin
                            odr[31:24] <= odr[31:24] & (~hwdata_i[31:24]);
                        end
                    end

                    8'h14: begin
                        if (write_mask[0]) begin
                            odr[7:0] <= odr[7:0] ^ hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            odr[15:8] <= odr[15:8] ^ hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            odr[23:16] <= odr[23:16] ^ hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            odr[31:24] <= odr[31:24] ^ hwdata_i[31:24];
                        end
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    /* Output data at the end of address phase */
    always @ (posedge hclk_i) begin
        if (read_xfer_valid) begin
            case (haddr_i[9:2])
                8'h00: begin
                    hrdata_o <= {16'b0, padr[15:0]};
                end

                8'h01: begin
                    hrdata_o <= afr1[31:0];
                end

                8'h02: begin
                    hrdata_o <= afr2[31:0];
                end

                8'h03: begin
                    hrdata_o <= {16'b0, gpmoder[15:0]};
                end

                8'h10: begin
                    hrdata_o <= {16'b0, idr[15:0]};
                end

                8'h11: begin
                    hrdata_o <= {16'b0, odr[15:0]};
                end

                default: begin
                    hrdata_o <= 32'h0000_0000;
                end
            endcase
        end
    end

    /* Control AHB slave response state */
    localparam RESP_OKAY = 3'b001;
    localparam RESP_ERR1 = 3'b010;
    localparam RESP_ERR2 = 3'b100;

    reg [2:0] resp_state;

    always @ (posedge hclk_i) begin
        case (resp_state)
            RESP_OKAY: begin
                if (xfer_error) begin
                    resp_state <= RESP_ERR1;
                end
            end

            RESP_ERR1: begin
                resp_state <= RESP_ERR2;
            end

            RESP_ERR2: begin
                if (xfer_error) begin
                    resp_state <= RESP_ERR1;
                end else begin
                    resp_state <= RESP_OKAY;
                end
            end

            default: begin
                resp_state <= RESP_OKAY;
            end
        endcase
    end

    /* Output HRESP and HREADYOUT signals */
    always @ (*) begin
        case (resp_state)
            RESP_ERR1: begin
                hresp_o = 1'b1;
                hreadyout_o = 1'b0;
            end

            RESP_ERR2: begin
                hresp_o = 1'b1;
                hreadyout_o = 1'b1;
            end

            default: begin
                hresp_o = 1'b0;
                hreadyout_o = ~read_write_xfer_collision;
            end
        endcase
    end

    /* Output alternate number signal to IOMUX */
    assign pin00_alternate_number_o = afr1[3:0];
    assign pin01_alternate_number_o = afr1[7:4];
    assign pin02_alternate_number_o = afr1[11:8];
    assign pin03_alternate_number_o = afr1[15:12];
    assign pin04_alternate_number_o = afr1[19:16];
    assign pin05_alternate_number_o = afr1[23:20];
    assign pin06_alternate_number_o = afr1[27:24];
    assign pin07_alternate_number_o = afr1[31:28];
    assign pin08_alternate_number_o = afr2[3:0];
    assign pin09_alternate_number_o = afr2[7:4];
    assign pin10_alternate_number_o = afr2[11:8];
    assign pin11_alternate_number_o = afr2[15:12];
    assign pin12_alternate_number_o = afr2[19:16];
    assign pin13_alternate_number_o = afr2[23:20];
    assign pin14_alternate_number_o = afr2[27:24];
    assign pin15_alternate_number_o = afr2[31:28];

    /* GPIO sub-system */
    wire [15:0] gpio_input_data;

    always @ (*) begin
        idr = gpio_input_data;
    end

    gpio_core gpio_core_subsystem (
        .clk_i                 (hclk_i),
        .rst_n_i               (hreset_n_i),
        .open_drain_enabled_i  (padr[15:0]),
        .gpio_output_enabled_i (gpmoder[15:0]),
        .gpio_output_data_i    (odr[15:0]),
        .gpio_input_data_o     (gpio_input_data),
        .afio_enabled_i        (afio_enabled_i),
        .afio_output_enabled_i (afio_output_enabled_i),
        .afio_output_data_i    (afio_output_data_i),
        .afio_input_data_o     (afio_input_data_o),
        .pin_io                (pin_io)
    );
endmodule
