`timescale 1ns / 1ps

module bus_matrix_top (
/* AHB-Lite master device signal */
    input  wire        hclk_master_i,
    input  wire        hreset_master_n_i,
    input  wire [31:0] haddr_master_i,
    input  wire [31:0] hwdata_master_i,
    input  wire        hwrite_master_i,
    input  wire  [1:0] htrans_master_i,
    input  wire  [2:0] hsize_master_i,
    input  wire  [2:0] hburst_master_i,
    input  wire  [3:0] hprot_master_i,
    input  wire        hmastlock_master_i,
    output reg  [31:0] hrdata_master_o,
    output reg         hready_master_o,
    output reg         hresp_master_o,
/* AHB slave device 00 (RCC) signal */
    output wire        hsel_slave00_o,
    output wire [31:0] haddr_slave00_o,
    output wire [31:0] hwdata_slave00_o,
    output wire        hwrite_slave00_o,
    output wire  [1:0] htrans_slave00_o,
    output wire  [2:0] hsize_slave00_o,
    output wire        hready_slave00_o,
    output wire  [2:0] hburst_slave00_o,
    output wire  [3:0] hprot_slave00_o,
    output wire        hmastlock_slave00_o,
    input  wire [31:0] hrdata_slave00_i,
    input  wire        hreadyout_slave00_i,
    input  wire        hresp_slave00_i,
/* AHB slave device 01 (Flash Model Main Bank) signal */
    output wire        hsel_slave01_o,
    output wire [31:0] haddr_slave01_o,
    output wire [31:0] hwdata_slave01_o,
    output wire        hwrite_slave01_o,
    output wire  [1:0] htrans_slave01_o,
    output wire  [2:0] hsize_slave01_o,
    output wire        hready_slave01_o,
    output wire  [2:0] hburst_slave01_o,
    output wire  [3:0] hprot_slave01_o,
    output wire        hmastlock_slave01_o,
    input  wire [31:0] hrdata_slave01_i,
    input  wire        hreadyout_slave01_i,
    input  wire        hresp_slave01_i,
/* AHB slave device 02 (SRAM Model) signal */
    output wire        hsel_slave02_o,
    output wire [31:0] haddr_slave02_o,
    output wire [31:0] hwdata_slave02_o,
    output wire        hwrite_slave02_o,
    output wire  [1:0] htrans_slave02_o,
    output wire  [2:0] hsize_slave02_o,
    output wire        hready_slave02_o,
    output wire  [2:0] hburst_slave02_o,
    output wire  [3:0] hprot_slave02_o,
    output wire        hmastlock_slave02_o,
    input  wire [31:0] hrdata_slave02_i,
    input  wire        hreadyout_slave02_i,
    input  wire        hresp_slave02_i,
/* AHB slave device 03 (GPIO A) signal */
    output wire        hsel_slave03_o,
    output wire [31:0] haddr_slave03_o,
    output wire [31:0] hwdata_slave03_o,
    output wire        hwrite_slave03_o,
    output wire  [1:0] htrans_slave03_o,
    output wire  [2:0] hsize_slave03_o,
    output wire        hready_slave03_o,
    output wire  [2:0] hburst_slave03_o,
    output wire  [3:0] hprot_slave03_o,
    output wire        hmastlock_slave03_o,
    input  wire [31:0] hrdata_slave03_i,
    input  wire        hreadyout_slave03_i,
    input  wire        hresp_slave03_i,
/* AHB slave device 04 (GPIO B) signal */
    output wire        hsel_slave04_o,
    output wire [31:0] haddr_slave04_o,
    output wire [31:0] hwdata_slave04_o,
    output wire        hwrite_slave04_o,
    output wire  [1:0] htrans_slave04_o,
    output wire  [2:0] hsize_slave04_o,
    output wire        hready_slave04_o,
    output wire  [2:0] hburst_slave04_o,
    output wire  [3:0] hprot_slave04_o,
    output wire        hmastlock_slave04_o,
    input  wire [31:0] hrdata_slave04_i,
    input  wire        hreadyout_slave04_i,
    input  wire        hresp_slave04_i,
/* AHB slave device 05 (UART 1) signal */
    output wire        hsel_slave05_o,
    output wire [31:0] haddr_slave05_o,
    output wire [31:0] hwdata_slave05_o,
    output wire        hwrite_slave05_o,
    output wire  [1:0] htrans_slave05_o,
    output wire  [2:0] hsize_slave05_o,
    output wire        hready_slave05_o,
    output wire  [2:0] hburst_slave05_o,
    output wire  [3:0] hprot_slave05_o,
    output wire        hmastlock_slave05_o,
    input  wire [31:0] hrdata_slave05_i,
    input  wire        hreadyout_slave05_i,
    input  wire        hresp_slave05_i,
/* AHB slave device 06 (UART 2) signal */
    output wire        hsel_slave06_o,
    output wire [31:0] haddr_slave06_o,
    output wire [31:0] hwdata_slave06_o,
    output wire        hwrite_slave06_o,
    output wire  [1:0] htrans_slave06_o,
    output wire  [2:0] hsize_slave06_o,
    output wire        hready_slave06_o,
    output wire  [2:0] hburst_slave06_o,
    output wire  [3:0] hprot_slave06_o,
    output wire        hmastlock_slave06_o,
    input  wire [31:0] hrdata_slave06_i,
    input  wire        hreadyout_slave06_i,
    input  wire        hresp_slave06_i,
/* AHB slave device 07 (TUART 1) signal */
    output wire        hsel_slave07_o,
    output wire [31:0] haddr_slave07_o,
    output wire [31:0] hwdata_slave07_o,
    output wire        hwrite_slave07_o,
    output wire  [1:0] htrans_slave07_o,
    output wire  [2:0] hsize_slave07_o,
    output wire        hready_slave07_o,
    output wire  [2:0] hburst_slave07_o,
    output wire  [3:0] hprot_slave07_o,
    output wire        hmastlock_slave07_o,
    input  wire [31:0] hrdata_slave07_i,
    input  wire        hreadyout_slave07_i,
    input  wire        hresp_slave07_i,
/* AHB slave device 08 (FMC) signal */
    output wire        hsel_slave08_o,
    output wire [31:0] haddr_slave08_o,
    output wire [31:0] hwdata_slave08_o,
    output wire        hwrite_slave08_o,
    output wire  [1:0] htrans_slave08_o,
    output wire  [2:0] hsize_slave08_o,
    output wire        hready_slave08_o,
    output wire  [2:0] hburst_slave08_o,
    output wire  [3:0] hprot_slave08_o,
    output wire        hmastlock_slave08_o,
    input  wire [31:0] hrdata_slave08_i,
    input  wire        hreadyout_slave08_i,
    input  wire        hresp_slave08_i
);
    /* Transfer AHB-Lite master device global signal to all slave device */
    assign haddr_slave00_o = haddr_master_i;
    assign haddr_slave01_o = haddr_master_i;
    assign haddr_slave02_o = haddr_master_i;
    assign haddr_slave03_o = haddr_master_i;
    assign haddr_slave04_o = haddr_master_i;
    assign haddr_slave05_o = haddr_master_i;
    assign haddr_slave06_o = haddr_master_i;
    assign haddr_slave07_o = haddr_master_i;
    assign haddr_slave08_o = haddr_master_i;

    assign hwdata_slave00_o = hwdata_master_i;
    assign hwdata_slave01_o = hwdata_master_i;
    assign hwdata_slave02_o = hwdata_master_i;
    assign hwdata_slave03_o = hwdata_master_i;
    assign hwdata_slave04_o = hwdata_master_i;
    assign hwdata_slave05_o = hwdata_master_i;
    assign hwdata_slave06_o = hwdata_master_i;
    assign hwdata_slave07_o = hwdata_master_i;
    assign hwdata_slave08_o = hwdata_master_i;

    assign hwrite_slave00_o = hwrite_master_i;
    assign hwrite_slave01_o = hwrite_master_i;
    assign hwrite_slave02_o = hwrite_master_i;
    assign hwrite_slave03_o = hwrite_master_i;
    assign hwrite_slave04_o = hwrite_master_i;
    assign hwrite_slave05_o = hwrite_master_i;
    assign hwrite_slave06_o = hwrite_master_i;
    assign hwrite_slave07_o = hwrite_master_i;
    assign hwrite_slave08_o = hwrite_master_i;

    assign htrans_slave00_o = htrans_master_i;
    assign htrans_slave01_o = htrans_master_i;
    assign htrans_slave02_o = htrans_master_i;
    assign htrans_slave03_o = htrans_master_i;
    assign htrans_slave04_o = htrans_master_i;
    assign htrans_slave05_o = htrans_master_i;
    assign htrans_slave06_o = htrans_master_i;
    assign htrans_slave07_o = htrans_master_i;
    assign htrans_slave08_o = htrans_master_i;

    assign hsize_slave00_o = hsize_master_i;
    assign hsize_slave01_o = hsize_master_i;
    assign hsize_slave02_o = hsize_master_i;
    assign hsize_slave03_o = hsize_master_i;
    assign hsize_slave04_o = hsize_master_i;
    assign hsize_slave05_o = hsize_master_i;
    assign hsize_slave06_o = hsize_master_i;
    assign hsize_slave07_o = hsize_master_i;
    assign hsize_slave08_o = hsize_master_i;

    assign hready_slave00_o = hready_master_o;
    assign hready_slave01_o = hready_master_o;
    assign hready_slave02_o = hready_master_o;
    assign hready_slave03_o = hready_master_o;
    assign hready_slave04_o = hready_master_o;
    assign hready_slave05_o = hready_master_o;
    assign hready_slave06_o = hready_master_o;
    assign hready_slave07_o = hready_master_o;
    assign hready_slave08_o = hready_master_o;

    assign hburst_slave00_o = hburst_master_i;
    assign hburst_slave01_o = hburst_master_i;
    assign hburst_slave02_o = hburst_master_i;
    assign hburst_slave03_o = hburst_master_i;
    assign hburst_slave04_o = hburst_master_i;
    assign hburst_slave05_o = hburst_master_i;
    assign hburst_slave06_o = hburst_master_i;
    assign hburst_slave07_o = hburst_master_i;
    assign hburst_slave08_o = hburst_master_i;

    assign hprot_slave00_o = hprot_master_i;
    assign hprot_slave01_o = hprot_master_i;
    assign hprot_slave02_o = hprot_master_i;
    assign hprot_slave03_o = hprot_master_i;
    assign hprot_slave04_o = hprot_master_i;
    assign hprot_slave05_o = hprot_master_i;
    assign hprot_slave06_o = hprot_master_i;
    assign hprot_slave07_o = hprot_master_i;
    assign hprot_slave08_o = hprot_master_i;

    assign hmastlock_slave00_o = hmastlock_master_i;
    assign hmastlock_slave01_o = hmastlock_master_i;
    assign hmastlock_slave02_o = hmastlock_master_i;
    assign hmastlock_slave03_o = hmastlock_master_i;
    assign hmastlock_slave04_o = hmastlock_master_i;
    assign hmastlock_slave05_o = hmastlock_master_i;
    assign hmastlock_slave06_o = hmastlock_master_i;
    assign hmastlock_slave07_o = hmastlock_master_i;
    assign hmastlock_slave08_o = hmastlock_master_i;

    /* Select AHB slave device */
    assign hsel_slave00_o =
        (haddr_master_i >= 32'h4000_0000 && haddr_master_i <= 32'h4000_3FFF) ? (1'b1) : (1'b0);
    assign hsel_slave01_o =
        (haddr_master_i >= 32'h0000_0000 && haddr_master_i <= 32'h0000_FFFF) ? (1'b1) : (1'b0);
    assign hsel_slave02_o =
        (haddr_master_i >= 32'h2000_0000 && haddr_master_i <= 32'h2000_FFFF) ? (1'b1) : (1'b0);
    assign hsel_slave03_o =
        (haddr_master_i >= 32'h4008_0000 && haddr_master_i <= 32'h4008_03FF) ? (1'b1) : (1'b0);
    assign hsel_slave04_o =
        (haddr_master_i >= 32'h4008_0400 && haddr_master_i <= 32'h4008_07FF) ? (1'b1) : (1'b0);
    assign hsel_slave05_o =
        (haddr_master_i >= 32'h4001_0000 && haddr_master_i <= 32'h4001_03FF) ? (1'b1) : (1'b0);
    assign hsel_slave06_o =
        (haddr_master_i >= 32'h4001_0400 && haddr_master_i <= 32'h4001_07FF) ? (1'b1) : (1'b0);
    assign hsel_slave07_o =
        (haddr_master_i >= 32'h4001_0800 && haddr_master_i <= 32'h4001_0BFF) ? (1'b1) : (1'b0);
    assign hsel_slave08_o =
        (haddr_master_i >= 32'h4002_0000 && haddr_master_i <= 32'h4002_03FF) ? (1'b1) : (1'b0);

    wire [8:0] hsel_comb;

    assign hsel_comb = {
        hsel_slave08_o,
        hsel_slave07_o,
        hsel_slave06_o,
        hsel_slave05_o,
        hsel_slave04_o,
        hsel_slave03_o,
        hsel_slave02_o,
        hsel_slave01_o,
        hsel_slave00_o
    };

    reg  [8:0] hsel_comb_phase;

    always @(posedge hclk_master_i or negedge hreset_master_n_i) begin
        if (!hreset_master_n_i) begin
            hsel_comb_phase <= 9'h0;
        end else if (hready_master_o) begin
            hsel_comb_phase <= hsel_comb;
        end
    end

    /* Transfer AHB slave device feedback signal to master device */
    always @ (*) begin
        case (hsel_comb_phase)
            9'h001: begin
                hrdata_master_o = hrdata_slave00_i;
                hready_master_o = hreadyout_slave00_i;
                hresp_master_o = hresp_slave00_i;
            end

            9'h002: begin
                hrdata_master_o = hrdata_slave01_i;
                hready_master_o = hreadyout_slave01_i;
                hresp_master_o = hresp_slave01_i;
            end

            9'h004: begin
                hrdata_master_o = hrdata_slave02_i;
                hready_master_o = hreadyout_slave02_i;
                hresp_master_o = hresp_slave02_i;
            end

            9'h008: begin
                hrdata_master_o = hrdata_slave03_i;
                hready_master_o = hreadyout_slave03_i;
                hresp_master_o = hresp_slave03_i;
            end

            9'h010: begin
                hrdata_master_o = hrdata_slave04_i;
                hready_master_o = hreadyout_slave04_i;
                hresp_master_o = hresp_slave04_i;
            end

            9'h020: begin
                hrdata_master_o = hrdata_slave05_i;
                hready_master_o = hreadyout_slave05_i;
                hresp_master_o = hresp_slave05_i;
            end

            9'h040: begin
                hrdata_master_o = hrdata_slave06_i;
                hready_master_o = hreadyout_slave06_i;
                hresp_master_o = hresp_slave06_i;
            end

            9'h080: begin
                hrdata_master_o = hrdata_slave07_i;
                hready_master_o = hreadyout_slave07_i;
                hresp_master_o = hresp_slave07_i;
            end

            9'h100: begin
                hrdata_master_o = hrdata_slave08_i;
                hready_master_o = hreadyout_slave08_i;
                hresp_master_o = hresp_slave08_i;
            end

            default: begin
                hrdata_master_o = 32'hDEADBEEF;
                hready_master_o = 1'b1;
                hresp_master_o = 1'b0;
            end
        endcase
    end
endmodule
