// =============================================================================
// SDRAM Controller for Altera DE2 Board
// SDRAM Chip: 8-Mbyte, organized as 1M x 16 bits x 4 banks
// Clock:      50 MHz (from CLOCK_50 on DE2)
// Author:     DE2 SDRAM Controller Example
// =============================================================================
//
// Pin Assignments (from DE2 User Manual Table 4.16):
//   DRAM_ADDR[11:0] - Row/Column Address
//   DRAM_DQ[15:0]   - Data Bus (bidirectional)
//   DRAM_BA_0, DRAM_BA_1 - Bank Address
//   DRAM_LDQM, DRAM_UDQM - Data Mask (Low/High byte)
//   DRAM_RAS_N  - Row Address Strobe
//   DRAM_CAS_N  - Column Address Strobe
//   DRAM_CKE    - Clock Enable
//   DRAM_CLK    - SDRAM Clock
//   DRAM_WE_N   - Write Enable
//   DRAM_CS_N   - Chip Select
//
// Usage:
//   1. Pulse init_done goes high after ~200us initialization
//   2. To WRITE: set wr_en=1, address, wr_data, then pulse cmd_valid
//   3. To READ:  set rd_en=1, address, then pulse cmd_valid
//               rd_data_valid pulses high when rd_data is valid
// =============================================================================

module sdram_controller (
    // System
    input  wire        clk,          // 50 MHz system clock
    input  wire        rst_n,        // Active-low reset

    // User Interface
    input  wire        cmd_valid,    // Pulse high for 1 cycle to issue command
    input  wire        wr_en,        // 1 = Write operation
    input  wire        rd_en,        // 1 = Read operation
    input  wire [22:0] address,      // Byte address [22:0] = {bank[1:0], row[11:0], col[8:0]}
    input  wire [15:0] wr_data,      // Write data
    input  wire [1:0]  byte_en,      // Byte enable: bit1=upper byte, bit0=lower byte

    output reg  [15:0] rd_data,      // Read data output
    output reg         rd_data_valid,// Pulses high when rd_data is valid
    output reg         busy,         // Controller is busy (cannot accept new command)
    output reg         init_done,    // High after initialization complete

    // SDRAM Hardware Interface (connect to DE2 board pins)
    output wire        DRAM_CLK,
    output wire        DRAM_CKE,
    output wire        DRAM_CS_N,
    output wire        DRAM_RAS_N,
    output wire        DRAM_CAS_N,
    output wire        DRAM_WE_N,
    output wire [11:0] DRAM_ADDR,
    output wire [1:0]  DRAM_BA,
    output wire        DRAM_LDQM,
    output wire        DRAM_UDQM,
    inout  wire [15:0] DRAM_DQ       // Bidirectional data bus
);

// =============================================================================
// Parameters - Timing for 50 MHz clock (20 ns per cycle)
// SDRAM: standard 166 MHz part used conservatively at 50 MHz
// =============================================================================
    parameter CLK_FREQ_MHZ  = 50;
    parameter tINIT_US      = 200;   // Initialization wait: 200 us
    parameter tINIT_CYCLES  = CLK_FREQ_MHZ * tINIT_US; // 10000 cycles

    // SDRAM timing parameters (in clock cycles at 50 MHz)
    parameter tRP           = 2;     // Precharge to active: 20 ns  -> 1 cycle min, use 2
    parameter tRCD          = 2;     // Active to R/W: 20 ns        -> 1 cycle min, use 2
    parameter tCAS_LATENCY  = 2;     // CAS latency (set in mode register)
    parameter tWR           = 2;     // Write recovery: 2 cycles
    parameter tRFC          = 7;     // Auto-refresh: 66 ns         -> 4 cycles min, use 7
    parameter tREFI_CYCLES  = 781;   // Refresh interval: 64ms/8192 rows = ~7.8 us -> 390 cycles; use 781 for safety

    // Number of Auto-Refresh commands during init
    parameter INIT_REFRESH_COUNT = 8;

// =============================================================================
// SDRAM Commands {CS_N, RAS_N, CAS_N, WE_N}
// =============================================================================
    localparam CMD_INHIBIT      = 4'b1111;
    localparam CMD_NOP          = 4'b0111;
    localparam CMD_ACTIVE       = 4'b0011;
    localparam CMD_READ         = 4'b0101;
    localparam CMD_WRITE        = 4'b0100;
    localparam CMD_BURST_TERM   = 4'b0110;
    localparam CMD_PRECHARGE    = 4'b0010;
    localparam CMD_AUTO_REFRESH = 4'b0001;
    localparam CMD_LOAD_MODE    = 4'b0000;

    // Mode Register:
    // [12:10] = 000 (reserved)
    // [9]     = 0   (write burst = programmed length)
    // [8:7]   = 00  (standard operation)
    // [6:4]   = 010 (CAS latency = 2)
    // [3]     = 0   (sequential burst)
    // [2:0]   = 000 (burst length = 1)
    localparam MODE_REG = 12'b000_0_00_010_0_000;

// =============================================================================
// FSM States
// =============================================================================
    localparam ST_INIT_WAIT     = 4'd0;
    localparam ST_INIT_PRECHARGE= 4'd1;
    localparam ST_INIT_REFRESH  = 4'd2;
    localparam ST_INIT_MODE     = 4'd3;
    localparam ST_IDLE          = 4'd4;
    localparam ST_ACTIVE        = 4'd5;
    localparam ST_READ          = 4'd6;
    localparam ST_READ_DATA     = 4'd7;
    localparam ST_WRITE         = 4'd8;
    localparam ST_PRECHARGE     = 4'd9;
    localparam ST_AUTO_REFRESH  = 4'd10;
    localparam ST_WAIT          = 4'd11;

// =============================================================================
// Internal Signals
// =============================================================================
    reg [3:0]  state, next_state_after_wait;
    reg [13:0] wait_cnt;        // General wait counter
    reg [13:0] refresh_cnt;     // Refresh interval counter
    reg [3:0]  refresh_init_cnt;// Init refresh counter
    reg [3:0]  cmd_reg;         // {CS_N, RAS_N, CAS_N, WE_N}
    reg [11:0] addr_reg;        // Address to SDRAM
    reg [1:0]  ba_reg;          // Bank address
    reg        dqm_low_reg;     // Lower byte mask
    reg        dqm_high_reg;    // Upper byte mask
    reg [15:0] dq_out;          // Data to write
    reg        dq_oe;           // Output enable for DQ bus

    // Latched user command
    reg [22:0] op_address;
    reg [15:0] op_wr_data;
    reg [1:0]  op_byte_en;
    reg        op_wr;
    reg        op_rd;
    reg        op_pending;

    // CAS latency pipeline
    reg [1:0]  cas_pipe;        // Pipeline for CAS latency

    // Address decoding: address[22:0] = {bank[1:0], row[11:0], col[8:0]}
    wire [1:0]  op_bank = op_address[22:21];
    wire [11:0] op_row  = op_address[20:9];
    wire [8:0]  op_col  = op_address[8:0];

// =============================================================================
// SDRAM Output Assignments
// =============================================================================
    assign DRAM_CLK   = clk;           // Forward clock to SDRAM
    assign DRAM_CKE   = 1'b1;          // Always enabled
    assign DRAM_CS_N  = cmd_reg[3];
    assign DRAM_RAS_N = cmd_reg[2];
    assign DRAM_CAS_N = cmd_reg[1];
    assign DRAM_WE_N  = cmd_reg[0];
    assign DRAM_ADDR  = addr_reg;
    assign DRAM_BA    = ba_reg;
    assign DRAM_LDQM  = dqm_low_reg;
    assign DRAM_UDQM  = dqm_high_reg;

    // Bidirectional data bus
    assign DRAM_DQ = dq_oe ? dq_out : 16'bz;

// =============================================================================
// Latch user command when cmd_valid and not busy
// =============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_pending  <= 0;
            op_wr       <= 0;
            op_rd       <= 0;
            op_address  <= 0;
            op_wr_data  <= 0;
            op_byte_en  <= 2'b11;
        end else begin
            if (cmd_valid && !busy && init_done) begin
                op_pending <= 1;
                op_wr      <= wr_en;
                op_rd      <= rd_en;
                op_address <= address;
                op_wr_data <= wr_data;
                op_byte_en <= byte_en;
            end else if (state == ST_ACTIVE) begin
                op_pending <= 0;  // Command accepted
            end
        end
    end

// =============================================================================
// Refresh Counter
// =============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            refresh_cnt <= 0;
        else if (!init_done)
            refresh_cnt <= 0;
        else if (state == ST_AUTO_REFRESH)
            refresh_cnt <= 0;
        else
            refresh_cnt <= refresh_cnt + 1;
    end

    wire refresh_needed = (refresh_cnt >= tREFI_CYCLES);

// =============================================================================
// Main FSM
// =============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= ST_INIT_WAIT;
            wait_cnt            <= tINIT_CYCLES;
            next_state_after_wait <= ST_INIT_PRECHARGE;
            refresh_init_cnt    <= 0;
            init_done           <= 0;
            busy                <= 1;
            rd_data             <= 0;
            rd_data_valid       <= 0;
            cas_pipe            <= 0;

            cmd_reg     <= CMD_INHIBIT;
            addr_reg    <= 0;
            ba_reg      <= 0;
            dqm_low_reg <= 1;
            dqm_high_reg<= 1;
            dq_out      <= 0;
            dq_oe       <= 0;
        end else begin
            // Default outputs
            cmd_reg      <= CMD_NOP;
            rd_data_valid<= 0;
            dq_oe        <= 0;

            // CAS latency pipeline (for read)
            cas_pipe <= {cas_pipe[0], 1'b0};

            case (state)

                // ---------------------------------------------------------
                // INIT: Wait 200 us with CKE high, NOP
                // ---------------------------------------------------------
                ST_INIT_WAIT: begin
                    busy <= 1;
                    if (wait_cnt == 0) begin
                        state    <= ST_INIT_PRECHARGE;
                        wait_cnt <= 0;
                    end else begin
                        wait_cnt <= wait_cnt - 1;
                    end
                end

                // ---------------------------------------------------------
                // INIT: Precharge All Banks
                // ---------------------------------------------------------
                ST_INIT_PRECHARGE: begin
                    busy        <= 1;
                    cmd_reg     <= CMD_PRECHARGE;
                    addr_reg    <= 12'b0100_0000_0000; // A10=1 -> precharge all
                    ba_reg      <= 2'b00;
                    dqm_low_reg <= 1;
                    dqm_high_reg<= 1;

                    state               <= ST_WAIT;
                    wait_cnt            <= tRP - 1;
                    next_state_after_wait <= ST_INIT_REFRESH;
                    refresh_init_cnt    <= 0;
                end

                // ---------------------------------------------------------
                // INIT: Auto-Refresh x8
                // ---------------------------------------------------------
                ST_INIT_REFRESH: begin
                    busy    <= 1;
                    cmd_reg <= CMD_AUTO_REFRESH;

                    if (refresh_init_cnt < INIT_REFRESH_COUNT - 1) begin
                        refresh_init_cnt <= refresh_init_cnt + 1;
                        state            <= ST_WAIT;
                        wait_cnt         <= tRFC - 1;
                        next_state_after_wait <= ST_INIT_REFRESH;
                    end else begin
                        state    <= ST_WAIT;
                        wait_cnt <= tRFC - 1;
                        next_state_after_wait <= ST_INIT_MODE;
                    end
                end

                // ---------------------------------------------------------
                // INIT: Load Mode Register
                // ---------------------------------------------------------
                ST_INIT_MODE: begin
                    busy        <= 1;
                    cmd_reg     <= CMD_LOAD_MODE;
                    addr_reg    <= MODE_REG;
                    ba_reg      <= 2'b00;
                    dqm_low_reg <= 0;
                    dqm_high_reg<= 0;

                    state     <= ST_WAIT;
                    wait_cnt  <= 3;  // tMRD = 2 cycles min
                    next_state_after_wait <= ST_IDLE;
                end

                // ---------------------------------------------------------
                // IDLE: Wait for command or refresh
                // ---------------------------------------------------------
                ST_IDLE: begin
                    init_done <= 1;
                    busy      <= 0;
                    dqm_low_reg <= 1;
                    dqm_high_reg<= 1;

                    if (refresh_needed) begin
                        busy    <= 1;
                        cmd_reg <= CMD_AUTO_REFRESH;
                        state   <= ST_AUTO_REFRESH;
                        wait_cnt<= tRFC - 1;
                    end else if (op_pending) begin
                        // Issue ACTIVE command
                        busy        <= 1;
                        cmd_reg     <= CMD_ACTIVE;
                        addr_reg    <= op_row;
                        ba_reg      <= op_bank;
                        dqm_low_reg <= 0;
                        dqm_high_reg<= 0;

                        state    <= ST_WAIT;
                        wait_cnt <= tRCD - 1;
                        next_state_after_wait <= ST_ACTIVE;
                    end
                end

                // ---------------------------------------------------------
                // ACTIVE: Decide Read or Write
                // ---------------------------------------------------------
                ST_ACTIVE: begin
                    busy <= 1;
                    if (op_wr) begin
                        // WRITE command
                        cmd_reg      <= CMD_WRITE;
                        addr_reg     <= {3'b000, op_col}; // A10=0 (no auto precharge)
                        ba_reg       <= op_bank;
                        dqm_low_reg  <= ~op_byte_en[0];
                        dqm_high_reg <= ~op_byte_en[1];
                        dq_out       <= op_wr_data;
                        dq_oe        <= 1;
                        state        <= ST_WRITE;
                        wait_cnt     <= tWR;
                    end else begin
                        // READ command
                        cmd_reg      <= CMD_READ;
                        addr_reg     <= {3'b000, op_col}; // A10=0 (no auto precharge)
                        ba_reg       <= op_bank;
                        dqm_low_reg  <= 0;
                        dqm_high_reg <= 0;
                        cas_pipe     <= 2'b10;  // CAS latency=2: data ready in 2 cycles
                        state        <= ST_READ;
                        wait_cnt     <= tCAS_LATENCY;
                    end
                end

                // ---------------------------------------------------------
                // READ: Wait for CAS latency
                // ---------------------------------------------------------
                ST_READ: begin
                    busy <= 1;
                    dqm_low_reg  <= 0;
                    dqm_high_reg <= 0;

                    if (wait_cnt == 0) begin
                        state <= ST_READ_DATA;
                    end else begin
                        wait_cnt <= wait_cnt - 1;
                    end
                end

                // ---------------------------------------------------------
                // READ_DATA: Capture data from DRAM_DQ
                // ---------------------------------------------------------
                ST_READ_DATA: begin
                    busy          <= 1;
                    rd_data       <= DRAM_DQ;
                    rd_data_valid <= 1;

                    // Precharge after read
                    cmd_reg     <= CMD_PRECHARGE;
                    addr_reg    <= 12'b0100_0000_0000; // All banks
                    ba_reg      <= op_bank;
                    dqm_low_reg <= 1;
                    dqm_high_reg<= 1;

                    state    <= ST_WAIT;
                    wait_cnt <= tRP - 1;
                    next_state_after_wait <= ST_IDLE;
                end

                // ---------------------------------------------------------
                // WRITE: Hold data, then precharge
                // ---------------------------------------------------------
                ST_WRITE: begin
                    busy    <= 1;
                    dq_oe   <= 1;
                    dq_out  <= op_wr_data;

                    if (wait_cnt == 0) begin
                        dq_oe        <= 0;
                        cmd_reg      <= CMD_PRECHARGE;
                        addr_reg     <= 12'b0100_0000_0000; // All banks
                        ba_reg       <= op_bank;
                        dqm_low_reg  <= 1;
                        dqm_high_reg <= 1;

                        state    <= ST_WAIT;
                        wait_cnt <= tRP - 1;
                        next_state_after_wait <= ST_IDLE;
                    end else begin
                        wait_cnt <= wait_cnt - 1;
                    end
                end

                // ---------------------------------------------------------
                // AUTO_REFRESH: Wait for tRFC
                // ---------------------------------------------------------
                ST_AUTO_REFRESH: begin
                    busy <= 1;
                    if (wait_cnt == 0) begin
                        state <= ST_IDLE;
                    end else begin
                        wait_cnt <= wait_cnt - 1;
                    end
                end

                // ---------------------------------------------------------
                // WAIT: Generic wait state
                // ---------------------------------------------------------
                ST_WAIT: begin
                    busy <= 1;
                    if (wait_cnt == 0) begin
                        state <= next_state_after_wait;
                    end else begin
                        wait_cnt <= wait_cnt - 1;
                    end
                end

                default: state <= ST_IDLE;

            endcase
        end
    end

endmodule


// =============================================================================
// Top-Level Example: Write then Read-back test on DE2 board
// Uses LEDR and LEDG to show pass/fail
// =============================================================================
module sdram_rw_test (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,       // KEY[0] = reset (active-low)

    // SDRAM pins
    output wire        DRAM_CLK,
    output wire        DRAM_CKE,
    output wire        DRAM_CS_N,
    output wire        DRAM_RAS_N,
    output wire        DRAM_CAS_N,
    output wire        DRAM_WE_N,
    output wire [11:0] DRAM_ADDR,
    output wire [1:0]  DRAM_BA,
    output wire        DRAM_LDQM,
    output wire        DRAM_UDQM,
    inout  wire [15:0] DRAM_DQ,

    // LED outputs
    output reg  [17:0] LEDR,      // Red LEDs: show write data
    output reg  [8:0]  LEDG       // Green LEDs: LEDG[8]=pass, LEDG[0]=fail
);

    wire        init_done;
    wire        busy;
    wire [15:0] rd_data;
    wire        rd_data_valid;

    reg         cmd_valid;
    reg         wr_en, rd_en;
    reg  [22:0] address;
    reg  [15:0] wr_data;
    reg  [1:0]  byte_en;

    // Test FSM
    localparam TS_WAIT_INIT = 3'd0;
    localparam TS_WRITE     = 3'd1;
    localparam TS_WAIT_BUSY = 3'd2;
    localparam TS_READ      = 3'd3;
    localparam TS_WAIT_DATA = 3'd4;
    localparam TS_CHECK     = 3'd5;
    localparam TS_DONE      = 3'd6;

    reg [2:0] test_state;
    reg [15:0] expected_data;

    wire rst_n = KEY[0];

    // Instantiate SDRAM controller
    sdram_controller u_sdram (
        .clk          (CLOCK_50),
        .rst_n        (rst_n),
        .cmd_valid    (cmd_valid),
        .wr_en        (wr_en),
        .rd_en        (rd_en),
        .address      (address),
        .wr_data      (wr_data),
        .byte_en      (byte_en),
        .rd_data      (rd_data),
        .rd_data_valid(rd_data_valid),
        .busy         (busy),
        .init_done    (init_done),
        .DRAM_CLK     (DRAM_CLK),
        .DRAM_CKE     (DRAM_CKE),
        .DRAM_CS_N    (DRAM_CS_N),
        .DRAM_RAS_N   (DRAM_RAS_N),
        .DRAM_CAS_N   (DRAM_CAS_N),
        .DRAM_WE_N    (DRAM_WE_N),
        .DRAM_ADDR    (DRAM_ADDR),
        .DRAM_BA      (DRAM_BA),
        .DRAM_LDQM    (DRAM_LDQM),
        .DRAM_UDQM    (DRAM_UDQM),
        .DRAM_DQ      (DRAM_DQ)
    );

    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            test_state    <= TS_WAIT_INIT;
            cmd_valid     <= 0;
            wr_en         <= 0;
            rd_en         <= 0;
            address       <= 23'h0000_10;  // Test address
            wr_data       <= 16'hABCD;     // Test write value
            byte_en       <= 2'b11;
            expected_data <= 16'hABCD;
            LEDR          <= 0;
            LEDG          <= 0;
        end else begin
            cmd_valid <= 0; // Default: no command

            case (test_state)

                TS_WAIT_INIT: begin
                    if (init_done) begin
                        test_state <= TS_WRITE;
                        LEDG[7]    <= 1; // Init done indicator
                    end
                end

                TS_WRITE: begin
                    if (!busy) begin
                        cmd_valid  <= 1;
                        wr_en      <= 1;
                        rd_en      <= 0;
                        address    <= 23'h000010;
                        wr_data    <= 16'hABCD;
                        byte_en    <= 2'b11;
                        LEDR[15:0] <= 16'hABCD;
                        test_state <= TS_WAIT_BUSY;
                    end
                end

                TS_WAIT_BUSY: begin
                    // Wait until write is accepted (busy goes high)
                    if (busy)
                        test_state <= TS_READ;
                end

                TS_READ: begin
                    // Wait until controller is free, then issue read
                    if (!busy) begin
                        cmd_valid  <= 1;
                        wr_en      <= 0;
                        rd_en      <= 1;
                        address    <= 23'h000010;
                        byte_en    <= 2'b11;
                        test_state <= TS_WAIT_DATA;
                    end
                end

                TS_WAIT_DATA: begin
                    if (rd_data_valid) begin
                        test_state <= TS_CHECK;
                        LEDR[17:16]<= 2'b11; // Read complete
                    end
                end

                TS_CHECK: begin
                    if (rd_data == expected_data) begin
                        LEDG[8] <= 1; // PASS: green LED on
                        LEDG[0] <= 0;
                    end else begin
                        LEDG[0] <= 1; // FAIL: red (using green[0])
                        LEDG[8] <= 0;
                    end
                    test_state <= TS_DONE;
                end

                TS_DONE: begin
                    // Stay here - test complete
                end

            endcase
        end
    end

endmodule