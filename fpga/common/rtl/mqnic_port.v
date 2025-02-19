/*

Copyright 2022, The Regents of the University of California.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of The Regents of the University of California.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * NIC port
 */
module mqnic_port #
(
    // PTP configuration
    parameter PTP_TS_WIDTH = 96,

    // Interface configuration
    parameter PTP_TS_ENABLE = 1,
    parameter TX_CPL_ENABLE = 1,
    parameter TX_CPL_FIFO_DEPTH = 32,
    parameter TX_TAG_WIDTH = 16,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,

    // Application block configuration
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,

    // Register interface configuration
    parameter REG_ADDR_WIDTH = 7,
    parameter REG_DATA_WIDTH = 32,
    parameter REG_STRB_WIDTH = (REG_DATA_WIDTH/8),
    parameter RB_BASE_ADDR = 0,
    parameter RB_NEXT_PTR = 0,

    // Streaming interface configuration
    parameter AXIS_DATA_WIDTH = 256,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_TX_USER_WIDTH = TX_TAG_WIDTH + 1,
    parameter AXIS_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1,
    parameter AXIS_RX_USE_READY = 0,
    parameter AXIS_TX_PIPELINE = 0,
    parameter AXIS_TX_FIFO_PIPELINE = 2,
    parameter AXIS_TX_TS_PIPELINE = 0,
    parameter AXIS_RX_PIPELINE = 0,
    parameter AXIS_RX_FIFO_PIPELINE = 2,
    parameter AXIS_SYNC_DATA_WIDTH = AXIS_DATA_WIDTH,
    parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8,
    parameter AXIS_SYNC_TX_USER_WIDTH = AXIS_TX_USER_WIDTH,
    parameter AXIS_SYNC_RX_USER_WIDTH = AXIS_RX_USER_WIDTH
)
(
    input  wire                                clk,
    input  wire                                rst,

    /*
     * Control register interface
     */
    input  wire [REG_ADDR_WIDTH-1:0]           ctrl_reg_wr_addr,
    input  wire [REG_DATA_WIDTH-1:0]           ctrl_reg_wr_data,
    input  wire [REG_STRB_WIDTH-1:0]           ctrl_reg_wr_strb,
    input  wire                                ctrl_reg_wr_en,
    output wire                                ctrl_reg_wr_wait,
    output wire                                ctrl_reg_wr_ack,
    input  wire [REG_ADDR_WIDTH-1:0]           ctrl_reg_rd_addr,
    input  wire                                ctrl_reg_rd_en,
    output wire [REG_DATA_WIDTH-1:0]           ctrl_reg_rd_data,
    output wire                                ctrl_reg_rd_wait,
    output wire                                ctrl_reg_rd_ack,

    /*
     * Transmit data from interface FIFO
     */
    input  wire [AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_if_tx_tdata,
    input  wire [AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_if_tx_tkeep,
    input  wire                                s_axis_if_tx_tvalid,
    output wire                                s_axis_if_tx_tready,
    input  wire                                s_axis_if_tx_tlast,
    input  wire [AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_if_tx_tuser,

    output wire [PTP_TS_WIDTH-1:0]             m_axis_if_tx_cpl_ts,
    output wire [TX_TAG_WIDTH-1:0]             m_axis_if_tx_cpl_tag,
    output wire                                m_axis_if_tx_cpl_valid,
    input  wire                                m_axis_if_tx_cpl_ready,

    /*
     * Receive data to interface FIFO
     */
    output wire [AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_if_rx_tdata,
    output wire [AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_if_rx_tkeep,
    output wire                                m_axis_if_rx_tvalid,
    input  wire                                m_axis_if_rx_tready,
    output wire                                m_axis_if_rx_tlast,
    output wire [AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_if_rx_tuser,

    /*
     * Application section datapath interface (synchronous MAC interface)
     */
    output wire [AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_app_sync_tx_tdata,
    output wire [AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_app_sync_tx_tkeep,
    output wire                                m_axis_app_sync_tx_tvalid,
    input  wire                                m_axis_app_sync_tx_tready,
    output wire                                m_axis_app_sync_tx_tlast,
    output wire [AXIS_SYNC_TX_USER_WIDTH-1:0]  m_axis_app_sync_tx_tuser,

    input  wire [AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_app_sync_tx_tdata,
    input  wire [AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_app_sync_tx_tkeep,
    input  wire                                s_axis_app_sync_tx_tvalid,
    output wire                                s_axis_app_sync_tx_tready,
    input  wire                                s_axis_app_sync_tx_tlast,
    input  wire [AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_app_sync_tx_tuser,

    output wire [PTP_TS_WIDTH-1:0]             m_axis_app_sync_tx_cpl_ts,
    output wire [TX_TAG_WIDTH-1:0]             m_axis_app_sync_tx_cpl_tag,
    output wire                                m_axis_app_sync_tx_cpl_valid,
    input  wire                                m_axis_app_sync_tx_cpl_ready,

    input  wire [PTP_TS_WIDTH-1:0]             s_axis_app_sync_tx_cpl_ts,
    input  wire [TX_TAG_WIDTH-1:0]             s_axis_app_sync_tx_cpl_tag,
    input  wire                                s_axis_app_sync_tx_cpl_valid,
    output wire                                s_axis_app_sync_tx_cpl_ready,

    output wire [AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_app_sync_rx_tdata,
    output wire [AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_app_sync_rx_tkeep,
    output wire                                m_axis_app_sync_rx_tvalid,
    input  wire                                m_axis_app_sync_rx_tready,
    output wire                                m_axis_app_sync_rx_tlast,
    output wire [AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_app_sync_rx_tuser,

    input  wire [AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_app_sync_rx_tdata,
    input  wire [AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_app_sync_rx_tkeep,
    input  wire                                s_axis_app_sync_rx_tvalid,
    output wire                                s_axis_app_sync_rx_tready,
    input  wire                                s_axis_app_sync_rx_tlast,
    input  wire [AXIS_SYNC_RX_USER_WIDTH-1:0]  s_axis_app_sync_rx_tuser,

    /*
     * Application section datapath interface (direct MAC interface)
     */
    output wire [AXIS_DATA_WIDTH-1:0]          m_axis_app_direct_tx_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]          m_axis_app_direct_tx_tkeep,
    output wire                                m_axis_app_direct_tx_tvalid,
    input  wire                                m_axis_app_direct_tx_tready,
    output wire                                m_axis_app_direct_tx_tlast,
    output wire [AXIS_TX_USER_WIDTH-1:0]       m_axis_app_direct_tx_tuser,

    input  wire [AXIS_DATA_WIDTH-1:0]          s_axis_app_direct_tx_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]          s_axis_app_direct_tx_tkeep,
    input  wire                                s_axis_app_direct_tx_tvalid,
    output wire                                s_axis_app_direct_tx_tready,
    input  wire                                s_axis_app_direct_tx_tlast,
    input  wire [AXIS_TX_USER_WIDTH-1:0]       s_axis_app_direct_tx_tuser,

    output wire [PTP_TS_WIDTH-1:0]             m_axis_app_direct_tx_cpl_ts,
    output wire [TX_TAG_WIDTH-1:0]             m_axis_app_direct_tx_cpl_tag,
    output wire                                m_axis_app_direct_tx_cpl_valid,
    input  wire                                m_axis_app_direct_tx_cpl_ready,

    input  wire [PTP_TS_WIDTH-1:0]             s_axis_app_direct_tx_cpl_ts,
    input  wire [TX_TAG_WIDTH-1:0]             s_axis_app_direct_tx_cpl_tag,
    input  wire                                s_axis_app_direct_tx_cpl_valid,
    output wire                                s_axis_app_direct_tx_cpl_ready,

    output wire [AXIS_DATA_WIDTH-1:0]          m_axis_app_direct_rx_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]          m_axis_app_direct_rx_tkeep,
    output wire                                m_axis_app_direct_rx_tvalid,
    input  wire                                m_axis_app_direct_rx_tready,
    output wire                                m_axis_app_direct_rx_tlast,
    output wire [AXIS_RX_USER_WIDTH-1:0]       m_axis_app_direct_rx_tuser,

    input  wire [AXIS_DATA_WIDTH-1:0]          s_axis_app_direct_rx_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]          s_axis_app_direct_rx_tkeep,
    input  wire                                s_axis_app_direct_rx_tvalid,
    output wire                                s_axis_app_direct_rx_tready,
    input  wire                                s_axis_app_direct_rx_tlast,
    input  wire [AXIS_RX_USER_WIDTH-1:0]       s_axis_app_direct_rx_tuser,

    /*
     * Transmit data output
     */
    input  wire                                tx_clk,
    input  wire                                tx_rst,

    output wire [AXIS_DATA_WIDTH-1:0]          m_axis_tx_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]          m_axis_tx_tkeep,
    output wire                                m_axis_tx_tvalid,
    input  wire                                m_axis_tx_tready,
    output wire                                m_axis_tx_tlast,
    output wire [AXIS_TX_USER_WIDTH-1:0]       m_axis_tx_tuser,

    input  wire [PTP_TS_WIDTH-1:0]             s_axis_tx_cpl_ts,
    input  wire [TX_TAG_WIDTH-1:0]             s_axis_tx_cpl_tag,
    input  wire                                s_axis_tx_cpl_valid,
    output wire                                s_axis_tx_cpl_ready,

    input  wire                                tx_status,

    /*
     * Receive data input
     */
    input  wire                                rx_clk,
    input  wire                                rx_rst,

    input  wire [AXIS_DATA_WIDTH-1:0]          s_axis_rx_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]          s_axis_rx_tkeep,
    input  wire                                s_axis_rx_tvalid,
    output wire                                s_axis_rx_tready,
    input  wire                                s_axis_rx_tlast,
    input  wire [AXIS_RX_USER_WIDTH-1:0]       s_axis_rx_tuser,

    input  wire                                rx_status
);

localparam RBB = RB_BASE_ADDR & {REG_ADDR_WIDTH{1'b1}};

// check configuration
initial begin
    if (REG_DATA_WIDTH != 32) begin
        $error("Error: Register interface width must be 32 (instance %m)");
        $finish;
    end

    if (REG_STRB_WIDTH * 8 != REG_DATA_WIDTH) begin
        $error("Error: Register interface requires byte (8-bit) granularity (instance %m)");
        $finish;
    end

    if (REG_ADDR_WIDTH < $clog2(64)) begin
        $error("Error: Register address width too narrow (instance %m)");
        $finish;
    end

    if (RB_NEXT_PTR >= RB_BASE_ADDR && RB_NEXT_PTR < RB_BASE_ADDR + 64) begin
        $error("Error: RB_NEXT_PTR overlaps block (instance %m)");
        $finish;
    end
end

// TX status
reg tx_rst_sync_1_reg = 1'b0;
reg tx_rst_sync_2_reg = 1'b0;
reg tx_rst_sync_3_reg = 1'b0;
reg tx_status_sync_1_reg = 1'b0;
reg tx_status_sync_2_reg = 1'b0;
reg tx_status_sync_3_reg = 1'b0;

always @(posedge tx_clk or posedge tx_rst) begin
    if (tx_rst) begin
        tx_rst_sync_1_reg <= 1'b1;
        tx_status_sync_1_reg <= 1'b0;
    end else begin
        tx_rst_sync_1_reg <= 1'b0;
        tx_status_sync_1_reg <= tx_status;
    end
end

always @(posedge clk) begin
    tx_rst_sync_2_reg <= tx_rst_sync_1_reg;
    tx_rst_sync_3_reg <= tx_rst_sync_2_reg;
    tx_status_sync_2_reg <= tx_status_sync_1_reg;
    tx_status_sync_3_reg <= tx_status_sync_2_reg;
end

// RX status
reg rx_rst_sync_1_reg = 1'b0;
reg rx_rst_sync_2_reg = 1'b0;
reg rx_rst_sync_3_reg = 1'b0;
reg rx_status_sync_1_reg = 1'b0;
reg rx_status_sync_2_reg = 1'b0;
reg rx_status_sync_3_reg = 1'b0;

always @(posedge rx_clk or posedge rx_rst) begin
    if (rx_rst) begin
        rx_rst_sync_1_reg <= 1'b1;
        rx_status_sync_1_reg <= 1'b0;
    end else begin
        rx_rst_sync_1_reg <= 1'b0;
        rx_status_sync_1_reg <= rx_status;
    end
end

always @(posedge clk) begin
    rx_rst_sync_2_reg <= rx_rst_sync_1_reg;
    rx_rst_sync_3_reg <= rx_rst_sync_2_reg;
    rx_status_sync_2_reg <= rx_status_sync_1_reg;
    rx_status_sync_3_reg <= rx_status_sync_2_reg;
end

// control registers
reg ctrl_reg_wr_ack_reg = 1'b0;
reg [REG_DATA_WIDTH-1:0] ctrl_reg_rd_data_reg = {REG_DATA_WIDTH{1'b0}};
reg ctrl_reg_rd_ack_reg = 1'b0;

assign ctrl_reg_wr_wait = 1'b0;
assign ctrl_reg_wr_ack = ctrl_reg_wr_ack_reg;
assign ctrl_reg_rd_data = ctrl_reg_rd_data_reg;
assign ctrl_reg_rd_wait = 1'b0;
assign ctrl_reg_rd_ack = ctrl_reg_rd_ack_reg;

always @(posedge clk) begin
    ctrl_reg_wr_ack_reg <= 1'b0;
    ctrl_reg_rd_data_reg <= {REG_DATA_WIDTH{1'b0}};
    ctrl_reg_rd_ack_reg <= 1'b0;

    if (ctrl_reg_wr_en && !ctrl_reg_wr_ack_reg) begin
        // write operation
        ctrl_reg_wr_ack_reg <= 1'b1;
        case ({ctrl_reg_wr_addr >> 2, 2'b00})
            // Port control
            default: ctrl_reg_wr_ack_reg <= 1'b0;
        endcase
    end

    if (ctrl_reg_rd_en && !ctrl_reg_rd_ack_reg) begin
        // read operation
        ctrl_reg_rd_ack_reg <= 1'b1;
        case ({ctrl_reg_rd_addr >> 2, 2'b00})
            // Port
            RBB+8'h00: ctrl_reg_rd_data_reg <= 32'h0000C002;                // Port: Type
            RBB+8'h04: ctrl_reg_rd_data_reg <= 32'h00000200;                // Port: Version
            RBB+8'h08: ctrl_reg_rd_data_reg <= RB_NEXT_PTR;                 // Port: Next header
            RBB+8'h0C: ctrl_reg_rd_data_reg <= RB_BASE_ADDR+8'h10;          // Port: Offset
            // Port control
            RBB+8'h10: ctrl_reg_rd_data_reg <= 32'h0000C003;                // Port ctrl: Type
            RBB+8'h14: ctrl_reg_rd_data_reg <= 32'h00000200;                // Port ctrl: Version
            RBB+8'h18: ctrl_reg_rd_data_reg <= 0;                           // Port ctrl: Next header
            RBB+8'h1C: begin
                // Port ctrl: features
            end
            RBB+8'h20: begin
                // Port ctrl: TX status
                ctrl_reg_rd_data_reg[0] <= tx_status_sync_3_reg;
                ctrl_reg_rd_data_reg[1] <= tx_rst_sync_3_reg;
            end
            RBB+8'h24: begin
                // Port ctrl: RX status
                ctrl_reg_rd_data_reg[0] <= rx_status_sync_3_reg;
                ctrl_reg_rd_data_reg[1] <= rx_rst_sync_3_reg;
            end
            default: ctrl_reg_rd_ack_reg <= 1'b0;
        endcase
    end

    if (rst) begin
        ctrl_reg_wr_ack_reg <= 1'b0;
        ctrl_reg_rd_ack_reg <= 1'b0;
    end
end

mqnic_port_tx #(
    // PTP configuration
    .PTP_TS_WIDTH(PTP_TS_WIDTH),

    // Interface configuration
    .PTP_TS_ENABLE(PTP_TS_ENABLE),
    .TX_CPL_ENABLE(TX_CPL_ENABLE),
    .TX_CPL_FIFO_DEPTH(TX_CPL_FIFO_DEPTH),
    .TX_TAG_WIDTH(TX_TAG_WIDTH),
    .MAX_TX_SIZE(MAX_TX_SIZE),

    // Application block configuration
    .APP_AXIS_DIRECT_ENABLE(APP_AXIS_DIRECT_ENABLE),
    .APP_AXIS_SYNC_ENABLE(APP_AXIS_SYNC_ENABLE),

    // Streaming interface configuration
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_TX_USER_WIDTH(AXIS_TX_USER_WIDTH),
    .AXIS_TX_PIPELINE(AXIS_TX_PIPELINE),
    .AXIS_TX_FIFO_PIPELINE(AXIS_TX_FIFO_PIPELINE),
    .AXIS_TX_TS_PIPELINE(AXIS_TX_TS_PIPELINE),
    .AXIS_SYNC_DATA_WIDTH(AXIS_SYNC_DATA_WIDTH),
    .AXIS_SYNC_KEEP_WIDTH(AXIS_SYNC_KEEP_WIDTH),
    .AXIS_SYNC_TX_USER_WIDTH(AXIS_SYNC_TX_USER_WIDTH)
)
port_tx_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Transmit data from interface FIFO
     */
    .s_axis_if_tx_tdata(s_axis_if_tx_tdata),
    .s_axis_if_tx_tkeep(s_axis_if_tx_tkeep),
    .s_axis_if_tx_tvalid(s_axis_if_tx_tvalid),
    .s_axis_if_tx_tready(s_axis_if_tx_tready),
    .s_axis_if_tx_tlast(s_axis_if_tx_tlast),
    .s_axis_if_tx_tuser(s_axis_if_tx_tuser),

    .m_axis_if_tx_cpl_ts(m_axis_if_tx_cpl_ts),
    .m_axis_if_tx_cpl_tag(m_axis_if_tx_cpl_tag),
    .m_axis_if_tx_cpl_valid(m_axis_if_tx_cpl_valid),
    .m_axis_if_tx_cpl_ready(m_axis_if_tx_cpl_ready),

    /*
     * Application section datapath interface (synchronous MAC interface)
     */
    .m_axis_app_sync_tx_tdata(m_axis_app_sync_tx_tdata),
    .m_axis_app_sync_tx_tkeep(m_axis_app_sync_tx_tkeep),
    .m_axis_app_sync_tx_tvalid(m_axis_app_sync_tx_tvalid),
    .m_axis_app_sync_tx_tready(m_axis_app_sync_tx_tready),
    .m_axis_app_sync_tx_tlast(m_axis_app_sync_tx_tlast),
    .m_axis_app_sync_tx_tuser(m_axis_app_sync_tx_tuser),

    .s_axis_app_sync_tx_tdata(s_axis_app_sync_tx_tdata),
    .s_axis_app_sync_tx_tkeep(s_axis_app_sync_tx_tkeep),
    .s_axis_app_sync_tx_tvalid(s_axis_app_sync_tx_tvalid),
    .s_axis_app_sync_tx_tready(s_axis_app_sync_tx_tready),
    .s_axis_app_sync_tx_tlast(s_axis_app_sync_tx_tlast),
    .s_axis_app_sync_tx_tuser(s_axis_app_sync_tx_tuser),

    .m_axis_app_sync_tx_cpl_ts(m_axis_app_sync_tx_cpl_ts),
    .m_axis_app_sync_tx_cpl_tag(m_axis_app_sync_tx_cpl_tag),
    .m_axis_app_sync_tx_cpl_valid(m_axis_app_sync_tx_cpl_valid),
    .m_axis_app_sync_tx_cpl_ready(m_axis_app_sync_tx_cpl_ready),

    .s_axis_app_sync_tx_cpl_ts(s_axis_app_sync_tx_cpl_ts),
    .s_axis_app_sync_tx_cpl_tag(s_axis_app_sync_tx_cpl_tag),
    .s_axis_app_sync_tx_cpl_valid(s_axis_app_sync_tx_cpl_valid),
    .s_axis_app_sync_tx_cpl_ready(s_axis_app_sync_tx_cpl_ready),

    /*
     * Application section datapath interface (direct MAC interface)
     */
    .m_axis_app_direct_tx_tdata(m_axis_app_direct_tx_tdata),
    .m_axis_app_direct_tx_tkeep(m_axis_app_direct_tx_tkeep),
    .m_axis_app_direct_tx_tvalid(m_axis_app_direct_tx_tvalid),
    .m_axis_app_direct_tx_tready(m_axis_app_direct_tx_tready),
    .m_axis_app_direct_tx_tlast(m_axis_app_direct_tx_tlast),
    .m_axis_app_direct_tx_tuser(m_axis_app_direct_tx_tuser),

    .s_axis_app_direct_tx_tdata(s_axis_app_direct_tx_tdata),
    .s_axis_app_direct_tx_tkeep(s_axis_app_direct_tx_tkeep),
    .s_axis_app_direct_tx_tvalid(s_axis_app_direct_tx_tvalid),
    .s_axis_app_direct_tx_tready(s_axis_app_direct_tx_tready),
    .s_axis_app_direct_tx_tlast(s_axis_app_direct_tx_tlast),
    .s_axis_app_direct_tx_tuser(s_axis_app_direct_tx_tuser),

    .m_axis_app_direct_tx_cpl_ts(m_axis_app_direct_tx_cpl_ts),
    .m_axis_app_direct_tx_cpl_tag(m_axis_app_direct_tx_cpl_tag),
    .m_axis_app_direct_tx_cpl_valid(m_axis_app_direct_tx_cpl_valid),
    .m_axis_app_direct_tx_cpl_ready(m_axis_app_direct_tx_cpl_ready),

    .s_axis_app_direct_tx_cpl_ts(s_axis_app_direct_tx_cpl_ts),
    .s_axis_app_direct_tx_cpl_tag(s_axis_app_direct_tx_cpl_tag),
    .s_axis_app_direct_tx_cpl_valid(s_axis_app_direct_tx_cpl_valid),
    .s_axis_app_direct_tx_cpl_ready(s_axis_app_direct_tx_cpl_ready),

    /*
     * Transmit data output
     */
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),

    .m_axis_tx_tdata(m_axis_tx_tdata),
    .m_axis_tx_tkeep(m_axis_tx_tkeep),
    .m_axis_tx_tvalid(m_axis_tx_tvalid),
    .m_axis_tx_tready(m_axis_tx_tready),
    .m_axis_tx_tlast(m_axis_tx_tlast),
    .m_axis_tx_tuser(m_axis_tx_tuser),

    .s_axis_tx_cpl_ts(s_axis_tx_cpl_ts),
    .s_axis_tx_cpl_tag(s_axis_tx_cpl_tag),
    .s_axis_tx_cpl_valid(s_axis_tx_cpl_valid),
    .s_axis_tx_cpl_ready(s_axis_tx_cpl_ready)
);

mqnic_port_rx #(
    // PTP configuration
    .PTP_TS_WIDTH(PTP_TS_WIDTH),

    // Interface configuration
    .PTP_TS_ENABLE(PTP_TS_ENABLE),
    .MAX_RX_SIZE(MAX_RX_SIZE),

    // Application block configuration
    .APP_AXIS_DIRECT_ENABLE(APP_AXIS_DIRECT_ENABLE),
    .APP_AXIS_SYNC_ENABLE(APP_AXIS_SYNC_ENABLE),

    // Streaming interface configuration
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_RX_USER_WIDTH(AXIS_RX_USER_WIDTH),
    .AXIS_RX_USE_READY(AXIS_RX_USE_READY),
    .AXIS_RX_PIPELINE(AXIS_RX_PIPELINE),
    .AXIS_RX_FIFO_PIPELINE(AXIS_RX_FIFO_PIPELINE),
    .AXIS_SYNC_DATA_WIDTH(AXIS_SYNC_DATA_WIDTH),
    .AXIS_SYNC_KEEP_WIDTH(AXIS_SYNC_KEEP_WIDTH),
    .AXIS_SYNC_RX_USER_WIDTH(AXIS_SYNC_RX_USER_WIDTH)
)
port_rx_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Receive data to interface FIFO
     */
    .m_axis_if_rx_tdata(m_axis_if_rx_tdata),
    .m_axis_if_rx_tkeep(m_axis_if_rx_tkeep),
    .m_axis_if_rx_tvalid(m_axis_if_rx_tvalid),
    .m_axis_if_rx_tready(m_axis_if_rx_tready),
    .m_axis_if_rx_tlast(m_axis_if_rx_tlast),
    .m_axis_if_rx_tuser(m_axis_if_rx_tuser),

    /*
     * Application section datapath interface (synchronous MAC interface)
     */
    .m_axis_app_sync_rx_tdata(m_axis_app_sync_rx_tdata),
    .m_axis_app_sync_rx_tkeep(m_axis_app_sync_rx_tkeep),
    .m_axis_app_sync_rx_tvalid(m_axis_app_sync_rx_tvalid),
    .m_axis_app_sync_rx_tready(m_axis_app_sync_rx_tready),
    .m_axis_app_sync_rx_tlast(m_axis_app_sync_rx_tlast),
    .m_axis_app_sync_rx_tuser(m_axis_app_sync_rx_tuser),

    .s_axis_app_sync_rx_tdata(s_axis_app_sync_rx_tdata),
    .s_axis_app_sync_rx_tkeep(s_axis_app_sync_rx_tkeep),
    .s_axis_app_sync_rx_tvalid(s_axis_app_sync_rx_tvalid),
    .s_axis_app_sync_rx_tready(s_axis_app_sync_rx_tready),
    .s_axis_app_sync_rx_tlast(s_axis_app_sync_rx_tlast),
    .s_axis_app_sync_rx_tuser(s_axis_app_sync_rx_tuser),

    /*
     * Application section datapath interface (direct MAC interface)
     */
    .m_axis_app_direct_rx_tdata(m_axis_app_direct_rx_tdata),
    .m_axis_app_direct_rx_tkeep(m_axis_app_direct_rx_tkeep),
    .m_axis_app_direct_rx_tvalid(m_axis_app_direct_rx_tvalid),
    .m_axis_app_direct_rx_tready(m_axis_app_direct_rx_tready),
    .m_axis_app_direct_rx_tlast(m_axis_app_direct_rx_tlast),
    .m_axis_app_direct_rx_tuser(m_axis_app_direct_rx_tuser),

    .s_axis_app_direct_rx_tdata(s_axis_app_direct_rx_tdata),
    .s_axis_app_direct_rx_tkeep(s_axis_app_direct_rx_tkeep),
    .s_axis_app_direct_rx_tvalid(s_axis_app_direct_rx_tvalid),
    .s_axis_app_direct_rx_tready(s_axis_app_direct_rx_tready),
    .s_axis_app_direct_rx_tlast(s_axis_app_direct_rx_tlast),
    .s_axis_app_direct_rx_tuser(s_axis_app_direct_rx_tuser),

    /*
     * Receive data input
     */
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),

    .s_axis_rx_tdata(s_axis_rx_tdata),
    .s_axis_rx_tkeep(s_axis_rx_tkeep),
    .s_axis_rx_tvalid(s_axis_rx_tvalid),
    .s_axis_rx_tready(s_axis_rx_tready),
    .s_axis_rx_tlast(s_axis_rx_tlast),
    .s_axis_rx_tuser(s_axis_rx_tuser)
);

endmodule

`resetall
