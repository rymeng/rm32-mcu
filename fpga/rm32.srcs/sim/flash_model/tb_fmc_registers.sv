`timescale 1ns / 1ps

module tb_fmc_registers;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */

    /* Address range of the FMC slave */
    localparam logic [31: 0] FMC_BASE  = 32'h4004_0000;
    localparam logic [31: 0] FMC_LIMIT = 32'h4004_03FF;

    /* Register offsets */
    localparam logic [31: 0] ACR_ADDR = 32'h4004_0000;
    localparam logic [31: 0] KEYR_ADDR = 32'h4004_0004;
    localparam logic [31: 0] CR_ADDR   = 32'h4004_0008;
    localparam logic [31: 0] CR2_ADDR  = 32'h4004_000C;
    localparam logic [31: 0] AR_ADDR   = 32'h4004_0040;
    localparam logic [31: 0] SR_ADDR   = 32'h4004_0080;
    localparam logic [31: 0] IER_ADDR  = 32'h4004_0100;
    localparam logic [31: 0] ISR_ADDR  = 32'h4004_0104;
    localparam logic [31: 0] ICR_ADDR  = 32'h4004_0108;

    /* AHB encodings */
    localparam logic [1: 0] TRANS_IDLE   = 2'b00;
    localparam logic [1: 0] TRANS_NONSEQ = 2'b10;

    localparam logic [2: 0] SIZE_BYTE = 3'b000;
    localparam logic [2: 0] SIZE_HALF = 3'b001;
    localparam logic [2: 0] SIZE_WORD = 3'b010;

    int error_count = 0;

    /* DUT port signals */
    logic         hclk = 1'b0;
    logic         hreset_n = 1'b0;
    logic         hsel;
    logic [31: 0] haddr;
    logic [31: 0] hwdata;
    logic         hwrite;
    logic  [1: 0] htrans;
    logic  [2: 0] hsize;
    logic         hready;
    logic  [2: 0] hburst;
    logic  [3: 0] hprot;
    logic         hmastlock;
    logic [31: 0] hrdata;
    logic         hreadyout;
    logic         hresp;

    logic         flash_ser_req;
    logic  [5: 0] flash_ser_page;
    logic         flash_ber_req;
    logic         flash_pg_enable;
    logic         flash_busy   = 1'b0;
    logic         flash_eop    = 1'b0;
    logic         flash_pg_err = 1'b0;
    logic         flash_pg_na  = 1'b0;
    logic         flash_pgbufnf = 1'b0;

    fmc_top dut (
        .hclk_i            (hclk),
        .hreset_n_i        (hreset_n),
        .hsel_i            (hsel),
        .haddr_i           (haddr),
        .hwdata_i          (hwdata),
        .hwrite_i          (hwrite),
        .htrans_i          (htrans),
        .hsize_i           (hsize),
        .hready_i          (hready),
        .hburst_i          (hburst),
        .hprot_i           (hprot),
        .hmastlock_i       (hmastlock),
        .hrdata_o          (hrdata),
        .hreadyout_o       (hreadyout),
        .hresp_o           (hresp),
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

    /* Count the erase requests issued by the FMC */
    int         ser_req_count = 0;
    int         ber_req_count = 0;
    logic [5: 0] ser_page_seen = 6'b0;

    always @(posedge hclk) begin
        if (flash_ser_req) begin
            ser_req_count++;
            ser_page_seen <= flash_ser_page;
        end

        if (flash_ber_req) begin
            ber_req_count++;
        end
    end

    /* Model a flash bank that acknowledges one erase request */
    int erase_wait = 0;

    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            flash_busy <= 1'b0;
            flash_eop  <= 1'b0;
            erase_wait <= 0;
        end else begin
            flash_eop <= 1'b0;

            if (flash_ser_req | flash_ber_req) begin
                flash_busy <= 1'b1;
                erase_wait <= 16;
            end else if (flash_busy) begin
                if (erase_wait == 0) begin
                    flash_busy <= 1'b0;
                    flash_eop  <= 1'b1;
                end else begin
                    erase_wait <= erase_wait - 1;
                end
            end
        end
    end

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
        hsel   = (addr >= FMC_BASE) && (addr <= FMC_LIMIT);
        haddr  = addr;
        htrans = TRANS_NONSEQ;
        hsize  = size;
        hwrite = write;

        /* Align the write data on the byte lanes given by the address */
        case (size)
            SIZE_BYTE: begin
                hwdata = wdata << (addr[1:0] * 8);
            end

            SIZE_HALF: begin
                hwdata = wdata << (addr[1] * 16);
            end

            default: begin
                hwdata = wdata;
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
        hsel   = 1'b0;
        htrans = TRANS_IDLE;
        hwrite = 1'b0;
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

    task automatic ahb_read(input logic [31: 0] addr,
                            output logic [31: 0] data);
        logic err_dummy;
        ahb_xfer(addr, SIZE_WORD, 1'b0, 32'h0, data, err_dummy);
        if (err_dummy) begin
            error_count++;
            $display("FAIL: read @%08X got bus error", addr);
        end
    endtask

    task automatic check32(input string name, input logic [31: 0] got,
                           input logic [31: 0] exp);
        if (got !== exp) begin
            error_count++;
            $display("FAIL: %s got %08X expected %08X", name, got, exp);
        end else begin
            $display("PASS: %s = %08X", name, got);
        end
    endtask

    /* Wait until the modelled bank finishes its erase operation */
    task automatic wait_erase_done();
        while (flash_busy !== 1'b0) begin
            @(posedge hclk);
        end
        repeat (2) @(posedge hclk);
    endtask

    /* Emulate a one-cycle pulse on a flash status input */
    task automatic pulse_pg_err();
        @(posedge hclk);
        #(1);
        flash_pg_err = 1'b1;
        @(posedge hclk);
        #(1);
        flash_pg_err = 1'b0;
    endtask

    task automatic pulse_pg_na();
        @(posedge hclk);
        #(1);
        flash_pg_na = 1'b1;
        @(posedge hclk);
        #(1);
        flash_pg_na = 1'b0;
    endtask

    logic [31: 0] rd;

    initial begin
        hsel   = 1'b0;
        haddr  = 32'h0;
        hwdata = 32'h0;
        hwrite = 1'b0;
        htrans = TRANS_IDLE;
        hsize  = SIZE_WORD;
        hready = 1'b1;
        hburst = 3'b000;
        hprot  = 4'b0001;
        hmastlock = 1'b0;

        /* Reset */
        hreset_n = 1'b0;
        repeat (5) @(posedge hclk);
        hreset_n = 1'b1;
        repeat (2) @(posedge hclk);

        /* Reset values */
        ahb_read(ACR_ADDR, rd);
        check32("ACR reset", rd, 32'h0000_0000);
        ahb_read(CR_ADDR, rd);
        check32("CR reset (LOCK set)", rd, 32'h0001_0000);
        ahb_read(AR_ADDR, rd);
        check32("AR reset", rd, 32'h0000_0000);
        ahb_read(SR_ADDR, rd);
        check32("SR reset", rd, 32'h0000_0000);
        ahb_read(CR2_ADDR, rd);
        check32("CR2 reset", rd, 32'h0000_0000);
        ahb_read(IER_ADDR, rd);
        check32("IER read zero", rd, 32'h0000_0000);
        ahb_read(ISR_ADDR, rd);
        check32("ISR reset", rd, 32'h0000_0000);

        /* ACR is accessible without unlock */
        ahb_write(ACR_ADDR, SIZE_WORD, 32'h0000_000A);
        ahb_read(ACR_ADDR, rd);
        check32("ACR write/read", rd, 32'h0000_000A);

        /* CR and AR are write protected while locked */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0007);
        ahb_read(CR_ADDR, rd);
        check32("CR locked write ignored", rd, 32'h0001_0000);

        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0400);
        ahb_read(AR_ADDR, rd);
        check32("AR locked write ignored", rd, 32'h0000_0000);

        /* Writing CR1.LOCK while locked keeps the FMC locked */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0001_0000);
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        check32("CR stays locked after LOCK write", rd, 32'h0001_0000);

        /* Wrong unlock sequence resets the key step */
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h5555_AAAA);
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h1111_1111);
        ahb_read(CR_ADDR, rd);
        check32("CR still locked after bad key", rd, 32'h0001_0000);

        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h3333_CCCC);
        ahb_read(CR_ADDR, rd);
        check32("CR still locked after lone key2", rd, 32'h0001_0000);

        /* Correct unlock sequence */
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h5555_AAAA);
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h3333_CCCC);
        /* Let the strobed KEYR value propagate to the core key check */
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        check32("CR unlocked", rd, 32'h0000_0000);

        ahb_read(KEYR_ADDR, rd);
        check32("KEYR reads as zero", rd, 32'h0000_0000);

        /* CR bits and AR after unlock */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0007);
        ahb_read(CR_ADDR, rd);
        check32("CR PG/SER/BER set", rd, 32'h0000_0007);

        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0400);
        ahb_read(AR_ADDR, rd);
        check32("AR write/read", rd, 32'h0000_0400);

        /* Program enable output follows unlock and CR.PG */
        check32("flash_pg_enable", {31'b0, flash_pg_enable}, 32'h1);

        /* ISR set by flash error pulses, cleared by writing one to ICR */
        pulse_pg_err();
        ahb_read(ISR_ADDR, rd);
        check32("ISR PGERR set", rd, 32'h0000_0002);

        pulse_pg_na();
        ahb_read(ISR_ADDR, rd);
        check32("ISR PGNA set", rd, 32'h0000_0006);

        /* ICR: writing zero keeps the flag, writing one clears it */
        ahb_write(ICR_ADDR, SIZE_WORD, 32'h0000_0000);
        ahb_read(ISR_ADDR, rd);
        check32("ISR kept by ICR write 0", rd, 32'h0000_0006);

        ahb_write(ICR_ADDR, SIZE_WORD, 32'h0000_0002);
        ahb_read(ISR_ADDR, rd);
        check32("ISR PGERR cleared by write 1", rd, 32'h0000_0004);

        ahb_write(ICR_ADDR, SIZE_WORD, 32'h0000_0004);
        ahb_read(ISR_ADDR, rd);
        check32("ISR PGNA cleared by write 1", rd, 32'h0000_0000);

        /* Quiesce erase enables, then set the start bit by byte write */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0001);
        ahb_write(CR2_ADDR, SIZE_BYTE, 32'h0000_0001);
        repeat (2) @(posedge hclk);
        ahb_read(CR2_ADDR, rd);
        check32("CR2 byte START set", rd, 32'h0000_0001);
        ahb_read(CR_ADDR, rd);
        check32("CR1 keeps PG only", rd, 32'h0000_0001);
        check32("no ser request issued", {28'b0, ser_req_count[3:0]}, 32'h0);
        check32("no ber request issued", {28'b0, ber_req_count[3:0]}, 32'h0);

        /* A misaligned AR is masked down to the sector start and erased */
        ahb_write(AR_ADDR, SIZE_WORD, 32'h0000_0404);
        ahb_read(AR_ADDR, rd);
        check32("AR rounded to sector start", rd, 32'h0000_0400);
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0002);
        repeat (4) @(posedge hclk);
        check32("ser request count", {28'b0, ser_req_count[3:0]}, 32'h1);
        check32("ser page masked to 1", {26'b0, ser_page_seen}, 32'h01);
        check32("no ber request issued", {28'b0, ber_req_count[3:0]}, 32'h0);

        ahb_read(CR2_ADDR, rd);
        check32("CR2 START self cleared", rd, 32'h0000_0000);
        ahb_read(CR_ADDR, rd);
        check32("CR1 keeps SER", rd, 32'h0000_0002);

        ahb_read(ISR_ADDR, rd);
        check32("ISR clean before erase completes", rd, 32'h0000_0000);

        ahb_read(SR_ADDR, rd);
        check32("SR BUSY during erase", rd, 32'h0000_0001);

        wait_erase_done();
        ahb_read(SR_ADDR, rd);
        check32("SR BUSY cleared", rd, 32'h0000_0000);
        ahb_read(ISR_ADDR, rd);
        check32("ISR EOP set", rd, 32'h0000_0001);

        ahb_write(ICR_ADDR, SIZE_WORD, 32'h0000_0007);

        /* Bank erase is used when SER is not enabled */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0004);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        repeat (4) @(posedge hclk);
        check32("ber request count", {28'b0, ber_req_count[3:0]}, 32'h1);

        wait_erase_done();

        /* With SER and BER both set the bank erase wins */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0006);
        ahb_write(CR2_ADDR, SIZE_WORD, 32'h0000_0001);
        repeat (4) @(posedge hclk);
        check32("ser request count still", {28'b0, ser_req_count[3:0]}, 32'h1);
        check32("ber request count 2", {28'b0, ber_req_count[3:0]}, 32'h2);

        wait_erase_done();

        /* Software re-locks the FMC by writing CR1.LOCK */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0001_0000);
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        check32("CR1 LOCK set by software", rd, 32'h0001_0000);

        /* A re-locked FMC ignores CR writes and accepts the key again */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0000_0007);
        ahb_read(CR_ADDR, rd);
        check32("CR1 write ignored after re-lock", rd, 32'h0001_0000);

        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h5555_AAAA);
        ahb_write(KEYR_ADDR, SIZE_WORD, 32'h3333_CCCC);
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        check32("CR1 unlocked again", rd, 32'h0000_0000);

        /* Re-locking clears the enables regardless of the write payload */
        ahb_write(CR_ADDR, SIZE_WORD, 32'h0001_0007);
        repeat (2) @(posedge hclk);
        ahb_read(CR_ADDR, rd);
        check32("CR1 re-lock clears enables", rd, 32'h0001_0000);

        if (error_count == 0) begin
            $display("==== ALL CHECKS PASSED ====");
        end else begin
            $display("==== %0d CHECK(S) FAILED ====", error_count);
        end
        $finish;
    end

    /* Simulation timeout guard */
    initial begin
        repeat (20000) @(posedge hclk);
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
