`timescale 1ns / 1ps

module fmc_core (
    input  wire        hclk_i,
    input  wire        hreset_n_i,
/* FMC register interface */
    input  wire  [3:0] fmc_latency_i,
    input  wire        fmc_keyr_write_strobe_i,
    input  wire [31:0] fmc_key_i,
    input  wire        fmc_lock_strobe_i,
    input  wire        fmc_bank_erase_en_i,
    input  wire        fmc_sector_erase_en_i,
    input  wire [15:0] fmc_sector_erase_sector_idx_i,
    input  wire        fmc_start_erase_i,
    input  wire        fmc_program_en_i,
    output wire        fmc_locked_o,
    output wire        fmc_busy_o,
    output wire        fmc_ops_done_pulse_o,
    output wire        fmc_program_precheck_err_pulse_o,
    output wire        fmc_program_unaligned_pulse_o,
    output wire        fmc_start_erase_clear_pulse_o,
/* Flash model interface */
    input  wire        flash_model_busy_i,
    input  wire        flash_model_ops_done_i,
    input  wire        flash_model_program_precheck_err_i,
    input  wire        flash_model_program_unaligned_i,
    output wire        flash_model_bank_erase_req_o,
    output wire        flash_model_sector_erase_req_o,
    output wire  [5:0] flash_model_sector_erase_sector_idx_o,
    output wire        flash_model_program_en_o
);
    /* Unlock logic */
    reg locked;
    reg unlock_step;

    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            locked <= 1'b1;
            unlock_step <= 1'b0;
        end else begin
            if (fmc_lock_strobe_i) begin
                locked <= 1'b1;
                unlock_step <= 1'b0;
            end else if (fmc_keyr_write_strobe_i) begin
                if (fmc_key_i == 32'h5555_AAAA) begin
                    unlock_step <= 1'b1;
                end else if ((fmc_key_i == 32'h3333_CCCC) & unlock_step) begin
                    locked <= 1'b0;
                    unlock_step <= 1'b0;
                end else begin
                    unlock_step <= 1'b0;
                end
            end
        end
    end

    assign fmc_locked_o = locked;

    /* Generate erase request logic */
    wire bank_erase_req;
    wire sector_erase_req;
    reg  erase_active;

    assign bank_erase_req =
        (!locked) & (!fmc_busy_o) & (fmc_start_erase_i) &
        (fmc_bank_erase_en_i);
    assign sector_erase_req =
        (!locked) & (!fmc_busy_o) & (fmc_start_erase_i) &
        (~fmc_bank_erase_en_i) & (fmc_sector_erase_en_i);

    always @ (posedge hclk_i or negedge hreset_n_i) begin
        if (!hreset_n_i) begin
            erase_active <= 1'b0;
        end else begin
            if (bank_erase_req | sector_erase_req) begin
                erase_active <= 1'b1;
            end

            if (flash_model_ops_done_i) begin
                erase_active <= 1'b0;
            end
        end
    end

    /* Output the flash model control signals */
    assign flash_model_sector_erase_req_o = sector_erase_req;
    assign flash_model_sector_erase_sector_idx_o = fmc_sector_erase_sector_idx_i[15:10];
    assign flash_model_bank_erase_req_o = bank_erase_req;
    assign flash_model_program_en_o = (~locked) & (fmc_program_en_i);

    /* Output FMC status signals */
    assign fmc_busy_o = erase_active | flash_model_busy_i;
    assign fmc_ops_done_pulse_o = flash_model_ops_done_i;
    assign fmc_program_precheck_err_pulse_o = flash_model_program_precheck_err_i;
    assign fmc_program_unaligned_pulse_o = flash_model_program_unaligned_i;

    /* Output FMC status clear signals */
    assign fmc_start_erase_clear_pulse_o = bank_erase_req | sector_erase_req;

endmodule
