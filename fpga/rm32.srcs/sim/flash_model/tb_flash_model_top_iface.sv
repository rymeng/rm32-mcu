`timescale 1ns / 1ps

/* Top level flash model testbench: AHB protocol errors, precheck errors,
   unaligned writes and erase versus program corner cases. */
module tb_flash_model_top_iface;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Operation timings, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    /* AHB encodings */
    localparam logic [1: 0] TRANS_IDLE   = 2'b00;
    localparam logic [1: 0] TRANS_NONSEQ = 2'b10;

    localparam logic [2: 0] SIZE_BYTE = 3'b000;
    localparam logic [2: 0] SIZE_HALF = 3'b001;
    localparam logic [2: 0] SIZE_WORD = 3'b010;

    int error_count = 0;
    int case_count  = 0;
    int done_pulses = 0;
    int err_pulses  = 0;
    int na_pulses   = 0;

    logic hclk    = 1'b0;
    logic hreset_n = 1'b0;

    /* AHB master signals */
    logic [31: 0] a_addr;
    logic  [2: 0] a_size;
    logic         a_write;
    logic  [1: 0] a_trans;
    logic [31: 0] d_wdata;

    logic [31: 0] hrdata;
    logic         hreadyout;
    logic         hresp;

    /* FMC style control signals */
    logic         ser_req;
    logic  [5: 0] ser_idx;
    logic         ber_req;
    logic         pg_en;

    /* DUT status signals */
    logic busy;
    logic ops_done;
    logic pg_err;
    logic pg_na;
    logic pgbufnf;

    always #(CLK_PERIOD / 2) hclk = ~hclk;

    /* Count the one cycle status pulses */
    always @(posedge hclk) begin
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

    flash_model_top #(
        .ADDR_WIDTH         (14),
        .SECTOR_ERASE_TICKS (SER_TICKS),
        .BANK_ERASE_TICKS   (BER_TICKS),
        .PROGRAM_TICKS      (PROG_TICKS)
    ) dut (
        .hclk_i                    (hclk),
        .hreset_n_i                (hreset_n),
        .hsel_i                    (1'b1),
        .haddr_i                   (a_addr),
        .hwdata_i                  (d_wdata),
        .hwrite_i                  (a_write),
        .htrans_i                  (a_trans),
        .hsize_i                   (a_size),
        .hready_i                  (1'b1),
        .hburst_i                  (3'b000),
        .hprot_i                   (4'b0001),
        .hmastlock_i               (1'b0),
        .hrdata_o                  (hrdata),
        .hreadyout_o               (hreadyout),
        .hresp_o                   (hresp),
        .program_en_i              (pg_en),
        .sector_erase_req_i        (ser_req),
        .sector_erase_sector_idx_i (ser_idx),
        .bank_erase_req_i          (ber_req),
        .busy_o                    (busy),
        .ops_done_o                (ops_done),
        .program_precheck_err_o    (pg_err),
        .program_unaligned_o       (pg_na),
        .program_pending_o         (pgbufnf)
    );

    /* One AHB word write transfer */
    task automatic ahb_write(input logic [31: 0] addr, input logic [31: 0] data);
        @(posedge hclk);
        #(1);
        a_addr  = addr;
        a_size  = SIZE_WORD;
        a_write = 1'b1;
        a_trans = TRANS_NONSEQ;
        d_wdata = data;
        @(posedge hclk);
        while (hreadyout !== 1'b1) begin
            @(posedge hclk);
        end
        #(1);
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
    endtask

    /* One AHB read transfer, any aligned size */
    task automatic ahb_read(input logic [31: 0] addr, input logic [2: 0] size,
                            output logic [31: 0] data);
        @(posedge hclk);
        #(1);
        a_addr  = addr;
        a_size  = size;
        a_write = 1'b0;
        a_trans = TRANS_NONSEQ;
        @(posedge hclk);
        while (hreadyout !== 1'b1) begin
            @(posedge hclk);
        end
        #(1);
        data    = hrdata;
        a_trans = TRANS_IDLE;
    endtask

    /* Program one page with a low and a high word */
    task automatic write_page(input int page, input logic [31: 0] low,
                              input logic [31: 0] high);
        ahb_write(page * 8, low);
        ahb_write(page * 8 + 4, high);
    endtask

    /* Compare one word and print the result */
    task automatic check_word(input string name, input logic [31: 0] addr,
                              input logic [31: 0] exp);
        logic [31: 0] got;
        ahb_read(addr, SIZE_WORD, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s @%04X got %08X expected %08X",
                     name, addr, got, exp);
        end else begin
            $display("PASS: %s @%04X = %08X", name, addr, got);
        end
    endtask

    /* Compare one byte lane and print the result */
    task automatic check_byte(input string name, input logic [31: 0] addr,
                              input logic [7: 0] exp);
        logic [31: 0] got;
        logic  [7: 0] lane;
        ahb_read(addr, SIZE_BYTE, got);
        lane = got[(addr[1: 0] * 8) +: 8];
        if (lane !== exp) begin
            error_count++;
            $display("FAIL: %s @%04X lane got %02X expected %02X",
                     name, addr, lane, exp);
        end else begin
            $display("PASS: %s @%04X byte = %02X", name, addr, lane);
        end
    endtask

    /* Compare one halfword lane and print the result */
    task automatic check_half(input string name, input logic [31: 0] addr,
                              input logic [15: 0] exp);
        logic [31: 0] got;
        logic [15: 0] lane;
        ahb_read(addr, SIZE_HALF, got);
        lane = got[(addr[1] * 16) +: 16];
        if (lane !== exp) begin
            error_count++;
            $display("FAIL: %s @%04X lane got %04X expected %04X",
                     name, addr, lane, exp);
        end else begin
            $display("PASS: %s @%04X half = %04X", name, addr, lane);
        end
    endtask

    /* One cycle sector erase request pulse with the given index */
    task automatic pulse_sector_erase(input int idx);
        @(posedge hclk);
        #(1);
        ser_idx = idx[5: 0];
        ser_req = 1'b1;
        @(posedge hclk);
        #(1);
        ser_req = 1'b0;
    endtask

    /* One cycle bank erase request pulse */
    task automatic pulse_bank_erase();
        @(posedge hclk);
        #(1);
        ber_req = 1'b1;
        @(posedge hclk);
        #(1);
        ber_req = 1'b0;
    endtask

    /* Wait for one operation, check its busy period and completion pulse.
       quiet mutes the pass report, expect_done drops the pulse check. */
    task automatic wait_busy(input string name, input int exp_cycles,
                             input bit quiet = 1'b0,
                             input bit expect_done = 1'b1);
        time t_start;
        time t_end;
        int  n = 0;
        int  cycles;

        done_pulses = 0;

        while (busy !== 1'b1) begin
            @(posedge hclk);
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
            @(posedge hclk);
            n++;
            if (n > 200000) begin
                error_count++;
                $display("FAIL: %s never finished", name);
                return;
            end
        end
        t_end = $time;
        repeat (2) @(posedge hclk);

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
        repeat (cycles) @(posedge hclk);
        if (busy !== 1'b0) begin
            error_count++;
            $display("FAIL: %s unexpected busy", name);
        end else begin
            $display("PASS: %s no operation started", name);
        end
    endtask

    initial begin
        a_addr  = 32'h0;
        a_size  = SIZE_WORD;
        a_write = 1'b0;
        a_trans = TRANS_IDLE;
        d_wdata = 32'h0;
        ser_req = 1'b0;
        ser_idx = 6'h00;
        ber_req = 1'b0;
        pg_en   = 1'b0;

        /* Reset */
        hreset_n = 1'b0;
        repeat (5) @(posedge hclk);
        hreset_n = 1'b1;
        repeat (2) @(posedge hclk);
        pg_en = 1'b1;

        /* Give the array a known blank baseline */
        pulse_bank_erase();
        wait_busy("cleanup bank erase", 16384 + BER_TICKS, 1'b1);

        /* I01: an unsupported write size is rejected with an AHB error */
        case_count++;
        $display("=== I%02d: unsupported write size is rejected ===",
                 case_count);
        @(posedge hclk);
        #(1);
        a_addr  = 32'h0000;
        a_size  = 3'b011;
        a_write = 1'b1;
        a_trans = TRANS_NONSEQ;
        d_wdata = 32'hBAD0_0001;
        @(posedge hclk);
        #(1);
        if ((hresp !== 1'b1) || (hreadyout !== 1'b0)) begin
            error_count++;
            $display("FAIL: I01 error phase 1 hresp=%b ready=%b",
                     hresp, hreadyout);
        end else begin
            $display("PASS: I01 error phase 1 seen");
        end
        @(posedge hclk);
        #(1);
        if ((hresp !== 1'b1) || (hreadyout !== 1'b1)) begin
            error_count++;
            $display("FAIL: I01 error phase 2 hresp=%b ready=%b",
                     hresp, hreadyout);
        end else begin
            $display("PASS: I01 error phase 2 seen");
        end
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
        @(posedge hclk);
        #(1);
        if (hresp !== 1'b0) begin
            error_count++;
            $display("FAIL: I01 response still in error");
        end else begin
            $display("PASS: I01 response back to okay");
        end
        check_word("I01 no data collected", 32'h0000, 32'hFFFF_FFFF);

        /* I02: an unaligned word write is rejected with an AHB error */
        case_count++;
        $display("=== I%02d: unaligned word write is rejected ===",
                 case_count);
        @(posedge hclk);
        #(1);
        a_addr  = 32'h0002;
        a_size  = SIZE_WORD;
        a_write = 1'b1;
        a_trans = TRANS_NONSEQ;
        d_wdata = 32'hBAD0_0002;
        @(posedge hclk);
        #(1);
        if ((hresp !== 1'b1) || (hreadyout !== 1'b0)) begin
            error_count++;
            $display("FAIL: I02 error phase 1 hresp=%b ready=%b",
                     hresp, hreadyout);
        end else begin
            $display("PASS: I02 error phase 1 seen");
        end
        @(posedge hclk);
        #(1);
        if ((hresp !== 1'b1) || (hreadyout !== 1'b1)) begin
            error_count++;
            $display("FAIL: I02 error phase 2 hresp=%b ready=%b",
                     hresp, hreadyout);
        end else begin
            $display("PASS: I02 error phase 2 seen");
        end
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
        @(posedge hclk);
        #(1);
        if (hresp !== 1'b0) begin
            error_count++;
            $display("FAIL: I02 response still in error");
        end else begin
            $display("PASS: I02 response back to okay");
        end
        check_word("I02 no data collected", 32'h0000, 32'hFFFF_FFFF);

        /* I03: byte and halfword reads must pick the right lanes */
        case_count++;
        $display("=== I%02d: byte and halfword read lanes ===",
                 case_count);
        write_page(6, 32'hAABB_CCDD, 32'h1122_3344);
        wait_busy("I03 program page 6", 7 + PROG_TICKS);
        check_word("I03 word read", 32'h0030, 32'hAABB_CCDD);
        check_byte("I03 byte 0", 32'h0030, 8'hDD);
        check_byte("I03 byte 1", 32'h0031, 8'hCC);
        check_byte("I03 byte 2", 32'h0032, 8'hBB);
        check_byte("I03 byte 3", 32'h0033, 8'hAA);
        check_half("I03 half 0", 32'h0030, 16'hCCDD);
        check_half("I03 half 1", 32'h0032, 16'hAABB);
        check_byte("I03 high word byte", 32'h0034, 8'h44);

        /* I04: a dirty low word makes the precheck reject the program */
        case_count++;
        $display("=== I%02d: precheck rejects a dirty low word ===",
                 case_count);
        write_page(10, 32'h0000_0000, 32'hFFFF_FFFF);
        wait_busy("I04 setup program", 7 + PROG_TICKS, 1'b1);
        err_pulses = 0;
        write_page(10, 32'h1111_1111, 32'h2222_2222);
        wait_busy("I04 rejected program", 5, 1'b0, 1'b0);
        if (err_pulses != 1) begin
            error_count++;
            $display("FAIL: I04 precheck error pulses %0d expected 1",
                     err_pulses);
        end else begin
            $display("PASS: I04 precheck error pulse seen");
        end
        check_word("I04 dirty low kept", 32'h0050, 32'h0000_0000);
        check_word("I04 blank high kept", 32'h0054, 32'hFFFF_FFFF);

        /* I05: a dirty high word makes the precheck reject the program */
        case_count++;
        $display("=== I%02d: precheck rejects a dirty high word ===",
                 case_count);
        write_page(11, 32'hFFFF_FFFF, 32'h0000_0000);
        wait_busy("I05 setup program", 7 + PROG_TICKS, 1'b1);
        err_pulses = 0;
        write_page(11, 32'h3333_3333, 32'h4444_4444);
        wait_busy("I05 rejected program", 5, 1'b0, 1'b0);
        if (err_pulses != 1) begin
            error_count++;
            $display("FAIL: I05 precheck error pulses %0d expected 1",
                     err_pulses);
        end else begin
            $display("PASS: I05 precheck error pulse seen");
        end
        check_word("I05 blank low kept", 32'h0058, 32'hFFFF_FFFF);
        check_word("I05 dirty high kept", 32'h005C, 32'h0000_0000);

        /* I06: a high word without a matching low word raises PGNA */
        case_count++;
        $display("=== I%02d: high word without low word raises PGNA ===",
                 case_count);
        na_pulses = 0;
        ahb_write(32'h0064, 32'hDEAD_BEEF);
        check_no_operation("I06 stray high word", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: I06 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: I06 unaligned pulse seen");
        end
        check_word("I06 low untouched", 32'h0060, 32'hFFFF_FFFF);
        check_word("I06 high untouched", 32'h0064, 32'hFFFF_FFFF);

        /* I07: a sector request and a write in the same cycle, erase wins */
        case_count++;
        $display("=== I%02d: erase and write in the same cycle ===",
                 case_count);
        @(posedge hclk);
        #(1);
        a_addr  = 32'h0068;
        a_size  = SIZE_WORD;
        a_write = 1'b1;
        a_trans = TRANS_NONSEQ;
        d_wdata = 32'h1234_5678;
        @(posedge hclk);
        #(1);
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
        ser_idx = 6'h00;
        ser_req = 1'b1;
        @(posedge hclk);
        #(1);
        ser_req = 1'b0;
        wait_busy("I07 sector erase wins", 256 + SER_TICKS);
        check_word("I07 write dropped", 32'h0068, 32'hFFFF_FFFF);
        /* The buffer must be clean: a lone high word raises PGNA */
        na_pulses = 0;
        ahb_write(32'h006C, 32'h5555_5555);
        check_no_operation("I07 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: I07 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: I07 no stale low word in the buffer");
        end
        check_word("I07 page still blank", 32'h006C, 32'hFFFF_FFFF);

        /* I08: a write during a program is dropped */
        case_count++;
        $display("=== I%02d: write during program is dropped ===",
                 case_count);
        ahb_write(32'h0070, 32'h1400_0001);
        ahb_write(32'h0074, 32'h1400_0002);
        while (busy !== 1'b1) begin
            @(posedge hclk);
        end
        ahb_write(32'h0078, 32'h1500_0001);
        while (busy !== 1'b0) begin
            @(posedge hclk);
        end
        repeat (2) @(posedge hclk);
        check_word("I08 program done", 32'h0070, 32'h1400_0001);
        check_word("I08 page 15 blank", 32'h0078, 32'hFFFF_FFFF);
        na_pulses = 0;
        ahb_write(32'h007C, 32'h1500_0002);
        check_no_operation("I08 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: I08 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: I08 no stale low word in the buffer");
        end
        write_page(15, 32'h1510_0001, 32'h1510_0002);
        wait_busy("I08 recovery page 15", 7 + PROG_TICKS);
        check_word("I08 page 15 new", 32'h0078, 32'h1510_0001);
        check_word("I08 page 15 high", 32'h007C, 32'h1510_0002);

        /* I09: a write during an erase is dropped */
        case_count++;
        $display("=== I%02d: write during erase is dropped ===",
                 case_count);
        pulse_sector_erase(2);
        while (busy !== 1'b1) begin
            @(posedge hclk);
        end
        ahb_write(32'h0C80, 32'h1910_0400);
        while (busy !== 1'b0) begin
            @(posedge hclk);
        end
        repeat (2) @(posedge hclk);
        na_pulses = 0;
        ahb_write(32'h0C84, 32'h1910_0401);
        check_no_operation("I09 buffer clean", 10);
        if (na_pulses != 1) begin
            error_count++;
            $display("FAIL: I09 unaligned pulses %0d expected 1", na_pulses);
        end else begin
            $display("PASS: I09 no stale low word in the buffer");
        end
        check_word("I09 page 400 blank", 32'h0C80, 32'hFFFF_FFFF);
        check_word("I09 page 400 high blank", 32'h0C84, 32'hFFFF_FFFF);

        /* I10: a sector request during a program is ignored */
        case_count++;
        $display("=== I%02d: erase request during program is ignored ===",
                 case_count);
        write_page(512, 32'h0400_0001, 32'h0400_0002);
        wait_busy("I10 sector 4 data", 7 + PROG_TICKS, 1'b1);
        ahb_write(32'h0000, 32'h0000_0001);
        ahb_write(32'h0004, 32'h0000_0002);
        while (busy !== 1'b1) begin
            @(posedge hclk);
        end
        @(posedge hclk);
        #(1);
        ser_idx = 6'h04;
        ser_req = 1'b1;
        @(posedge hclk);
        #(1);
        ser_req = 1'b0;
        while (busy !== 1'b0) begin
            @(posedge hclk);
        end
        check_no_operation("I10 after program", 20);
        check_word("I10 sector 4 kept", 32'h1000, 32'h0400_0001);
        check_word("I10 page 0 new", 32'h0000, 32'h0000_0001);
        check_word("I10 page 0 high", 32'h0004, 32'h0000_0002);

        repeat (10) @(posedge hclk);

        if (error_count == 0) begin
            $display("==== ALL CHECKS PASSED (%0d CASES) ====", case_count);
        end else begin
            $display("==== %0d CHECK(S) FAILED ====", error_count);
        end
        $finish;
    end

    /* Simulation timeout guard */
    initial begin
        repeat (300000) @(posedge hclk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
