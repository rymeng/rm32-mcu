`timescale 1ns / 1ps

module uart (
/* AHB Slave Interface */
    input  wire         HCLK,
    input  wire         HRESETn,
    input  wire         HSEL,
    input  wire [31: 0] HADDR,
    input  wire [31: 0] HWDATA,
    input  wire         HWRITE,
    input  wire  [1: 0] HTRANS,
    input  wire  [2: 0] HSIZE,
    input  wire         HREADY,
    input  wire  [2: 0] HBURST,
    input  wire  [3: 0] HPROT,
    input  wire         HMASTLOCK,
    output reg  [31: 0] HRDATA,
    output wire         HREADYOUT,
    output wire         HRESP,
/* UART Port */
    output wire         txd_o
);
    /* Register */
    reg [31: 0] BRR;
    reg [31: 0] CR1;
    reg [31: 0] CR2;
    reg [31: 0] NICR1;
    reg [31: 0] NICR2;
    reg [31: 0] NICR3;
    reg [31: 0] NICR4;
    reg [31: 0] NICR5;
    reg [31: 0] NICR6;
    reg [31: 0] NICR7;
    reg [31: 0] NICR8;
    reg [31: 0] NICR9;
    reg [31: 0] NICR10;
    reg [31: 0] NICR11;
    reg [31: 0] NICR12;
    reg [31: 0] TDR;

    /* Sample in address phase */
    reg         hsel_register;
    reg [31: 0] haddr_register;
    reg [31: 0] hwdata_register;
    reg         hwrite_register;
    reg  [1: 0] htrans_register;
    reg  [2: 0] hsize_register;
    reg         hready_register;
    
    always @ (posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_register <= 1'b0;
        end else begin
            hsel_register <= HSEL;
        end
    end

    always @ (posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            haddr_register  <= 32'b0;
            hwdata_register <= 32'b0;
            hwrite_register <= 1'b0;
            htrans_register <= 2'b0;
            hsize_register  <= 3'b0;
            hready_register <= 1'b0;
        end else begin
            if (HSEL && (HTRANS[1] == 1'b1) && HREADY) begin
                haddr_register  <= HADDR;
                hwdata_register <= HWDATA;
                hwrite_register <= HWRITE;
                htrans_register <= HTRANS;
                hsize_register  <= HSIZE;
                hready_register <= HREADY;
            end
        end
    end

    /* Generate data valid byte index */
    reg [3: 0] ahb_lite_data_valid_byte_index;

    always @ (*) begin
        case (hsize_register)
            3'b000: begin
                case (haddr_register[1: 0])
                    2'b00: begin
                        ahb_lite_data_valid_byte_index = 4'b0001;
                    end

                    2'b01: begin
                        ahb_lite_data_valid_byte_index = 4'b0010;
                    end

                    2'b10: begin
                        ahb_lite_data_valid_byte_index = 4'b0100;
                    end

                    2'b11: begin
                        ahb_lite_data_valid_byte_index = 4'b1000;
                    end

                    default: begin
                        ahb_lite_data_valid_byte_index = 4'b0000;
                    end
                endcase
            end

            3'b001: begin
                case(haddr_register[1])
                    1'b0: begin
                        ahb_lite_data_valid_byte_index = 4'b0011;
                    end

                    1'b1: begin
                        ahb_lite_data_valid_byte_index = 4'b1100;
                    end
                endcase
            end

            3'b010: begin
                ahb_lite_data_valid_byte_index = 4'b1111;
            end

            default: begin
                ahb_lite_data_valid_byte_index = 4'b0000;
            end
        endcase
    end

    /* Generate write request flag */
    wire ahb_lite_write_request_flag;

    assign ahb_lite_write_request_flag =
        hsel_register && hwrite_register && (htrans_register[1] == 1'b1) &&
        hready_register;

    /* Generate BRR new value */
    reg [31: 0] BRR_new_value;
    reg         BRR_new_value_valid;

    always @ (*) begin
        BRR_new_value = BRR;

        if (ahb_lite_data_valid_byte_index[0]) begin
            BRR_new_value[7: 0] = HWDATA[7: 0];
        end

        if (ahb_lite_data_valid_byte_index[1]) begin
            BRR_new_value[15: 8] = HWDATA[15: 8];
        end

        if (ahb_lite_data_valid_byte_index[2]) begin
            BRR_new_value[23: 16] = HWDATA[23: 16];
        end

        if (ahb_lite_data_valid_byte_index[3]) begin
            BRR_new_value[31: 24] = HWDATA[31: 24];
        end

        if (BRR_new_value[21: 16] < 6'h08) begin
            BRR_new_value_valid = 1'b0;
        end else if (BRR_new_value[21: 16] > 6'h20) begin
            BRR_new_value_valid = 1'b0;
        end else if (BRR_new_value[15: 0] < 16'h0001) begin
            BRR_new_value_valid = 1'b0;
        end else begin
            BRR_new_value_valid = 1'b1;
        end
    end

    /* Write logic */
    reg TDR_write_strobe;

    always @ (posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            BRR              <= 32'h00080001;
            CR1              <= 32'h00000007;
            CR2              <= 32'h00000000;
            NICR1            <= 32'h00000000;
            NICR2            <= 32'h00000000;
            NICR3            <= 32'h00000000;
            NICR4            <= 32'h00000000;
            NICR5            <= 32'h00000000;
            NICR6            <= 32'h00000000;
            NICR7            <= 32'h00000000;
            NICR8            <= 32'h00000000;
            NICR9            <= 32'h00000000;
            NICR10           <= 32'h00000000;
            NICR11           <= 32'h00000000;
            NICR12           <= 32'h00000000;
            TDR              <= 32'h00000000;
            TDR_write_strobe <= 1'b0;
        end else begin
            TDR_write_strobe <= 1'b0;
            if (ahb_lite_write_request_flag) begin
                case (haddr_register[11: 2])
                    /* BRR */
                    10'h000: begin
                        if (CR2[0] == 1'b0) begin
                            if (BRR_new_value_valid) begin
                                BRR <= BRR_new_value;
                            end
                        end
                    end

                    /* CR1 */
                    10'h001: begin
                        if (CR2[0] == 1'b0) begin
                            if (ahb_lite_data_valid_byte_index[0]) begin
                                CR1[7: 0]   <= HWDATA[7: 0];
                            end

                            if (ahb_lite_data_valid_byte_index[1]) begin
                                CR1[15: 8]  <= HWDATA[15: 8];
                            end

                            if (ahb_lite_data_valid_byte_index[2]) begin
                                CR1[23: 16] <= HWDATA[23: 16];
                            end

                            if (ahb_lite_data_valid_byte_index[3]) begin
                                CR1[31: 24] <= HWDATA[31: 24];
                            end
                        end
                    end

                    /* CR2 */
                    10'h002: begin
                        if (ahb_lite_data_valid_byte_index[0])
                            CR2[0] <= HWDATA[0];
                    end

                    /* NICR1 */
                    30'h0008: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR1[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR1[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR1[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR1[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* NICR2 */
                    10'h009: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR2[7: 0]   <= HWDATA[7:0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR2[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR2[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR2[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR3 */
                    10'h00A: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR3[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR3[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR3[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR3[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR4 */
                    10'h00B: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR4[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR4[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR4[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR4[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR5 */
                    10'h00C: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR5[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR5[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR5[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR5[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR6 */
                    10'h00D: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR6[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR6[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR6[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR6[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR7 */
                    10'h00E: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR7[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR7[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR7[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR7[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR8 */
                    10'h00F: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR8[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR8[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR8[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR8[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* INCR9 */
                    10'h010: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR9[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR9[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR9[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR9[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* NICR10 */
                    10'h011: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR10[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR10[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR10[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR10[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* NICR11 */
                    10'h012: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR11[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR11[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR11[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR11[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* NICR12 */
                    10'h013: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            NICR12[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            NICR12[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            NICR12[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            NICR12[31: 24] <= HWDATA[31: 24];
                        end
                    end

                    /* TDR */
                    10'h018: begin
                        if (ahb_lite_data_valid_byte_index[0]) begin
                            TDR[7: 0]   <= HWDATA[7: 0];
                        end

                        if (ahb_lite_data_valid_byte_index[1]) begin
                            TDR[15: 8]  <= HWDATA[15: 8];
                        end

                        if (ahb_lite_data_valid_byte_index[2]) begin
                            TDR[23: 16] <= HWDATA[23: 16];
                        end

                        if (ahb_lite_data_valid_byte_index[3]) begin
                            TDR[31: 24] <= HWDATA[31: 24];
                        end

                        /* Generate TDR write strobe */
                        TDR_write_strobe <= 1'b1;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    /* Read logic */
    wire txrdy;

    always @ (*) begin
        case (haddr_register[11: 2])
            10'h000: begin
                HRDATA = BRR;
            end

            10'h001: begin
                HRDATA = CR1;
            end

            10'h002: begin
                HRDATA = CR2;
            end

            10'h008: begin
                HRDATA = NICR1;
            end

            10'h009: begin
                HRDATA = NICR2;
            end

            10'h00A: begin
                HRDATA = NICR3;
            end

            10'h00B: begin
                HRDATA = NICR4;
            end

            10'h00C: begin
                HRDATA = NICR5;
            end

            10'h00D: begin
                HRDATA = NICR6;
            end

            10'h00E: begin
                HRDATA = NICR7;
            end

            10'h00F: begin
                HRDATA = NICR8;
            end

            10'h010: begin
                HRDATA = NICR9;
            end

            10'h011: begin
                HRDATA = NICR10;
            end

            10'h012: begin
                HRDATA = NICR11;
            end

            10'h013: begin
                HRDATA = NICR12;
            end

            10'h018: begin
                HRDATA = TDR;
            end

            10'h020: begin
                HRDATA = {31'b0, txrdy};
            end

            default: begin
                HRDATA = 32'hAAAAAAAA;
            end
        endcase
    end

    /* UART TX sub-system */
    uart_core_tx tx_subsystem (
        .clock_i                            (HCLK),
        .reset_n_i                          (HRESETn),
        .tx_data_write_strobe_i             (TDR_write_strobe),
        .oversampling_rate_i                (BRR[21:16]),
        .baud_divisor_i                     (BRR[15:0]),
        .data_length_i                      (CR1[2:0]),
        .parity_enable_i                    (CR1[3]),
        .parity_type_i                      (CR1[4]),
        .stop_length_i                      (CR1[5]),
        .tx_enable_i                        (CR2[0]),
        .tx_start_noise_index_i             (NICR1),
        .tx_data_noise_index_i              ({NICR9, NICR8, NICR7, NICR6, NICR5, NICR4, NICR3, NICR2}),
        .tx_parity_noise_index_i            (NICR10),
        .tx_stop_noise_index_i              ({NICR12, NICR11}),
        .tx_noise_injection_enable_i        (TDR[11]),
        .tx_parity_error_injection_enable_i (TDR[8]),
        .tx_frame_error_injection_enable_i  ({TDR[10], TDR[9]}),
        .tx_data_i                          (TDR[7:0]),
        .tx_data_register_empty_o           (txrdy),
        .txd_o                              (txd_o)
    );

    /* AHB-Lite slave signal: always 0 wait state */
    assign HREADYOUT = 1'b1;

    /* AHB-Lite slave signal: always no error */
    assign HRESP     = 2'b00;

endmodule
