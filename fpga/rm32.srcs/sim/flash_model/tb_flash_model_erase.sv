`timescale 1ns / 1ps

module tb_flash_model_erase;

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
    localparam logic [31: 0] ISR_ADDR  = 32'h4004_0104;
    localparam logic [31: 0] ICR_ADDR  = 32'h4004_0108;

    /* Operation timing parameters, kept small for simulation */
    localparam int PROG_TICKS = 32;
    localparam int SER_TICKS  = 300;
    localparam int BER_TICKS  = 4200;

    /* AHB encodings */
    localparam logic [1: 0] TRANS_IDLE   = 2'b00;
    localparam logic [1: 0] TRANS_NONSEQ = 2'b10;

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

    /* Count the erase requests issued by the FMC */
    int ser_req_count = 0;
    int ber_req_count = 0;

    always @(posedge hclk) begin
        if (flash_ser_req) begin
            ser_req_count++;
        end

        if (flash_ber_req) begin
            ber_req_count++;
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
        .bank_erase_req_i          (flash_ber_req),
        .sector_erase_req_i        (flash_ser_req),
        .sector_erase_sector_idx_i (flash_ser_page),
        .program_en_i              (flash_pg_enable),
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
        d_wdata = wdata;

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
                             input logic [31: 0] data);
        logic [31: 0] rdata_dummy;
        logic         err_dummy;
        ahb_xfer(addr, SIZE_WORD, 1'b1, data, rdata_dummy, err_dummy);
        if (err_dummy) begin
            error_count++;
            $display("FAIL: write @%08X got bus error", addr);
        end
    endtask

    task automatic ahb_read(input logic [31: 0] addr,
                            output logic [31: 0] data);
        logic err_dummy;
        ahb_xfer(addr, SIZE_WORD, 1'b0, 32'h0, data, err_dummy);
        if (err_dummy) begin
            error_count++;
            $display("FAIL: read @%08X got bus error", addr);
        end
    endtask

    task automatic check_word(input string name, input logic [31: 0] addr,
                              input logic [31: 0] exp);
        logic [31: 0] got;
        ahb_read(addr, got);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s got %08X expected %08X", name, got, exp);
        end else begin
            $display("PASS: %s = %08X", name, got);
        end
    endtask

    task automatic check_count(input string name, input int got, input int exp);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s %0d expected %0d", name, got, exp);
        end else begin
            $display("PASS: %s = %0d", name, got);
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
        ahb_write(KEYR_ADDR, 32'h5555_AAAA);
        ahb_write(KEYR_ADDR, 32'h3333_CCCC);
        /* Let the strobed KEYR value propagate to the core key check */
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        if (rd[16] !== 1'b0) begin
            error_count++;
            $display("FAIL: FMC still locked");
        end
    endtask

    task automatic fmc_clear_isr();
        ahb_write(ICR_ADDR, 32'h0000_0007);
    endtask

    task automatic program_unit(input logic [31: 0] addr,
                                input logic [31: 0] data0,
                                input logic [31: 0] data1);
        ahb_write(addr, data0);
        ahb_write(addr + 32'h4, data1);
        wait_busy_done("program unit", 7 + PROG_TICKS);
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

        fmc_unlock();

        /* Bank erase turns the whole flash model into all ones */
        ahb_write(CR_ADDR, 32'h0000_0004);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("bank erase", 16384 + BER_TICKS);
        check_word("ISR EOP after bank erase", ISR_ADDR, 32'h0000_0001);
        fmc_clear_isr();
        check_word("bank erased word 0", 32'h0000_0000, 32'hFFFF_FFFF);
        check_word("bank erased word 0x4000", 32'h0000_4000, 32'hFFFF_FFFF);
        check_word("bank erased word 0x8000", 32'h0000_8000, 32'hFFFF_FFFF);
        check_word("bank erased word 0xFC00", 32'h0000_FC00, 32'hFFFF_FFFF);

        /* Program three units in different places */
        ahb_write(CR_ADDR, 32'h0000_0001);
        program_unit(32'h0000_0000, 32'h1122_3344, 32'h5566_7788);
        program_unit(32'h0000_0400, 32'h99AA_BBCC, 32'hDDEE_FF00);
        program_unit(32'h0000_4000, 32'h0102_0304, 32'h0506_0708);
        fmc_clear_isr();

        /* Sector erase of the first page of bank 0 */
        ahb_write(AR_ADDR, 32'h0000_0000);
        ahb_write(CR_ADDR, 32'h0000_0002);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("sector erase page0", 256 + SER_TICKS);
        fmc_clear_isr();
        check_word("erased word 0", 32'h0000_0000, 32'hFFFF_FFFF);
        check_word("erased word 4", 32'h0000_0004, 32'hFFFF_FFFF);
        check_word("kept word 0x400", 32'h0000_0400, 32'h99AA_BBCC);
        check_word("kept word 0x404", 32'h0000_0404, 32'hDDEE_FF00);
        check_word("kept word 0x4000", 32'h0000_4000, 32'h0102_0304);

        /* Sector erase of the first page of bank 1 */
        ahb_write(AR_ADDR, 32'h0000_4000);
        ahb_write(CR_ADDR, 32'h0000_0002);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("sector erase at 0x4000", 256 + SER_TICKS);
        fmc_clear_isr();
        check_word("erased word 0x4000", 32'h0000_4000, 32'hFFFF_FFFF);
        check_word("erased word 0x4004", 32'h0000_4004, 32'hFFFF_FFFF);
        check_word("kept word 0x400", 32'h0000_0400, 32'h99AA_BBCC);

        /* A second bank erase removes the remaining data */
        ahb_write(CR_ADDR, 32'h0000_0004);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("bank erase 2", 16384 + BER_TICKS);
        fmc_clear_isr();
        check_word("bank erased 0x400", 32'h0000_0400, 32'hFFFF_FFFF);
        check_word("bank erased 0x8000", 32'h0000_8000, 32'hFFFF_FFFF);

        /* A misaligned AR is masked to the sector start and erased */
        ahb_write(AR_ADDR, 32'h0000_0404);
        ahb_write(CR_ADDR, 32'h0000_0002);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("masked sector erase", 256 + SER_TICKS);
        check_word("ISR EOP after masked erase", ISR_ADDR, 32'h0000_0001);
        check_word("CR2 START self cleared", CR2_ADDR, 32'h0000_0000);
        check_word("CR1 keeps SER", CR_ADDR, 32'h0000_0002);
        fmc_clear_isr();

        /* With SER and BER enabled at the same time, bank erase wins */
        ahb_write(CR_ADDR, 32'h0000_0001);
        program_unit(32'h0000_0000, 32'h0A0B_0C0D, 32'h0E0F_1011);
        program_unit(32'h0000_0400, 32'h2021_2223, 32'h2425_2627);
        fmc_clear_isr();

        ahb_write(AR_ADDR, 32'h0000_0000);
        ahb_write(CR_ADDR, 32'h0000_0006);
        ahb_write(CR2_ADDR, 32'h0000_0001);
        wait_busy_done("priority bank erase", 16384 + BER_TICKS);
        fmc_clear_isr();
        check_word("erased word 0", 32'h0000_0000, 32'hFFFF_FFFF);
        check_word("erased word 0x400 after priority", 32'h0000_0400,
                   32'hFFFF_FFFF);
        check_count("ser request count", ser_req_count, 3);
        check_count("ber request count", ber_req_count, 3);

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
        repeat (300000) @(posedge hclk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
