`timescale 1ns / 1ps

module fmc_top (
/* AHB slave device interface */
    input  wire        hclk_i,
    input  wire        hreset_n_i,
    input  wire        hsel_i,
    input  wire [31:0] haddr_i,
    input  wire [31:0] hwdata_i,
    input  wire        hwrite_i,
    input  wire [1:0]  htrans_i,
    input  wire [2:0]  hsize_i,
    input  wire        hready_i,
    input  wire [2:0]  hburst_i,
    input  wire [3:0]  hprot_i,
    input  wire        hmastlock_i,
    output reg  [31:0] hrdata_o,
    output reg         hreadyout_o,
    output reg         hresp_o,
/* Flash model interface */
    input  wire        flash_model_busy_i,
    input  wire        flash_model_ops_done_i,
    input  wire        flash_model_program_precheck_err_i,
    input  wire        flash_model_program_unaligned_i,
    input  wire        flash_model_program_pending_i,
    output wire        flash_model_bank_erase_req_o,
    output wire        flash_model_sector_erase_req_o,
    output wire [5:0]  flash_model_sector_erase_sector_idx_o,
    output wire        flash_model_program_en_o
);
    /* Generate address phase valid flag */
    wire addr_valid;

    assign addr_valid = hsel_i & htrans_i[1] & hready_i;

    /* Generate transfer size valid flag */
    wire size_valid;

    assign size_valid = ~hsize_i[2];

    /* Generate transfer address valid (aligned) flag */
    wire addr_aligned;

    assign addr_aligned =
        (hsize_i == 3'b000) ? 1'b1 :
        (hsize_i == 3'b001) ? ~(haddr_i[0]) :
        (hsize_i == 3'b010) ? ~(|haddr_i[1:0]) : 1'b0;

    /* Generate read address phase occurrence flag */
    wire read_addr_phase;

    assign read_addr_phase = hsel_i & htrans_i[1] & size_valid & addr_aligned & ~hwrite_i;

    /* Generate transfer valid / error flags */
    wire xfer_valid;
    wire xfer_error;

    assign xfer_valid = addr_valid & size_valid & addr_aligned;
    assign xfer_error = addr_valid & ~xfer_valid;

    /* Generate read / write transfer flags */
    wire read_xfer_valid;
    wire write_xfer_valid;

    assign read_xfer_valid = xfer_valid & ~hwrite_i;
    assign write_xfer_valid = xfer_valid & hwrite_i;

    /* Generate byte lanes mask */
    reg [3:0] byte_mask;

    always @ (*) begin
        case (hsize_i)
            3'b000: begin
                byte_mask = 4'b0001 << haddr_i[1:0];
            end

            3'b001: begin
                byte_mask = 4'b0011 << haddr_i[1:0];
            end

            3'b010: begin
                byte_mask = 4'b1111;
            end

            default: begin
                byte_mask = 4'b0000;
            end
        endcase
    end

    /* Latch the index and byte mask at the end of address phase */
    reg        write_valid;
    reg [3:0]  write_mask;
    reg [7:0]  write_index;

    always @ (posedge hclk_i) begin
        write_valid <= write_xfer_valid;

        if (write_xfer_valid) begin
            write_mask <= byte_mask;
            write_index <= haddr_i[9:2];
        end
    end

    /* Generate read-write collision flag */
    wire read_write_xfer_collision;

    assign read_write_xfer_collision =
        read_addr_phase & write_valid & (write_index == haddr_i[9:2]);

    /* Registers */
    reg [31:0] acr;
    reg [31:0] keyr;
    reg [31:0] cr1;
    reg [31:0] cr2;
    reg [31:0] ar;
    reg [31:0] isr;

    /* FMC sub-system wire */
    wire fmc_locked;
    wire fmc_busy;
    wire fmc_ops_done_pulse;
    wire fmc_program_precheck_err_pulse;
    wire fmc_program_unaligned_pulse;
    wire fmc_start_erase_clear_pulse;

    /* Store the data at the end of data phase */
    /* Generate keyr and cr1 lock write strobes at the end of data phase */
    reg keyr_write_strobe;
    reg lock_strobe;

    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            acr <= 32'h0000_0000;
            keyr <= 32'h0000_0000;
            cr1 <= 32'h0000_0000;
            ar <= 32'h0000_0000;
            cr2 <= 32'h0000_0000;
            isr <= 32'h0000_0000;
            keyr_write_strobe <= 1'b0;
            lock_strobe <= 1'b0;
        end else begin
            keyr_write_strobe <= 1'b0;
            lock_strobe <= 1'b0;

            if (write_valid) begin
                case (write_index)
                    8'h00: begin
                        if (write_mask[0]) begin
                            acr[7:0] <= hwdata_i[7:0];
                        end

                        if (write_mask[1]) begin
                            acr[15:8] <= hwdata_i[15:8];
                        end

                        if (write_mask[2]) begin
                            acr[23:16] <= hwdata_i[23:16];
                        end

                        if (write_mask[3]) begin
                            acr[31:24] <= hwdata_i[31:24];
                        end
                    end

                    8'h01: begin
                        if (write_mask[0]) begin
                            keyr[7:0] <= hwdata_i[7:0];
                        end

                        if (write_mask[1]) begin
                            keyr[15:8] <= hwdata_i[15:8];
                        end

                        if (write_mask[2]) begin
                            keyr[23:16] <= hwdata_i[23:16];
                        end

                        if (write_mask[3]) begin
                            keyr[31:24] <= hwdata_i[31:24];
                        end

                        keyr_write_strobe <= 1'b1;
                    end

                    8'h02: begin
                        if (!fmc_locked) begin
                            if (write_mask[0]) begin
                                cr1[7:0] <= hwdata_i[7:0];
                            end
                        end

                        if (write_mask[2] & hwdata_i[16]) begin
                            lock_strobe <= 1'b1;
                            cr1[2:0] <= 3'b000;
                        end
                    end

                    8'h03: begin
                        if (!fmc_locked) begin
                            if (write_mask[0] & hwdata_i[0]) begin
                                cr2[0] <= 1'b1;
                            end
                        end
                    end

                    8'h10: begin
                        if (!fmc_locked) begin
                            if (write_mask[0]) begin
                                ar[7:0] <= 8'b0;
                            end

                            if (write_mask[1]) begin
                                ar[15:8] <= {hwdata_i[15:10], 2'b00};
                            end

                            if (write_mask[2]) begin
                                ar[23:16] <= hwdata_i[23:16];
                            end

                            if (write_mask[3]) begin
                                ar[31:24] <= hwdata_i[31:24];
                            end
                        end
                    end

                    8'h42: begin
                        /* Clear the flag when one is written */
                        if (write_mask[0]) begin
                            if (hwdata_i[0]) begin
                                isr[0] <= 1'b0;
                            end

                            if (hwdata_i[1]) begin
                                isr[1] <= 1'b0;
                            end

                            if (hwdata_i[2]) begin
                                isr[2] <= 1'b0;
                            end
                        end
                    end

                    default: begin
                    end
                endcase
            end

            if (fmc_start_erase_clear_pulse) begin
                cr2[0] <= 1'b0;
            end

            if (fmc_ops_done_pulse) begin
                isr[0] <= 1'b1;
            end

            if (fmc_program_precheck_err_pulse) begin
                isr[1] <= 1'b1;
            end

            if (fmc_program_unaligned_pulse) begin
                isr[2] <= 1'b1;
            end
        end
    end

    /* Output data at the end of address phase */
    always @ (posedge hclk_i) begin
        if (read_xfer_valid) begin
            case (haddr_i[9:2])
                8'h00: begin
                    hrdata_o <= {28'b0, acr[3:0]};
                end

                8'h02: begin
                    hrdata_o <= {15'b0, fmc_locked, 13'b0, cr1[2:0]};
                end

                8'h03: begin
                    hrdata_o <= {31'b0, cr2[0]};
                end

                8'h10: begin
                    hrdata_o <= ar;
                end

                8'h20: begin
                    hrdata_o <= {30'b0, flash_model_program_pending_i, fmc_busy};
                end

                8'h40: begin
                    hrdata_o <= 32'h0000_0000;
                end

                8'h41: begin
                    hrdata_o <= {29'b0, isr[2:0]};
                end

                default: begin
                    hrdata_o <= 32'h0000_0000;
                end
            endcase
        end
    end

    /* Control AHB slave response state */
    localparam RESP_OKAY = 3'b001;
    localparam RESP_ERR1 = 3'b010;
    localparam RESP_ERR2 = 3'b100;

    reg [2:0] resp_state;

    always @ (posedge hclk_i) begin
        case (resp_state)
            RESP_OKAY: begin
                if (xfer_error) begin
                    resp_state <= RESP_ERR1;
                end
            end

            RESP_ERR1: begin
                resp_state <= RESP_ERR2;
            end

            RESP_ERR2: begin
                if (xfer_error) begin
                    resp_state <= RESP_ERR1;
                end else begin
                    resp_state <= RESP_OKAY;
                end
            end

            default: begin
                resp_state <= RESP_OKAY;
            end
        endcase
    end

    /* Output HRESP and HREADYOUT signals */
    always @ (*) begin
        case (resp_state)
            RESP_ERR1: begin
                hresp_o = 1'b1;
                hreadyout_o = 1'b0;
            end

            RESP_ERR2: begin
                hresp_o = 1'b1;
                hreadyout_o = 1'b1;
            end

            default: begin
                hresp_o = 1'b0;
                hreadyout_o = ~read_write_xfer_collision;
            end
        endcase
    end

    /* FMC sub-system */
    fmc_core fmc_core_subsystem (
        .hclk_i                                (hclk_i),
        .hreset_n_i                            (hreset_n_i),
        .fmc_latency_i                         (acr[3:0]),
        .fmc_keyr_write_strobe_i               (keyr_write_strobe),
        .fmc_key_i                             (keyr),
        .fmc_lock_strobe_i                     (lock_strobe),
        .fmc_bank_erase_en_i                   (cr1[2]),
        .fmc_sector_erase_en_i                 (cr1[1]),
        .fmc_sector_erase_sector_idx_i         (ar[15:0]),
        .fmc_start_erase_i                     (cr2[0]),
        .fmc_program_en_i                      (cr1[0]),
        .fmc_locked_o                          (fmc_locked),
        .fmc_busy_o                            (fmc_busy),
        .fmc_ops_done_pulse_o                  (fmc_ops_done_pulse),
        .fmc_program_precheck_err_pulse_o      (fmc_program_precheck_err_pulse),
        .fmc_program_unaligned_pulse_o         (fmc_program_unaligned_pulse),
        .fmc_start_erase_clear_pulse_o         (fmc_start_erase_clear_pulse),
        .flash_model_busy_i                    (flash_model_busy_i),
        .flash_model_ops_done_i                (flash_model_ops_done_i),
        .flash_model_program_precheck_err_i    (flash_model_program_precheck_err_i),
        .flash_model_program_unaligned_i       (flash_model_program_unaligned_i),
        .flash_model_bank_erase_req_o          (flash_model_bank_erase_req_o),
        .flash_model_sector_erase_req_o        (flash_model_sector_erase_req_o),
        .flash_model_sector_erase_sector_idx_o (flash_model_sector_erase_sector_idx_o),
        .flash_model_program_en_o              (flash_model_program_en_o)
    );

endmodule
