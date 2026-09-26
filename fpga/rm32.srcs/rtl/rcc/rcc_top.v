`timescale 1ns / 1ps

module rcc_top (
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
/* AHB slave device 01 (Flash Main Bank Model Block 1) */
    output wire        hclk_slave01_o,
    output wire        hreset_n_slave01_o,
/* AHB slave device 02 (Flash Main Bank Model Block 2) */
    output wire        hclk_slave02_o,
    output wire        hreset_n_slave02_o,
/* AHB slave device 03 (Flash Main Bank Model Block 3) */
    output wire        hclk_slave03_o,
    output wire        hreset_n_slave03_o,
/* AHB slave device 04 (Flash Main Bank Model Block 4) */
    output wire        hclk_slave04_o,
    output wire        hreset_n_slave04_o,
/* AHB slave device 05 (Flash Option Byte Bank Model) */
    output wire        hclk_slave05_o,
    output wire        hreset_n_slave05_o,
/* AHB slave device 06 (IRAM Block 1) */
    output wire        hclk_slave06_o,
    output wire        hreset_n_slave06_o,
/* AHB slave device 07 (IRAM Block 2) */
    output wire        hclk_slave07_o,
    output wire        hreset_n_slave07_o,
/* AHB slave device 08 (IRAM Block 3) */
    output wire        hclk_slave08_o,
    output wire        hreset_n_slave08_o,
/* AHB slave device 09 (IRAM Block 4) */
    output wire        hclk_slave09_o,
    output wire        hreset_n_slave09_o,
/* AHB slave device 10 (GPIO A) */
    output wire        hclk_slave10_o,
    output wire        hreset_n_slave10_o,
/* AHB slave device 11 (GPIO B) */
    output wire        hclk_slave11_o,
    output wire        hreset_n_slave11_o,
/* AHB slave device 12 (UART 1) */
    output wire        hclk_slave12_o,
    output wire        hreset_n_slave12_o,
/* AHB slave device 13 (UART 2) */
    output wire        hclk_slave13_o,
    output wire        hreset_n_slave13_o,
/* AHB slave device 14 (TUART 1) */
    output wire        hclk_slave14_o,
    output wire        hreset_n_slave14_o
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
    reg [31:0] ahben1;
    reg [31:0] ahben2;
    reg [31:0] ahbrst1;
    reg [31:0] ahbrst2;

    /* Store the data at the end of data phase */
    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            ahben1 <= 32'h0000_0000;
            ahben2 <= 32'h0000_0000;
            ahbrst1 <= 32'h0000_0000;
            ahbrst2 <= 32'h0000_0000;
        end else begin
            if (write_valid) begin
                case (write_index)
                    8'h10: begin
                        if (write_mask[0]) begin
                            ahben1[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            ahben1[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            ahben1[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            ahben1[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h11: begin
                        if (write_mask[0]) begin
                            ahben2[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            ahben2[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            ahben2[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            ahben2[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h20: begin
                        if (write_mask[0]) begin
                            ahbrst1[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            ahbrst1[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            ahbrst1[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            ahbrst1[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h21: begin
                        if (write_mask[0]) begin
                            ahbrst2[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            ahbrst2[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            ahbrst2[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            ahbrst2[31:24] <= hwdata_i[31:24];
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
                8'h10: begin
                    hrdata_o <= {29'b0, ahben1[1:0]};
                end

                8'h11: begin
                    hrdata_o <= {28'b0, ahben2[2:0]};
                end

                8'h20: begin
                    hrdata_o <= {29'b0, ahbrst1[1:0]};
                end

                8'h21: begin
                    hrdata_o <= {28'b0, ahbrst2[2:0]};
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

    /* RCC sub-system */
    rcc_core rcc_core_subsystem (
        .hclk_master_i      (hclk_i),
        .hreset_n_master_i  (hreset_n_i),
        .hclk_slave01_o     (hclk_slave01_o),
        .hreset_n_slave01_o (hreset_n_slave01_o),
        .hclk_slave02_o     (hclk_slave02_o),
        .hreset_n_slave02_o (hreset_n_slave02_o),
        .hclk_slave03_o     (hclk_slave03_o),
        .hreset_n_slave03_o (hreset_n_slave03_o),
        .hclk_slave04_o     (hclk_slave04_o),
        .hreset_n_slave04_o (hreset_n_slave04_o),
        .hclk_slave05_o     (hclk_slave05_o),
        .hreset_n_slave05_o (hreset_n_slave05_o),
        .hclk_slave06_o     (hclk_slave06_o),
        .hreset_n_slave06_o (hreset_n_slave06_o),
        .hclk_slave07_o     (hclk_slave07_o),
        .hreset_n_slave07_o (hreset_n_slave07_o),
        .hclk_slave08_o     (hclk_slave08_o),
        .hreset_n_slave08_o (hreset_n_slave08_o),
        .hclk_slave09_o     (hclk_slave09_o),
        .hreset_n_slave09_o (hreset_n_slave09_o),
        .gpioa_enable_i     (ahben1[0]),
        .gpioa_rst_n_i      (~ahbrst1[0]),
        .hclk_slave10_o     (hclk_slave10_o),
        .hreset_n_slave10_o (hreset_n_slave10_o),
        .gpiob_enable_i     (ahben1[1]),
        .gpiob_rst_n_i      (~ahbrst1[1]),
        .hclk_slave11_o     (hclk_slave11_o),
        .hreset_n_slave11_o (hreset_n_slave11_o),
        .uart1_enable_i     (ahben2[0]),
        .uart1_rst_n_i      (~ahbrst2[0]),
        .hclk_slave12_o     (hclk_slave12_o),
        .hreset_n_slave12_o (hreset_n_slave12_o),
        .uart2_enable_i     (ahben2[1]),
        .uart2_rst_n_i      (~ahbrst2[1]),
        .hclk_slave13_o     (hclk_slave13_o),
        .hreset_n_slave13_o (hreset_n_slave13_o),
        .tuart1_enable_i    (ahben2[2]),
        .tuart1_rst_n_i     (~ahbrst2[2]),
        .hclk_slave14_o     (hclk_slave14_o),
        .hreset_n_slave14_o (hreset_n_slave14_o)
    );
endmodule
