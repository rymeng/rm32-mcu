`timescale 1ns / 1ps

/* Case: error response, two cycles
   A misaligned half word, a misaligned word and an illegal size must all
   give the AHB two cycle error response: HRESP high for two cycles with
   HREADYOUT low on the first and high on the second. A failing access
   must not change the stored data */

module tb_bram_top_error_response;

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

    /* Error response checker: cycle count and phase flag */
    int   err_resp_cycles = 0;
    logic err_resp_phase  = 1'b0;

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

    bram_top #(.ADDR_WIDTH (ADDR_WIDTH)) dut (
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

    task automatic check_bool(input string name, input logic cond);
        if (cond !== 1'b1) begin
            error_count++;
            $display("[%0t] FAIL %s", $time, name);
        end
    endtask

    /* Check HRESP high for two cycles and the HREADYOUT pattern */
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            err_resp_cycles <= 0;
            err_resp_phase  <= 1'b0;
        end else if (hresp === 1'b1) begin
            err_resp_cycles <= err_resp_cycles + 1;

            if (!err_resp_phase) begin
                check_bool("error resp cycle1 hreadyout low",
                           hreadyout === 1'b0);
                err_resp_phase <= 1'b1;
            end else begin
                check_bool("error resp cycle2 hreadyout high",
                           hreadyout === 1'b1);
                err_resp_phase <= 1'b0;
            end
        end else begin
            err_resp_phase <= 1'b0;
        end
    end

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

    /* Model the bus matrix: the read channel is muxed by a registered
       select, so a data phase takes the response of the slave that was
       selected one cycle earlier */
    logic bram_phase_sel = 1'b1;

    always_ff @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            bram_phase_sel <= 1'b1;
        end else if (hready) begin
            bram_phase_sel <= hsel;
        end
    end

    logic other_hsel_comb;
    logic other_hreadyout;

    assign other_hsel_comb = (a_addr >= OTHER_BASE) &&
                             (a_addr <= OTHER_LIMIT);
    assign other_hreadyout = 1'b1;

    assign hready = bram_phase_sel ? hreadyout : other_hreadyout;

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

    task automatic check_read(input logic [31: 0] addr,
                              input logic  [2: 0] size,
                              input logic [31: 0] rdata);
        int word_index;
        logic [31: 0] expected;
        word_index = addr[(ADDR_WIDTH + 1): 2];
        expected   = ref_mem[word_index];

        if (rdata !== expected) begin
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

    /* Stimulus: four failing beats, the last read checks the side effect */
    initial begin
        foreach (ref_mem[i]) begin
            ref_mem[i] = 32'h0000_0000;
        end

        hreset_n = 1'b0;
        repeat (4) @(posedge hclk);
        @(negedge hclk);
        hreset_n = 1'b1;
        repeat (2) @(posedge hclk);

        /* Write one word as the reference data */
        push_write(32'h0000_0800, 32'h1234_5678, SIZE_WORD);

        /* Misaligned half word */
        push_read (32'h0000_0801, SIZE_HALF);

        /* Misaligned word */
        push_read (32'h0000_0802, SIZE_WORD);

        /* Illegal size, encoding 3'b011 */
        push_read (32'h0000_0800, 3'b011);

        /* Misaligned write: the stored data must stay unchanged */
        push_write(32'h0000_0802, 32'h0000_FFFF, SIZE_WORD);

        /* Read the reference data back */
        push_read (32'h0000_0800, SIZE_WORD);

        wait_done(6);
        check_int("stall count", stall_count, 4);
        check_int("err resp cycles", err_resp_cycles, 8);
        repeat (4) @(posedge hclk);

        if (error_count == 0) begin
            $display("==== TEST PASSED : tb_bram_top_error_response ====");
        end else begin
            $display("==== TEST FAILED : tb_bram_top_error_response, %0d ====",
                     error_count);
        end

        $finish;
    end

endmodule
