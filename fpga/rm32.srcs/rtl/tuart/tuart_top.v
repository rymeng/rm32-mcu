`timescale 1ns / 1ps

module tuart_top (
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
/* AFIO signals */
    input  wire        rxd_i,
    output wire        txd_o,
    output wire        swap_o
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
    reg [31:0] brr;
    reg [31:0] cr1;
    reg [31:0] cr2;
    reg [31:0] nicr1;
    reg [31:0] nicr2;
    reg [31:0] nicr3;
    reg [31:0] nicr4;
    reg [31:0] nicr5;
    reg [31:0] nicr6;
    reg [31:0] nicr7;
    reg [31:0] nicr8;
    reg [31:0] nicr9;
    reg [31:0] nicr10;
    reg [31:0] nicr11;
    reg [31:0] nicr12;
    reg [31:0] tdr;
    reg [31:0] sr1;

    /* Store the data at the end of data phase */
    /* Generate TDR register write strobe at the end of data phase */
    reg tdr_write_strobe;

    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            brr <= 32'h0008_0001;
            cr1 <= 32'h0000_0007;
            cr2 <= 32'h0000_0000;
            nicr1 <= 32'h0000_0000;
            nicr2 <= 32'h0000_0000;
            nicr3 <= 32'h0000_0000;
            nicr4 <= 32'h0000_0000;
            nicr5 <= 32'h0000_0000;
            nicr6 <= 32'h0000_0000;
            nicr7 <= 32'h0000_0000;
            nicr8 <= 32'h0000_0000;
            nicr9 <= 32'h0000_0000;
            nicr10 <= 32'h0000_0000;
            nicr11 <= 32'h0000_0000;
            nicr12 <= 32'h0000_0000;
            tdr <= 32'h0000_0000;
            tdr_write_strobe <= 1'b0;
        end else begin
            tdr_write_strobe <= 1'b0;
            if (write_valid) begin
                case (write_index)
                    8'h00: begin
                        if (cr2[1:0] == 2'b00) begin
                            if (write_mask[0]) begin
                                brr[7:0] <= hwdata_i[7:0];
                            end
                            if (write_mask[1]) begin
                                brr[15:8] <= hwdata_i[15:8];
                            end
                            if (write_mask[2]) begin
                                brr[23:16] <= hwdata_i[23:16];
                            end
                            if (write_mask[3]) begin
                                brr[31:24] <= hwdata_i[31:24];
                            end
                        end else begin
                            brr <= brr;
                        end
                    end

                    8'h01: begin
                        if (cr2[1:0] == 2'b00) begin
                            if (write_mask[0]) begin
                                cr1[7:0] <= hwdata_i[7:0];
                            end
                            if (write_mask[1]) begin
                                cr1[15:8] <= hwdata_i[15:8];
                            end
                            if (write_mask[2]) begin
                                cr1[23:16] <= hwdata_i[23:16];
                            end
                            if (write_mask[3]) begin
                                cr1[31:24] <= hwdata_i[31:24];
                            end
                        end
                    end

                    8'h02: begin
                        if (write_mask[0]) begin
                            cr2[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            cr2[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            cr2[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            cr2[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h08: begin
                        if (write_mask[0]) begin
                            nicr1[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr1[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr1[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr1[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h09: begin
                        if (write_mask[0]) begin
                            nicr2[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr2[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr2[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr2[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0A: begin
                        if (write_mask[0]) begin
                            nicr3[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr3[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr3[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr3[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0B: begin
                        if (write_mask[0]) begin
                            nicr4[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr4[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr4[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr4[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0C: begin
                        if (write_mask[0]) begin
                            nicr5[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr5[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr5[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr5[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0D: begin
                        if (write_mask[0]) begin
                            nicr6[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr6[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr6[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr6[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0E: begin
                        if (write_mask[0]) begin
                            nicr7[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr7[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr7[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr7[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h0F: begin
                        if (write_mask[0]) begin
                            nicr8[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr8[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr8[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr8[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h10: begin
                        if (write_mask[0]) begin
                            nicr9[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr9[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr9[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr9[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h11: begin
                        if (write_mask[0]) begin
                            nicr10[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr10[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr10[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr10[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h12: begin
                        if (write_mask[0]) begin
                            nicr11[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr11[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr11[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr11[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h13: begin
                        if (write_mask[0]) begin
                            nicr12[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            nicr12[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            nicr12[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            nicr12[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h18: begin
                        if (write_mask[0]) begin
                            tdr[7:0] <= hwdata_i[7:0];
                        end
                        if (write_mask[1]) begin
                            tdr[15:8] <= hwdata_i[15:8];
                        end
                        if (write_mask[2]) begin
                            tdr[23:16] <= hwdata_i[23:16];
                        end
                        if (write_mask[3]) begin
                            tdr[31:24] <= hwdata_i[31:24];
                        end
                        tdr_write_strobe <= 1'b1;
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
                    hrdata_o <= {10'b0, brr[21:0]};
                end

                8'h01: begin
                    hrdata_o <= {16'b0, cr1[5:0]};
                end

                8'h02: begin
                    hrdata_o <= {30'b0, cr2[1:0]};
                end

                8'h08: begin
                    hrdata_o <= nicr1;
                end

                8'h09: begin
                    hrdata_o <= nicr2;
                end

                8'h0A: begin
                    hrdata_o <= nicr3;
                end

                8'h0B: begin
                    hrdata_o <= nicr4;
                end

                8'h0C: begin
                    hrdata_o <= nicr5;
                end

                8'h0D: begin
                    hrdata_o <= nicr6;
                end

                8'h0E: begin
                    hrdata_o <= nicr7;
                end

                8'h0F: begin
                    hrdata_o <= nicr8;
                end

                8'h10: begin
                    hrdata_o <= nicr9;
                end

                8'h11: begin
                    hrdata_o <= nicr10;
                end

                8'h12: begin
                    hrdata_o <= nicr11;
                end

                8'h13: begin
                    hrdata_o <= nicr12;
                end

                8'h18: begin
                    hrdata_o <= tdr;
                end

                8'h20: begin
                    hrdata_o <= sr1;
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

    /* TUART TX sub-system */
    wire [255:0] nicr9_2;
    wire  [63:0] nicr12_11;
    wire         txrdy;
    wire         txc;

    assign nicr9_2 = {nicr9, nicr8, nicr7, nicr6, nicr5, nicr4, nicr3, nicr2};
    assign nicr12_11 = {nicr12, nicr11};

    tuart_core_tx tuart_core_tx_subsystem (
        .clk_i                     (hclk_i),
        .rst_n_i                   (hreset_n_i),
        .data_write_strobe_i       (tdr_write_strobe),
        .osr_i                     (brr[21:16]),
        .div_i                     (brr[15:0]),
        .data_bits_i               (cr1[2:0]),
        .parity_en_i               (cr1[3]),
        .parity_type_i             (cr1[4]),
        .stop_bits_i               (cr1[5]),
        .tx_en_i                   (cr2[0]),
        .start_bit_noise_idx_i     (nicr1),
        .data_bit_noise_idx_i      (nicr9_2),
        .parity_code_noise_idx_i   (nicr10),
        .stop_bit_noise_idx_i      (nicr12_11),
        .noise_injection_en_i      (tdr[11]),
        .parity_err_injection_en_i (tdr[8]),
        .frame_err_injection_en_i  ({tdr[10], tdr[9]}),
        .data_i                    (tdr[7:0]),
        .data_reg_empty_o          (txrdy),
        .xfer_complete_o           (txc),
        .txd_o                     (txd_o)
    );

    always @ (*) begin
        sr1[31:2] = 30'b0;
        sr1[1] = txc;
        sr1[0] = txrdy;
    end

    /* IO controller sub-system */
    assign swap_o = 1'b0;
endmodule
