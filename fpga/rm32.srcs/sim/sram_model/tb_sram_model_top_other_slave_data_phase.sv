`timescale 1ns / 1ps

/* Case: the data phase of the other slave overlaps this slave (D2)
   A zero wait state slave keeps this slave at zero wait, and a delayed
   data phase holds the bus low without breaking this slave address phase */

module tb_sram_model_top_other_slave_data_phase;

    localparam int CLK_PERIOD = 20;         /* 50 MHz, as in the design */
    localparam int ADDR_WIDTH = 12;         /* 16 KB memory space */

    /* Address ranges: this slave and another slave on the bus */
    localparam logic [31: 0] BRAM_BASE   = 32'h0000_0000;
    localparam logic [31: 0] BRAM_LIMIT  = 32'h0000_3FFF;
    localparam logic [31: 0] OTHER_BASE  = 32'h4000_0000;
    localparam logic [31: 0] OTHER_LIMIT = 32'h4000_03FF;

    /* AHB encodings */
    localparam logic [1: 0] TRANS_IDLE   = 2'b00;
    localparam logic [1: 0] TRANS_NONSEQ = 2'b10;
    localparam logic [1: 0] TRANS_SEQ    = 2'b11;

    localparam logic [2: 0] SIZE_BYTE    = 3'b000;
    localparam logic [2: 0] SIZE_HALF    = 3'b001;
    localparam logic [2: 0] SIZE_WORD    = 3'b010;

    localparam logic [2: 0] BURST_SINGLE = 3'b000;

    int error_count = 0;
    int stall_count = 0;

    /* Wait cycles inserted by the other slave, filled during the run */
    int other_stall_seen = 0;

    /* DUT port signals */
    logic         hclk        = 1'b0;
    logic         hreset_n    = 1'b0;
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

    sram_model_top #(.ADDR_WIDTH (ADDR_WIDTH)) dut (
        .hclk_i      (hclk),
        .hreset_n_i  (hreset_n),
        .hsel_i      (hsel),
        .haddr_i     (haddr),
        .hwdata_i    (hwdata),
        .hwrite_i    (hwrite),
        .htrans_i    (htrans),
        .hsize_i     (hsize),
        .hready_i    (hready),
        .hburst_i    (hburst),
        .hprot_i     (hprot),
        .hmastlock_i (hmastlock),
        .hrdata_o    (hrdata),
        .hreadyout_o (hreadyout),
        .hresp_o     (hresp)
    );

    always #(CLK_PERIOD / 2) hclk = ~hclk;

    /* Wait cycles inserted by this slave: cycles with HREADYOUT low */
    always @(posedge hclk) begin
        if (hreset_n === 1'b1 && hreadyout === 1'b0) begin
            stall_count++;
        end
    end

    /* One AHB beat driven by the master */
    typedef struct {
        logic [31: 0] addr;
        logic [31: 0] wdata;
        logic  [2: 0] size;
        logic         write;
        logic  [2: 0] burst;
        logic  [1: 0] trans;
    } ahb_beat_t;

    ahb_beat_t    cmd_q[$];
    ahb_beat_t    beat_tmp;
    int           done_count = 0;

    logic [31: 0] a_addr  = 32'h0;
    logic [31: 0] a_wdata = 32'h0;
    logic  [2: 0] a_size  = SIZE_WORD;
    logic         a_write = 1'b0;
    logic  [2: 0] a_burst = BURST_SINGLE;
    logic  [1: 0] a_trans = TRANS_IDLE;
    logic         a_idle  = 1'b1;

    logic [31: 0] d_addr  = 32'h0;
    logic [31: 0] d_wdata = 32'h0;
    logic  [2: 0] d_size  = SIZE_WORD;
    logic         d_write = 1'b0;
    logic         d_valid = 1'b0;

    logic [31: 0] ref_mem [0:(1 << ADDR_WIDTH) - 1];

    assign haddr     = a_addr;
    assign hwdata    = d_wdata;
    assign hsize     = a_size;
    assign hwrite    = a_write;
    assign hburst    = a_burst;
    assign htrans    = a_idle ? TRANS_IDLE : a_trans;
    assign hsel      = (a_addr >= BRAM_BASE) && (a_addr <= BRAM_LIMIT);
    assign hprot     = 4'b0001;
    assign hmastlock = 1'b0;

    /* Model the bus matrix: the read channel is muxed by a registered select */
    logic bram_phase_sel = 1'b1;

    always_ff @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            bram_phase_sel <= 1'b1;
        end else if (hready) begin
            bram_phase_sel <= hsel;
        end
    end

    /* Another slave: a set other_stall_req delays its next data phase */
    logic other_hsel_comb;
    logic other_hreadyout;
    logic other_stall_req  = 1'b0;
    logic other_stall_q    = 1'b0;
    logic other_phase_sel  = 1'b0;
    logic other_data_phase = 1'b0;
    int   other_done_count = 0;

    assign other_hsel_comb = (a_addr >= OTHER_BASE) &&
                             (a_addr <= OTHER_LIMIT);
    assign other_hreadyout = other_stall_q ? 1'b0 : 1'b1;

    always_ff @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            other_stall_q    <= 1'b0;
            other_phase_sel  <= 1'b0;
            other_data_phase <= 1'b0;
            other_done_count <= 0;
        end else begin
            other_stall_q <= other_stall_req;

            if (hready) begin
                if (other_data_phase) begin
                    other_done_count <= other_done_count + 1;
                end

                other_phase_sel  <= other_hsel_comb;
                other_data_phase <= other_hsel_comb &&
                                    (htrans != TRANS_IDLE);
            end
        end
    end

    assign hready = bram_phase_sel ? hreadyout : other_hreadyout;

    /* Count the cycles where the bus is held low by the other slave */
    always @(posedge hclk) begin
        if (hreset_n === 1'b1 && hready === 1'b0 && hreadyout === 1'b1) begin
            other_stall_seen++;
        end
    end

    /* Update the reference model, AHB byte lane rules applied */
    task automatic apply_write(input logic [31: 0] addr,
                               input logic [31: 0] wdata,
                               input logic  [2: 0] size);
        int word_index;
        int lane;
        word_index = addr[(ADDR_WIDTH + 1): 2];

        case (size)
            SIZE_BYTE: begin
                lane = addr[1: 0] * 8;
                ref_mem[word_index][lane +: 8] = wdata[lane +: 8];
            end

            SIZE_HALF: begin
                lane = addr[1] * 16;
                ref_mem[word_index][lane +: 16] = wdata[lane +: 16];
            end

            default: begin
                ref_mem[word_index] = wdata;
            end
        endcase
    endtask

    /* Compare read data, this slave returns the whole word */
    task automatic check_read(input logic [31: 0] addr,
                              input logic  [2: 0] size,
                              input logic [31: 0] rdata);
        int word_index;
        logic [31: 0] expected;
        word_index = addr[(ADDR_WIDTH + 1): 2];
        expected   = ref_mem[word_index];

        if ((addr < BRAM_BASE) || (addr > BRAM_LIMIT)) begin
            /* Another slave owns this address, no data to compare */
            $display("[%0t] INFO read  %08h size %0d other slave",
                     $time, addr, size);
        end else if (rdata !== expected) begin
            error_count++;
            $display("[%0t] FAIL read %08h size %0d got %08h exp %08h",
                     $time, addr, size, rdata, expected);
        end else begin
            $display("[%0t] INFO read  %08h size %0d data %08h ok",
                     $time, addr, size, rdata);
        end
    endtask

    task automatic check_int(input string name, input int got,
                             input int expected);
        if (got !== expected) begin
            error_count++;
            $display("[%0t] FAIL %s got %0d exp %0d",
                     $time, name, got, expected);
        end else begin
            $display("[%0t] INFO %s = %0d ok", $time, name, got);
        end
    endtask

    /* Master pipeline: address and data phase, extended by wait cycles */
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            a_idle     <= 1'b1;
            a_trans    <= TRANS_IDLE;
            d_valid    <= 1'b0;
            done_count <= 0;
        end else if (hready) begin
            if (d_valid) begin
                done_count <= done_count + 1;
                if (hresp === 1'b1) begin
                    /* Error response: no model update, no compare */
                end else if (d_write) begin
                    apply_write(d_addr, d_wdata, d_size);
                end else begin
                    check_read(d_addr, d_size, hrdata);
                end
            end

            d_valid <= ~a_idle;
            d_addr  <= a_addr;
            d_wdata <= a_wdata;
            d_size  <= a_size;
            d_write <= a_write;

            if (cmd_q.size() > 0) begin
                beat_tmp = cmd_q.pop_front();
                a_addr  <= beat_tmp.addr;
                a_wdata <= beat_tmp.wdata;
                a_size  <= beat_tmp.size;
                a_write <= beat_tmp.write;
                a_burst <= beat_tmp.burst;
                a_trans <= beat_tmp.trans;
                a_idle  <= 1'b0;
            end else begin
                a_idle  <= 1'b1;
                a_trans <= TRANS_IDLE;
            end
        end
    end

    /* Push one beat into the master command queue */
    task automatic push_beat(input logic [31: 0] addr,
                             input logic [31: 0] wdata,
                             input logic  [2: 0] size,
                             input logic         write,
                             input logic  [2: 0] burst,
                             input logic  [1: 0] trans);
        beat_tmp.addr  = addr;
        beat_tmp.wdata = wdata;
        beat_tmp.size  = size;
        beat_tmp.write = write;
        beat_tmp.burst = burst;
        beat_tmp.trans = trans;
        cmd_q.push_back(beat_tmp);
    endtask

    task automatic push_write(input logic [31: 0] addr,
                              input logic [31: 0] wdata,
                              input logic  [2: 0] size);
        push_beat(addr, wdata, size, 1'b1, BURST_SINGLE, TRANS_NONSEQ);
    endtask

    task automatic push_read(input logic [31: 0] addr,
                             input logic  [2: 0] size);
        push_beat(addr, 32'h0, size, 1'b0, BURST_SINGLE, TRANS_NONSEQ);
    endtask

    /* Wait for the beats to finish, with a timeout guard */
    task automatic wait_done(input int n, input int timeout_cycles = 2000);
        int cycles = 0;
        while (done_count < n && cycles < timeout_cycles) begin
            @(posedge hclk);
            cycles++;
        end

        if (done_count < n) begin
            error_count++;
            $display("[%0t] FAIL timeout: want %0d beats, done %0d",
                     $time, n, done_count);
        end
    endtask

    /* Wait for the n th address phase of the other slave */
    task automatic wait_other_addr_phase(input int n);
        int   seen = 0;
        logic prev = 1'b0;
        logic now;

        while (seen < n) begin
            @(negedge hclk);
            now = (other_hsel_comb === 1'b1) && (htrans !== TRANS_IDLE);

            if (now && !prev) begin
                seen++;
            end

            prev = now;
        end
    endtask

    /* Stimulus: the third access of the other slave is delayed by one
       wait cycle, the first two run at zero wait state */
    initial begin
        foreach (ref_mem[i]) begin
            ref_mem[i] = 32'h0000_0000;
            dut.unit[i] = 32'b0;
        end

        hreset_n = 1'b0;
        repeat (4) @(posedge hclk);
        @(negedge hclk);
        hreset_n = 1'b1;
        repeat (2) @(posedge hclk);

        push_write(32'h0000_0200, 32'hAAAA_5555, SIZE_WORD);
        push_write(32'h0000_0204, 32'hBBBB_6666, SIZE_WORD);
        push_write(32'h0000_0208, 32'hCCCC_7777, SIZE_WORD);

        /* The other slave runs at zero wait, its data phase shares the
           cycle with the address phase of this slave */
        push_read (32'h4000_0000, SIZE_WORD);
        push_read (32'h0000_0200, SIZE_WORD);

        push_read (32'h4000_0004, SIZE_WORD);
        push_read (32'h0000_0204, SIZE_WORD);

        /* Third access of the other slave: inject one wait cycle when it
           enters its address phase */
        push_read (32'h4000_0008, SIZE_WORD);
        push_read (32'h0000_0208, SIZE_WORD);

        wait_other_addr_phase(3);
        other_stall_req = 1'b1;
        @(negedge hclk);
        other_stall_req = 1'b0;

        wait_done(9);
        check_int("stall count", stall_count, 0);
        check_int("other stall seen", other_stall_seen, 1);
        check_int("other slave beats", other_done_count, 3);
        repeat (4) @(posedge hclk);

        if (error_count == 0) begin
            $display("==== TEST PASSED ====");
            $display("tb_sram_model_top_other_slave_data_phase");
        end else begin
            $display("==== TEST FAILED ====");
            $display("tb_sram_model_top_other_slave_data_phase %0d errors",
                     error_count);
        end

        $finish;
    end

endmodule
