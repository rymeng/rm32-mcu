`timescale 1ns / 1ps

module rcc_core (
/* AHB-Lite master */
    input  wire        hclk_master_i,
    input  wire        hreset_n_master_i,
/* AHB slave device 01 (Flash Main Bank Model Block 1) */
    output wire        hclk_slave01_o,
    output wire        hreset_n_slave01_o,
/* AHB slave device 02 (Flash Main Bank Model Block 2) */
    output wire        hclk_slave02_o,
    output wire        hreset_n_slave02_o,
/* AHB slave device 03 (Flash Main Bank Model Block 3) */
    output wire        hclk_slave03_o,
    output wire        hreset_n_slave03_o,
/* AHB slave device 04 (Flash Main Bank Model Block 4) */
    output wire        hclk_slave04_o,
    output wire        hreset_n_slave04_o,
/* AHB slave device 05 (Flash Option Byte Bank Model) */
    output wire        hclk_slave05_o,
    output wire        hreset_n_slave05_o,
/* AHB slave device 06 (IRAM Block 1) */
    output wire        hclk_slave06_o,
    output wire        hreset_n_slave06_o,
/* AHB slave device 07 (IRAM Block 2) */
    output wire        hclk_slave07_o,
    output wire        hreset_n_slave07_o,
/* AHB slave device 08 (IRAM Block 3) */
    output wire        hclk_slave08_o,
    output wire        hreset_n_slave08_o,
/* AHB slave device 09 (IRAM Block 4) */
    output wire        hclk_slave09_o,
    output wire        hreset_n_slave09_o,
/* AHB slave device 10 (GPIO A) */
    input  wire        gpioa_enable_i,
    input  wire        gpioa_rst_i,
    output wire        hclk_slave10_o,
    output wire        hreset_n_slave10_o,
/* AHB slave device 11 (GPIO B) */
    input  wire        gpiob_enable_i,
    input  wire        gpiob_rst_i,
    output wire        hclk_slave11_o,
    output wire        hreset_n_slave11_o,
/* AHB slave device 12 (UART 1) */
    input  wire        uart1_enable_i,
    input  wire        uart1_rst_i,
    output wire        hclk_slave12_o,
    output wire        hreset_n_slave12_o,
/* AHB slave device 13 (UART 2) */
    input  wire        uart2_enable_i,
    input  wire        uart2_rst_i,
    output wire        hclk_slave13_o,
    output wire        hreset_n_slave13_o,
/* AHB slave device 14 (TUART 1) */
    input  wire        tuart1_enable_i,
    input  wire        tuart1_rst_i,
    output wire        hclk_slave14_o,
    output wire        hreset_n_slave14_o
);

    /* Output perpherial clock (always-on) */
    assign hclk_slave01_o = hclk_master_i;
    assign hclk_slave02_o = hclk_master_i;
    assign hclk_slave03_o = hclk_master_i;
    assign hclk_slave04_o = hclk_master_i;
    assign hclk_slave05_o = hclk_master_i;
    assign hclk_slave06_o = hclk_master_i;
    assign hclk_slave07_o = hclk_master_i;
    assign hclk_slave08_o = hclk_master_i;
    assign hclk_slave09_o = hclk_master_i;
    assign hclk_slave10_o = hclk_master_i;
    assign hclk_slave11_o = hclk_master_i;
    assign hclk_slave12_o = hclk_master_i;
    assign hclk_slave13_o = hclk_master_i;
    assign hclk_slave14_o = hclk_master_i;

    /* Output perpherial reset signal */
    assign hreset_n_slave01_o = hreset_n_master_i;
    assign hreset_n_slave02_o = hreset_n_master_i;
    assign hreset_n_slave03_o = hreset_n_master_i;
    assign hreset_n_slave04_o = hreset_n_master_i;
    assign hreset_n_slave05_o = hreset_n_master_i;
    assign hreset_n_slave06_o = hreset_n_master_i;
    assign hreset_n_slave07_o = hreset_n_master_i;
    assign hreset_n_slave08_o = hreset_n_master_i;
    assign hreset_n_slave09_o = hreset_n_master_i;
    assign hreset_n_slave10_o = (~gpioa_rst_i) & hreset_n_master_i;
    assign hreset_n_slave11_o = (~gpiob_rst_i) & hreset_n_master_i;
    assign hreset_n_slave12_o = (~uart1_rst_i) & hreset_n_master_i;
    assign hreset_n_slave13_o = (~uart2_rst_i) & hreset_n_master_i;
    assign hreset_n_slave14_o = (~tuart1_rst_i) & hreset_n_master_i;

    (* DONT_TOUCH = "true" *) wire gpioa_enable_dummy_load;
    (* DONT_TOUCH = "true" *) wire gpiob_enable_dummy_load;
    (* DONT_TOUCH = "true" *) wire uart1_enable_dummy_load;
    (* DONT_TOUCH = "true" *) wire uart2_enable_dummy_load;
    (* DONT_TOUCH = "true" *) wire tuart1_enable_dummy_load;
    assign gpioa_enable_dummy_load = gpioa_enable_i;
    assign gpiob_enable_dummy_load = gpiob_enable_i;
    assign uart1_enable_dummy_load = uart1_enable_i;
    assign uart2_enable_dummy_load = uart2_enable_i;
    assign tuart1_enable_dummy_load = tuart1_enable_i;

endmodule
