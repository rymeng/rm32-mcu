`timescale 1ns / 1ps

module top (
    input wire        xclk_i,
    input wire        xrst_n_i,
    input wire        swclk_i,
    inout wire        swdio_io,
    inout wire [15:0] port_a_io,
    inout wire [15:0] port_b_io
);
    /* AHB-Lite master clock signal */
    reg hclk;

    always @ (*) begin
        hclk = xclk_i;
    end

    /* AHB-Lite master reset signal */
    reg  hreset_n;
    wire power_on_rst_n;
    wire debug_rst_n;
    wire system_rst_req;
    wire rst_bypass_enabled;

    assign power_on_rst_n = xrst_n_i;
    assign debug_rst_n = xrst_n_i;
    assign rst_bypass_enabled = 1'b0;

    always @(posedge hclk or negedge xrst_n_i) begin
        if (!xrst_n_i) begin
            hreset_n <= 1'b0;
        end else if (system_rst_req) begin
            hreset_n <= 1'b0;
        end else begin
            hreset_n <= 1'b1;
        end
    end

    /* Debug port sub-system */
    wire swdi;
    wire swdo;
    wire swdo_enabled;
    wire ntrst;
    wire tdi;
    wire debug_restart;
    wire external_debug_req;

    assign swdi = swdio_io;
    assign swdio_io = (swdo_enabled) ? swdo : 1'bz;
    assign ntrst = 1'b1;
    assign tdi = 1'b0;
    assign debug_restart = 1'b0;
    assign external_debug_req = 1'b0;

    /* PMU sub-system */
    wire sleep_hold_req_n;
    wire wic_enabled_req;
    wire core_debug_power_up_req;
    wire core_debug_power_up_ack;
    (* ASYNC_REG = "TRUE" *) reg core_debug_power_up_req_sync1;
    (* ASYNC_REG = "TRUE" *) reg core_debug_power_up_req_sync2;

    always @(posedge hclk or negedge xrst_n_i) begin
        if (!xrst_n_i) begin
            core_debug_power_up_req_sync1 <= 1'b0;
            core_debug_power_up_req_sync2 <= 1'b0;
        end else begin
            core_debug_power_up_req_sync1 <= core_debug_power_up_req;
            core_debug_power_up_req_sync2 <= core_debug_power_up_req_sync1;
        end
    end

    assign core_debug_power_up_ack = core_debug_power_up_req_sync2;
    assign sleep_hold_req_n = 1'b1;
    assign wic_enabled_req  = 1'b1;

    /* Interrupt sub-system */
    wire [31:0] interrupt_req;
    wire  [7:0] interrupt_req_latency;
    wire        non_maskable_interrupt;
    wire        rx_event;

    assign interrupt_req = 32'b0;
    assign interrupt_req_latency = 8'b0;
    assign rx_event = 1'b0;
    assign non_maskable_interrupt = 1'b0;

    /* SysTick sub-system */
    wire        systick_enabled;
    wire [25:0] systick_calibration;

    assign systick_enabled = 1'b0;
    assign systick_calibration = 26'b0;

    /* Scan mode sub-system */
    wire scan_enabled;

    assign scan_enabled = 1'b0;

    /* ECO information */
    wire [27:0] eco_rev;

    assign eco_rev = 28'b0;

    /* AHB-Lite master signal */
    wire [31:0] haddr_master;
    wire [31:0] hwdata_master;
    wire        hwrite_master;
    wire  [1:0] htrans_master;
    wire  [2:0] hsize_master;
    wire  [2:0] hburst_master;
    wire  [3:0] hprot_master;
    wire        hmastlock_master;
    wire [31:0] hrdata_master;
    wire        hready_master;
    wire        hresp_master;

    /* ARM Cortex-M0 sub-system */
    CORTEXM0INTEGRATION core1 (
        .FCLK          (hclk),
        .SCLK          (hclk),
        .HCLK          (hclk),
        .DCLK          (hclk),
        .PORESETn      (power_on_rst_n),
        .DBGRESETn     (debug_rst_n),
        .HRESETn       (hreset_n),
        .SWCLKTCK      (swclk_i),
        .nTRST         (ntrst),
        .HADDR         (haddr_master),
        .HBURST        (hburst_master),
        .HMASTLOCK     (hmastlock_master),
        .HPROT         (hprot_master),
        .HSIZE         (hsize_master),
        .HTRANS        (htrans_master),
        .HWDATA        (hwdata_master),
        .HWRITE        (hwrite_master),
        .HRDATA        (hrdata_master),
        .HREADY        (hready_master),
        .HRESP         (hresp_master),
        .HMASTER       (),
        .CODENSEQ      (),
        .CODEHINTDE    (),
        .SPECHTRANS    (),
        .SWDITMS       (swdi),
        .TDI           (tdi),
        .SWDO          (swdo),
        .SWDOEN        (swdo_enabled),
        .TDO           (),
        .nTDOEN        (),
        .DBGRESTART    (debug_restart),
        .DBGRESTARTED  (),
        .EDBGRQ        (external_debug_req),
        .HALTED        (),
        .NMI           (non_maskable_interrupt),
        .IRQ           (interrupt_req),
        .TXEV          (),
        .RXEV          (rx_event),
        .LOCKUP        (),
        .SYSRESETREQ   (system_rst_req),
        .STCLKEN       (systick_enabled),
        .STCALIB       (systick_calibration),
        .IRQLATENCY    (interrupt_req_latency),
        .ECOREVNUM     (eco_rev),
        .GATEHCLK      (),
        .SLEEPING      (),
        .SLEEPDEEP     (),
        .WAKEUP        (),
        .WICSENSE      (),
        .SLEEPHOLDREQn (sleep_hold_req_n),
        .SLEEPHOLDACKn (),
        .WICENREQ      (wic_enabled_req),
        .WICENACK      (),
        .CDBGPWRUPREQ  (core_debug_power_up_req),
        .CDBGPWRUPACK  (core_debug_power_up_ack),
        .SE            (scan_enabled),
        .RSTBYPASS     (rst_bypass_enabled)
    );

    /* IOMUX sub-system */
    wire        uart1_txd;
    wire        uart1_rxd;
    wire        uart1_swap;
    wire        uart2_txd;
    wire        uart2_rxd;
    wire        uart2_swap;
    wire        tuart1_txd;
    wire        tuart1_rxd;
    wire        tuart1_swap;
    wire  [3:0] gpioa_pin00_alternate_number;
    wire  [3:0] gpioa_pin01_alternate_number;
    wire  [3:0] gpioa_pin02_alternate_number;
    wire  [3:0] gpioa_pin03_alternate_number;
    wire  [3:0] gpioa_pin04_alternate_number;
    wire  [3:0] gpioa_pin05_alternate_number;
    wire  [3:0] gpioa_pin06_alternate_number;
    wire  [3:0] gpioa_pin07_alternate_number;
    wire  [3:0] gpioa_pin08_alternate_number;
    wire  [3:0] gpioa_pin09_alternate_number;
    wire  [3:0] gpioa_pin10_alternate_number;
    wire  [3:0] gpioa_pin11_alternate_number;
    wire  [3:0] gpioa_pin12_alternate_number;
    wire  [3:0] gpioa_pin13_alternate_number;
    wire  [3:0] gpioa_pin14_alternate_number;
    wire  [3:0] gpioa_pin15_alternate_number;
    wire [15:0] gpioa_afio_enabled;
    wire [15:0] gpioa_afio_output_enabled;
    wire [15:0] gpioa_afio_output_data;
    wire [15:0] gpioa_afio_input_data;
    wire  [3:0] gpiob_pin00_alternate_number;
    wire  [3:0] gpiob_pin01_alternate_number;
    wire  [3:0] gpiob_pin02_alternate_number;
    wire  [3:0] gpiob_pin03_alternate_number;
    wire  [3:0] gpiob_pin04_alternate_number;
    wire  [3:0] gpiob_pin05_alternate_number;
    wire  [3:0] gpiob_pin06_alternate_number;
    wire  [3:0] gpiob_pin07_alternate_number;
    wire  [3:0] gpiob_pin08_alternate_number;
    wire  [3:0] gpiob_pin09_alternate_number;
    wire  [3:0] gpiob_pin10_alternate_number;
    wire  [3:0] gpiob_pin11_alternate_number;
    wire  [3:0] gpiob_pin12_alternate_number;
    wire  [3:0] gpiob_pin13_alternate_number;
    wire  [3:0] gpiob_pin14_alternate_number;
    wire  [3:0] gpiob_pin15_alternate_number;
    wire [15:0] gpiob_afio_enabled;
    wire [15:0] gpiob_afio_output_enabled;
    wire [15:0] gpiob_afio_output_data;
    wire [15:0] gpiob_afio_input_data;

    iomux_top iomux (
        .gpioa_pin00_alternate_number_i (gpioa_pin00_alternate_number),
        .gpioa_pin01_alternate_number_i (gpioa_pin01_alternate_number),
        .gpioa_pin02_alternate_number_i (gpioa_pin02_alternate_number),
        .gpioa_pin03_alternate_number_i (gpioa_pin03_alternate_number),
        .gpioa_pin04_alternate_number_i (gpioa_pin04_alternate_number),
        .gpioa_pin05_alternate_number_i (gpioa_pin05_alternate_number),
        .gpioa_pin06_alternate_number_i (gpioa_pin06_alternate_number),
        .gpioa_pin07_alternate_number_i (gpioa_pin07_alternate_number),
        .gpioa_pin08_alternate_number_i (gpioa_pin08_alternate_number),
        .gpioa_pin09_alternate_number_i (gpioa_pin09_alternate_number),
        .gpioa_pin10_alternate_number_i (gpioa_pin10_alternate_number),
        .gpioa_pin11_alternate_number_i (gpioa_pin11_alternate_number),
        .gpioa_pin12_alternate_number_i (gpioa_pin12_alternate_number),
        .gpioa_pin13_alternate_number_i (gpioa_pin13_alternate_number),
        .gpioa_pin14_alternate_number_i (gpioa_pin14_alternate_number),
        .gpioa_pin15_alternate_number_i (gpioa_pin15_alternate_number),
        .gpiob_pin00_alternate_number_i (gpiob_pin00_alternate_number),
        .gpiob_pin01_alternate_number_i (gpiob_pin01_alternate_number),
        .gpiob_pin02_alternate_number_i (gpiob_pin02_alternate_number),
        .gpiob_pin03_alternate_number_i (gpiob_pin03_alternate_number),
        .gpiob_pin04_alternate_number_i (gpiob_pin04_alternate_number),
        .gpiob_pin05_alternate_number_i (gpiob_pin05_alternate_number),
        .gpiob_pin06_alternate_number_i (gpiob_pin06_alternate_number),
        .gpiob_pin07_alternate_number_i (gpiob_pin07_alternate_number),
        .gpiob_pin08_alternate_number_i (gpiob_pin08_alternate_number),
        .gpiob_pin09_alternate_number_i (gpiob_pin09_alternate_number),
        .gpiob_pin10_alternate_number_i (gpiob_pin10_alternate_number),
        .gpiob_pin11_alternate_number_i (gpiob_pin11_alternate_number),
        .gpiob_pin12_alternate_number_i (gpiob_pin12_alternate_number),
        .gpiob_pin13_alternate_number_i (gpiob_pin13_alternate_number),
        .gpiob_pin14_alternate_number_i (gpiob_pin14_alternate_number),
        .gpiob_pin15_alternate_number_i (gpiob_pin15_alternate_number),
        .gpioa_afio_enabled_o           (gpioa_afio_enabled),
        .gpioa_afio_output_enabled_o    (gpioa_afio_output_enabled),
        .gpioa_afio_output_data_o       (gpioa_afio_output_data),
        .gpioa_afio_input_data_i        (gpioa_afio_input_data),
        .gpiob_afio_enabled_o           (gpiob_afio_enabled),
        .gpiob_afio_output_enabled_o    (gpiob_afio_output_enabled),
        .gpiob_afio_output_data_o       (gpiob_afio_output_data),
        .gpiob_afio_input_data_i        (gpiob_afio_input_data),
        .uart1_swap_i                   (uart1_swap),
        .uart1_txd_i                    (uart1_txd),
        .uart1_rxd_o                    (uart1_rxd),
        .uart2_swap_i                   (uart2_swap),
        .uart2_txd_i                    (uart2_txd),
        .uart2_rxd_o                    (uart2_rxd),
        .tuart1_swap_i                  (tuart1_swap),
        .tuart1_txd_i                   (tuart1_txd),
        .tuart1_rxd_o                   (tuart1_rxd)
    );

    /* AHB slave device 01 (Flash Main Bank Model Block 1) signal */
    wire        hclk_slave01;
    wire        hreset_n_slave01;
    wire        hsel_slave01;
    wire [31:0] haddr_slave01;
    wire [31:0] hwdata_slave01;
    wire        hwrite_slave01;
    wire  [1:0] htrans_slave01;
    wire  [2:0] hsize_slave01;
    wire        hready_slave01;
    wire  [2:0] hburst_slave01;
    wire  [3:0] hprot_slave01;
    wire        hmastlock_slave01;
    wire [31:0] hrdata_slave01;
    wire        hreadyout_slave01;
    wire        hresp_slave01;

    bram_top #(.ADDR_WIDTH (12)) flash_main_bank_model_block1 (
        .hclk_i      (hclk_slave01),
        .hreset_n_i  (hreset_n_slave01),
        .hsel_i      (hsel_slave01),
        .haddr_i     (haddr_slave01),
        .hwdata_i    (hwdata_slave01),
        .hwrite_i    (hwrite_slave01),
        .htrans_i    (htrans_slave01),
        .hsize_i     (hsize_slave01),
        .hready_i    (hready_slave01),
        .hburst_i    (hburst_slave01),
        .hprot_i     (hprot_slave01),
        .hmastlock_i (hmastlock_slave01),
        .hrdata_o    (hrdata_slave01),
        .hreadyout_o (hreadyout_slave01),
        .hresp_o     (hresp_slave01)
    );

    /* AHB slave device 02 (Flash Main Bank Model Block 2) signal */
    wire        hclk_slave02;
    wire        hreset_n_slave02;
    wire        hsel_slave02;
    wire [31:0] haddr_slave02;
    wire [31:0] hwdata_slave02;
    wire        hwrite_slave02;
    wire  [1:0] htrans_slave02;
    wire  [2:0] hsize_slave02;
    wire        hready_slave02;
    wire  [2:0] hburst_slave02;
    wire  [3:0] hprot_slave02;
    wire        hmastlock_slave02;
    wire [31:0] hrdata_slave02;
    wire        hreadyout_slave02;
    wire        hresp_slave02;

    bram_top #(.ADDR_WIDTH (12)) flash_main_bank_model_block2 (
        .hclk_i      (hclk_slave02),
        .hreset_n_i  (hreset_n_slave02),
        .hsel_i      (hsel_slave02),
        .haddr_i     (haddr_slave02),
        .hwdata_i    (hwdata_slave02),
        .hwrite_i    (hwrite_slave02),
        .htrans_i    (htrans_slave02),
        .hsize_i     (hsize_slave02),
        .hready_i    (hready_slave02),
        .hburst_i    (hburst_slave02),
        .hprot_i     (hprot_slave02),
        .hmastlock_i (hmastlock_slave02),
        .hrdata_o    (hrdata_slave02),
        .hreadyout_o (hreadyout_slave02),
        .hresp_o     (hresp_slave02)
    );

    /* AHB slave device 03 (Flash Main Bank Model Block 3) signal */
    wire        hclk_slave03;
    wire        hreset_n_slave03;
    wire        hsel_slave03;
    wire [31:0] haddr_slave03;
    wire [31:0] hwdata_slave03;
    wire        hwrite_slave03;
    wire  [1:0] htrans_slave03;
    wire  [2:0] hsize_slave03;
    wire        hready_slave03;
    wire  [2:0] hburst_slave03;
    wire  [3:0] hprot_slave03;
    wire        hmastlock_slave03;
    wire [31:0] hrdata_slave03;
    wire        hreadyout_slave03;
    wire        hresp_slave03;

    bram_top #(.ADDR_WIDTH (12)) flash_main_bank_model_block3 (
        .hclk_i      (hclk_slave03),
        .hreset_n_i  (hreset_n_slave03),
        .hsel_i      (hsel_slave03),
        .haddr_i     (haddr_slave03),
        .hwdata_i    (hwdata_slave03),
        .hwrite_i    (hwrite_slave03),
        .htrans_i    (htrans_slave03),
        .hsize_i     (hsize_slave03),
        .hready_i    (hready_slave03),
        .hburst_i    (hburst_slave03),
        .hprot_i     (hprot_slave03),
        .hmastlock_i (hmastlock_slave03),
        .hrdata_o    (hrdata_slave03),
        .hreadyout_o (hreadyout_slave03),
        .hresp_o     (hresp_slave03)
    );

    /* AHB slave device 04 (Flash Main Bank Model Block 4) signal */
    wire        hclk_slave04;
    wire        hreset_n_slave04;
    wire        hsel_slave04;
    wire [31:0] haddr_slave04;
    wire [31:0] hwdata_slave04;
    wire        hwrite_slave04;
    wire  [1:0] htrans_slave04;
    wire  [2:0] hsize_slave04;
    wire        hready_slave04;
    wire  [2:0] hburst_slave04;
    wire  [3:0] hprot_slave04;
    wire        hmastlock_slave04;
    wire [31:0] hrdata_slave04;
    wire        hreadyout_slave04;
    wire        hresp_slave04;

    bram_top #(.ADDR_WIDTH (12)) flash_main_bank_model_block4 (
        .hclk_i      (hclk_slave04),
        .hreset_n_i  (hreset_n_slave04),
        .hsel_i      (hsel_slave04),
        .haddr_i     (haddr_slave04),
        .hwdata_i    (hwdata_slave04),
        .hwrite_i    (hwrite_slave04),
        .htrans_i    (htrans_slave04),
        .hsize_i     (hsize_slave04),
        .hready_i    (hready_slave04),
        .hburst_i    (hburst_slave04),
        .hprot_i     (hprot_slave04),
        .hmastlock_i (hmastlock_slave04),
        .hrdata_o    (hrdata_slave04),
        .hreadyout_o (hreadyout_slave04),
        .hresp_o     (hresp_slave04)
    );

    /* AHB slave device 05 (Flash Option Byte Model) signal */
    wire        hclk_slave05;
    wire        hreset_n_slave05;
    wire        hsel_slave05;
    wire [31:0] haddr_slave05;
    wire [31:0] hwdata_slave05;
    wire        hwrite_slave05;
    wire  [1:0] htrans_slave05;
    wire  [2:0] hsize_slave05;
    wire        hready_slave05;
    wire  [2:0] hburst_slave05;
    wire  [3:0] hprot_slave05;
    wire        hmastlock_slave05;
    wire [31:0] hrdata_slave05;
    wire        hreadyout_slave05;
    wire        hresp_slave05;

    bram_top #(.ADDR_WIDTH (8)) flash_option_byte_bank_model (
        .hclk_i      (hclk_slave05),
        .hreset_n_i  (hreset_n_slave05),
        .hsel_i      (hsel_slave05),
        .haddr_i     (haddr_slave05),
        .hwdata_i    (hwdata_slave05),
        .hwrite_i    (hwrite_slave05),
        .htrans_i    (htrans_slave05),
        .hsize_i     (hsize_slave05),
        .hready_i    (hready_slave05),
        .hburst_i    (hburst_slave05),
        .hprot_i     (hprot_slave05),
        .hmastlock_i (hmastlock_slave05),
        .hrdata_o    (hrdata_slave05),
        .hreadyout_o (hreadyout_slave05),
        .hresp_o     (hresp_slave05)
    );

    /* AHB slave device 06 (IRAM 1 Block 1) signal */
    wire        hclk_slave06;
    wire        hreset_n_slave06;
    wire        hsel_slave06;
    wire [31:0] haddr_slave06;
    wire [31:0] hwdata_slave06;
    wire        hwrite_slave06;
    wire  [1:0] htrans_slave06;
    wire  [2:0] hsize_slave06;
    wire        hready_slave06;
    wire  [2:0] hburst_slave06;
    wire  [3:0] hprot_slave06;
    wire        hmastlock_slave06;
    wire [31:0] hrdata_slave06;
    wire        hreadyout_slave06;
    wire        hresp_slave06;

    bram_top #(.ADDR_WIDTH (12)) iram1_block1 (
        .hclk_i      (hclk_slave06),
        .hreset_n_i  (hreset_n_slave06),
        .hsel_i      (hsel_slave06),
        .haddr_i     (haddr_slave06),
        .hwdata_i    (hwdata_slave06),
        .hwrite_i    (hwrite_slave06),
        .htrans_i    (htrans_slave06),
        .hsize_i     (hsize_slave06),
        .hready_i    (hready_slave06),
        .hburst_i    (hburst_slave06),
        .hprot_i     (hprot_slave06),
        .hmastlock_i (hmastlock_slave06),
        .hrdata_o    (hrdata_slave06),
        .hreadyout_o (hreadyout_slave06),
        .hresp_o     (hresp_slave06)
    );

    /* AHB slave device 07 (IRAM 1 Block 2) signal */
    wire        hclk_slave07;
    wire        hreset_n_slave07;
    wire        hsel_slave07;
    wire [31:0] haddr_slave07;
    wire [31:0] hwdata_slave07;
    wire        hwrite_slave07;
    wire  [1:0] htrans_slave07;
    wire  [2:0] hsize_slave07;
    wire        hready_slave07;
    wire  [2:0] hburst_slave07;
    wire  [3:0] hprot_slave07;
    wire        hmastlock_slave07;
    wire [31:0] hrdata_slave07;
    wire        hreadyout_slave07;
    wire        hresp_slave07;

    bram_top #(.ADDR_WIDTH (12)) iram1_block2 (
        .hclk_i      (hclk_slave07),
        .hreset_n_i  (hreset_n_slave07),
        .hsel_i      (hsel_slave07),
        .haddr_i     (haddr_slave07),
        .hwdata_i    (hwdata_slave07),
        .hwrite_i    (hwrite_slave07),
        .htrans_i    (htrans_slave07),
        .hsize_i     (hsize_slave07),
        .hready_i    (hready_slave07),
        .hburst_i    (hburst_slave07),
        .hprot_i     (hprot_slave07),
        .hmastlock_i (hmastlock_slave07),
        .hrdata_o    (hrdata_slave07),
        .hreadyout_o (hreadyout_slave07),
        .hresp_o     (hresp_slave07)
    );

    /* AHB slave device 08 (IRAM 1 Block 3) signal */
    wire        hclk_slave08;
    wire        hreset_n_slave08;
    wire        hsel_slave08;
    wire [31:0] haddr_slave08;
    wire [31:0] hwdata_slave08;
    wire        hwrite_slave08;
    wire  [1:0] htrans_slave08;
    wire  [2:0] hsize_slave08;
    wire        hready_slave08;
    wire  [2:0] hburst_slave08;
    wire  [3:0] hprot_slave08;
    wire        hmastlock_slave08;
    wire [31:0] hrdata_slave08;
    wire        hreadyout_slave08;
    wire        hresp_slave08;

    bram_top #(.ADDR_WIDTH (12)) iram1_block3 (
        .hclk_i      (hclk_slave08),
        .hreset_n_i  (hreset_n_slave08),
        .hsel_i      (hsel_slave08),
        .haddr_i     (haddr_slave08),
        .hwdata_i    (hwdata_slave08),
        .hwrite_i    (hwrite_slave08),
        .htrans_i    (htrans_slave08),
        .hsize_i     (hsize_slave08),
        .hready_i    (hready_slave08),
        .hburst_i    (hburst_slave08),
        .hprot_i     (hprot_slave08),
        .hmastlock_i (hmastlock_slave08),
        .hrdata_o    (hrdata_slave08),
        .hreadyout_o (hreadyout_slave08),
        .hresp_o     (hresp_slave08)
    );

    /* AHB slave device 09 (IRAM 1 Block 4) signal */
    wire        hclk_slave09;
    wire        hreset_n_slave09;
    wire        hsel_slave09;
    wire [31:0] haddr_slave09;
    wire [31:0] hwdata_slave09;
    wire        hwrite_slave09;
    wire  [1:0] htrans_slave09;
    wire  [2:0] hsize_slave09;
    wire        hready_slave09;
    wire  [2:0] hburst_slave09;
    wire  [3:0] hprot_slave09;
    wire        hmastlock_slave09;
    wire [31:0] hrdata_slave09;
    wire        hreadyout_slave09;
    wire        hresp_slave09;

    bram_top #(.ADDR_WIDTH (12)) iram1_block4 (
        .hclk_i      (hclk_slave09),
        .hreset_n_i  (hreset_n_slave09),
        .hsel_i      (hsel_slave09),
        .haddr_i     (haddr_slave09),
        .hwdata_i    (hwdata_slave09),
        .hwrite_i    (hwrite_slave09),
        .htrans_i    (htrans_slave09),
        .hsize_i     (hsize_slave09),
        .hready_i    (hready_slave09),
        .hburst_i    (hburst_slave09),
        .hprot_i     (hprot_slave09),
        .hmastlock_i (hmastlock_slave09),
        .hrdata_o    (hrdata_slave09),
        .hreadyout_o (hreadyout_slave09),
        .hresp_o     (hresp_slave09)
    );

    /* AHB slave device 10 (GPIO A) signal */
    wire        hclk_slave10;
    wire        hreset_n_slave10;
    wire        hsel_slave10;
    wire [31:0] haddr_slave10;
    wire [31:0] hwdata_slave10;
    wire        hwrite_slave10;
    wire  [1:0] htrans_slave10;
    wire  [2:0] hsize_slave10;
    wire        hready_slave10;
    wire  [2:0] hburst_slave10;
    wire  [3:0] hprot_slave10;
    wire        hmastlock_slave10;
    wire [31:0] hrdata_slave10;
    wire        hreadyout_slave10;
    wire        hresp_slave10;

    gpio_top gpioa (
        .hclk_i                   (hclk_slave10),
        .hreset_n_i               (hreset_n_slave10),
        .hsel_i                   (hsel_slave10),
        .haddr_i                  (haddr_slave10),
        .hwdata_i                 (hwdata_slave10),
        .hwrite_i                 (hwrite_slave10),
        .htrans_i                 (htrans_slave10),
        .hsize_i                  (hsize_slave10),
        .hready_i                 (hready_slave10),
        .hburst_i                 (hburst_slave10),
        .hprot_i                  (hprot_slave10),
        .hmastlock_i              (hmastlock_slave10),
        .hrdata_o                 (hrdata_slave10),
        .hreadyout_o              (hreadyout_slave10),
        .hresp_o                  (hresp_slave10),
        .pin00_alternate_number_o (gpioa_pin00_alternate_number),
        .pin01_alternate_number_o (gpioa_pin01_alternate_number),
        .pin02_alternate_number_o (gpioa_pin02_alternate_number),
        .pin03_alternate_number_o (gpioa_pin03_alternate_number),
        .pin04_alternate_number_o (gpioa_pin04_alternate_number),
        .pin05_alternate_number_o (gpioa_pin05_alternate_number),
        .pin06_alternate_number_o (gpioa_pin06_alternate_number),
        .pin07_alternate_number_o (gpioa_pin07_alternate_number),
        .pin08_alternate_number_o (gpioa_pin08_alternate_number),
        .pin09_alternate_number_o (gpioa_pin09_alternate_number),
        .pin10_alternate_number_o (gpioa_pin10_alternate_number),
        .pin11_alternate_number_o (gpioa_pin11_alternate_number),
        .pin12_alternate_number_o (gpioa_pin12_alternate_number),
        .pin13_alternate_number_o (gpioa_pin13_alternate_number),
        .pin14_alternate_number_o (gpioa_pin14_alternate_number),
        .pin15_alternate_number_o (gpioa_pin15_alternate_number),
        .afio_enabled_i           (gpioa_afio_enabled),
        .afio_output_enabled_i    (gpioa_afio_output_enabled),
        .afio_output_data_i       (gpioa_afio_output_data),
        .afio_input_data_o        (gpioa_afio_input_data),
        .pin_io                   (port_a_io)
    );

    /* AHB slave device 11 (GPIO B) signal */
    wire        hclk_slave11;
    wire        hreset_n_slave11;
    wire        hsel_slave11;
    wire [31:0] haddr_slave11;
    wire [31:0] hwdata_slave11;
    wire        hwrite_slave11;
    wire  [1:0] htrans_slave11;
    wire  [2:0] hsize_slave11;
    wire        hready_slave11;
    wire  [2:0] hburst_slave11;
    wire  [3:0] hprot_slave11;
    wire        hmastlock_slave11;
    wire [31:0] hrdata_slave11;
    wire        hreadyout_slave11;
    wire        hresp_slave11;

    gpio_top gpiob (
        .hclk_i                   (hclk_slave11),
        .hreset_n_i               (hreset_n_slave11),
        .hsel_i                   (hsel_slave11),
        .haddr_i                  (haddr_slave11),
        .hwdata_i                 (hwdata_slave11),
        .hwrite_i                 (hwrite_slave11),
        .htrans_i                 (htrans_slave11),
        .hsize_i                  (hsize_slave11),
        .hready_i                 (hready_slave11),
        .hburst_i                 (hburst_slave11),
        .hprot_i                  (hprot_slave11),
        .hmastlock_i              (hmastlock_slave11),
        .hrdata_o                 (hrdata_slave11),
        .hreadyout_o              (hreadyout_slave11),
        .hresp_o                  (hresp_slave11),
        .pin00_alternate_number_o (gpiob_pin00_alternate_number),
        .pin01_alternate_number_o (gpiob_pin01_alternate_number),
        .pin02_alternate_number_o (gpiob_pin02_alternate_number),
        .pin03_alternate_number_o (gpiob_pin03_alternate_number),
        .pin04_alternate_number_o (gpiob_pin04_alternate_number),
        .pin05_alternate_number_o (gpiob_pin05_alternate_number),
        .pin06_alternate_number_o (gpiob_pin06_alternate_number),
        .pin07_alternate_number_o (gpiob_pin07_alternate_number),
        .pin08_alternate_number_o (gpiob_pin08_alternate_number),
        .pin09_alternate_number_o (gpiob_pin09_alternate_number),
        .pin10_alternate_number_o (gpiob_pin10_alternate_number),
        .pin11_alternate_number_o (gpiob_pin11_alternate_number),
        .pin12_alternate_number_o (gpiob_pin12_alternate_number),
        .pin13_alternate_number_o (gpiob_pin13_alternate_number),
        .pin14_alternate_number_o (gpiob_pin14_alternate_number),
        .pin15_alternate_number_o (gpiob_pin15_alternate_number),
        .afio_enabled_i           (gpiob_afio_enabled),
        .afio_output_enabled_i    (gpiob_afio_output_enabled),
        .afio_output_data_i       (gpiob_afio_output_data),
        .afio_input_data_o        (gpiob_afio_input_data),
        .pin_io                   (port_b_io)
    );

    /* AHB slave device 12 (UART 1) signal */
    wire        hclk_slave12;
    wire        hreset_n_slave12;
    wire        hsel_slave12;
    wire [31:0] haddr_slave12;
    wire [31:0] hwdata_slave12;
    wire        hwrite_slave12;
    wire  [1:0] htrans_slave12;
    wire  [2:0] hsize_slave12;
    wire        hready_slave12;
    wire  [2:0] hburst_slave12;
    wire  [3:0] hprot_slave12;
    wire        hmastlock_slave12;
    wire [31:0] hrdata_slave12;
    wire        hreadyout_slave12;
    wire        hresp_slave12;

    tuart_top uart1 (
        .hclk_i      (hclk_slave12),
        .hreset_n_i  (hreset_n_slave12),
        .hsel_i      (hsel_slave12),
        .haddr_i     (haddr_slave12),
        .hwdata_i    (hwdata_slave12),
        .hwrite_i    (hwrite_slave12),
        .htrans_i    (htrans_slave12),
        .hsize_i     (hsize_slave12),
        .hready_i    (hready_slave12),
        .hburst_i    (hburst_slave12),
        .hprot_i     (hprot_slave12),
        .hmastlock_i (hmastlock_slave12),
        .hrdata_o    (hrdata_slave12),
        .hreadyout_o (hreadyout_slave12),
        .hresp_o     (hresp_slave12),
        .txd_o       (uart1_txd),
        .rxd_i       (uart1_rxd),
        .swap_o      (uart1_swap)
    );

    /* AHB slave device 13 (UART 2) signal */
    wire        hclk_slave13;
    wire        hreset_n_slave13;
    wire        hsel_slave13;
    wire [31:0] haddr_slave13;
    wire [31:0] hwdata_slave13;
    wire        hwrite_slave13;
    wire  [1:0] htrans_slave13;
    wire  [2:0] hsize_slave13;
    wire        hready_slave13;
    wire  [2:0] hburst_slave13;
    wire  [3:0] hprot_slave13;
    wire        hmastlock_slave13;
    wire [31:0] hrdata_slave13;
    wire        hreadyout_slave13;
    wire        hresp_slave13;

    tuart_top uart2 (
        .hclk_i      (hclk_slave13),
        .hreset_n_i  (hreset_n_slave13),
        .hsel_i      (hsel_slave13),
        .haddr_i     (haddr_slave13),
        .hwdata_i    (hwdata_slave13),
        .hwrite_i    (hwrite_slave13),
        .htrans_i    (htrans_slave13),
        .hsize_i     (hsize_slave13),
        .hready_i    (hready_slave13),
        .hburst_i    (hburst_slave13),
        .hprot_i     (hprot_slave13),
        .hmastlock_i (hmastlock_slave13),
        .hrdata_o    (hrdata_slave13),
        .hreadyout_o (hreadyout_slave13),
        .hresp_o     (hresp_slave13),
        .txd_o       (uart2_txd),
        .rxd_i       (uart2_rxd),
        .swap_o      (uart2_swap)
    );

    /* AHB slave device 14 (TUART 1) signal */
    wire        hclk_slave14;
    wire        hreset_n_slave14;
    wire        hsel_slave14;
    wire [31:0] haddr_slave14;
    wire [31:0] hwdata_slave14;
    wire        hwrite_slave14;
    wire  [1:0] htrans_slave14;
    wire  [2:0] hsize_slave14;
    wire        hready_slave14;
    wire  [2:0] hburst_slave14;
    wire  [3:0] hprot_slave14;
    wire        hmastlock_slave14;
    wire [31:0] hrdata_slave14;
    wire        hreadyout_slave14;
    wire        hresp_slave14;

    tuart_top tuart1 (
        .hclk_i      (hclk_slave14),
        .hreset_n_i  (hreset_n_slave14),
        .hsel_i      (hsel_slave14),
        .haddr_i     (haddr_slave14),
        .hwdata_i    (hwdata_slave14),
        .hwrite_i    (hwrite_slave14),
        .htrans_i    (htrans_slave14),
        .hsize_i     (hsize_slave14),
        .hready_i    (hready_slave14),
        .hburst_i    (hburst_slave14),
        .hprot_i     (hprot_slave14),
        .hmastlock_i (hmastlock_slave14),
        .hrdata_o    (hrdata_slave14),
        .hreadyout_o (hreadyout_slave14),
        .hresp_o     (hresp_slave14),
        .txd_o       (tuart1_txd),
        .rxd_i       (tuart1_rxd),
        .swap_o      (tuart1_swap)
    );

    /* AHB slave device 00 (RCC) */
    wire        hsel_slave00;
    wire [31:0] haddr_slave00;
    wire [31:0] hwdata_slave00;
    wire        hwrite_slave00;
    wire  [1:0] htrans_slave00;
    wire  [2:0] hsize_slave00;
    wire        hready_slave00;
    wire  [2:0] hburst_slave00;
    wire  [3:0] hprot_slave00;
    wire        hmastlock_slave00;
    wire [31:0] hrdata_slave00;
    wire        hreadyout_slave00;
    wire        hresp_slave00;

    rcc_top rcc (
        .hclk_i             (hclk),
        .hreset_n_i         (hreset_n),
        .hsel_i             (hsel_slave00),
        .haddr_i            (haddr_slave00),
        .hwdata_i           (hwdata_slave00),
        .hwrite_i           (hwrite_slave00),
        .htrans_i           (htrans_slave00),
        .hsize_i            (hsize_slave00),
        .hready_i           (hready_slave00),
        .hburst_i           (hburst_slave00),
        .hprot_i            (hprot_slave00),
        .hmastlock_i        (hmastlock_slave00),
        .hrdata_o           (hrdata_slave00),
        .hreadyout_o        (hreadyout_slave00),
        .hresp_o            (hresp_slave00),

        .hclk_slave01_o     (hclk_slave01),
        .hreset_n_slave01_o (hreset_n_slave01),
        .hclk_slave02_o     (hclk_slave02),
        .hreset_n_slave02_o (hreset_n_slave02),
        .hclk_slave03_o     (hclk_slave03),
        .hreset_n_slave03_o (hreset_n_slave03),
        .hclk_slave04_o     (hclk_slave04),
        .hreset_n_slave04_o (hreset_n_slave04),
        .hclk_slave05_o     (hclk_slave05),
        .hreset_n_slave05_o (hreset_n_slave05),
        .hclk_slave06_o     (hclk_slave06),
        .hreset_n_slave06_o (hreset_n_slave06),
        .hclk_slave07_o     (hclk_slave07),
        .hreset_n_slave07_o (hreset_n_slave07),
        .hclk_slave08_o     (hclk_slave08),
        .hreset_n_slave08_o (hreset_n_slave08),
        .hclk_slave09_o     (hclk_slave09),
        .hreset_n_slave09_o (hreset_n_slave09),
        .hclk_slave10_o     (hclk_slave10),
        .hreset_n_slave10_o (hreset_n_slave10),
        .hclk_slave11_o     (hclk_slave11),
        .hreset_n_slave11_o (hreset_n_slave11),
        .hclk_slave12_o     (hclk_slave12),
        .hreset_n_slave12_o (hreset_n_slave12),
        .hclk_slave13_o     (hclk_slave13),
        .hreset_n_slave13_o (hreset_n_slave13),
        .hclk_slave14_o     (hclk_slave14),
        .hreset_n_slave14_o (hreset_n_slave14)
    );

    /* Bus matrix */
    bus_matrix_top bus_matrix (
        .hclk_master_i       (hclk),
        .hreset_master_n_i   (hreset_n),
        .haddr_master_i      (haddr_master),
        .hwdata_master_i     (hwdata_master),
        .hwrite_master_i     (hwrite_master),
        .htrans_master_i     (htrans_master),
        .hsize_master_i      (hsize_master),
        .hburst_master_i     (hburst_master),
        .hprot_master_i      (hprot_master),
        .hmastlock_master_i  (hmastlock_master),
        .hrdata_master_o     (hrdata_master),
        .hready_master_o     (hready_master),
        .hresp_master_o      (hresp_master),

        .hsel_slave00_o      (hsel_slave00),
        .haddr_slave00_o     (haddr_slave00),
        .hwdata_slave00_o    (hwdata_slave00),
        .hwrite_slave00_o    (hwrite_slave00),
        .htrans_slave00_o    (htrans_slave00),
        .hsize_slave00_o     (hsize_slave00),
        .hready_slave00_o    (hready_slave00),
        .hburst_slave00_o    (hburst_slave00),
        .hprot_slave00_o     (hprot_slave00),
        .hmastlock_slave00_o (hmastlock_slave00),
        .hrdata_slave00_i    (hrdata_slave00),
        .hreadyout_slave00_i (hreadyout_slave00),
        .hresp_slave00_i     (hresp_slave00),

        .hsel_slave01_o      (hsel_slave01),
        .haddr_slave01_o     (haddr_slave01),
        .hwdata_slave01_o    (hwdata_slave01),
        .hwrite_slave01_o    (hwrite_slave01),
        .htrans_slave01_o    (htrans_slave01),
        .hsize_slave01_o     (hsize_slave01),
        .hready_slave01_o    (hready_slave01),
        .hburst_slave01_o    (hburst_slave01),
        .hprot_slave01_o     (hprot_slave01),
        .hmastlock_slave01_o (hmastlock_slave01),
        .hrdata_slave01_i    (hrdata_slave01),
        .hreadyout_slave01_i (hreadyout_slave01),
        .hresp_slave01_i     (hresp_slave01),

        .hsel_slave02_o      (hsel_slave02),
        .haddr_slave02_o     (haddr_slave02),
        .hwdata_slave02_o    (hwdata_slave02),
        .hwrite_slave02_o    (hwrite_slave02),
        .htrans_slave02_o    (htrans_slave02),
        .hsize_slave02_o     (hsize_slave02),
        .hready_slave02_o    (hready_slave02),
        .hburst_slave02_o    (hburst_slave02),
        .hprot_slave02_o     (hprot_slave02),
        .hmastlock_slave02_o (hmastlock_slave02),
        .hrdata_slave02_i    (hrdata_slave02),
        .hreadyout_slave02_i (hreadyout_slave02),
        .hresp_slave02_i     (hresp_slave02),

        .hsel_slave03_o      (hsel_slave03),
        .haddr_slave03_o     (haddr_slave03),
        .hwdata_slave03_o    (hwdata_slave03),
        .hwrite_slave03_o    (hwrite_slave03),
        .htrans_slave03_o    (htrans_slave03),
        .hsize_slave03_o     (hsize_slave03),
        .hready_slave03_o    (hready_slave03),
        .hburst_slave03_o    (hburst_slave03),
        .hprot_slave03_o     (hprot_slave03),
        .hmastlock_slave03_o (hmastlock_slave03),
        .hrdata_slave03_i    (hrdata_slave03),
        .hreadyout_slave03_i (hreadyout_slave03),
        .hresp_slave03_i     (hresp_slave03),

        .hsel_slave04_o      (hsel_slave04),
        .haddr_slave04_o     (haddr_slave04),
        .hwdata_slave04_o    (hwdata_slave04),
        .hwrite_slave04_o    (hwrite_slave04),
        .htrans_slave04_o    (htrans_slave04),
        .hsize_slave04_o     (hsize_slave04),
        .hready_slave04_o    (hready_slave04),
        .hburst_slave04_o    (hburst_slave04),
        .hprot_slave04_o     (hprot_slave04),
        .hmastlock_slave04_o (hmastlock_slave04),
        .hrdata_slave04_i    (hrdata_slave04),
        .hreadyout_slave04_i (hreadyout_slave04),
        .hresp_slave04_i     (hresp_slave04),

        .hsel_slave05_o      (hsel_slave05),
        .haddr_slave05_o     (haddr_slave05),
        .hwdata_slave05_o    (hwdata_slave05),
        .hwrite_slave05_o    (hwrite_slave05),
        .htrans_slave05_o    (htrans_slave05),
        .hsize_slave05_o     (hsize_slave05),
        .hready_slave05_o    (hready_slave05),
        .hburst_slave05_o    (hburst_slave05),
        .hprot_slave05_o     (hprot_slave05),
        .hmastlock_slave05_o (hmastlock_slave05),
        .hrdata_slave05_i    (hrdata_slave05),
        .hreadyout_slave05_i (hreadyout_slave05),
        .hresp_slave05_i     (hresp_slave05),

        .hsel_slave06_o      (hsel_slave06),
        .haddr_slave06_o     (haddr_slave06),
        .hwdata_slave06_o    (hwdata_slave06),
        .hwrite_slave06_o    (hwrite_slave06),
        .htrans_slave06_o    (htrans_slave06),
        .hsize_slave06_o     (hsize_slave06),
        .hready_slave06_o    (hready_slave06),
        .hburst_slave06_o    (hburst_slave06),
        .hprot_slave06_o     (hprot_slave06),
        .hmastlock_slave06_o (hmastlock_slave06),
        .hrdata_slave06_i    (hrdata_slave06),
        .hreadyout_slave06_i (hreadyout_slave06),
        .hresp_slave06_i     (hresp_slave06),

        .hsel_slave07_o      (hsel_slave07),
        .haddr_slave07_o     (haddr_slave07),
        .hwdata_slave07_o    (hwdata_slave07),
        .hwrite_slave07_o    (hwrite_slave07),
        .htrans_slave07_o    (htrans_slave07),
        .hsize_slave07_o     (hsize_slave07),
        .hready_slave07_o    (hready_slave07),
        .hburst_slave07_o    (hburst_slave07),
        .hprot_slave07_o     (hprot_slave07),
        .hmastlock_slave07_o (hmastlock_slave07),
        .hrdata_slave07_i    (hrdata_slave07),
        .hreadyout_slave07_i (hreadyout_slave07),
        .hresp_slave07_i     (hresp_slave07),

        .hsel_slave08_o      (hsel_slave08),
        .haddr_slave08_o     (haddr_slave08),
        .hwdata_slave08_o    (hwdata_slave08),
        .hwrite_slave08_o    (hwrite_slave08),
        .htrans_slave08_o    (htrans_slave08),
        .hsize_slave08_o     (hsize_slave08),
        .hready_slave08_o    (hready_slave08),
        .hburst_slave08_o    (hburst_slave08),
        .hprot_slave08_o     (hprot_slave08),
        .hmastlock_slave08_o (hmastlock_slave08),
        .hrdata_slave08_i    (hrdata_slave08),
        .hreadyout_slave08_i (hreadyout_slave08),
        .hresp_slave08_i     (hresp_slave08),

        .hsel_slave09_o      (hsel_slave09),
        .haddr_slave09_o     (haddr_slave09),
        .hwdata_slave09_o    (hwdata_slave09),
        .hwrite_slave09_o    (hwrite_slave09),
        .htrans_slave09_o    (htrans_slave09),
        .hsize_slave09_o     (hsize_slave09),
        .hready_slave09_o    (hready_slave09),
        .hburst_slave09_o    (hburst_slave09),
        .hprot_slave09_o     (hprot_slave09),
        .hmastlock_slave09_o (hmastlock_slave09),
        .hrdata_slave09_i    (hrdata_slave09),
        .hreadyout_slave09_i (hreadyout_slave09),
        .hresp_slave09_i     (hresp_slave09),

        .hsel_slave10_o      (hsel_slave10),
        .haddr_slave10_o     (haddr_slave10),
        .hwdata_slave10_o    (hwdata_slave10),
        .hwrite_slave10_o    (hwrite_slave10),
        .htrans_slave10_o    (htrans_slave10),
        .hsize_slave10_o     (hsize_slave10),
        .hready_slave10_o    (hready_slave10),
        .hburst_slave10_o    (hburst_slave10),
        .hprot_slave10_o     (hprot_slave10),
        .hmastlock_slave10_o (hmastlock_slave10),
        .hrdata_slave10_i    (hrdata_slave10),
        .hreadyout_slave10_i (hreadyout_slave10),
        .hresp_slave10_i     (hresp_slave10),

        .hsel_slave11_o      (hsel_slave11),
        .haddr_slave11_o     (haddr_slave11),
        .hwdata_slave11_o    (hwdata_slave11),
        .hwrite_slave11_o    (hwrite_slave11),
        .htrans_slave11_o    (htrans_slave11),
        .hsize_slave11_o     (hsize_slave11),
        .hready_slave11_o    (hready_slave11),
        .hburst_slave11_o    (hburst_slave11),
        .hprot_slave11_o     (hprot_slave11),
        .hmastlock_slave11_o (hmastlock_slave11),
        .hrdata_slave11_i    (hrdata_slave11),
        .hreadyout_slave11_i (hreadyout_slave11),
        .hresp_slave11_i     (hresp_slave11),

        .hsel_slave12_o      (hsel_slave12),
        .haddr_slave12_o     (haddr_slave12),
        .hwdata_slave12_o    (hwdata_slave12),
        .hwrite_slave12_o    (hwrite_slave12),
        .htrans_slave12_o    (htrans_slave12),
        .hsize_slave12_o     (hsize_slave12),
        .hready_slave12_o    (hready_slave12),
        .hburst_slave12_o    (hburst_slave12),
        .hprot_slave12_o     (hprot_slave12),
        .hmastlock_slave12_o (hmastlock_slave12),
        .hrdata_slave12_i    (hrdata_slave12),
        .hreadyout_slave12_i (hreadyout_slave12),
        .hresp_slave12_i     (hresp_slave12),

        .hsel_slave13_o      (hsel_slave13),
        .haddr_slave13_o     (haddr_slave13),
        .hwdata_slave13_o    (hwdata_slave13),
        .hwrite_slave13_o    (hwrite_slave13),
        .htrans_slave13_o    (htrans_slave13),
        .hsize_slave13_o     (hsize_slave13),
        .hready_slave13_o    (hready_slave13),
        .hburst_slave13_o    (hburst_slave13),
        .hprot_slave13_o     (hprot_slave13),
        .hmastlock_slave13_o (hmastlock_slave13),
        .hrdata_slave13_i    (hrdata_slave13),
        .hreadyout_slave13_i (hreadyout_slave13),
        .hresp_slave13_i     (hresp_slave13),

        .hsel_slave14_o      (hsel_slave14),
        .haddr_slave14_o     (haddr_slave14),
        .hwdata_slave14_o    (hwdata_slave14),
        .hwrite_slave14_o    (hwrite_slave14),
        .htrans_slave14_o    (htrans_slave14),
        .hsize_slave14_o     (hsize_slave14),
        .hready_slave14_o    (hready_slave14),
        .hburst_slave14_o    (hburst_slave14),
        .hprot_slave14_o     (hprot_slave14),
        .hmastlock_slave14_o (hmastlock_slave14),
        .hrdata_slave14_i    (hrdata_slave14),
        .hreadyout_slave14_i (hreadyout_slave14),
        .hresp_slave14_i     (hresp_slave14)
    );
endmodule
