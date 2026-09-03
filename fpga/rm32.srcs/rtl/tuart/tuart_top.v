`timescale 1ns / 1ps

module tuart_top (
/* AHB Slave Interface */
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
/* IO port */
    input  wire         rxd_i,
    output wire         txd_o,
    output wire         swap_o,
    output wire         txd_output_enabled_o,
    output wire         rxd_output_enabled_o
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

    /* Register */
    reg [31: 0] brr;
    reg [31: 0] cr1;
    reg [31: 0] cr2;
    reg [31: 0] nicr1;
    reg [31: 0] nicr2;
    reg [31: 0] nicr3;
    reg [31: 0] nicr4;
    reg [31: 0] nicr5;
    reg [31: 0] nicr6;
    reg [31: 0] nicr7;
    reg [31: 0] nicr8;
    reg [31: 0] nicr9;
    reg [31: 0] nicr10;
    reg [31: 0] nicr11;
    reg [31: 0] nicr12;
    reg [31: 0] tdr;
    reg [31: 0] sr1;

    always @ (*) begin
        sr1[31: 1] = 31'b0;
    end

    /* Write TDR signal */
    reg tdr_write_strobe;

    /* Write logic: write data at the end of data phase */
    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            brr              <= 32'h0008_0001;
            cr1              <= 32'h0000_0007;
            cr2              <= 32'h0000_0000;
            nicr1            <= 32'h0000_0000;
            nicr2            <= 32'h0000_0000;
            nicr3            <= 32'h0000_0000;
            nicr4            <= 32'h0000_0000;
            nicr5            <= 32'h0000_0000;
            nicr6            <= 32'h0000_0000;
            nicr7            <= 32'h0000_0000;
            nicr8            <= 32'h0000_0000;
            nicr9            <= 32'h0000_0000;
            nicr10           <= 32'h0000_0000;
            nicr11           <= 32'h0000_0000;
            nicr12           <= 32'h0000_0000;
            tdr              <= 32'h0000_0000;
            tdr_write_strobe <= 1'b0;
        end else begin
            tdr_write_strobe <= 1'b0;
            if (write_valid) begin
                case (write_reg_index)
                    8'h00: begin
                        if (cr2[1: 0] == 2'b00) begin
                            if (write_valid_byte_mask[0]) begin
                                brr[7: 0] <= hwdata_i[7: 0];
                            end

                            if (write_valid_byte_mask[1]) begin
                                brr[15: 8] <= hwdata_i[15: 8];
                            end

                            if (write_valid_byte_mask[2]) begin
                                brr[23: 16] <= hwdata_i[23: 16];
                            end

                            if (write_valid_byte_mask[3]) begin
                                brr[31: 24] <= hwdata_i[31: 24];
                            end
                        end else begin
                            brr <= brr;
                        end
                    end

                    8'b01: begin
                        if (cr2[1: 0] == 2'b00) begin
                            if (write_valid_byte_mask[0]) begin
                                cr1[7: 0]   <= hwdata_i[7: 0];
                            end

                            if (write_valid_byte_mask[1]) begin
                                cr1[15: 8]  <= hwdata_i[15: 8];
                            end

                            if (write_valid_byte_mask[2]) begin
                                cr1[23: 16] <= hwdata_i[23: 16];
                            end

                            if (write_valid_byte_mask[3]) begin
                                cr1[31: 24] <= hwdata_i[31: 24];
                            end
                        end
                    end

                    8'h02: begin
                        if (write_valid_byte_mask[0]) begin
                            cr2[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            cr2[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            cr2[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            cr2[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h08: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr1[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr1[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr1[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr1[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h09: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr2[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr2[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr2[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr2[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0A: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr3[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr3[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr3[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr3[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0B: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr4[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr4[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr4[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr4[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0C: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr5[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr5[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr5[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr5[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0D: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr6[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr6[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr6[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr6[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0E: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr7[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr7[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr7[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr7[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h0F: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr8[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr8[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr8[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr8[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h10: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr9[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr9[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr9[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr9[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h11: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr10[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr10[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr10[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr10[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h12: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr11[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr11[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr11[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr11[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h13: begin
                        if (write_valid_byte_mask[0]) begin
                            nicr12[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            nicr12[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            nicr12[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            nicr12[31: 24] <= hwdata_i[31: 24];
                        end
                    end

                    8'h18: begin
                        if (write_valid_byte_mask[0]) begin
                            tdr[7: 0]   <= hwdata_i[7: 0];
                        end

                        if (write_valid_byte_mask[1]) begin
                            tdr[15: 8]  <= hwdata_i[15: 8];
                        end

                        if (write_valid_byte_mask[2]) begin
                            tdr[23: 16] <= hwdata_i[23: 16];
                        end

                        if (write_valid_byte_mask[3]) begin
                            tdr[31: 24] <= hwdata_i[31: 24];
                        end

                        tdr_write_strobe <= 1'b1;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    /* Read logic: read data at the beginning of data phase */
    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            hrdata_o <= 32'h0000_0000;
        end else begin
            if (read_xfer) begin
                case (haddr_i[9: 2])
                    8'h00: begin
                        hrdata_o <= {10'b0, brr[21: 0]};
                    end

                    8'h01: begin
                        hrdata_o <= {16'b0, cr1[5: 0]};
                    end

                    8'h02: begin
                        hrdata_o = {30'b0, cr2[1: 0]};
                    end

                    8'h08: begin
                        hrdata_o = nicr1;
                    end

                    8'h09: begin
                        hrdata_o = nicr2;
                    end

                    8'h0A: begin
                        hrdata_o = nicr3;
                    end

                    8'h0B: begin
                        hrdata_o = nicr4;
                    end

                    8'h0C: begin
                        hrdata_o = nicr5;
                    end

                    8'h0D: begin
                        hrdata_o = nicr6;
                    end

                    8'h0E: begin
                        hrdata_o = nicr7;
                    end

                    8'h0F: begin
                        hrdata_o = nicr8;
                    end

                    8'h10: begin
                        hrdata_o = nicr9;
                    end

                    8'h11: begin
                        hrdata_o = nicr10;
                    end

                    8'h12: begin
                        hrdata_o = nicr11;
                    end

                    8'h13: begin
                        hrdata_o = nicr12;
                    end

                    8'h18: begin
                        hrdata_o = tdr;
                    end

                    8'h20: begin
                        hrdata_o = {31'b0, sr1[0]};
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

    /* TX sub-system */
    wire          txrdy;
    reg  [255: 0] nicr9_2;
    reg  [ 63: 0] nicr12_11;

    tuart_core_tx tuart_core_tx_inst (
        .clock_i                            (hclk_i),
        .reset_n_i                          (hreset_n_i),
        .tx_data_write_strobe_i             (tdr_write_strobe),
        .oversampling_rate_i                (brr[21: 16]),
        .baud_divisor_i                     (brr[15: 0]),
        .data_length_i                      (cr1[2:0]),
        .parity_enable_i                    (cr1[3]),
        .parity_type_i                      (cr1[4]),
        .stop_length_i                      (cr1[5]),
        .tx_enable_i                        (cr2[0]),
        .tx_start_noise_index_i             (nicr1),
        .tx_data_noise_index_i              (nicr9_2),
        .tx_parity_noise_index_i            (nicr10),
        .tx_stop_noise_index_i              (nicr12_11),
        .tx_noise_injection_enable_i        (tdr[11]),
        .tx_parity_error_injection_enable_i (tdr[8]),
        .tx_frame_error_injection_enable_i  ({tdr[10], tdr[9]}),
        .tx_data_i                          (tdr[7:0]),
        .tx_data_register_empty_o           (txrdy),
        .txd_o                              (txd_o)
    );

    always @ (*) begin
        nicr9_2 = {nicr9, nicr8, nicr7, nicr6, nicr5, nicr4, nicr3, nicr2};
    end

    always @ (*) begin
        nicr12_11 = {nicr12, nicr11};
    end

    always @ (*) begin
        sr1[0] = txrdy;
    end

    /* RX subsystem */
//    (* DONT_TOUCH = "true" *) wire [31: 0] rxd_dummy_load;

//    assign rxd_dummy_load = rxd_i;

    /* IO controller subsystem */
    assign swap_o = 1'b0;
    assign txd_output_enabled_o = 1'b1;
    assign rxd_output_enabled_o = 1'b0;

endmodule
