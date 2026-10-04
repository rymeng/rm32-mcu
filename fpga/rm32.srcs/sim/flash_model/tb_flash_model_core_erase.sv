`timescale 1ns / 1ps

/* Core level flash model testbench: bank erase and every sector erase.
   The core is driven directly through its native port instead of the FMC. */
module tb_flash_model_core_erase;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Operation timings, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    /* Geometry of one flash bank */
    localparam int SECTORS          = 64;
    localparam int WORDS_PER_SECTOR = 256;
    localparam int PAGES_PER_SECTOR = WORDS_PER_SECTOR / 2;

    int error_count = 0;
    int case_count  = 0;
    int done_pulses = 0;

    logic clk   = 1'b0;
    logic rst_n = 1'b0;

    /* Core control signals */
    logic         bank_erase_req;
    logic         sector_erase_req;
    logic  [5: 0] sector_erase_idx;
    logic         program_en;
    logic         program_strobe;
    logic [31: 0] program_data;
    logic [12: 0] program_page_idx;
    logic         program_word_idx;
    logic         read_strobe;
    logic [13: 0] read_word_idx;
    logic [31: 0] read_data;

    /* Core status signals */
    logic busy;
    logic ops_done;
    logic pg_err;
    logic pg_na;
    logic pgbufnf;

    always #(CLK_PERIOD / 2) clk = ~clk;

    /* Count the one cycle operation completion pulses */
    always @(posedge clk) begin
        if (ops_done) begin
            done_pulses++;
        end
    end

    flash_model_core #(
        .ADDR_WIDTH         (14),
        .SECTOR_ERASE_TICKS (SER_TICKS),
        .BANK_ERASE_TICKS   (BER_TICKS),
        .PROGRAM_TICKS      (PROG_TICKS)
    ) dut (
        .clk_i                     (clk),
        .rst_n_i                   (rst_n),
        .bank_erase_req_i          (bank_erase_req),
        .sector_erase_req_i        (sector_erase_req),
        .sector_erase_sector_idx_i (sector_erase_idx),
        .program_en_i              (program_en),
        .program_strobe_i          (program_strobe),
        .program_data_i            (program_data),
        .program_page_idx_i        (program_page_idx),
        .program_word_idx_i        (program_word_idx),
        .read_strobe_i             (read_strobe),
        .read_word_idx_i           (read_word_idx),
        .read_data_o               (read_data),
        .busy_o                    (busy),
        .ops_done_o                (ops_done),
        .program_precheck_err_o    (pg_err),
        .program_unaligned_o       (pg_na),
        .program_pending_o         (pgbufnf)
    );

    /* Page data helpers, every sector gets a unique pair of words */
    function automatic logic [31: 0] sector_low(input int s);
        return 32'h5A5A_0000 + s[31: 0];
    endfunction

    function automatic logic [31: 0] sector_high(input int s);
        return 32'hA5A5_0000 + s[31: 0];
    endfunction

    /* One cycle sector erase request pulse with the given index */
    task automatic pulse_sector_erase(input int idx);
        @(posedge clk);
        #(1);
        sector_erase_idx = idx[5: 0];
        sector_erase_req = 1'b1;
        @(posedge clk);
        #(1);
        sector_erase_req = 1'b0;
    endtask

    /* One cycle bank erase request pulse */
    task automatic pulse_bank_erase();
        @(posedge clk);
        #(1);
        bank_erase_req = 1'b1;
        @(posedge clk);
        #(1);
        bank_erase_req = 1'b0;
    endtask

    /* Push one word into the program buffer of the given word address */
    task automatic core_write_word(input int waddr, input logic [31: 0] data);
        @(posedge clk);
        #(1);
        program_data     = data;
        program_page_idx = waddr[13: 1];
        program_word_idx = waddr[0];
        program_strobe   = 1'b1;
        @(posedge clk);
        #(1);
        program_strobe   = 1'b0;
    endtask

    /* Program one page with a low and a high word */
    task automatic program_page_op(input int page, input logic [31: 0] low,
                                   input logic [31: 0] high);
        core_write_word(page * 2, low);
        core_write_word(page * 2 + 1, high);
    endtask

    /* Read one word, the array output updates one cycle after the strobe */
    task automatic core_read_word(input int waddr, output logic [31: 0] data);
        @(posedge clk);
        #(1);
        read_word_idx = waddr[13: 0];
        read_strobe   = 1'b1;
        @(posedge clk);
        #(1);
        read_strobe   = 1'b0;
        data          = read_data;
    endtask

    /* Compare one word and print the result */
    task automatic check_word(input string name, input int waddr,
                              input logic [31: 0] exp);
        logic [31: 0] got;
        core_read_word(waddr, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s word %0d got %08X expected %08X",
                     name, waddr, got, exp);
        end else begin
            $display("PASS: %s word %0d = %08X", name, waddr, got);
        end
    endtask

    /* Compare one word, only a mismatch is printed */
    task automatic check_word_q(input string name, input int waddr,
                                input logic [31: 0] exp);
        logic [31: 0] got;
        core_read_word(waddr, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s word %0d got %08X expected %08X",
                     name, waddr, got, exp);
        end
    endtask

    /* Wait for one operation, check its busy period and completion pulse.
       quiet mutes the pass report, expect_done drops the pulse check */
    task automatic wait_busy(input string name, input int exp_cycles,
                             input bit quiet = 1'b0,
                             input bit expect_done = 1'b1);
        time t_start;
        time t_end;
        int  n = 0;
        int  cycles;

        done_pulses = 0;

        while (busy !== 1'b1) begin
            @(posedge clk);
            n++;
            if (n > 20) begin
                error_count++;
                $display("FAIL: %s never started", name);
                return;
            end
        end
        t_start = $time;

        n = 0;
        while (busy !== 1'b0) begin
            @(posedge clk);
            n++;
            if (n > 200000) begin
                error_count++;
                $display("FAIL: %s never finished", name);
                return;
            end
        end
        t_end = $time;
        repeat (2) @(posedge clk);

        cycles = (t_end - t_start) / CLK_PERIOD;
        if (cycles != exp_cycles) begin
            error_count++;
            $display("FAIL: %s busy cycles %0d expected %0d",
                     name, cycles, exp_cycles);
        end else if (!quiet) begin
            $display("PASS: %s busy cycles = %0d", name, cycles);
        end

        if (expect_done && (done_pulses != 1)) begin
            error_count++;
            $display("FAIL: %s ops_done pulses %0d expected 1",
                     name, done_pulses);
        end
    endtask

    initial begin
        bank_erase_req   = 1'b0;
        sector_erase_req = 1'b0;
        sector_erase_idx = 6'h00;
        program_en       = 1'b0;
        program_strobe   = 1'b0;
        program_data     = 32'h0;
        program_page_idx = 11'h0;
        program_word_idx = 1'b0;
        read_strobe      = 1'b0;
        read_word_idx    = 12'h0;

        /* Reset */
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
        program_en = 1'b1;

        /* E01: the pristine bank erases to all ones */
        case_count++;
        $display("=== E%02d: bank erase on a pristine array ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("E01 bank erase", 16384 + BER_TICKS);
        check_word("E01 blank", 0, 32'hFFFF_FFFF);
        check_word("E01 blank", 512, 32'hFFFF_FFFF);
        check_word("E01 blank", 1365, 32'hFFFF_FFFF);
        check_word("E01 blank", 2048, 32'hFFFF_FFFF);
        check_word("E01 blank", 2730, 32'hFFFF_FFFF);
        check_word("E01 blank", 3840, 32'hFFFF_FFFF);
        check_word("E01 blank", 4095, 32'hFFFF_FFFF);

        /* E02: data written before a bank erase must disappear */
        case_count++;
        $display("=== E%02d: bank erase after programming pages ===",
                 case_count);
        program_page_op(0, 32'h1111_0001, 32'h2222_0001);
        wait_busy("E02 program page 0", 7 + PROG_TICKS);
        program_page_op(100, 32'h1111_0064, 32'h2222_0064);
        wait_busy("E02 program page 100", 7 + PROG_TICKS);
        program_page_op(1500, 32'h1111_05DC, 32'h2222_05DC);
        wait_busy("E02 program page 1500", 7 + PROG_TICKS);
        program_page_op(2047, 32'h1111_07FF, 32'h2222_07FF);
        wait_busy("E02 program page 2047", 7 + PROG_TICKS);
        pulse_bank_erase();
        wait_busy("E02 bank erase", 16384 + BER_TICKS);
        check_word("E02 erased", 0, 32'hFFFF_FFFF);
        check_word("E02 erased", 1, 32'hFFFF_FFFF);
        check_word("E02 erased", 200, 32'hFFFF_FFFF);
        check_word("E02 erased", 3000, 32'hFFFF_FFFF);
        check_word("E02 erased", 4094, 32'hFFFF_FFFF);

        /* Prepare one programmed page in every sector */
        for (int s = 0; s < SECTORS; s = s + 1) begin
            program_page_op(s * PAGES_PER_SECTOR, sector_low(s),
                            sector_high(s));
            wait_busy("sector data", 7 + PROG_TICKS, 1'b1);
        end

        /* E03..E18: erase every single sector, the neighbours keep data */
        for (int s = 0; s < SECTORS; s = s + 1) begin
            case_count++;
            $display("=== E%02d: sector erase of sector %0d ===",
                     case_count, s);
            pulse_sector_erase(s);
            wait_busy($sformatf("E%02d sector %0d erase", case_count, s),
                      256 + SER_TICKS);
            check_word($sformatf("E%02d sector %0d blank", case_count, s),
                       s * WORDS_PER_SECTOR, 32'hFFFF_FFFF);
            check_word($sformatf("E%02d sector %0d blank+", case_count, s),
                       s * WORDS_PER_SECTOR + 1, 32'hFFFF_FFFF);

            if (s < SECTORS - 1) begin
                check_word($sformatf("E%02d next sector keeps data",
                                     case_count),
                           (s + 1) * WORDS_PER_SECTOR, sector_low(s + 1));
                check_word($sformatf("E%02d last sector keeps data",
                                     case_count),
                           (SECTORS - 1) * WORDS_PER_SECTOR,
                           sector_low(SECTORS - 1));
            end
            if (s > 0) begin
                check_word($sformatf("E%02d previous stays blank",
                                     case_count),
                           (s - 1) * WORDS_PER_SECTOR, 32'hFFFF_FFFF);
            end
        end

        /* E19: the highest sector indexes address real sectors */
        case_count++;
        $display("=== E%02d: high sector indexes address real sectors ===",
                 case_count);
        /* Keep one programmed page while erasing sectors far above it */
        program_page_op(0, 32'hDEAD_0001, 32'hBEEF_0001);
        wait_busy("E19 program page 0", 7 + PROG_TICKS);
        pulse_sector_erase(6'h10);
        wait_busy("E19 erase sector 0x10", 256 + SER_TICKS);
        check_word("E19 sector 0x10 blank", 16 * WORDS_PER_SECTOR,
                   32'hFFFF_FFFF);
        check_word("E19 page kept after 0x10", 0, 32'hDEAD_0001);
        pulse_sector_erase(6'h3F);
        wait_busy("E19 erase sector 0x3F", 256 + SER_TICKS);
        check_word("E19 sector 0x3F blank", 63 * WORDS_PER_SECTOR,
                   32'hFFFF_FFFF);
        check_word("E19 page kept after 0x3F", 0, 32'hDEAD_0001);

        /* E20: erase all even sectors, the odd sectors keep their data */
        case_count++;
        $display("=== E%02d: interleaved sector erase ===", case_count);
        pulse_bank_erase();
        wait_busy("E20 cleanup bank erase", 16384 + BER_TICKS);
        for (int s = 0; s < SECTORS; s = s + 1) begin
            program_page_op(s * PAGES_PER_SECTOR, sector_low(s),
                            sector_high(s));
            wait_busy("sector data", 7 + PROG_TICKS, 1'b1);
        end
        for (int s = 0; s < SECTORS; s = s + 2) begin
            pulse_sector_erase(s);
            wait_busy($sformatf("E20 erase sector %0d", s),
                      256 + SER_TICKS, 1'b1);
        end
        for (int s = 0; s < SECTORS; s = s + 1) begin
            if ((s % 2) == 0) begin
                check_word_q("E20 even blank", s * WORDS_PER_SECTOR,
                             32'hFFFF_FFFF);
            end else begin
                check_word_q("E20 odd kept", s * WORDS_PER_SECTOR,
                             sector_low(s));
                check_word_q("E20 odd kept", s * WORDS_PER_SECTOR + 1,
                             sector_high(s));
            end
        end
        $display("PASS: E20 even sectors blank, odd sectors intact");

        repeat (10) @(posedge clk);

        if (error_count == 0) begin
            $display("==== ALL CHECKS PASSED (%0d CASES) ====", case_count);
        end else begin
            $display("==== %0d CHECK(S) FAILED ====", error_count);
        end
        $finish;
    end

    /* Simulation timeout guard */
    initial begin
        repeat (300000) @(posedge clk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
