`timescale 1ns / 1ps

module bram #(
    parameter MEMORY_UNIT_ADDRESS_LINE_WIDTH = 8
)(
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
    output wire         HRESP
);
    /* Memory unit block depth */
    localparam MEMORY_UNIT_ADDRESS_LIMIT = 1 << MEMORY_UNIT_ADDRESS_LINE_WIDTH;

    /* Memory unit block */
    (* ram_style = "block" *) reg [31: 0] memory_unit [0: (MEMORY_UNIT_ADDRESS_LIMIT - 1)];
    reg [(MEMORY_UNIT_ADDRESS_LINE_WIDTH - 1): 0] memory_unit_address;
    
    /* Sampling HSEL */
    reg hsel_register;

    always @ (posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_register <= 1'b0;
        end else begin
            hsel_register <= HSEL;
        end
    end

    /* Sample in address phase */
    reg [31: 0] haddr_register;
    reg         hwrite_register;
    reg  [1: 0] htrans_register;
    reg  [2: 0] hsize_register;
    reg         hready_register;

    always @ (posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            haddr_register      <= 32'b0;
            hwrite_register     <= 1'b0;
            htrans_register     <= 2'b0;
            hsize_register      <= 3'b0;
            hready_register     <= 1'b0;
            memory_unit_address <= 0;
        end else begin
            if (HSEL & HREADY) begin
                haddr_register      <= HADDR;
                hwrite_register     <= HWRITE;
                htrans_register     <= HTRANS;
                hsize_register      <= HSIZE;
                hready_register     <= HREADY;
                memory_unit_address <= HADDR[(MEMORY_UNIT_ADDRESS_LINE_WIDTH + 1): 2];
            end
        end
    end

    /* Get valid byte index */
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
    
    /* Generate read request flag */
    wire ahb_lite_read_request_flag;

    assign ahb_lite_read_request_flag =
        hsel_register && (!hwrite_register) && (htrans_register[1] == 1'b1) &&
        hready_register;

    /* Read & Write logic */
    always @ (posedge HCLK) begin
        if (ahb_lite_write_request_flag) begin
            if (ahb_lite_data_valid_byte_index[0]) begin
                memory_unit[memory_unit_address][7: 0]   <= HWDATA[7: 0];
            end

            if (ahb_lite_data_valid_byte_index[1]) begin
                memory_unit[memory_unit_address][15: 8]  <= HWDATA[15: 8];
            end

            if (ahb_lite_data_valid_byte_index[2]) begin
                memory_unit[memory_unit_address][23: 16] <= HWDATA[23: 16];
            end

            if (ahb_lite_data_valid_byte_index[3]) begin
                memory_unit[memory_unit_address][31: 24] <= HWDATA[31: 24];
            end
        end 
    end

    always @ (*) begin
        if (ahb_lite_read_request_flag) begin
            HRDATA <= memory_unit[memory_unit_address];
        end
    end

    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0;

endmodule
