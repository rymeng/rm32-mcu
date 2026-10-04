`timescale 1ns / 1ps

module rcc_core (
/* AHB-Lite master */
    input  wire hclk_master_i,
    input  wire hreset_n_master_i,
/* AHB slave device 01 (Flash Model Main Bank) */
    output wire hclk_slave01_o,
    output wire hreset_n_slave01_o,
/* AHB slave device 02 (SRAM Model) */
    output wire hclk_slave02_o,
    output wire hreset_n_slave02_o,
/* AHB slave device 03 (GPIO A) */
    input  wire gpioa_enable_i,
    input  wire gpioa_rst_n_i,
    output wire hclk_slave03_o,
    output wire hreset_n_slave03_o,
/* AHB slave device 04 (GPIO B) */
    input  wire gpiob_enable_i,
    input  wire gpiob_rst_n_i,
    output wire hclk_slave04_o,
    output wire hreset_n_slave04_o,
/* AHB slave device 05 (UART 1) */
    input  wire uart1_enable_i,
    input  wire uart1_rst_n_i,
    output wire hclk_slave05_o,
    output wire hreset_n_slave05_o,
/* AHB slave device 06 (UART 2) */
    input  wire uart2_enable_i,
    input  wire uart2_rst_n_i,
    output wire hclk_slave06_o,
    output wire hreset_n_slave06_o,
/* AHB slave device 07 (TUART 1) */
    input  wire tuart1_enable_i,
    input  wire tuart1_rst_n_i,
    output wire hclk_slave07_o,
    output wire hreset_n_slave07_o,
/* AHB slave device 08 (FMC) */
    output wire hclk_slave08_o,
    output wire hreset_n_slave08_o
);
    /* Output always-on clocks for each slave */
    assign hclk_slave01_o = hclk_master_i;
    assign hclk_slave02_o = hclk_master_i;
    assign hclk_slave03_o = hclk_master_i;
    assign hclk_slave04_o = hclk_master_i;
    assign hclk_slave05_o = hclk_master_i;
    assign hclk_slave06_o = hclk_master_i;
    assign hclk_slave07_o = hclk_master_i;
    assign hclk_slave08_o = hclk_master_i;

    /* Generate reset requests for each slave */
    reg gpioa_rst_n;
    reg gpiob_rst_n;
    reg uart1_rst_n;
    reg uart2_rst_n;
    reg tuart1_rst_n;

    always @(posedge hclk_master_i or negedge hreset_n_master_i) begin
        if (!hreset_n_master_i) begin
            gpioa_rst_n <= 1'b0;
            gpiob_rst_n <= 1'b0;
            uart1_rst_n <= 1'b0;
            uart2_rst_n <= 1'b0;
            tuart1_rst_n <= 1'b0;
        end else begin
            gpioa_rst_n <= gpioa_rst_n_i;
            gpiob_rst_n <= gpiob_rst_n_i;
            uart1_rst_n <= uart1_rst_n_i;
            uart2_rst_n <= uart2_rst_n_i;
            tuart1_rst_n <= tuart1_rst_n_i;
        end
    end

    /* Output reset signals for each slave */
    assign hreset_n_slave01_o = hreset_n_master_i;
    assign hreset_n_slave02_o = hreset_n_master_i;
    assign hreset_n_slave03_o = gpioa_rst_n;
    assign hreset_n_slave04_o = gpiob_rst_n;
    assign hreset_n_slave05_o = uart1_rst_n;
    assign hreset_n_slave06_o = uart2_rst_n;
    assign hreset_n_slave07_o = tuart1_rst_n;
    assign hreset_n_slave08_o = hreset_n_master_i;
endmodule
