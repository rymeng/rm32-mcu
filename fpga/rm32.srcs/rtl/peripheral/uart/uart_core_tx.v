`timescale 1ns / 1ps

module uart_core_tx (
/* Clock & Reset */
    input  wire         clock_i,
    input  wire         reset_n_i,
/* Write strobe */
    input  wire         tx_data_write_strobe_i,
/* BRR */
    input  wire   [5:0] oversampling_rate_i,
    input  wire  [15:0] baud_divisor_i,
/* CR1 */
    input  wire   [2:0] data_length_i,
    input  wire         parity_enable_i,
    input  wire         parity_type_i,
    input  wire         stop_length_i,
/* CR2 */
    input  wire         tx_enable_i,
/* NICRx */
    input  wire  [31:0] tx_start_noise_index_i,
    input  wire [255:0] tx_data_noise_index_i,
    input  wire  [31:0] tx_parity_noise_index_i,
    input  wire  [63:0] tx_stop_noise_index_i,
/* TDR */
    input  wire         tx_noise_injection_enable_i,
    input  wire         tx_parity_error_injection_enable_i,
    input  wire   [1:0] tx_frame_error_injection_enable_i,
    input  wire   [7:0] tx_data_i,
/* SR1 */
    output wire         tx_data_register_empty_o,
/* Bus */
    output reg          txd_o
);

    /* Lock band parameter data */
    reg  [5:0] oversampling_rate;
    reg [15:0] baud_divisor;
    always @ (posedge clock_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            oversampling_rate <= 6'h08;
            baud_divisor      <= 16'h0001;
        end else if (!tx_enable_i) begin
            oversampling_rate <= oversampling_rate_i;
            baud_divisor      <= baud_divisor_i;
        end
    end

    /* Generate tick */
    wire bit_tick;
    wire sampling_tick;
    uart_baud_generator uart_baud_generator_inst (
        .clock_i             (clock_i),
        .reset_n_i           (reset_n_i),
        .oversampling_rate_i (oversampling_rate),
        .baud_divisor_i      (baud_divisor),
        .sampling_tick_o     (sampling_tick),
        .bit_tick_o          (bit_tick)
    );

    /* Lock communication parameters */
    reg [2:0] data_length;
    reg       parity_enable;
    reg       parity_type;
    reg       stop_length;
    always @ (posedge clock_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            data_length   <= 3'b111;
            parity_enable <= 1'b0;
            parity_type   <= 1'b0;
            stop_length   <= 1'b0;
        end else if (!tx_enable_i) begin
            data_length   <= data_length_i;
            parity_enable <= parity_enable_i;
            parity_type   <= parity_type_i;
            stop_length   <= stop_length_i;
        end
    end

    /* Create frame */
    reg   [7:0] data_register;
    reg  [11:0] frame_register;
    wire        parity_bit;
    assign parity_bit = ^(data_register & (8'hFF >> (3'h7 - data_length))) ^ (~parity_type);
    always @ (*) begin
        case (data_length)
            3'b000: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 7'b0, data_register[0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 7'b0, data_register[0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 7'b0, data_register[0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 7'b0, data_register[0], 1'b0};
                end
            end
            3'b001: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 6'b0, data_register[1:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 6'b0, data_register[1:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 6'b0, data_register[1:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 6'b0, data_register[1:0], 1'b0};
                end
            end
            3'b010: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 5'b0, data_register[2:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 5'b0, data_register[2:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 5'b0, data_register[2:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 5'b0, data_register[2:0], 1'b0};
                end
            end
            3'b011: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 4'b0, data_register[3:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 4'b0, data_register[3:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 4'b0, data_register[3:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 4'b0, data_register[3:0], 1'b0};
                end
            end
            3'b100: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 3'b0, data_register[4:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 3'b0, data_register[4:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 3'b0, data_register[4:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 3'b0, data_register[4:0], 1'b0};
                end
            end
            3'b101: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 2'b0, data_register[5:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 2'b0, data_register[5:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 2'b0, data_register[5:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 2'b0, data_register[5:0], 1'b0};
                end
            end
            3'b110: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, 1'b0, data_register[6:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, 1'b0, data_register[6:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, 1'b0, data_register[6:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, 1'b0, data_register[6:0], 1'b0};
                end
            end
            3'b111: begin
                if (parity_enable) begin
                    if (stop_length)
                        frame_register = {2'b11, parity_bit, data_register[7:0], 1'b0};
                    else
                        frame_register = {2'b01, parity_bit, data_register[7:0], 1'b0};
                end else begin
                    if (stop_length)
                        frame_register = {2'b11, 1'b0, data_register[7:0], 1'b0};
                    else
                        frame_register = {2'b01, 1'b0, data_register[7:0], 1'b0};
                end
            end
        endcase
    end

    /* Create frame with error injection */
    reg [11:0] frame_with_error_register;
    reg [11:0] error_injection_mask;
    always @ (*) begin
        error_injection_mask = 12'b0;
        if (tx_parity_error_injection_enable_i)
             error_injection_mask[9] = 1'b1;
        case (tx_frame_error_injection_enable_i)
            2'b00: begin end
            2'b01: begin error_injection_mask[10] = 1'b1; end
            2'b10: begin error_injection_mask[11] = 1'b1; end
            2'b11: begin error_injection_mask[11:10] = 2'b11; end
        endcase
        frame_with_error_register = frame_register ^ error_injection_mask;
    end

    /* Create sampling point sequence */
    wire [383:0] sampling_point_register;
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin
            assign sampling_point_register[32 * i +: 32] = {32{frame_with_error_register[i]}};
        end
    endgenerate

    /* Create sampling point sequence with noise */
    reg [383:0] sampling_point_with_noise_register;
    reg [383:0] noise_mask;
    always @ (*) begin
       noise_mask = {tx_stop_noise_index_i, tx_parity_noise_index_i, tx_data_noise_index_i, tx_start_noise_index_i};
       if (tx_noise_injection_enable_i)
           sampling_point_with_noise_register = sampling_point_register ^ noise_mask;
       else
           sampling_point_with_noise_register = sampling_point_register;
    end

    localparam IDLE   = 3'b000;
    localparam START  = 3'b001;
    localparam DATA   = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP   = 3'b100;

    reg   [2:0] state;
    reg [383:0] shift_register;
    reg   [4:0] sampling_point_count;
    reg   [2:0] data_bit_count;
    reg   [1:0] stop_bit_count;
    reg         data_register_valid;

    always @ (posedge clock_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            /* FSM state */
            state                <= IDLE;
            /* Core register */
            data_register        <= 8'b0;
            shift_register       <= 384'b0;
            /* Internal flag */
            data_register_valid  <= 1'b0;
            /* Internal counter */
            sampling_point_count <= 5'b0;
            data_bit_count       <= 3'b0;
            stop_bit_count       <= 2'b0;
            /* Bus */
            txd_o                <= 1'b1;
        end else begin
            /* Write data register */
            if (tx_data_write_strobe_i) begin
                /* Write */
                data_register        <= tx_data_i;
                /* Refresh data register valid flag */
                data_register_valid  <= 1'b1;
            end

            case (state)
                IDLE: begin
                    /* Refresh bus output */
                    txd_o                    <= 1'b1;
                    if (tx_enable_i && data_register_valid) begin
                        /* Load shift register */
                        shift_register       <= sampling_point_with_noise_register;
                        /* Change FSM state */
                        state                <= START;
                        /* Refresh data register valid flag */
                        data_register_valid  <= 1'b0;
                        /* Initialize all internal counter */
                        sampling_point_count <= 5'b0;
                        data_bit_count       <= 3'b0;
                        stop_bit_count       <= 2'b0;
                    end
                end

                START: begin
                    if (sampling_tick) begin
                        /* Refresh bus output */
                        txd_o                    <= shift_register[sampling_point_count];
                        if (sampling_point_count == oversampling_rate - 1) begin
                            /* Reset sampling point counter */
                            sampling_point_count <= 5'b0;
                            /* Change FSM state */
                            state                <= DATA;
                            /* Initialize data bit counter */
                            data_bit_count       <= 3'b0;
                        end else begin
                            /* Add sampling point counter */
                            sampling_point_count <= sampling_point_count + 1;
                        end
                    end
                end

                DATA: begin
                    if (sampling_tick) begin
                        /* Refresh bus output */
                        txd_o                      <= shift_register[((1 + data_bit_count) << 5) + sampling_point_count];
                        if (sampling_point_count == oversampling_rate - 1) begin
                            /* Reset sampling point counter */
                            sampling_point_count   <= 5'b0;
                            if (data_bit_count == data_length) begin
                                if (parity_enable)
                                    /* NOT change FSM state */
                                    state          <= PARITY;
                                else begin
                                    /* Change FSM state */
                                    state          <= STOP;
                                    /* Initialize stop bit counter */
                                    stop_bit_count <= 2'b0;
                                end
                            end else
                                /* Add data bit counter */
                                data_bit_count     <= data_bit_count + 1;
                        end else begin
                            /* Add sampling point counter */
                            sampling_point_count   <= sampling_point_count + 1;
                        end
                    end
                end

                PARITY : begin
                    if (sampling_tick) begin
                        /* Refresh bus output */
                        txd_o                    <= shift_register[(9 << 5) + sampling_point_count];
                        if (sampling_point_count == oversampling_rate - 1) begin
                            /* Reset sampling point counter */
                            sampling_point_count <= 5'b0;
                            /* Change FSM state */
                            state                <= STOP;
                            /* Initialize stop bit counter */
                            stop_bit_count       <= 2'b0;
                        end else begin
                            /* Add sampling point counter */
                            sampling_point_count <= sampling_point_count + 1;
                        end
                    end
                end

                STOP : begin
                    if (sampling_tick) begin
                        /* Refresh bus output */
                        txd_o                           <= shift_register[((10 + stop_bit_count) << 5) + sampling_point_count];
                        if (sampling_point_count == oversampling_rate - 1) begin
                            /* Reset sampling point counter */
                            sampling_point_count        <= 5'b0;
                            if (stop_bit_count == stop_length) begin
                                if (tx_enable_i && data_register_valid) begin
                                    /* Load shift register */
                                    shift_register      <= sampling_point_with_noise_register;
                                    /* Change FSM state */
                                    state               <= START;
                                    /* Refresh data register valid flag */
                                    data_register_valid <= 1'b0;
                                    /* Initialize all internal counter */
                                    data_bit_count      <= 3'b0;
                                    stop_bit_count      <= 2'b0;
                                end else begin
                                    /* Change FSM state */
                                    state               <= IDLE;
                                end
                            end else begin
                                /* Add stop bit counter */
                                stop_bit_count          <= stop_bit_count + 1;
                            end
                        end else begin
                            /* Add sampling point counter */
                            sampling_point_count        <= sampling_point_count + 1;
                        end
                    end
                end

                default: begin
                    /* Refresh bus output */
                    txd_o <= 1'b1;
                    /* Correct FSM state */
                    state <= IDLE;
                end
            endcase
        end
    end

    /* Output SR1 data register empty flag*/
    assign tx_data_register_empty_o = ~data_register_valid;

endmodule
