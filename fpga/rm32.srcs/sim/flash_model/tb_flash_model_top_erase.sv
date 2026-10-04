`timescale 1ns / 1ps

/* Top level flash model testbench: bank erase and every sector erase.
   The DUT is flash_model_top, driven through its AHB slave interface and
   its direct FMC style control ports. */
module tb_flash_model_top_erase;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Operation timings, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    /* Geometry of one flash bank */
    localparam int SECTORS          = 64;
    localparam int WORDS_PER_SECTOR = 256;
    localparam int PAGES_PER_SECTOR = WORDS_PER_SECTOR / 2;

    /* AHB encodings */
    localparam logic [1: 0] TRANS_IDLE   = 2'b00;
    localparam logic [1: 0] TRANS_NONSEQ = 2'b10;

    localparam logic [2: 0] SIZE_WORD = 3'b010;

    int error_count = 0;
    int case_count  = 0;
    int done_pulses = 0;

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

    /* Count the one cycle operation completion pulses */
    always @(posedge hclk) begin
        if (ops_done) begin
            done_pulses++;
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

    /* Page data helpers, every sector gets a unique pair of words */
    function automatic logic [31: 0] sector_low(input int s);
        return 32'h5A5A_0000 + s[31: 0];
    endfunction

    function automatic logic [31: 0] sector_high(input int s);
        return 32'hA5A5_0000 + s[31: 0];
    endfunction

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

    /* Compare one word, only a mismatch is printed */
    task automatic check_word_q(input string name, input logic [31: 0] addr,
                                input logic [31: 0] exp);
        logic [31: 0] got;
        ahb_read(addr, SIZE_WORD, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s @%04X got %08X expected %08X",
                     name, addr, got, exp);
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
       Call it right after the trigger so that the timing stays aligned. */
    task automatic wait_busy(input string name, input int exp_cycles,
                             input bit quiet = 1'b0);
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

        if (done_pulses != 1) begin
            error_count++;
            $display("FAIL: %s ops_done pulses %0d expected 1",
                     name, done_pulses);
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

        /* T01: the pristine bank erases to all ones */
        case_count++;
        $display("=== T%02d: bank erase on a pristine array ===",
                 case_count);
        pulse_bank_erase();
        wait_busy("T01 bank erase", 16384 + BER_TICKS);
        check_word("T01 blank", 32'h0000, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h0800, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h1554, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h2000, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h2AA8, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h3C00, 32'hFFFF_FFFF);
        check_word("T01 blank", 32'h3FFC, 32'hFFFF_FFFF);

        /* T02: data written before a bank erase must disappear */
        case_count++;
        $display("=== T%02d: bank erase after programming pages ===",
                 case_count);
        write_page(0, 32'h1111_0001, 32'h2222_0001);
        wait_busy("T02 program page 0", 7 + PROG_TICKS);
        write_page(100, 32'h1111_0064, 32'h2222_0064);
        wait_busy("T02 program page 100", 7 + PROG_TICKS);
        write_page(1500, 32'h1111_05DC, 32'h2222_05DC);
        wait_busy("T02 program page 1500", 7 + PROG_TICKS);
        write_page(2047, 32'h1111_07FF, 32'h2222_07FF);
        wait_busy("T02 program page 2047", 7 + PROG_TICKS);
        pulse_bank_erase();
        wait_busy("T02 bank erase", 16384 + BER_TICKS);
        check_word("T02 erased", 32'h0000, 32'hFFFF_FFFF);
        check_word("T02 erased", 32'h0320, 32'hFFFF_FFFF);
        check_word("T02 erased", 32'h1770, 32'hFFFF_FFFF);
        check_word("T02 erased", 32'h2EE0, 32'hFFFF_FFFF);
        check_word("T02 erased", 32'h3FF8, 32'hFFFF_FFFF);

        /* Prepare one programmed page in every sector */
        for (int s = 0; s < SECTORS; s = s + 1) begin
            write_page(s * PAGES_PER_SECTOR, sector_low(s), sector_high(s));
            wait_busy("sector data", 7 + PROG_TICKS, 1'b1);
        end

        /* T03..T18: erase every single sector, the neighbours keep data */
        for (int s = 0; s < SECTORS; s = s + 1) begin
            case_count++;
            $display("=== T%02d: sector erase of sector %0d ===",
                     case_count, s);
            pulse_sector_erase(s);
            wait_busy($sformatf("T%02d sector %0d erase", case_count, s),
                      256 + SER_TICKS);
            check_word($sformatf("T%02d sector %0d blank", case_count, s),
                       s * 1024, 32'hFFFF_FFFF);
            check_word($sformatf("T%02d sector %0d blank+", case_count, s),
                       s * 1024 + 4, 32'hFFFF_FFFF);

            if (s < SECTORS - 1) begin
                check_word($sformatf("T%02d next sector keeps data",
                                     case_count),
                           (s + 1) * 1024, sector_low(s + 1));
                check_word($sformatf("T%02d last sector keeps data",
                                     case_count),
                           (SECTORS - 1) * 1024, sector_low(SECTORS - 1));
            end
            if (s > 0) begin
                check_word($sformatf("T%02d previous stays blank",
                                     case_count),
                           (s - 1) * 1024, 32'hFFFF_FFFF);
            end
        end

        /* T19: the highest sector indexes address real sectors */
        case_count++;
        $display("=== T%02d: high sector indexes address real sectors ===",
                 case_count);
        write_page(0, 32'hDEAD_0001, 32'hBEEF_0001);
        wait_busy("T19 program page 0", 7 + PROG_TICKS);
        pulse_sector_erase(6'h10);
        wait_busy("T19 erase sector 0x10", 256 + SER_TICKS);
        check_word("T19 sector 0x10 blank", 16 * 1024, 32'hFFFF_FFFF);
        check_word("T19 page kept after 0x10", 32'h0000, 32'hDEAD_0001);
        pulse_sector_erase(6'h3F);
        wait_busy("T19 erase sector 0x3F", 256 + SER_TICKS);
        check_word("T19 sector 0x3F blank", 63 * 1024, 32'hFFFF_FFFF);
        check_word("T19 page kept after 0x3F", 32'h0000, 32'hDEAD_0001);

        /* T20: erase all even sectors, the odd sectors keep their data */
        case_count++;
        $display("=== T%02d: interleaved sector erase ===", case_count);
        pulse_bank_erase();
        wait_busy("T20 cleanup bank erase", 16384 + BER_TICKS, 1'b1);
        for (int s = 0; s < SECTORS; s = s + 1) begin
            write_page(s * PAGES_PER_SECTOR, sector_low(s), sector_high(s));
            wait_busy("sector data", 7 + PROG_TICKS, 1'b1);
        end
        for (int s = 0; s < SECTORS; s = s + 2) begin
            pulse_sector_erase(s);
            wait_busy($sformatf("T20 erase sector %0d", s),
                      256 + SER_TICKS, 1'b1);
        end
        for (int s = 0; s < SECTORS; s = s + 1) begin
            if ((s % 2) == 0) begin
                check_word_q("T20 even blank", s * 1024, 32'hFFFF_FFFF);
            end else begin
                check_word_q("T20 odd kept", s * 1024, sector_low(s));
                check_word_q("T20 odd kept", s * 1024 + 4, sector_high(s));
            end
        end
        $display("PASS: T20 even sectors blank, odd sectors intact");

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
