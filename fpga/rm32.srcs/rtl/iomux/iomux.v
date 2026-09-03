`timescale 1ns / 1ps

module iomux (
/* GPIO A alternate number */
    input  wire  [3: 0] gpioa_pin00_alternate_number_i,
    input  wire  [3: 0] gpioa_pin01_alternate_number_i,
    input  wire  [3: 0] gpioa_pin02_alternate_number_i,
    input  wire  [3: 0] gpioa_pin03_alternate_number_i,
    input  wire  [3: 0] gpioa_pin04_alternate_number_i,
    input  wire  [3: 0] gpioa_pin05_alternate_number_i,
    input  wire  [3: 0] gpioa_pin06_alternate_number_i,
    input  wire  [3: 0] gpioa_pin07_alternate_number_i,
    input  wire  [3: 0] gpioa_pin08_alternate_number_i,
    input  wire  [3: 0] gpioa_pin09_alternate_number_i,
    input  wire  [3: 0] gpioa_pin10_alternate_number_i,
    input  wire  [3: 0] gpioa_pin11_alternate_number_i,
    input  wire  [3: 0] gpioa_pin12_alternate_number_i,
    input  wire  [3: 0] gpioa_pin13_alternate_number_i,
    input  wire  [3: 0] gpioa_pin14_alternate_number_i,
    input  wire  [3: 0] gpioa_pin15_alternate_number_i,
/* GPIO B alternate number */
    input  wire  [3: 0] gpiob_pin00_alternate_number_i,
    input  wire  [3: 0] gpiob_pin01_alternate_number_i,
    input  wire  [3: 0] gpiob_pin02_alternate_number_i,
    input  wire  [3: 0] gpiob_pin03_alternate_number_i,
    input  wire  [3: 0] gpiob_pin04_alternate_number_i,
    input  wire  [3: 0] gpiob_pin05_alternate_number_i,
    input  wire  [3: 0] gpiob_pin06_alternate_number_i,
    input  wire  [3: 0] gpiob_pin07_alternate_number_i,
    input  wire  [3: 0] gpiob_pin08_alternate_number_i,
    input  wire  [3: 0] gpiob_pin09_alternate_number_i,
    input  wire  [3: 0] gpiob_pin10_alternate_number_i,
    input  wire  [3: 0] gpiob_pin11_alternate_number_i,
    input  wire  [3: 0] gpiob_pin12_alternate_number_i,
    input  wire  [3: 0] gpiob_pin13_alternate_number_i,
    input  wire  [3: 0] gpiob_pin14_alternate_number_i,
    input  wire  [3: 0] gpiob_pin15_alternate_number_i,
/* GPIO B AFIO signals */
    output reg  [15: 0] gpioa_afio_enabled_o,
    output reg  [15: 0] gpioa_afio_output_enabled_o,
    output reg  [15: 0] gpioa_afio_output_data_o,
    input  wire [15: 0] gpioa_afio_input_data_i,
/* GPIO B AFIO signals */
    output reg  [15: 0] gpiob_afio_enabled_o,
    output reg  [15: 0] gpiob_afio_output_enabled_o,
    output reg  [15: 0] gpiob_afio_output_data_o,
    input  wire [15: 0] gpiob_afio_input_data_i,
/* UART 1 */
    input  wire         uart1_swap_i,
    input  wire         uart1_txd_output_enabled_i,
    input  wire         uart1_rxd_output_enabled_i,
    input  wire         uart1_txd_i,
    output reg          uart1_rxd_o,
/* UART 2 */
    input  wire         uart2_swap_i,
    input  wire         uart2_txd_output_enabled_i,
    input  wire         uart2_rxd_output_enabled_i,
    input  wire         uart2_txd_i,
    output reg          uart2_rxd_o,
/* TUART 1 */
    input  wire         tuart1_swap_i,
    input  wire         tuart1_txd_output_enabled_i,
    input  wire         tuart1_rxd_output_enabled_i,
    input  wire         tuart1_txd_i,
    output reg          tuart1_rxd_o
);

    always @ (*) begin
        case (gpioa_pin00_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[0]          = 1'b0;
                gpioa_afio_output_enabled_o[0]   = 1'b0;
                gpioa_afio_output_data_o[0]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[0]          = 1'b1;
                gpioa_afio_output_enabled_o[0]   = uart1_txd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpioa_afio_output_data_o[0]  = uart1_txd_i;
                end else begin
                    gpioa_afio_output_data_o[0]  = 1'b0;
                end
            end

            4'hF: begin
                gpioa_afio_enabled_o[0]          = 1'b1;
                gpioa_afio_output_enabled_o[0]   = tuart1_txd_output_enabled_i;
                if (!tuart1_swap_i) begin
                    gpioa_afio_output_data_o[0]  = tuart1_txd_i;
                end else begin
                    gpioa_afio_output_data_o[0]  = 1'b0;
                end
            end

            default: begin
                gpioa_afio_enabled_o[0]          = 1'b0;
                gpioa_afio_output_enabled_o[0]   = 1'b0;
                gpioa_afio_output_data_o[0]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin01_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[1]          = 1'b0;
                gpioa_afio_output_enabled_o[1]   = 1'b0;
                gpioa_afio_output_data_o[1]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[1]          = 1'b1;
                gpioa_afio_output_enabled_o[1]   = uart1_rxd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpioa_afio_output_data_o[1]  = 1'b0;
                end else begin
                    gpioa_afio_output_data_o[1]  = uart1_txd_i;
                end
            end

            4'hF: begin
                gpioa_afio_enabled_o[1]          = 1'b1;
                gpioa_afio_output_enabled_o[1]   = tuart1_rxd_output_enabled_i;
                if (!tuart1_swap_i) begin
                    gpioa_afio_output_data_o[1]  = 1'b0;
                end else begin
                    gpioa_afio_output_data_o[1]  = tuart1_txd_i;
                end
            end

            default: begin
                gpioa_afio_enabled_o[1]          = 1'b0;
                gpioa_afio_output_enabled_o[1]   = 1'b0;
                gpioa_afio_output_data_o[1]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin02_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[2]          = 1'b0;
                gpioa_afio_output_enabled_o[2]   = 1'b0;
                gpioa_afio_output_data_o[2]      = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[2]          = 1'b0;
                gpioa_afio_output_enabled_o[2]   = 1'b0;
                gpioa_afio_output_data_o[2]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin03_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[3]          = 1'b0;
                gpioa_afio_output_enabled_o[3]   = 1'b0;
                gpioa_afio_output_data_o[3]      = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[3]          = 1'b0;
                gpioa_afio_output_enabled_o[3]   = 1'b0;
                gpioa_afio_output_data_o[3]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin04_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[4]          = 1'b0;
                gpioa_afio_output_enabled_o[4]   = 1'b0;
                gpioa_afio_output_data_o[4]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[4]          = 1'b1;
                gpioa_afio_output_enabled_o[4]   = uart2_txd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpioa_afio_output_data_o[4]  = uart2_txd_i;
                end else begin
                    gpioa_afio_output_data_o[4]  = 1'b0;
                end
            end

            default: begin
                gpioa_afio_enabled_o[4]          = 1'b0;
                gpioa_afio_output_enabled_o[4]   = 1'b0;
                gpioa_afio_output_data_o[4]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin05_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[5]          = 1'b0;
                gpioa_afio_output_enabled_o[5]   = 1'b0;
                gpioa_afio_output_data_o[5]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[5]          = 1'b1;
                gpioa_afio_output_enabled_o[5]   = uart2_rxd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpioa_afio_output_data_o[5]  = 1'b0;
                end else begin
                    gpioa_afio_output_data_o[5]  = uart2_txd_i;
                end
            end

            default: begin
                gpioa_afio_enabled_o[5]          = 1'b0;
                gpioa_afio_output_enabled_o[5]   = 1'b0;
                gpioa_afio_output_data_o[5]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin06_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[6]          = 1'b0;
                gpioa_afio_output_enabled_o[6]   = 1'b0;
                gpioa_afio_output_data_o[6]      = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[6]          = 1'b0;
                gpioa_afio_output_enabled_o[6]   = 1'b0;
                gpioa_afio_output_data_o[6]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin07_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[7]          = 1'b0;
                gpioa_afio_output_enabled_o[7]   = 1'b0;
                gpioa_afio_output_data_o[7]      = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[7]          = 1'b0;
                gpioa_afio_output_enabled_o[7]   = 1'b0;
                gpioa_afio_output_data_o[7]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin08_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[8]          = 1'b0;
                gpioa_afio_output_enabled_o[8]   = 1'b0;
                gpioa_afio_output_data_o[8]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[8]          = 1'b1;
                gpioa_afio_output_enabled_o[8]   = uart1_txd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpioa_afio_output_data_o[8]  = uart1_txd_i;
                end else begin
                    gpioa_afio_output_data_o[8]  = 1'b0;
                end
            end

            default: begin
                gpioa_afio_enabled_o[8]          = 1'b0;
                gpioa_afio_output_enabled_o[8]   = 1'b0;
                gpioa_afio_output_data_o[8]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin09_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[9]          = 1'b0;
                gpioa_afio_output_enabled_o[9]   = 1'b0;
                gpioa_afio_output_data_o[9]      = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[9]          = 1'b1;
                gpioa_afio_output_enabled_o[9]   = uart1_rxd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpioa_afio_output_data_o[9]  = 1'b0;
                end else begin
                    gpioa_afio_output_data_o[9]  = uart1_txd_i;
                end
            end

            default: begin
                gpioa_afio_enabled_o[9]          = 1'b0;
                gpioa_afio_output_enabled_o[9]   = 1'b0;
                gpioa_afio_output_data_o[9]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin10_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[10]         = 1'b0;
                gpioa_afio_output_enabled_o[10]  = 1'b0;
                gpioa_afio_output_data_o[10]     = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[10]         = 1'b0;
                gpioa_afio_output_enabled_o[10]  = 1'b0;
                gpioa_afio_output_data_o[10]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin11_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[11]         = 1'b0;
                gpioa_afio_output_enabled_o[11]  = 1'b0;
                gpioa_afio_output_data_o[11]     = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[11]         = 1'b0;
                gpioa_afio_output_enabled_o[11]  = 1'b0;
                gpioa_afio_output_data_o[11]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin12_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[12]         = 1'b0;
                gpioa_afio_output_enabled_o[12]  = 1'b0;
                gpioa_afio_output_data_o[12]     = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[12]         = 1'b1;
                gpioa_afio_output_enabled_o[12]  = uart2_txd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpioa_afio_output_data_o[12] = uart2_txd_i;
                end else begin
                    gpioa_afio_output_data_o[12] = 1'b0;
                end
            end

            default: begin
                gpioa_afio_enabled_o[12]         = 1'b0;
                gpioa_afio_output_enabled_o[12]  = 1'b0;
                gpioa_afio_output_data_o[12]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin13_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[13]         = 1'b0;
                gpioa_afio_output_enabled_o[13]  = 1'b0;
                gpioa_afio_output_data_o[13]     = 1'b0;
            end

            4'h1: begin
                gpioa_afio_enabled_o[13]         = 1'b1;
                gpioa_afio_output_enabled_o[13]  = uart2_rxd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpioa_afio_output_data_o[13] = 1'b0;
                end else begin
                    gpioa_afio_output_data_o[13] = uart2_txd_i;
                end
            end

            default: begin
                gpioa_afio_enabled_o[13]         = 1'b0;
                gpioa_afio_output_enabled_o[13]  = 1'b0;
                gpioa_afio_output_data_o[13]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin14_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[14]         = 1'b0;
                gpioa_afio_output_enabled_o[14]  = 1'b0;
                gpioa_afio_output_data_o[14]     = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[14]         = 1'b0;
                gpioa_afio_output_enabled_o[14]  = 1'b0;
                gpioa_afio_output_data_o[14]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpioa_pin15_alternate_number_i)
            4'h0: begin
                gpioa_afio_enabled_o[15]         = 1'b0;
                gpioa_afio_output_enabled_o[15]  = 1'b0;
                gpioa_afio_output_data_o[15]     = 1'b0;
            end

            default: begin
                gpioa_afio_enabled_o[15]         = 1'b0;
                gpioa_afio_output_enabled_o[15]  = 1'b0;
                gpioa_afio_output_data_o[15]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin00_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[0]          = 1'b0;
                gpiob_afio_output_enabled_o[0]   = 1'b0;
                gpiob_afio_output_data_o[0]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[0]          = 1'b0;
                gpiob_afio_output_enabled_o[0]   = 1'b0;
                gpiob_afio_output_data_o[0]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin01_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[1]          = 1'b0;
                gpiob_afio_output_enabled_o[1]   = 1'b0;
                gpiob_afio_output_data_o[1]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[1]          = 1'b0;
                gpiob_afio_output_enabled_o[1]   = 1'b0;
                gpiob_afio_output_data_o[1]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin02_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[2]          = 1'b0;
                gpiob_afio_output_enabled_o[2]   = 1'b0;
                gpiob_afio_output_data_o[2]      = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[2]          = 1'b1;
                gpiob_afio_output_enabled_o[2]   = uart2_txd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpiob_afio_output_data_o[2]  = uart2_txd_i;
                end else begin
                    gpiob_afio_output_data_o[2]  = 1'b0;
                end
            end

            default: begin
                gpiob_afio_enabled_o[2]          = 1'b0;
                gpiob_afio_output_enabled_o[2]   = 1'b0;
                gpiob_afio_output_data_o[2]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin03_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[3]          = 1'b0;
                gpiob_afio_output_enabled_o[3]   = 1'b0;
                gpiob_afio_output_data_o[3]      = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[3]          = 1'b1;
                gpiob_afio_output_enabled_o[3]   = uart2_rxd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpiob_afio_output_data_o[3]  = 1'b0;
                end else begin
                    gpiob_afio_output_data_o[3]  = uart2_txd_i;
                end
            end

            default: begin
                gpiob_afio_enabled_o[3]          = 1'b0;
                gpiob_afio_output_enabled_o[3]   = 1'b0;
                gpiob_afio_output_data_o[3]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin04_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[4]          = 1'b0;
                gpiob_afio_output_enabled_o[4]   = 1'b0;
                gpiob_afio_output_data_o[4]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[4]          = 1'b0;
                gpiob_afio_output_enabled_o[4]   = 1'b0;
                gpiob_afio_output_data_o[4]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin05_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[5]          = 1'b0;
                gpiob_afio_output_enabled_o[5]   = 1'b0;
                gpiob_afio_output_data_o[5]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[5]          = 1'b0;
                gpiob_afio_output_enabled_o[5]   = 1'b0;
                gpiob_afio_output_data_o[5]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin06_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[6]          = 1'b0;
                gpiob_afio_output_enabled_o[6]   = 1'b0;
                gpiob_afio_output_data_o[6]      = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[6]          = 1'b1;
                gpiob_afio_output_enabled_o[6]   = uart1_txd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpiob_afio_output_data_o[6]  = uart1_txd_i;
                end else begin
                    gpiob_afio_output_data_o[6]  = 1'b0;
                end
            end

            default: begin
                gpiob_afio_enabled_o[6]          = 1'b0;
                gpiob_afio_output_enabled_o[6]   = 1'b0;
                gpiob_afio_output_data_o[6]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin07_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[7]          = 1'b0;
                gpiob_afio_output_enabled_o[7]   = 1'b0;
                gpiob_afio_output_data_o[7]      = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[7]          = 1'b1;
                gpiob_afio_output_enabled_o[7]   = uart1_rxd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpiob_afio_output_data_o[7]  = 1'b0;
                end else begin
                    gpiob_afio_output_data_o[7]  = uart1_txd_i;
                end
            end

            default: begin
                gpiob_afio_enabled_o[7]          = 1'b0;
                gpiob_afio_output_enabled_o[7]   = 1'b0;
                gpiob_afio_output_data_o[7]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin08_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[8]          = 1'b0;
                gpiob_afio_output_enabled_o[8]   = 1'b0;
                gpiob_afio_output_data_o[8]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[8]          = 1'b0;
                gpiob_afio_output_enabled_o[8]   = 1'b0;
                gpiob_afio_output_data_o[8]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin09_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[9]          = 1'b0;
                gpiob_afio_output_enabled_o[9]   = 1'b0;
                gpiob_afio_output_data_o[9]      = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[9]          = 1'b0;
                gpiob_afio_output_enabled_o[9]   = 1'b0;
                gpiob_afio_output_data_o[9]      = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin10_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[10]         = 1'b0;
                gpiob_afio_output_enabled_o[10]  = 1'b0;
                gpiob_afio_output_data_o[10]     = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[10]         = 1'b1;
                gpiob_afio_output_enabled_o[10]  = uart2_txd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpiob_afio_output_data_o[10] = uart2_txd_i;
                end else begin
                    gpiob_afio_output_data_o[10] = 1'b0;
                end
            end

            default: begin
                gpiob_afio_enabled_o[10]         = 1'b0;
                gpiob_afio_output_enabled_o[10]  = 1'b0;
                gpiob_afio_output_data_o[10]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin11_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[11]         = 1'b0;
                gpiob_afio_output_enabled_o[11]  = 1'b0;
                gpiob_afio_output_data_o[11]     = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[11]         = 1'b1;
                gpiob_afio_output_enabled_o[11]  = uart2_rxd_output_enabled_i;
                if (!uart2_swap_i) begin
                    gpiob_afio_output_data_o[11] = 1'b0;
                end else begin
                    gpiob_afio_output_data_o[11] = uart2_txd_i;
                end
            end

            default: begin
                gpiob_afio_enabled_o[11]         = 1'b0;
                gpiob_afio_output_enabled_o[11]  = 1'b0;
                gpiob_afio_output_data_o[11]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin12_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[12]         = 1'b0;
                gpiob_afio_output_enabled_o[12]  = 1'b0;
                gpiob_afio_output_data_o[12]     = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[12]         = 1'b0;
                gpiob_afio_output_enabled_o[12]  = 1'b0;
                gpiob_afio_output_data_o[12]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin13_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[13]         = 1'b0;
                gpiob_afio_output_enabled_o[13]  = 1'b0;
                gpiob_afio_output_data_o[13]     = 1'b0;
            end

            default: begin
                gpiob_afio_enabled_o[13]         = 1'b0;
                gpiob_afio_output_enabled_o[13]  = 1'b0;
                gpiob_afio_output_data_o[13]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin14_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[14]         = 1'b0;
                gpiob_afio_output_enabled_o[14]  = 1'b0;
                gpiob_afio_output_data_o[14]     = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[14]         = 1'b1;
                gpiob_afio_output_enabled_o[14]  = uart1_txd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpiob_afio_output_data_o[14] = uart1_txd_i;
                end else begin
                    gpiob_afio_output_data_o[14] = 1'b0;
                end
            end

            4'hF: begin
                gpiob_afio_enabled_o[14]         = 1'b1;
                gpiob_afio_output_enabled_o[14]  = tuart1_txd_output_enabled_i;
                if (!tuart1_swap_i) begin
                    gpiob_afio_output_data_o[14] = tuart1_txd_i;
                end else begin
                    gpiob_afio_output_data_o[14] = 1'b0;
                end
            end

            default: begin
                gpiob_afio_enabled_o[14]         = 1'b0;
                gpiob_afio_output_enabled_o[14]  = 1'b0;
                gpiob_afio_output_data_o[14]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        case (gpiob_pin15_alternate_number_i)
            4'h0: begin
                gpiob_afio_enabled_o[15]         = 1'b0;
                gpiob_afio_output_enabled_o[15]  = 1'b0;
                gpiob_afio_output_data_o[15]     = 1'b0;
            end

            4'h1: begin
                gpiob_afio_enabled_o[15]         = 1'b1;
                gpiob_afio_output_enabled_o[15]  = uart1_rxd_output_enabled_i;
                if (!uart1_swap_i) begin
                    gpiob_afio_output_data_o[15] = 1'b0;
                end else begin
                    gpiob_afio_output_data_o[15] = uart1_txd_i;
                end
            end

            4'hF: begin
                gpiob_afio_enabled_o[15]         = 1'b1;
                gpiob_afio_output_enabled_o[15]  = tuart1_rxd_output_enabled_i;
                if (!tuart1_swap_i) begin
                    gpiob_afio_output_data_o[15] = 1'b0;
                end else begin
                    gpiob_afio_output_data_o[15] = tuart1_txd_i;
                end
            end

            default: begin
                gpiob_afio_enabled_o[15]         = 1'b0;
                gpiob_afio_output_enabled_o[15]  = 1'b0;
                gpiob_afio_output_data_o[15]     = 1'b0;
            end
        endcase
    end

    always @ (*) begin
        if (uart1_swap_i) begin
            if (gpioa_pin00_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpioa_afio_input_data_i[0];
            end else if (gpioa_pin08_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpioa_afio_input_data_i[8];
            end else if (gpiob_pin06_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpiob_afio_input_data_i[6];
            end else if (gpiob_pin14_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpiob_afio_input_data_i[14];
            end else begin
                uart1_rxd_o = 1'b1;
            end
        end else begin
            if (gpioa_pin01_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpioa_afio_input_data_i[1];
            end else if (gpioa_pin09_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpioa_afio_input_data_i[9];
            end else if (gpiob_pin07_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpiob_afio_input_data_i[7];
            end else if (gpiob_pin15_alternate_number_i == 4'h1) begin
                uart1_rxd_o = gpiob_afio_input_data_i[15];
            end else begin
                uart1_rxd_o = 1'b1;
            end
        end
    end

    always @ (*) begin
        if (uart2_swap_i) begin
            if (gpioa_pin04_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpioa_afio_input_data_i[4];
            end else if (gpioa_pin12_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpioa_afio_input_data_i[12];
            end else if (gpiob_pin02_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpiob_afio_input_data_i[2];
            end else if (gpiob_pin10_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpiob_afio_input_data_i[10];
            end else begin
                uart2_rxd_o = 1'b1;
            end
        end else begin
            if (gpioa_pin05_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpioa_afio_input_data_i[5];
            end else if (gpioa_pin13_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpioa_afio_input_data_i[13];
            end else if (gpiob_pin03_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpiob_afio_input_data_i[3];
            end else if (gpiob_pin11_alternate_number_i == 4'h1) begin
                uart2_rxd_o = gpiob_afio_input_data_i[11];
            end else begin
                uart2_rxd_o = 1'b1;
            end
        end
    end

    always @ (*) begin
        if (tuart1_swap_i) begin
            if (gpioa_pin00_alternate_number_i == 4'hF) begin
                tuart1_rxd_o = gpioa_afio_input_data_i[0];
            end else if (gpiob_pin14_alternate_number_i == 4'hF) begin
                tuart1_rxd_o = gpiob_afio_input_data_i[14];
            end else begin
                tuart1_rxd_o = 1'b1;
            end
        end else begin
            if (gpioa_pin01_alternate_number_i == 4'hF) begin
                tuart1_rxd_o = gpioa_afio_input_data_i[1];
            end else if (gpiob_pin15_alternate_number_i == 4'hF) begin
                tuart1_rxd_o = gpiob_afio_input_data_i[15];
            end else begin
                tuart1_rxd_o = 1'b1;
            end
        end
    end

endmodule
