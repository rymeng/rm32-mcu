`timescale 1ns / 1ps

module tb_flash_model_program;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Address ranges */
    localparam logic [31: 0] FLASH_BASE  = 32'h0000_0000;
    localparam logic [31: 0] FLASH_LIMIT = 32'h0000_FFFF;
    localparam logic [31: 0] FMC_BASE    = 32'h4004_0000;
    localparam logic [31: 0] FMC_LIMIT   = 32'h4004_03FF;

    /* FMC register offsets */
    localparam logic [31: 0] KEYR_ADDR = 32'h4004_0004;
    localparam logic [31: 0] CR_ADDR   = 32'h4004_0008;
    localparam logic [31: 0] CR2_ADDR  = 32'h4004_000C;
    localparam logic [31: 0] AR_ADDR   = 32'h4004_0040;
    localparam logic [31: 0] SR_ADDR   = 32'h4004_0080;
    localparam logic [31: 0] ISR_ADDR  = 32'h4004_0104;
    localparam logic [31: 0] ICR_ADDR  = 32'h4004_0108;

    /* Operation timing parameters, kept small for simulation */
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

    /* Bus master signals */
    logic         hclk = 1'b0;
    logic         hreset_n = 1'b0;
    logic [31: 0] a_addr;
    logic  [2: 0] a_size;
    logic         a_write;
    logic  [1: 0] a_trans;
    logic [31: 0] d_wdata;

    logic [31: 0] hrdata;
    logic         hreadyout;
    logic         hresp;

    /* Flash model read channel signals */
    logic [31: 0] flash_hrdata;
    logic         flash_hreadyout;
    logic         flash_hresp;

    /* Aggregated flash array status */
    logic         flash_busy;
    logic         flash_eop;
    logic         flash_pg_err;
    logic         flash_pg_na;
    logic         flash_pgbufnf;

    /* FMC flash control outputs */
    logic         flash_ser_req;
    logic  [5: 0] flash_ser_page;
    logic         flash_ber_req;
    logic         flash_pg_enable;

    logic [31: 0] fmc_hrdata;
    logic         fmc_hreadyout;
    logic         fmc_hresp;

    /* Read channel mux of the testbench bus */
    always @ (*) begin
        if ((a_addr >= FLASH_BASE) && (a_addr <= FLASH_LIMIT)) begin
            hrdata    = flash_hrdata;
            hreadyout = flash_hreadyout;
            hresp     = flash_hresp;
        end else begin
            hrdata    = fmc_hrdata;
            hreadyout = fmc_hreadyout;
            hresp     = fmc_hresp;
        end
    end

    flash_model_top #(
        .ADDR_WIDTH         (14),
        .SECTOR_ERASE_TICKS (SER_TICKS),
        .BANK_ERASE_TICKS   (BER_TICKS),
        .PROGRAM_TICKS      (PROG_TICKS)
    ) flash_model_subsystem (
        .hclk_i         (hclk),
        .hreset_n_i     (hreset_n),
        .hsel_i         ((a_addr >= FLASH_BASE) && (a_addr <= FLASH_LIMIT)),
        .haddr_i        (a_addr),
        .hwdata_i       (d_wdata),
        .hwrite_i       (a_write),
        .htrans_i       (a_trans),
        .hsize_i        (a_size),
        .hready_i       (1'b1),
        .hburst_i       (3'b000),
        .hprot_i        (4'b0001),
        .hmastlock_i    (1'b0),
        .hrdata_o       (flash_hrdata),
        .hreadyout_o    (flash_hreadyout),
        .hresp_o        (flash_hresp),
        .program_en_i              (flash_pg_enable),
        .sector_erase_req_i        (flash_ser_req),
        .sector_erase_sector_idx_i (flash_ser_page),
        .bank_erase_req_i          (flash_ber_req),
        .busy_o                    (flash_busy),
        .ops_done_o                (flash_eop),
        .program_precheck_err_o    (flash_pg_err),
        .program_unaligned_o       (flash_pg_na),
        .program_pending_o         (flash_pgbufnf)
    );

    fmc_top dut_fmc (
        .hclk_i            (hclk),
        .hreset_n_i        (hreset_n),
        .hsel_i            ((a_addr >= FMC_BASE) && (a_addr <= FMC_LIMIT)),
        .haddr_i           (a_addr),
        .hwdata_i          (d_wdata),
        .hwrite_i          (a_write),
        .htrans_i          (a_trans),
        .hsize_i           (a_size),
        .hready_i          (1'b1),
        .hburst_i          (3'b000),
        .hprot_i           (4'b0001),
        .hmastlock_i       (1'b0),
        .hrdata_o          (fmc_hrdata),
        .hreadyout_o       (fmc_hreadyout),
        .hresp_o           (fmc_hresp),
        .flash_model_bank_erase_req_o          (flash_ber_req),
        .flash_model_sector_erase_req_o        (flash_ser_req),
        .flash_model_sector_erase_sector_idx_o (flash_ser_page),
        .flash_model_program_en_o              (flash_pg_enable),
        .flash_model_busy_i                    (flash_busy),
        .flash_model_ops_done_i                (flash_eop),
        .flash_model_program_precheck_err_i    (flash_pg_err),
        .flash_model_program_unaligned_i       (flash_pg_na),
        .flash_model_program_pending_i         (flash_pgbufnf)
    );

    always #(CLK_PERIOD / 2) hclk = ~hclk;

    /* One AHB transfer, signals are held while the slave stalls */
    task automatic ahb_xfer(input logic [31: 0] addr,
                            input logic  [2: 0] size,
                            input logic         write,
                            input logic [31: 0] wdata,
                            output logic [31: 0] rdata,
                            output logic         err);
        /* Address phase */
        @(posedge hclk);
        #(1);
        a_addr  = addr;
        a_trans = TRANS_NONSEQ;
        a_size  = size;
        a_write = write;

        /* Align the write data on the byte lanes given by the address */
        case (size)
            SIZE_BYTE: begin
                d_wdata = wdata << (addr[1:0] * 8);
            end

            SIZE_HALF: begin
                d_wdata = wdata << (addr[1] * 16);
            end

            default: begin
                d_wdata = wdata;
            end
        endcase

        /* Data phase: wait until the slave accepts the transfer */
        @(posedge hclk);
        while (hreadyout !== 1'b1) begin
            @(posedge hclk);
        end
        #(1);
        rdata = hrdata;
        err   = hresp;

        /* Release the bus */
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
    endtask

    task automatic ahb_write(input logic [31: 0] addr,
                             input logic  [2: 0] size,
                             input logic [31: 0] data);
        logic [31: 0] rdata_dummy;
        logic         err_dummy;
        ahb_xfer(addr, size, 1'b1, data, rdata_dummy, err_dummy);
        if (err_dummy) begin
            error_count++;
            $display("FAIL: write @%08X got bus error", addr);
        end
    endtask

    /* A write that must be silently ignored without a bus error */
    task automatic ahb_write_ignored(input logic [31: 0] addr,
                                     input logic  [2: 0] size,
                                     input logic [31: 0] data);
        logic [31: 0] rdata_dummy;
        logic         err_dummy;
        ahb_xfer(addr, size, 1'b1, data, rdata_dummy, err_dummy);
        if (err_dummy !== 1'b0) begin
            error_count++;
            $display("FAIL: write @%08X size %0d got bus error", addr, size);
        end else begin
            $display("PASS: write @%08X size %0d ignored", addr, size);
        end
    endtask

    task automatic ahb_read(input logic [31: 0] addr,
                            input logic  [2: 0] size,
                            output logic [31: 0] data);
        logic err_dummy;
        ahb_xfer(addr, size, 1'b0, 32'h0, data, err_dummy);
        if (err_dummy) begin
            error_count++;
            $display("FAIL: read @%08X got bus error", addr);
        end
    endtask

    /* Three back-to-back 32 bit writes for exact cycle spacing */
    task automatic ahb_write_burst3(input logic [31: 0] addr_a,
                                    input logic [31: 0] data_a,
                                    input logic [31: 0] addr_b,
                                    input logic [31: 0] data_b,
                                    input logic [31: 0] addr_c,
                                    input logic [31: 0] data_c);
        @(posedge hclk);
        #(1);
        a_addr  = addr_a;
        a_size  = SIZE_WORD;
        a_write = 1'b1;
        a_trans = TRANS_NONSEQ;
        d_wdata = data_a;

        @(posedge hclk);
        #(1);
        a_addr  = addr_b;
        d_wdata = data_a;

        @(posedge hclk);
        #(1);
        a_addr  = addr_c;
        d_wdata = data_b;

        @(posedge hclk);
        #(1);
        d_wdata = data_c;

        @(posedge hclk);
        #(1);
        a_trans = TRANS_IDLE;
        a_write = 1'b0;
    endtask

    task automatic check_word(input string name, input logic [31: 0] addr,
                              input logic [31: 0] exp);
        logic [31: 0] got;
        ahb_read(addr, SIZE_WORD, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s got %08X expected %08X", name, got, exp);
        end else begin
            $display("PASS: %s = %08X", name, got);
        end
    endtask

    task automatic check_byte(input string name, input logic [31: 0] addr,
                              input logic [7: 0] exp);
        logic [31: 0] got;
        logic  [7: 0] lane;
        ahb_read(addr, SIZE_BYTE, got);
        lane = got[(addr[1:0] * 8) +: 8];
        if (lane !== exp) begin
            error_count++;
            $display("FAIL: %s lane got %02X expected %02X", name, lane, exp);
        end else begin
            $display("PASS: %s byte = %02X", name, lane);
        end
    endtask

    task automatic check_half(input string name, input logic [31: 0] addr,
                              input logic [15: 0] exp);
        logic [31: 0] got;
        logic [15: 0] lane;
        ahb_read(addr, SIZE_HALF, got);
        lane = got[(addr[1] * 16) +: 16];
        if (lane !== exp) begin
            error_count++;
            $display("FAIL: %s lane got %04X expected %04X", name, lane, exp);
        end else begin
            $display("PASS: %s half = %04X", name, lane);
        end
    endtask

    /* Wait for one flash operation to start and finish, optionally
       checking its BUSY duration in clock cycles */
    task automatic wait_busy_done(input string name, input int exp_cycles);
        time t_start;
        time t_end;
        int  n = 0;
        int  cycles;

        while (flash_busy !== 1'b1) begin
            @(posedge hclk);
            n++;
            if (n > 200) begin
                error_count++;
                $display("FAIL: %s operation never started", name);
                return;
            end
        end
        t_start = $time;

        n = 0;
        while (flash_busy !== 1'b0) begin
            @(posedge hclk);
            n++;
            if (n > 200000) begin
                error_count++;
                $display("FAIL: %s operation never finished", name);
                return;
            end
        end
        t_end = $time;
        repeat (2) @(posedge hclk);

        if (exp_cycles >= 0) begin
            cycles = (t_end - t_start) / CLK_PERIOD;
            if (cycles != exp_cycles) begin
                error_count++;
                $display("FAIL: %s busy cycles %0d expected %0d",
                         name, cycles, exp_cycles);
            end else begin
                $display("PASS: %s busy cycles = %0d", name, cycles);
            end
        end
    endtask

    task automatic fmc_unlock();
        logic [31: 0] rd;
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h5555_AAAA);
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h3333_CCCC);
        /* Let the strobed KEYR value propagate to the core key check */
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, SIZE_WORD, rd);
        if (rd[16] !== 1'b0) begin
            error_count++;
            $display("FAIL: FMC still locked");
        end
    endtask

    task automatic fmc_clear_isr();
        ahb_write(ICR_ADDR, SIZE_WORD, 32'h0000_0007);
    endtask

    initial begin
        a_addr  = 32'h0;
        a_size  = SIZE_WORD;
        a_write = 1'b0;
        a_trans = TRANS_IDLE;
        d_wdata = 32'h0;

        /* Reset */
        hreset_n = 1'b0;
        repeat (5) @(posedge hclk);
        hreset_n = 1'b1;
        repeat (2) @(posedge hclk);

        /* Unlock the FMC and enable programming */
        fmc_unlock();
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);

        /* Erase the first sector so that it reads as all ones */
        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0000);
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0002);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        wait_busy_done("sector erase 0", 256 + SER_TICKS);
        check_word("ISR EOP after erase", ISR_ADDR, 32'h0000_0001);
        fmc_clear_isr();
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);
        check_word("erased word 0", 32'h0000_0000, 32'hFFFF_FFFF);
        check_word("erased word 0x3FC", 32'h0000_03FC, 32'hFFFF_FFFF);

        /* Program the first 8 bytes of the flash */
        ahb_write(32'h0000_0000, SIZE_WORD, 32'hAABB_CCDD);
        repeat (2) @(posedge hclk);
        check_word("SR PGBUFNF set after word 0", SR_ADDR, 32'h0000_0002);
        ahb_write(32'h0000_0004, SIZE_WORD, 32'h1122_3344);
        fork
            wait_busy_done("program 8 bytes", 7 + PROG_TICKS);
            begin
                while (flash_busy !== 1'b1) begin
                    @(posedge hclk);
                end
                repeat (2) @(posedge hclk);
                check_word("SR busy, PGBUFNF clear during program", SR_ADDR,
                           32'h0000_0001);
            end
        join
        check_word("ISR EOP after program", ISR_ADDR, 32'h0000_0001);
        check_word("SR PGBUFNF set after program", SR_ADDR, 32'h0000_0002);
        fmc_clear_isr();
        check_word("programmed word 0", 32'h0000_0000, 32'hAABB_CCDD);
        check_word("programmed word 4", 32'h0000_0004, 32'h1122_3344);

        /* Byte and halfword reads must pick the right lanes */
        check_byte("byte 0 of word 0", 32'h0000_0000, 8'hDD);
        check_byte("byte 1 of word 0", 32'h0000_0001, 8'hCC);
        check_byte("byte 5 of word 4", 32'h0000_0005, 8'h33);
        check_byte("byte 7 of word 4", 32'h0000_0007, 8'h11);
        check_half("half 0 of word 0", 32'h0000_0000, 16'hCCDD);
        check_half("half 1 of word 4", 32'h0000_0006, 16'h1122);

        /* Programming into a not erased unit reports PGERR */
        ahb_write(32'h0000_0000, SIZE_WORD, 32'h0000_0000);
        ahb_write(32'h0000_0004, SIZE_WORD, 32'hFFFF_FFFF);
        wait_busy_done("program error", 5);
        check_word("ISR PGERR", ISR_ADDR, 32'h0000_0002);
        check_word("data unchanged 0", 32'h0000_0000, 32'hAABB_CCDD);
        check_word("data unchanged 4", 32'h0000_0004, 32'h1122_3344);
        fmc_clear_isr();

        /* A write that does not start on an aligned unit reports PGNA */
        ahb_write(32'h0000_0004, SIZE_WORD, 32'h5A5A_5A5A);
        repeat (3) @(posedge hclk);
        check_word("ISR PGNA", ISR_ADDR, 32'h0000_0004);
        check_word("SR PGBUFNF set after PGNA", SR_ADDR, 32'h0000_0002);
        fmc_clear_isr();

        /* A half filled buffer is dropped when the next unit starts */
        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0400);
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0002);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        wait_busy_done("sector erase 1", 256 + SER_TICKS);
        fmc_clear_isr();
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);

        ahb_write(32'h0000_0400, SIZE_WORD, 32'hDEAD_BEEF);
        repeat (3) @(posedge hclk);
        check_word("SR PGBUFNF set on half buffer", SR_ADDR,
                   32'h0000_0002);

        ahb_write(32'h0000_0410, SIZE_WORD, 32'hCAFE_BABE);
        repeat (3) @(posedge hclk);
        check_word("SR PGBUFNF set", SR_ADDR, 32'h0000_0002);
        check_word("stale half buffer dropped", 32'h0000_0400,
                   32'hFFFF_FFFF);
        check_word("next unit pending", 32'h0000_0410, 32'hFFFF_FFFF);

        ahb_write(32'h0000_0414, SIZE_WORD, 32'h1234_5678);
        wait_busy_done("full program after drop", 7 + PROG_TICKS);
        check_word("second unit programmed", 32'h0000_0410, 32'hCAFE_BABE);
        check_word("second unit high word", 32'h0000_0414, 32'h1234_5678);
        check_word("SR PGBUFNF set after program", SR_ADDR, 32'h0000_0002);

        /* Byte and halfword writes are ignored, only 32 bit writes work */
        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0800);
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0002);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        wait_busy_done("sector erase 2", 256 + SER_TICKS);
        fmc_clear_isr();
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);

        ahb_write_ignored(32'h0000_0800, SIZE_HALF, 32'h1111);
        ahb_write_ignored(32'h0000_0802, SIZE_HALF, 32'h2222);
        ahb_write_ignored(32'h0000_0800, SIZE_BYTE, 32'h33);
        repeat (3) @(posedge hclk);
        check_word("SR PGBUFNF set after ignored writes", SR_ADDR,
                   32'h0000_0002);
        check_word("nothing programmed by ignored writes", 32'h0000_0800,
                   32'hFFFF_FFFF);

        /* Programming works in the second flash bank as well */
        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_4000);
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0002);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        wait_busy_done("sector erase at 0x4000", 256 + SER_TICKS);
        fmc_clear_isr();
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);

        ahb_write(32'h0000_4000, SIZE_WORD, 32'h00C0_FFEE);
        ahb_write(32'h0000_4004, SIZE_WORD, 32'h0BAD_F00D);
        wait_busy_done("program at 0x4000", 7 + PROG_TICKS);
        check_word("word 0x4000", 32'h0000_4000, 32'h00C0_FFEE);
        check_word("word 0x4004", 32'h0000_4004, 32'h0BAD_F00D);
        check_word("word 0 untouched", 32'h0000_0000, 32'hAABB_CCDD);

        /* Repeating the low word keeps the buffer half filled until
           the high word arrives */
        fmc_clear_isr();
        ahb_write(32'h0000_0810, SIZE_WORD, 32'hA0A0_1111);
        repeat (2) @(posedge hclk);
        ahb_write(32'h0000_0810, SIZE_WORD, 32'hB0B0_2222);
        repeat (2) @(posedge hclk);
        ahb_write(32'h0000_0814, SIZE_WORD, 32'hC0C0_3333);
        wait_busy_done("repeat low word", 7 + PROG_TICKS);
        check_word("repeated low word wins", 32'h0000_0810,
                   32'hB0B0_2222);
        check_word("high word after repeat", 32'h0000_0814,
                   32'hC0C0_3333);
        check_word("no PGNA after repeat", ISR_ADDR, 32'h0000_0001);
        fmc_clear_isr();

        /* A write in the cycle right after the buffer fills is ignored */
        /* Monitor busy from before the burst so the first cycle counts */
        fork
            wait_busy_done("window write ignored", 7 + PROG_TICKS);
            ahb_write_burst3(32'h0000_0820, 32'h1111_AAAA,
                             32'h0000_0824, 32'h2222_BBBB,
                             32'h0000_0824, 32'h3333_CCCC);
        join
        check_word("window low word", 32'h0000_0820, 32'h1111_AAAA);
        check_word("window high word", 32'h0000_0824, 32'h2222_BBBB);
        check_word("no PGNA after window write", ISR_ADDR,
                   32'h0000_0001);

        /* A next page low word arriving while busy is dropped */
        fmc_clear_isr();
        fork
            wait_busy_done("next page low word dropped", 7 + PROG_TICKS);
            ahb_write_burst3(32'h0000_0830, 32'h0A0A_1111,
                             32'h0000_0834, 32'h0A0A_2222,
                             32'h0000_0840, 32'h0A0A_3333);
        join
        check_word("unit 0830 low word", 32'h0000_0830, 32'h0A0A_1111);
        check_word("unit 0830 high word", 32'h0000_0834, 32'h0A0A_2222);
        check_word("next page low word dropped", 32'h0000_0840,
                   32'hFFFF_FFFF);
        check_word("no PGNA after dropped low word", ISR_ADDR,
                   32'h0000_0001);
        fmc_clear_isr();

        /* With CR.PG cleared the flash ignores programming writes */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0000);
        ahb_write(32'h0000_0800, SIZE_WORD, 32'hFFFF_FFFF);
        ahb_write(32'h0000_0804, SIZE_WORD, 32'hFFFF_FFFF);
        repeat (5) @(posedge hclk);
        check_word("SR idle with PG off", SR_ADDR, 32'h0000_0000);
        check_word("no program with PG off", 32'h0000_0800,
                   32'hFFFF_FFFF);

        repeat (10) @(posedge hclk);

        if (error_count == 0) begin
            $display("==== ALL CHECKS PASSED ====");
        end else begin
            $display("==== %0d CHECK(S) FAILED ====", error_count);
        end
        $finish;
    end

    /* Simulation timeout guard */
    initial begin
        repeat (200000) @(posedge hclk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
