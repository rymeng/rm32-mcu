`timescale 1ns / 1ps

/* Core level flash model testbench: page programming, write erase write
   sequences and data pattern coverage. The core is driven directly. */
module tb_flash_model_core_program;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Operation timings, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    /* Geometry of one flash bank */
    localparam int PAGES = 8192;
    localparam int WORDS = 16384;

    int error_count = 0;
    int case_count  = 0;
    int done_pulses = 0;

    /* Random page data for the full array sweep and shuffle order */
    logic [31: 0] pat [0: WORDS - 1];
    int           order [0: PAGES - 1];

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

    /* Simple xorshift32 pseudo random generator, xsim friendly */
    logic [31: 0] rand_state = 32'h2468_ACE0;

    function automatic logic [31: 0] rand32();
        rand_state = rand_state ^ (rand_state << 13);
        rand_state = rand_state ^ (rand_state >> 17);
        rand_state = rand_state ^ (rand_state << 5);
        return rand_state;
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

    /* Sample the program buffer pending flag one cycle later */
    task automatic check_pending(input string name, input bit exp);
        @(posedge clk);
        #(1);
        if (pgbufnf !== exp) begin
            error_count++;
            $display("FAIL: %s pending %b expected %b", name, pgbufnf, exp);
        end else begin
            $display("PASS: %s pending = %b", name, pgbufnf);
        end
    endtask

    /* Wait for one operation, check its busy period and completion pulse.
       quiet mutes the pass report, expect_done drops the pulse check.
       Call it right after the trigger so that the timing stays aligned. */
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

        /* Give the array a known blank baseline */
        pulse_bank_erase();
        wait_busy("cleanup bank erase", 16384 + BER_TICKS, 1'b1);

        /* P01: single page program and the buffer pending flag */
        case_count++;
        $display("=== P%02d: single page program and buffer flag ===",
                 case_count);
        check_pending("P01 idle", 1'b1);
        core_write_word(2, 32'hCAFE_0001);
        check_pending("P01 after low word", 1'b1);
        core_write_word(3, 32'hCAFE_0002);
        wait_busy("P01 program page 1", 7 + PROG_TICKS);
        check_pending("P01 after program", 1'b1);
        check_word("P01 low word", 2, 32'hCAFE_0001);
        check_word("P01 high word", 3, 32'hCAFE_0002);

        /* P02: program and verify every single page with random data */
        case_count++;
        $display("=== P%02d: program and verify every page ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("P02 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        for (int i = 0; i < WORDS; i = i + 1) begin
            pat[i] = rand32();
        end
        for (int p = 0; p < PAGES; p = p + 1) begin
            program_page_op(p, pat[p * 2], pat[p * 2 + 1]);
            wait_busy("P02 page", 7 + PROG_TICKS, 1'b1);
        end
        for (int p = 0; p < PAGES; p = p + 1) begin
            check_word_q("P02 readback", p * 2, pat[p * 2]);
            check_word_q("P02 readback", p * 2 + 1, pat[p * 2 + 1]);
        end
        $display("PASS: P02 programmed and verified %0d pages", PAGES);

        /* P03: program 64 pages in random order and read them back */
        case_count++;
        $display("=== P%02d: 64 pages in shuffled order ===", case_count);
        pulse_bank_erase();
        wait_busy("P03 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        for (int i = 0; i < PAGES; i = i + 1) begin
            order[i] = i;
        end
        for (int i = PAGES - 1; i > 0; i = i - 1) begin
            int j;
            int tmp;
            j = rand32() % (i + 1);
            tmp = order[i];
            order[i] = order[j];
            order[j] = tmp;
        end
        for (int k = 0; k < 64; k = k + 1) begin
            int p;
            p = order[k];
            program_page_op(p, 32'h0033_0000 + p, 32'h0044_0000 + p);
            wait_busy("P03 page", 7 + PROG_TICKS, 1'b1);
        end
        for (int k = 0; k < 64; k = k + 1) begin
            int p;
            p = order[k];
            check_word_q("P03 readback", p * 2, 32'h0033_0000 + p);
            check_word_q("P03 readback", p * 2 + 1, 32'h0044_0000 + p);
        end
        $display("PASS: P03 64 shuffled pages verified");

        /* P04: restart a page after an interleaved program */
        case_count++;
        $display("=== P%02d: restart a page after interleave ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("P04 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        core_write_word(40, 32'hAAAA_0014);
        program_page_op(21, 32'hBBBB_0015, 32'hCCCC_0015);
        wait_busy("P04 interleaved page 21", 7 + PROG_TICKS);
        program_page_op(20, 32'hDDDD_0014, 32'hEEEE_0014);
        wait_busy("P04 restarted page 20", 7 + PROG_TICKS);
        check_word("P04 page 21 low", 42, 32'hBBBB_0015);
        check_word("P04 page 21 high", 43, 32'hCCCC_0015);
        check_word("P04 page 20 low", 40, 32'hDDDD_0014);
        check_word("P04 page 20 high", 41, 32'hEEEE_0014);

        /* P05: repeating the low word keeps only the newest one */
        case_count++;
        $display("=== P%02d: repeated low word overwrites ===",
                 case_count);
        core_write_word(44, 32'h1111_0016);
        core_write_word(44, 32'h2222_0016);
        core_write_word(45, 32'h3333_0016);
        wait_busy("P05 program page 22", 7 + PROG_TICKS);
        check_word("P05 overwritten low", 44, 32'h2222_0016);
        check_word("P05 high word", 45, 32'h3333_0016);

        /* P06: write erase write inside one sector */
        case_count++;
        $display("=== P%02d: write erase write in sector 3 ===",
                 case_count);
        program_page_op(500, 32'h600D_01F4, 32'h600D_01F5);
        wait_busy("P06 program page 500", 7 + PROG_TICKS);
        check_word("P06 before erase", 1000, 32'h600D_01F4);
        pulse_sector_erase(3);
        wait_busy("P06 sector 3 erase", 256 + SER_TICKS);
        check_word("P06 erased low", 1000, 32'hFFFF_FFFF);
        check_word("P06 erased high", 1001, 32'hFFFF_FFFF);
        program_page_op(500, 32'h700D_01F4, 32'h700D_01F5);
        wait_busy("P06 reprogram page 500", 7 + PROG_TICKS);
        check_word("P06 rewritten low", 1000, 32'h700D_01F4);
        check_word("P06 rewritten high", 1001, 32'h700D_01F5);

        /* P07: write erase write across a full bank erase */
        case_count++;
        $display("=== P%02d: write erase write across bank erase ===",
                 case_count);
        program_page_op(700, 32'h0B0B_02BC, 32'h0B0B_02BD);
        wait_busy("P07 program page 700", 7 + PROG_TICKS);
        check_word("P07 before erase", 1400, 32'h0B0B_02BC);
        pulse_bank_erase();
        wait_busy("P07 bank erase", 16384 + BER_TICKS);
        check_word("P07 erased low", 1400, 32'hFFFF_FFFF);
        check_word("P07 erased high", 1401, 32'hFFFF_FFFF);
        program_page_op(700, 32'h0C0C_02BC, 32'h0C0C_02BD);
        wait_busy("P07 reprogram page 700", 7 + PROG_TICKS);
        check_word("P07 rewritten low", 1400, 32'h0C0C_02BC);
        check_word("P07 rewritten high", 1401, 32'h0C0C_02BD);

        /* P08: page 127/255 sit on the sector 0 and 1 boundary */
        case_count++;
        $display("=== P%02d: sector boundary pages ===", case_count);
        pulse_bank_erase();
        wait_busy("P08 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        program_page_op(127, 32'h1270_0001, 32'h1270_0002);
        wait_busy("P08 page 127", 7 + PROG_TICKS);
        program_page_op(128, 32'h1280_0001, 32'h1280_0002);
        wait_busy("P08 page 128", 7 + PROG_TICKS);
        program_page_op(255, 32'h2550_0001, 32'h2550_0002);
        wait_busy("P08 page 255", 7 + PROG_TICKS);
        pulse_sector_erase(1);
        wait_busy("P08 sector 1 erase", 256 + SER_TICKS);
        check_word("P08 page 127 kept", 254, 32'h1270_0001);
        check_word("P08 page 128 blank", 256, 32'hFFFF_FFFF);
        check_word("P08 page 255 blank", 510, 32'hFFFF_FFFF);
        program_page_op(128, 32'h1290_0001, 32'h1290_0002);
        wait_busy("P08 rewrite page 128", 7 + PROG_TICKS);
        check_word("P08 page 128 new", 256, 32'h1290_0001);
        check_word("P08 page 127 still kept", 254, 32'h1270_0001);

        /* P09: three write erase write rounds on the same page */
        case_count++;
        $display("=== P%02d: three write erase write rounds ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("P09 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        program_page_op(2, 32'hA0A0_0001, 32'hA0A0_0002);
        wait_busy("P09 round 1", 7 + PROG_TICKS);
        check_word("P09 round 1 low", 4, 32'hA0A0_0001);
        pulse_sector_erase(0);
        wait_busy("P09 erase 1", 256 + SER_TICKS);
        check_word("P09 blank after erase 1", 4, 32'hFFFF_FFFF);
        program_page_op(2, 32'hB0B0_0001, 32'hB0B0_0002);
        wait_busy("P09 round 2", 7 + PROG_TICKS);
        check_word("P09 round 2 low", 4, 32'hB0B0_0001);
        pulse_sector_erase(0);
        wait_busy("P09 erase 2", 256 + SER_TICKS);
        check_word("P09 blank after erase 2", 4, 32'hFFFF_FFFF);
        program_page_op(2, 32'hC0C0_0001, 32'hC0C0_0002);
        wait_busy("P09 round 3", 7 + PROG_TICKS);
        check_word("P09 round 3 low", 4, 32'hC0C0_0001);
        check_word("P09 round 3 high", 5, 32'hC0C0_0002);

        /* P10: boundary data patterns zero, ones and checkerboard */
        case_count++;
        $display("=== P%02d: special data patterns ===", case_count);
        pulse_bank_erase();
        wait_busy("P10 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        program_page_op(3, 32'h0000_0000, 32'hFFFF_FFFF);
        wait_busy("P10 zero low", 7 + PROG_TICKS);
        program_page_op(4, 32'hFFFF_FFFF, 32'h0000_0000);
        wait_busy("P10 zero high", 7 + PROG_TICKS);
        program_page_op(5, 32'hA5A5_5A5A, 32'h5A5A_A5A5);
        wait_busy("P10 checkerboard", 7 + PROG_TICKS);
        check_word("P10 zero low", 6, 32'h0000_0000);
        check_word("P10 ones high", 7, 32'hFFFF_FFFF);
        check_word("P10 ones low", 8, 32'hFFFF_FFFF);
        check_word("P10 zero high", 9, 32'h0000_0000);
        check_word("P10 checker low", 10, 32'hA5A5_5A5A);
        check_word("P10 checker high", 11, 32'h5A5A_A5A5);

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
        repeat (600000) @(posedge clk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
