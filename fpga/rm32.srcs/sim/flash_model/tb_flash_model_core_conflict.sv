`timescale 1ns / 1ps

/* Core level flash model testbench: precheck errors, unaligned writes and
   erase versus program corner cases. The core is driven directly. */
module tb_flash_model_core_conflict;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Operation timings, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    int error_count = 0;
    int case_count  = 0;
    int done_pulses = 0;
    int err_pulses  = 0;
    int na_pulses   = 0;

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

    /* Count the one cycle status pulses */
    always @(posedge clk) begin
        if (ops_done) begin
            done_pulses++;
        end
        if (pg_err) begin
            err_pulses++;
        end
        if (pg_na) begin
            na_pulses++;
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

    /* Watch the bus for a given number of cycles, it must stay idle */
    task automatic check_no_operation(input string name, input int cycles);
        repeat (cycles) @(posedge clk);
        if (busy !== 1'b0) begin
            error_count++;
            $display("FAIL: %s unexpected busy", name);
        end else begin
            $display("PASS: %s no operation started", name);
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

        /* X01: a dirty low word makes the precheck reject the program */
        case_count++;
        $display("=== X%02d: precheck rejects a dirty low word ===",
                 case_count);
        program_page_op(10, 32'h0000_0000, 32'hFFFF_FFFF);
        wait_busy("X01 setup program", 7 + PROG_TICKS, 1'b1);
        err_pulses = 0;
        program_page_op(10, 32'h1111_1111, 32'h2222_2222);
        wait_busy("X01 rejected program", 5, 1'b0, 1'b0);
        if (err_pulses != 1) begin
            error_count++;
            $display("FAIL: X01 precheck error pulses %0d expected 1",
                     err_pulses);
        end else begin
            $display("PASS: X01 precheck error pulse seen");
        end
        check_word("X01 dirty low kept", 20, 32'h0000_0000);
        check_word("X01 blank high kept", 21, 32'hFFFF_FFFF);

        /* X02: a dirty high word makes the precheck reject the program */
        case_count++;
        $display("=== X%02d: precheck rejects a dirty high word ===",
                 case_count);
        program_page_op(11, 32'hFFFF_FFFF, 32'h0000_0000);
        wait_busy("X02 setup program", 7 + PROG_TICKS, 1'b1);
        err_pulses = 0;
        program_page_op(11, 32'h3333_3333, 32'h4444_4444);
        wait_busy("X02 rejected program", 5, 1'b0, 1'b0);
        if (err_pulses != 1) begin
            error_count++;
            $display("FAIL: X02 precheck error pulses %0d expected 1",
                     err_pulses);
        end else begin
            $display("PASS: X02 precheck error pulse seen");
        end
        check_word("X02 blank low kept", 22, 32'hFFFF_FFFF);
        check_word("X02 dirty high kept", 23, 32'h0000_0000);

        /* X03: the sector erase clears the dirty pages and writing recovers */
        case_count++;
        $display("=== X%02d: recovery after precheck error ===",
                 case_count);
        pulse_sector_erase(0);
        wait_busy("X03 sector 0 erase", 256 + SER_TICKS);
        check_word("X03 dirty low gone", 20, 32'hFFFF_FFFF);
        check_word("X03 dirty high gone", 23, 32'hFFFF_FFFF);
        program_page_op(10, 32'hABCD_0001, 32'hABCD_0002);
        wait_busy("X03 reprogram page 10", 7 + PROG_TICKS);
        check_word("X03 recovered low", 20, 32'hABCD_0001);
        check_word("X03 recovered high", 21, 32'hABCD_0002);

        /* X04: a high word without a matching low word raises PGNA */
        case_count++;
        $display("=== X%02d: high word without low word raises PGNA ===",
                 case_count);
        na_pulses = 0;
        core_write_word(25, 32'hDEAD_BEEF);
        check_no_operation("X04 stray high word", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: X04 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: X04 unaligned pulse seen");
        end
        check_word("X04 low untouched", 24, 32'hFFFF_FFFF);
        check_word("X04 high untouched", 25, 32'hFFFF_FFFF);
        program_page_op(12, 32'hFEED_0001, 32'hFEED_0002);
        wait_busy("X04 recovery page 12", 7 + PROG_TICKS);
        check_word("X04 recovered low", 24, 32'hFEED_0001);
        check_word("X04 recovered high", 25, 32'hFEED_0002);

        /* X05: a sector request and a write in the same cycle, erase wins */
        case_count++;
        $display("=== X%02d: erase and write in the same cycle ===",
                 case_count);
        @(posedge clk);
        #(1);
        sector_erase_idx = 6'h00;
        sector_erase_req = 1'b1;
        program_data     = 32'h1234_5678;
        program_page_idx = 11'd13;
        program_word_idx = 1'b0;
        program_strobe   = 1'b1;
        @(posedge clk);
        #(1);
        sector_erase_req = 1'b0;
        program_strobe   = 1'b0;
        wait_busy("X05 sector erase wins", 256 + SER_TICKS);
        check_word("X05 write dropped", 26, 32'hFFFF_FFFF);
        /* The buffer must be clean: a lone high word raises PGNA again */
        na_pulses = 0;
        core_write_word(27, 32'h5555_5555);
        check_no_operation("X05 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: X05 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: X05 no stale low word in the buffer");
        end
        check_word("X05 page still blank", 27, 32'hFFFF_FFFF);

        /* X06: a write during a program is dropped */
        case_count++;
        $display("=== X%02d: write during program is dropped ===",
                 case_count);
        program_page_op(14, 32'h1400_0001, 32'h1400_0002);
        while (busy !== 1'b1) begin
            @(posedge clk);
        end
        core_write_word(30, 32'h1500_0001);
        while (busy !== 1'b0) begin
            @(posedge clk);
        end
        repeat (2) @(posedge clk);
        check_word("X06 program done", 28, 32'h1400_0001);
        check_word("X06 page 15 blank", 30, 32'hFFFF_FFFF);
        na_pulses = 0;
        core_write_word(31, 32'h1500_0002);
        check_no_operation("X06 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: X06 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: X06 no stale low word in the buffer");
        end
        program_page_op(15, 32'h1510_0001, 32'h1510_0002);
        wait_busy("X06 recovery page 15", 7 + PROG_TICKS);
        check_word("X06 page 15 new", 30, 32'h1510_0001);
        check_word("X06 page 15 high", 31, 32'h1510_0002);

        /* X07: a write during an erase is dropped */
        case_count++;
        $display("=== X%02d: write during erase is dropped ===",
                 case_count);
        pulse_sector_erase(2);
        while (busy !== 1'b1) begin
            @(posedge clk);
        end
        core_write_word(800, 32'h1910_0400);
        while (busy !== 1'b0) begin
            @(posedge clk);
        end
        repeat (2) @(posedge clk);
        na_pulses = 0;
        core_write_word(801, 32'h1910_0401);
        check_no_operation("X07 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: X07 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: X07 no stale low word in the buffer");
        end
        check_word("X07 page 400 blank", 800, 32'hFFFF_FFFF);
        check_word("X07 page 400 high blank", 801, 32'hFFFF_FFFF);

        /* X08: a sector request during a program is ignored */
        case_count++;
        $display("=== X%02d: erase request during program is ignored ===",
                 case_count);
        program_page_op(512, 32'h0400_0001, 32'h0400_0002);
        wait_busy("X08 sector 4 data", 7 + PROG_TICKS, 1'b1);
        program_page_op(0, 32'h0000_0001, 32'h0000_0002);
        while (busy !== 1'b1) begin
            @(posedge clk);
        end
        @(posedge clk);
        #(1);
        sector_erase_idx = 6'h04;
        sector_erase_req = 1'b1;
        @(posedge clk);
        #(1);
        sector_erase_req = 1'b0;
        while (busy !== 1'b0) begin
            @(posedge clk);
        end
        check_no_operation("X08 after program", 20);
        check_word("X08 sector 4 kept", 1024, 32'h0400_0001);
        check_word("X08 page 0 new", 0, 32'h0000_0001);
        check_word("X08 page 0 high", 1, 32'h0000_0002);

        /* X09: bank and sector request in the same cycle, bank wins */
        case_count++;
        $display("=== X%02d: bank and sector request at once ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("X09 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        program_page_op(640, 32'h0500_0001, 32'h0500_0002);
        wait_busy("X09 sector 5 data", 7 + PROG_TICKS, 1'b1);
        program_page_op(896, 32'h0700_0001, 32'h0700_0002);
        wait_busy("X09 sector 7 data", 7 + PROG_TICKS, 1'b1);
        @(posedge clk);
        #(1);
        sector_erase_idx  = 6'h05;
        sector_erase_req  = 1'b1;
        bank_erase_req    = 1'b1;
        @(posedge clk);
        #(1);
        sector_erase_req  = 1'b0;
        bank_erase_req    = 1'b0;
        wait_busy("X09 bank erase wins", 16384 + BER_TICKS);
        check_word("X09 sector 5 blank", 1280, 32'hFFFF_FFFF);
        check_word("X09 sector 7 erased", 1792, 32'hFFFF_FFFF);

        /* X10: a reset in the middle of a program, then recovery */
        case_count++;
        $display("=== X%02d: reset during program and recovery ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("X10 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        program_page_op(600, 32'h1010_0001, 32'h1010_0002);
        while (busy !== 1'b1) begin
            @(posedge clk);
        end
        @(posedge clk);
        #(1);
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #(1);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
        if (busy !== 1'b0) begin
            error_count++;
            $display("FAIL: X10 core busy after reset");
        end else begin
            $display("PASS: X10 core idle after reset");
        end
        pulse_sector_erase(4);
        wait_busy("X10 sector erase after reset", 256 + SER_TICKS);
        check_word("X10 blank after reset", 1200, 32'hFFFF_FFFF);
        program_page_op(600, 32'h2020_0001, 32'h2020_0002);
        wait_busy("X10 program after reset", 7 + PROG_TICKS);
        check_word("X10 low after reset", 1200, 32'h2020_0001);
        check_word("X10 high after reset", 1201, 32'h2020_0002);

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
