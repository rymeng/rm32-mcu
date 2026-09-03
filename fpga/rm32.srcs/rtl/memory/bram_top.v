`timescale 1ns / 1ps

module bram_top #(
    parameter ADDR_WIDTH = 8
)(
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
    output wire         hresp_o
);
    /* Memory unit block depth */
    localparam ADDR_LIMIT = 1 << ADDR_WIDTH;

    /* Memory unit */
    (* ram_style = "block" *) reg [31: 0] unit [0: (ADDR_LIMIT - 1)];

    /* Sample read_xfer / write_xfer signal at any time */
    reg read_xfer;
    reg write_xfer;

    always @ (*) begin
        read_xfer = hsel_i & (!hwrite_i) & htrans_i[1] & hready_i;
        write_xfer = hsel_i & hwrite_i & htrans_i[1] & hready_i;
    end

    /* Write logic: generate write_valid signal */
    reg write_valid;

    always @(posedge hclk_i) begin
        if (!hreset_n_i) begin
            write_valid <= 1'b0;
        end else begin
            write_valid <= write_xfer;
        end
    end

    /* Write logic: sample address & mask signal in address phase */
    reg [(ADDR_WIDTH + 1): 2] write_mem_index;
    reg                [4: 0] write_valid_data_mask;

    always @(posedge hclk_i) begin
        if (!hreset_n_i) begin
            write_mem_index       <= {ADDR_WIDTH{1'b0}};
            write_valid_data_mask <= 4'b0000;
        end else begin
            if (write_xfer) begin
                write_mem_index <= haddr_i[(ADDR_WIDTH + 1): 2];
                case (hsize_i)
                    3'b000: begin
                        case(haddr_i[1: 0])
                            2'b00: begin
                                write_valid_data_mask <= 4'b0001;
                            end

                            2'b01: begin
                                write_valid_data_mask <= 4'b0010;
                            end

                            2'b10: begin
                                write_valid_data_mask <= 4'b0100;
                            end

                            2'b11: begin
                                write_valid_data_mask <= 4'b1000;
                            end
                        endcase
                    end

                    3'b001: begin
                        case (haddr_i[1])
                            1'b0: begin
                                write_valid_data_mask <= 4'b0011;
                            end

                            1'b1: begin
                                write_valid_data_mask <= 4'b1100;
                            end
                        endcase
                    end

                    3'b010: begin
                        write_valid_data_mask <= 4'b1111;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    /* Write logic: write data at the end of data phase */
    always @(posedge hclk_i) begin
        if (write_valid) begin
            if (write_valid_data_mask[0]) begin
                unit[write_mem_index][7: 0]   <= hwdata_i[7: 0];
            end

            if (write_valid_data_mask[1]) begin
                unit[write_mem_index][15: 8]  <= hwdata_i[15: 8];
            end

            if (write_valid_data_mask[2]) begin
                unit[write_mem_index][23: 16] <= hwdata_i[23: 16];
            end

            if (write_valid_data_mask[3]) begin
                unit[write_mem_index][31: 24] <= hwdata_i[31: 24];
            end
        end
    end

    /* Read logic: read data at the beginning of data phase */
    always @ (posedge hclk_i) begin
        if (read_xfer) begin
            hrdata_o <= unit[haddr_i[(ADDR_WIDTH + 1): 2]];
        end else begin
            hrdata_o <= hrdata_o;
        end
    end

    /* hreadyout_o: always 0 wait state */
    assign hreadyout_o = 1'b1;

    /* hresp_o: always no error response */
    assign hresp_o = 2'b00;

endmodule
