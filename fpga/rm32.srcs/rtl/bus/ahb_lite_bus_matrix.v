`timescale 1ns / 1ps

module ahb_lite_bus_matrix (
/* AHB-Lite clock & reset signal */
    input  wire         HCLK,
    input  wire         HRESETn,
/* AHB-Lite master device signal */
    input  wire [31: 0] HADDR_master,
    input  wire [31: 0] HWDATA_master,
    input  wire         HWRITE_master,
    input  wire  [1: 0] HTRANS_master,
    input  wire  [2: 0] HSIZE_master,
    input  wire  [2: 0] HBURST_master,
    input  wire  [3: 0] HPROT_master,
    input  wire         HMASTLOCK_master,
    output reg  [31: 0] HRDATA_master,
    output reg          HREADY_master,
    output reg          HRESP_master,
/* AHB-Lite slave device 0 signal */
    output wire         HSEL_slave0,
    output wire [31: 0] HADDR_slave0,
    output wire [31: 0] HWDATA_slave0,
    output wire         HWRITE_slave0,
    output wire  [1: 0] HTRANS_slave0,
    output wire  [2: 0] HSIZE_slave0,
    output wire         HREADY_slave0,
    output wire  [2: 0] HBURST_slave0,
    output wire  [3: 0] HPROT_slave0,
    output wire         HMASTLOCK_slave0,
    input  wire [31: 0] HRDATA_slave0,
    input  wire         HREADYOUT_slave0,
    input  wire         HRESP_slave0,
/* AHB-Lite slave device 1 signal */
    output wire         HSEL_slave1,
    output wire [31: 0] HADDR_slave1,
    output wire [31: 0] HWDATA_slave1,
    output wire         HWRITE_slave1,
    output wire  [1: 0] HTRANS_slave1,
    output wire  [2: 0] HSIZE_slave1,
    output wire         HREADY_slave1,
    output wire  [2: 0] HBURST_slave1,
    output wire  [3: 0] HPROT_slave1,
    output wire         HMASTLOCK_slave1,
    input  wire [31: 0] HRDATA_slave1,
    input  wire         HREADYOUT_slave1,
    input  wire         HRESP_slave1,
/* AHB-Lite slave device 2 signal */
    output wire         HSEL_slave2,
    output wire [31: 0] HADDR_slave2,
    output wire [31: 0] HWDATA_slave2,
    output wire         HWRITE_slave2,
    output wire  [1: 0] HTRANS_slave2,
    output wire  [2: 0] HSIZE_slave2,
    output wire         HREADY_slave2,
    output wire  [2: 0] HBURST_slave2,
    output wire  [3: 0] HPROT_slave2,
    output wire         HMASTLOCK_slave2,
    input  wire [31: 0] HRDATA_slave2,
    input  wire         HREADYOUT_slave2,
    input  wire         HRESP_slave2
);
    /* Transfer AHB lite master device control signal to slave device */
    assign HADDR_slave0 = HADDR_master;
    assign HADDR_slave1 = HADDR_master;
    assign HADDR_slave2 = HADDR_master;

    assign HWDATA_slave0 = HWDATA_master;
    assign HWDATA_slave1 = HWDATA_master;
    assign HWDATA_slave2 = HWDATA_master;

    assign HWRITE_slave0 = HWRITE_master;
    assign HWRITE_slave1 = HWRITE_master;
    assign HWRITE_slave2 = HWRITE_master;

    assign HTRANS_slave0 = HTRANS_master;
    assign HTRANS_slave1 = HTRANS_master;
    assign HTRANS_slave2 = HTRANS_master;

    assign HSIZE_slave0 = HSIZE_master;
    assign HSIZE_slave1 = HSIZE_master;
    assign HSIZE_slave2 = HSIZE_master;

    assign HREADY_slave0 = HREADY_master;
    assign HREADY_slave1 = HREADY_master;
    assign HREADY_slave2 = HREADY_master;

    assign HBURST_slave0 = HBURST_master;
    assign HBURST_slave1 = HBURST_master;
    assign HBURST_slave2 = HBURST_master;

    assign HPROT_slave0 = HPROT_master;
    assign HPROT_slave1 = HPROT_master;
    assign HPROT_slave2 = HPROT_master;

    assign HMASTLOCK_slave0 = HMASTLOCK_master;
    assign HMASTLOCK_slave1 = HMASTLOCK_master;
    assign HMASTLOCK_slave2 = HMASTLOCK_master;

    /* Select AHB lite slave device */
    wire [2: 0] hsel_combination;
    reg  [2: 0] hsel_combination_register;

    assign HSEL_slave0 = (HADDR_master[31:16] == 16'h0000) ? 1'b1 : 1'b0;
    assign HSEL_slave1 = (HADDR_master[31:16] == 16'h2000) ? 1'b1 : 1'b0;
    assign HSEL_slave2 = (HADDR_master[31:12] == 20'h40000) ? 1'b1 : 1'b0;
    assign hsel_combination = {HSEL_slave2, HSEL_slave1, HSEL_slave0};

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_combination_register <= 3'b000;
        end else if (HREADY_master) begin
            hsel_combination_register <= hsel_combination;
        end
    end

    /* Transfer AHB lite slave device feedback signal to master device */
    always @ (*) begin
        case (hsel_combination_register)
            3'b001: begin
                HRDATA_master = HRDATA_slave0;
                HREADY_master = HREADYOUT_slave0;
                HRESP_master  = HRESP_slave0;
            end

            3'b010: begin
                HRDATA_master = HRDATA_slave1;
                HREADY_master = HREADYOUT_slave1;
                HRESP_master  = HRESP_slave1;
            end

            3'b100: begin
                HRDATA_master = HRDATA_slave2;
                HREADY_master = HREADYOUT_slave2;
                HRESP_master  = HRESP_slave2;
            end

            default: begin
                HRDATA_master = 32'hDEADBEEF;
                HREADY_master = 1'b1;
                HRESP_master  = 1'b0;
            end
        endcase
    end

endmodule
