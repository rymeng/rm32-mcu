`timescale 1ns / 1ps

module top (
    input  wire XCLK,
    input  wire XRSTn,
    input  wire SWCLK,
    inout  wire SWDIO,
    output wire TXD
);
    /* AHB-Lite clock signal */
    reg         HCLK;
    reg [31: 0] xclk_prescaler_count;

    always @(posedge XCLK or negedge XRSTn) begin
        if (!XRSTn) begin
            HCLK                 <= 1'b0;
            xclk_prescaler_count <= 32'b0;
        end else begin
            if (xclk_prescaler_count == 32'd1) begin
                HCLK                 <= ~HCLK;
                xclk_prescaler_count <= 32'b0;
            end else begin
                xclk_prescaler_count <= xclk_prescaler_count + 1;
            end
        end
    end

    /* AHB-Lite reset signal */
    reg  HRESETn;
    wire PORESETn;
    wire DBGRESETn;
    wire SYSRESETREQ;

    assign PORESETn  = XRSTn;
    assign DBGRESETn = XRSTn;

    always @(posedge HCLK or negedge XRSTn) begin
        if (!XRSTn) begin
            HRESETn <= 1'b0;
        end else if (SYSRESETREQ) begin
            HRESETn <= 1'b0;
        end else begin
            HRESETn <= 1'b1;
        end
    end

    /* AHB-Lite master signal */
    wire [31: 0] HADDR_master;
    wire [31: 0] HWDATA_master;
    wire         HWRITE_master;
    wire  [1: 0] HTRANS_master;
    wire  [2: 0] HSIZE_master;
    wire  [2: 0] HBURST_master;
    wire  [3: 0] HPROT_master;
    wire         HMASTLOCK_master;
    wire         HMASTER_master;
    wire [31: 0] HRDATA_master;
    wire         HREADY_master;
    wire         HRESP_master;

    /* SWD port sub-system */
    wire SWDI;
    wire SWDO;
    wire SWDOEN;

    assign SWDI  = SWDIO;
    assign SWDIO = (SWDOEN) ? SWDO : 1'bz;

    /* PMU sub-system */
    wire CDBGPWRUPREQ;
    reg  CDBGPWRUPACK;

    always @(posedge HCLK or negedge XRSTn) begin
        if (!XRSTn) begin
            CDBGPWRUPACK <= 1'b0;
        end else begin
            CDBGPWRUPACK <= CDBGPWRUPREQ;
        end
    end

    /* Interrupt sub-system */
    wire [31: 0] IRQ;
    wire         RXEV;

    assign IRQ  = 32'b0;
    assign RXEV = 1'b0;

    /* ARM Cortex-M0 sub-system */
    CORTEXM0INTEGRATION core1 (
        .FCLK          (HCLK),
        .SCLK          (HCLK),
        .HCLK          (HCLK),
        .DCLK          (HCLK),
        .PORESETn      (PORESETn),
        .HRESETn       (HRESETn),
        .DBGRESETn     (DBGRESETn),
        .RSTBYPASS     (1'b0),
        .SE            (1'b0),
        .SLEEPHOLDREQn (1'b1),
        .WICENREQ      (1'b0),
        .CDBGPWRUPACK  (CDBGPWRUPACK),
        .CDBGPWRUPREQ  (CDBGPWRUPREQ),
        .SYSRESETREQ   (SYSRESETREQ),
        .HADDR         (HADDR_master),
        .HTRANS        (HTRANS_master),
        .HSIZE         (HSIZE_master),
        .HBURST        (HBURST_master),
        .HPROT         (HPROT_master),
        .HMASTER       (HMASTER_master),
        .HMASTLOCK     (HMASTLOCK_master),
        .HWRITE        (HWRITE_master),
        .HWDATA        (HWDATA_master),
        .HRDATA        (HRDATA_master),
        .HREADY        (HREADY_master),
        .HRESP         (HRESP_master),
        .IRQ           (IRQ),
        .NMI           (1'b0),
        .IRQLATENCY    (8'h0),
        .ECOREVNUM     (28'h0),
        .STCLKEN       (1'b1),
        .STCALIB       (26'h0),
        .nTRST         (1'b1),
        .SWDITMS       (SWDI),
        .SWCLKTCK      (SWCLK),
        .TDI           (1'b0),
        .SWDO          (SWDO),
        .SWDOEN        (SWDOEN),
        .DBGRESTART    (1'b0),
        .RXEV          (RXEV),
        .EDBGRQ        (1'b0)
    );

    /* AHB-Lite slave device 0 signal */
    wire         HSEL_slave0;
    wire [31: 0] HADDR_slave0;
    wire [31: 0] HWDATA_slave0;
    wire         HWRITE_slave0;
    wire  [1: 0] HTRANS_slave0;
    wire  [2: 0] HSIZE_slave0;
    wire         HREADY_slave0;
    wire  [2: 0] HBURST_slave0;
    wire  [3: 0] HPROT_slave0;
    wire         HMASTLOCK_slave0;
    wire [31: 0] HRDATA_slave0;
    wire         HREADYOUT_slave0;
    wire         HRESP_slave0;

    /* AHB-Lite slave device 1 signal */
    wire         HSEL_slave1;
    wire [31: 0] HADDR_slave1;
    wire [31: 0] HWDATA_slave1;
    wire         HWRITE_slave1;
    wire  [1: 0] HTRANS_slave1;
    wire  [2: 0] HSIZE_slave1;
    wire         HREADY_slave1;
    wire  [2: 0] HBURST_slave1;
    wire  [3: 0] HPROT_slave1;
    wire         HMASTLOCK_slave1;
    wire [31: 0] HRDATA_slave1;
    wire         HREADYOUT_slave1;
    wire         HRESP_slave1;

    /* AHB-Lite slave device 2 signal */
    wire         HSEL_slave2;
    wire [31: 0] HADDR_slave2;
    wire [31: 0] HWDATA_slave2;
    wire         HWRITE_slave2;
    wire  [1: 0] HTRANS_slave2;
    wire  [2: 0] HSIZE_slave2;
    wire         HREADY_slave2;
    wire  [2: 0] HBURST_slave2;
    wire  [3: 0] HPROT_slave2;
    wire         HMASTLOCK_slave2;
    wire [31: 0] HRDATA_slave2;
    wire         HREADYOUT_slave2;
    wire         HRESP_slave2;

    /* Bus matrix */
    ahb_lite_bus_matrix bus_matrix (
        .HCLK             (HCLK),
        .HRESETn          (HRESETn),

        .HADDR_master     (HADDR_master),
        .HWDATA_master    (HWDATA_master),
        .HWRITE_master    (HWRITE_master),
        .HTRANS_master    (HTRANS_master),
        .HSIZE_master     (HSIZE_master),
        .HBURST_master    (HBURST_master),
        .HPROT_master     (HPROT_master),
        .HMASTLOCK_master (HMASTLOCK_master),
        .HRDATA_master    (HRDATA_master),
        .HREADY_master    (HREADY_master),
        .HRESP_master     (HRESP_master),

        .HSEL_slave0      (HSEL_slave0),
        .HADDR_slave0     (HADDR_slave0),
        .HWDATA_slave0    (HWDATA_slave0),
        .HWRITE_slave0    (HWRITE_slave0),
        .HTRANS_slave0    (HTRANS_slave0),
        .HSIZE_slave0     (HSIZE_slave0),
        .HREADY_slave0    (HREADY_slave0),
        .HBURST_slave0    (HBURST_slave0),
        .HPROT_slave0     (HPROT_slave0),
        .HMASTLOCK_slave0 (HMASTLOCK_slave0),
        .HRDATA_slave0    (HRDATA_slave0),
        .HREADYOUT_slave0 (HREADYOUT_slave0),
        .HRESP_slave0     (HRESP_slave0),

        .HSEL_slave1      (HSEL_slave1),
        .HADDR_slave1     (HADDR_slave1),
        .HWDATA_slave1    (HWDATA_slave1),
        .HWRITE_slave1    (HWRITE_slave1),
        .HTRANS_slave1    (HTRANS_slave1),
        .HSIZE_slave1     (HSIZE_slave1),
        .HREADY_slave1    (HREADY_slave1),
        .HBURST_slave1    (HBURST_slave1),
        .HPROT_slave1     (HPROT_slave1),
        .HMASTLOCK_slave1 (HMASTLOCK_slave1),
        .HRDATA_slave1    (HRDATA_slave1),
        .HREADYOUT_slave1 (HREADYOUT_slave1),
        .HRESP_slave1     (HRESP_slave1),

        .HSEL_slave2      (HSEL_slave2),
        .HADDR_slave2     (HADDR_slave2),
        .HWDATA_slave2    (HWDATA_slave2),
        .HWRITE_slave2    (HWRITE_slave2),
        .HTRANS_slave2    (HTRANS_slave2),
        .HSIZE_slave2     (HSIZE_slave2),
        .HREADY_slave2    (HREADY_slave2),
        .HBURST_slave2    (HBURST_slave2),
        .HPROT_slave2     (HPROT_slave2),
        .HMASTLOCK_slave2 (HMASTLOCK_slave2),
        .HRDATA_slave2    (HRDATA_slave2),
        .HREADYOUT_slave2 (HREADYOUT_slave2),
        .HRESP_slave2     (HRESP_slave2)
    );

    /* AHB-Lite slave device 0: OCSRAM 1 */
    bram #(
        .MEMORY_UNIT_ADDRESS_LINE_WIDTH (11)
    ) ocsram1 (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HSEL      (HSEL_slave0),
        .HADDR     (HADDR_slave0),
        .HWDATA    (HWDATA_slave0),
        .HWRITE    (HWRITE_slave0),
        .HTRANS    (HTRANS_slave0),
        .HSIZE     (HSIZE_slave0),
        .HREADY    (HREADY_slave0),
        .HBURST    (HBURST_slave0),
        .HPROT     (HPROT_slave0),
        .HMASTLOCK (HMASTLOCK_slave0),
        .HRDATA    (HRDATA_slave0),
        .HREADYOUT (HREADYOUT_slave0),
        .HRESP     (HRESP_slave0)
    );

    /* AHB-Lite slave device 1: OCSRAM 2 */
    bram #(
        .MEMORY_UNIT_ADDRESS_LINE_WIDTH (11)
    ) ocsram2 (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HSEL      (HSEL_slave1),
        .HADDR     (HADDR_slave1),
        .HWDATA    (HWDATA_slave1),
        .HWRITE    (HWRITE_slave1),
        .HTRANS    (HTRANS_slave1),
        .HSIZE     (HSIZE_slave1),
        .HREADY    (HREADY_slave1),
        .HBURST    (HBURST_slave1),
        .HPROT     (HPROT_slave1),
        .HMASTLOCK (HMASTLOCK_slave1),
        .HRDATA    (HRDATA_slave1),
        .HREADYOUT (HREADYOUT_slave1),
        .HRESP     (HRESP_slave1)
    );

    uart uart1 (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .HSEL      (HSEL_slave2),
        .HADDR     (HADDR_slave2),
        .HWDATA    (HWDATA_slave2),
        .HWRITE    (HWRITE_slave2),
        .HTRANS    (HTRANS_slave2),
        .HSIZE     (HSIZE_slave2),
        .HREADY    (HREADY_slave2),
        .HBURST    (HBURST_slave2),
        .HPROT     (HPROT_slave2),
        .HMASTLOCK (HMASTLOCK_slave2),
        .HRDATA    (HRDATA_slave2),
        .HREADYOUT (HREADYOUT_slave2),
        .HRESP     (HRESP_slave2),
        .txd_o     (TXD)
    );

endmodule
