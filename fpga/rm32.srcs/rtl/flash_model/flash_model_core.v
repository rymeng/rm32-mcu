`timescale 1ns / 1ps

module flash_model_core #(
    /* Default operation timings, 15 ms / 15 ms / 80 us at 50 MHz */
    parameter ADDR_WIDTH         = 14,
    parameter SECTOR_ERASE_TICKS = 32'd749744,
    parameter BANK_ERASE_TICKS   = 32'd745904,
    parameter PROGRAM_TICKS      = 32'd3993
)(
/* Clock and reset */
    input  wire                      clk_i,
    input  wire                      rst_n_i,
/* Read signals */
    input  wire                      read_strobe_i,
    input  wire [(ADDR_WIDTH - 1):0] read_word_idx_i,
    output wire [31:0]               read_data_o,
/* Bank erase signals */
    input  wire                      bank_erase_req_i,
/* Sector erase signals */
    input  wire                      sector_erase_req_i,
    input  wire [5:0]                sector_erase_sector_idx_i,
/* Program signals */
    input  wire                      program_strobe_i,
    input  wire                      program_en_i,
    input  wire [(ADDR_WIDTH + 1):3] program_page_idx_i,
    input  wire                      program_word_idx_i,
    input  wire [31:0]               program_data_i,
/* Flash model status signals */
    output wire                      busy_o,
    output wire                      ops_done_o,
    output wire                      program_pending_o,
    output wire                      program_unaligned_o,
    output wire                      program_precheck_err_o
);
    /* Define bank erase status signals */
    reg  [(ADDR_WIDTH - 1):0] bank_erase_cnt;
    reg  [31:0]               bank_erase_busy_cnt;

    /* Define sector erase status signals */
    reg  [5:0]  sector_erase_sector_idx;
    reg  [12:0] sector_erase_cnt;
    reg  [31:0] sector_erase_busy_cnt;

    /* Define program status signals */
    reg  [1:0]  program_precheck_cnt;
    reg  [1:0]  program_cnt;
    reg  [31:0] program_busy_cnt;
    wire        program_req;
    wire        program_precheck_err;

    /* Define the total word count of the bank */
    localparam ADDR_LIMIT = 1 << ADDR_WIDTH;

    /* Define FMC states */
    localparam IDLE              = 9'b000000001;
    localparam PROGRAM_LOAD      = 9'b000000010;
    localparam PROGRAM_PRECHECK  = 9'b000000100;
    localparam PROGRAM_EXEC      = 9'b000001000;
    localparam PROGRAM_BUSY      = 9'b000010000;
    localparam SECTOR_ERASE_EXEC = 9'b000100000;
    localparam SECTOR_ERASE_BUSY = 9'b001000000;
    localparam BANK_ERASE_EXEC   = 9'b010000000;
    localparam BANK_ERASE_BUSY   = 9'b100000000;

    reg  [8:0] state;
    wire       busy;

    always @ (posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state <= IDLE;
            program_precheck_cnt <= 2'b0;
            program_cnt <= 2'b0;
            program_busy_cnt <= 32'b0;
            bank_erase_busy_cnt <= 32'b0;
            sector_erase_busy_cnt <= 32'b0;
            bank_erase_cnt <= {(ADDR_WIDTH){1'b0}};
            sector_erase_cnt <= 13'b0;
            sector_erase_sector_idx <= 6'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (bank_erase_req_i) begin
                        state <= BANK_ERASE_EXEC;
                        bank_erase_cnt <= {(ADDR_WIDTH){1'b0}};
                    end else if (sector_erase_req_i) begin
                        state <= SECTOR_ERASE_EXEC;
                        sector_erase_cnt <= 13'b0;
                        sector_erase_sector_idx <= sector_erase_sector_idx_i;
                    end else if (program_req) begin
                        state <= PROGRAM_LOAD;
                    end
                end

                PROGRAM_LOAD: begin
                    state <= PROGRAM_PRECHECK;
                    program_precheck_cnt <= 2'b0;
                end

                PROGRAM_PRECHECK: begin
                    if (program_precheck_cnt == 2'd3) begin
                        if (program_precheck_err) begin
                            state <= IDLE;
                        end else begin
                            state <= PROGRAM_EXEC;
                            program_cnt <= 2'b0;
                        end
                    end else begin
                        program_precheck_cnt <= program_precheck_cnt + 2'd1;
                    end
                end

                PROGRAM_EXEC: begin
                    if (program_cnt == 2'd1) begin
                        state <= PROGRAM_BUSY;
                        program_busy_cnt <= 32'b0;
                    end else begin
                        program_cnt <= program_cnt + 2'd1;
                    end
                end

                PROGRAM_BUSY: begin
                    if (program_busy_cnt == (PROGRAM_TICKS - 1)) begin
                        state <= IDLE;
                    end else begin
                        program_busy_cnt <= program_busy_cnt + 32'd1;
                    end
                end

                SECTOR_ERASE_EXEC: begin
                    if (sector_erase_cnt == (13'h100 - 1)) begin
                        state <= SECTOR_ERASE_BUSY;
                        sector_erase_busy_cnt <= 32'b0;
                    end else begin
                        sector_erase_cnt <= sector_erase_cnt + 13'd1;
                    end
                end

                SECTOR_ERASE_BUSY: begin
                    if (sector_erase_busy_cnt == (SECTOR_ERASE_TICKS - 1)) begin
                        state <= IDLE;
                    end else begin
                        sector_erase_busy_cnt <= sector_erase_busy_cnt + 32'd1;
                    end
                end

                BANK_ERASE_EXEC: begin
                    if (bank_erase_cnt == (ADDR_LIMIT - 1)) begin
                        state <= BANK_ERASE_BUSY;
                        bank_erase_busy_cnt <= 32'b0;
                    end else begin
                        bank_erase_cnt <= bank_erase_cnt + 1'b1;
                    end
                end

                BANK_ERASE_BUSY: begin
                    if (bank_erase_busy_cnt == (BANK_ERASE_TICKS - 1)) begin
                        state <= IDLE;
                    end else begin
                        bank_erase_busy_cnt <= bank_erase_busy_cnt + 32'd1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    assign busy = (state != IDLE);
    assign busy_o = busy;

    /* Define read data flip-flop */
    reg [31:0] read_data;

    /* Bank erase done logic */
    wire bank_erase_done;

    assign bank_erase_done =
        (state == BANK_ERASE_BUSY) && (bank_erase_busy_cnt == (BANK_ERASE_TICKS - 1));

    /* Sector erase done logic */
    wire sector_erase_done;

    assign sector_erase_done =
        (state == SECTOR_ERASE_BUSY) && (sector_erase_busy_cnt == (SECTOR_ERASE_TICKS - 1));

    /* Write page buffer logic */
    /* Program loading & request & alert logic */
    reg  [63:0]               page_buf_data;
    reg  [(ADDR_WIDTH + 1):3] page_buf_idx;
    reg                       page_buf_half;
    reg                       page_buf_full;
    reg  [63:0]               program_page_data;
    reg  [(ADDR_WIDTH + 1):3] program_page_idx;
    wire                      program_en;
    wire                      program_valid;
    wire                      program_collect;
    wire                      program_refresh;
    wire                      program_unaligned;
    wire                      program_overwrite;
    wire                      program_merge;
    wire                      program_pending;
    wire                      program_done;

    assign program_en = program_en_i;
    assign program_valid =
        (program_en) && (!bank_erase_req_i) && (!sector_erase_req_i) && (!busy);
    assign program_collect = (program_valid) && (program_strobe_i);
    assign program_refresh =
        (program_collect) &&
        ((!page_buf_half) || (program_page_idx_i != page_buf_idx)) &&
        (program_word_idx_i == 1'b0);
    assign program_unaligned =
        (program_collect) &&
        ((!page_buf_half) || (program_page_idx_i != page_buf_idx)) &&
        (program_word_idx_i == 1'b1);
    assign program_overwrite =
        (program_collect) && (page_buf_half && (!page_buf_full)) &&
        (program_page_idx_i == page_buf_idx) && (program_word_idx_i == 1'b0);
    assign program_merge =
        (program_collect) && (page_buf_half && (!page_buf_full)) &&
        (program_page_idx_i == page_buf_idx) && (program_word_idx_i == 1'b1);
    assign program_pending = (program_valid) && (!page_buf_full);
    assign program_req = (program_merge) || (page_buf_full);
    assign program_done = (state == PROGRAM_BUSY) && (program_busy_cnt == (PROGRAM_TICKS - 1));
    assign program_unaligned_o = program_unaligned;
    assign program_pending_o = program_pending;

    always @ (posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            page_buf_data <= 64'b0;
            page_buf_idx <= {(ADDR_WIDTH - 1){1'b0}};
            page_buf_half <= 1'b0;
            page_buf_full <= 1'b0;
            program_page_data <= 64'b0;
            program_page_idx <= {(ADDR_WIDTH - 1){1'b0}};
        end else begin
            if (program_refresh) begin
                page_buf_data[31:0] <= program_data_i;
                page_buf_idx <= program_page_idx_i;
                page_buf_half <= 1'b1;
                page_buf_full <= 1'b0;
            end else if (program_overwrite) begin
                page_buf_data[31:0] <= program_data_i;
            end else if (program_merge) begin
                page_buf_data[63:32] <= program_data_i;
                page_buf_full <= 1'b1;
            end

            if (state == PROGRAM_LOAD) begin
                program_page_data <= page_buf_data;
                program_page_idx <= page_buf_idx;
                page_buf_half <= 1'b0;
                page_buf_full <= 1'b0;
            end
        end
    end

    /* Program precheck logic */
    reg  [31:0]               program_precheck_data_word_low;
    reg  [31:0]               program_precheck_data_word_high;
    wire                      program_precheck_active;
    wire [(ADDR_WIDTH - 1):0] program_precheck_word_idx;
    wire                      program_precheck_result;

    assign program_precheck_active = (state == PROGRAM_PRECHECK) && (program_precheck_cnt <= 2'd1);
    assign program_precheck_word_idx = {program_page_idx, program_precheck_cnt[0]};
    assign program_precheck_result =
        (program_precheck_data_word_high == 32'hFFFF_FFFF) &&
        (program_precheck_data_word_low == 32'hFFFF_FFFF);
    assign program_precheck_err =
        (state == PROGRAM_PRECHECK) && (program_precheck_cnt == 2'd3) &&
        (!program_precheck_result);
    assign program_precheck_err_o = program_precheck_err;

    always @ (posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            program_precheck_data_word_low <= 32'b0;
            program_precheck_data_word_high <= 32'b0;
        end else begin
            if (state == PROGRAM_PRECHECK) begin
                if (program_precheck_cnt == 2'd1) begin
                    program_precheck_data_word_low <= read_data;
                end else if (program_precheck_cnt == 2'd2) begin
                    program_precheck_data_word_high <= read_data;
                end
            end
        end
    end

    /* Generate the operation completion flag */
    assign ops_done_o = program_done || sector_erase_done || bank_erase_done;

    /* BRAM memory unit */
    (* ram_style = "block" *) reg [31:0] unit [0:(ADDR_LIMIT - 1)];

    /* BRAM memory unit write logic */
    reg                      bram_write_valid;
    reg [(ADDR_WIDTH - 1):0] bram_write_word_idx;
    reg [31:0]               bram_write_data;

    always @ (*) begin
        bram_write_valid = 1'b0;
        bram_write_word_idx = {(ADDR_WIDTH){1'b0}};
        bram_write_data = 32'hFFFF_FFFF;

        case (state)
            PROGRAM_EXEC: begin
                bram_write_valid = 1'b1;
                bram_write_word_idx = {program_page_idx, program_cnt[0]};
                bram_write_data =
                    (program_cnt[0]) ? program_page_data[63:32] : program_page_data[31:0];
            end

            SECTOR_ERASE_EXEC: begin
                bram_write_valid = 1'b1;
                bram_write_word_idx =
                    {sector_erase_sector_idx, 8'b0} + sector_erase_cnt;
                bram_write_data = 32'hFFFF_FFFF;
            end

            BANK_ERASE_EXEC: begin
                bram_write_valid = 1'b1;
                bram_write_word_idx = bank_erase_cnt;
                bram_write_data = 32'hFFFF_FFFF;
            end

            default: begin
            end
        endcase
    end

    always @ (posedge clk_i) begin
        if (bram_write_valid) begin
            unit[bram_write_word_idx] <= bram_write_data;
        end
    end

    /* BRAM memory unit read logic */
    wire [(ADDR_WIDTH - 1):0] bram_read_word_idx;
    wire [(ADDR_WIDTH - 1):0] read_word_idx;

    assign read_word_idx = read_word_idx_i;
    assign bram_read_word_idx =
        program_precheck_active ? program_precheck_word_idx : read_word_idx;

    always @ (posedge clk_i) begin
        if (read_strobe_i | program_precheck_active) begin
            read_data <= unit[bram_read_word_idx];
        end
    end

    assign read_data_o = read_data;

endmodule
