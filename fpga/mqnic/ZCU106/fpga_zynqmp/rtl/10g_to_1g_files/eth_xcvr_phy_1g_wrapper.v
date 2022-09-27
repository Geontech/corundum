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
 * GTY transceiver and PHY wrapper
 */
module eth_xcvr_phy_1g_wrapper #
(
    parameter INDEX = 0,
    parameter HAS_COMMON = (INDEX == 0),

    // GT parameters
    parameter GT_TX_POLARITY   = 1'b0,
    parameter GT_TX_INHIBIT    = 1'b0,
    parameter GT_TX_DIFFCTRL   = 5'd16,
    parameter GT_TX_POSTCURSOR = 5'd0,
    parameter GT_TX_PRECURSOR  = 5'd0,
    parameter GT_RX_LPM_EN     = 1'b0,
    parameter GT_RX_POLARITY   = 1'b0,

    // PHY parameters
    parameter DATA_WIDTH       = 8
)
(
    input  wire                   xcvr_ctrl_clk,
    input  wire                   xcvr_ctrl_rst,

    /*
     * Common
     */
    output wire                   xcvr_gtpowergood_out,
    input  wire                   xcvr_gtrefclk_p,
    input  wire                   xcvr_gtrefclk_n,
    output wire                   xcvr_gtrefclk_out,
    input  wire                   xcvr_gtrefclk1,


    /*
     * DRP
     */
    input  wire                   drp_clk,
    input  wire [9:0]             drp_addr,
    input  wire [15:0]            drp_di,
    input  wire                   drp_en,
    input  wire                   drp_we,
    output wire [15:0]            drp_do,
    output wire                   drp_rdy,

    /*
     * PLL out
     */

    /*
     * Serial data
     */
    output wire                   xcvr_txp,
    output wire                   xcvr_txn,
    input  wire                   xcvr_rxp,
    input  wire                   xcvr_rxn,

    /*
     * PHY connections
     */

    output wire                   phy_tx_clk,
    output wire                   phy_tx_rst,
    output wire                   phy_rx_clk,
    output wire                   phy_rx_rst,
    input  wire [DATA_WIDTH-1:0]  phy_gmii_txd,
    input  wire                   phy_gmii_tx_en,
    input  wire                   phy_gmii_tx_er,
    output wire [DATA_WIDTH-1:0]  phy_gmii_rxd,
    output wire                   phy_gmii_rx_dv,
    output wire                   phy_gmii_rx_er,

    /*
     * STATUS connections
     */

    output wire                   phy_tx_bad_block,
    output wire                   phy_rx_bad_block,
    output wire                   phy_rx_sequence_error,
    output wire                   phy_rx_block_lock,
    output wire                   phy_rx_high_ber
);

// wire
wire txoutclk;
wire rxoutclk;
wire gt_tx_reset_done;
wire gt_rx_reset_done;
wire gt_rx_pma_reset_done;

// reg
reg [4:0] gt_txdiffctrl_reg     = GT_TX_DIFFCTRL;
reg [4:0] gt_txpostcursor_reg   = GT_TX_POSTCURSOR;
reg [4:0] gt_txprecursor_reg    = GT_TX_PRECURSOR;
reg gt_txpolarity_sync_reg      = GT_TX_POLARITY;
reg gt_txinhibit_sync_reg       = GT_TX_INHIBIT;
reg gt_rxpolarity_sync_reg      = GT_RX_POLARITY;
reg [2:0] gt_txprbssel_sync_reg = 3'd0;
reg [2:0] gt_rxprbssel_sync_reg = 3'd0;
reg [2:0] gt_loopback_reg       = 3'b000;
reg gt_rx_dfe_lpm_reset_reg     = 1'b0;
reg gt_rxlpmen_reg              = GT_RX_LPM_EN;
reg gt_eyescan_reset_reg        = 1'b0;
reg gt_rxcdrhold_reg            = 1'b0;
reg gt_tx_pma_reset_reg         = 1'b0;
reg gt_tx_pcs_reset_reg         = 1'b0;
reg gt_rx_pma_reset_reg         = 1'b0;
reg gt_rx_pcs_reset_reg         = 1'b0;
reg gt_rx_reset_done_reg        = 1'b0;
reg gt_tx_reset_done_reg        = 1'b0;

reg reg0 = 1'b0;
reg [1:0] reg2 = 2'b00;
reg [2:0] reg3 = 3'b000;
reg [3:0] reg4 = 4'b0000;
reg [15:0] reg16 = 16'b0000000000000000;

wire rst_int;


/////////////////////////////////
//
//always @(posedge txoutclk) begin
//    gt_tx_reset_done_reg <= gt_tx_reset_done;
//    //gt_userclk_tx_active_reg <= gt_userclk_tx_active;
//end
//
//always @(posedge rxoutclk) begin
//    gt_rx_reset_done_reg <= gt_rx_reset_done;
//    //gt_userclk_rx_active_reg <= gt_userclk_rx_active;
//end
//
/////////////////////////////////

assign phy_tx_clk = txoutclk;

sync_reset #(
    .N(4)
)
tx_reset_sync_inst (
    .clk(phy_tx_clk),
    .rst(!rst_int),
    .out(phy_tx_rst)
);

assign phy_rx_clk = rxoutclk;

sync_reset #(
    .N(4)
)
rx_reset_sync_inst (
    .clk(phy_rx_clk),
    .rst(!rst_int),
    .out(phy_rx_rst)
);

gig_ethernet_pcs_pma_0 eth_pcspma (

    // Transceiver Interface
    //----------------------

    .gtrefclk_p               (xcvr_gtrefclk_p),
    .gtrefclk_n               (xcvr_gtrefclk_n),
    //.gtrefclk_out             (xcvr_gtrefclk_out),
    .gtrefclk_out             (),

    .txp                      (xcvr_txp),
    .txn                      (xcvr_txn),
    .rxp                      (xcvr_rxp),
    .rxn                      (xcvr_rxn),

    .resetdone                (),

    .userclk_out              (txoutclk),

    //.userclk2_out             (),
    .userclk2_out             (xcvr_gtrefclk_out),

    .rxuserclk_out            (rxoutclk),
    .rxuserclk2_out           (),

    .independent_clock_bufg   (reg0),

    .pma_reset_out            (),
    .mmcm_locked_out          (),

    // GMII Interface
    //---------------
    .gmii_txd                 (phy_gmii_txd),
    .gmii_tx_en               (phy_gmii_tx_en),
    .gmii_tx_er               (phy_gmii_tx_er),
    .gmii_rxd                 (phy_gmii_rxd),
    .gmii_rx_dv               (phy_gmii_rx_dv),
    .gmii_rx_er               (phy_gmii_rx_er),
    .gmii_isolate             (),                // Doesn't exist on eth_mac_1g.v

    // Management: Alternative to MDIO Interface
    //------------------------------------------
    .configuration_vector     (reg4),

    // General IO's
    //-------------
    .status_vector            (),
    .reset                    (rst_int),

    .gt_drpaddr               (drp_addr),
    .gt_drpclk                (drp_clk),
    .gt_drpdi                 (drp_di),
    .gt_drpdo                 (drp_do),
    .gt_drpen                 (drp_en),
    .gt_drprdy                (drp_rdy),
    .gt_drpwe                 (drp_we),
    .gt_rxcommadet            (),
    .gt_txpolarity            (gt_txpolarity_sync_reg),
    .gt_txdiffctrl            (gt_txdiffctrl_reg),
    .gt_txinhibit             (gt_txinhibit_sync_reg),
    .gt_txpostcursor          (gt_txpostcursor_reg),
    .gt_txprecursor           (gt_txprecursor_reg),
    .gt_rxpolarity            (gt_rxpolarity_sync_reg),
    .gt_rxdfelpmreset         (gt_rx_dfe_lpm_reset_reg),
    .gt_rxlpmen               (gt_rxlpmen_reg),
    .gt_txprbssel             (gt_txprbssel_sync_reg),
    .gt_txprbsforceerr        (reg0),
    .gt_rxprbscntreset        (reg0),
    .gt_rxprbserr             (),
    .gt_rxprbssel             (gt_rxprbssel_sync_reg),
    .gt_loopback              (gt_loopback_reg),
    .gt_txresetdone           (gt_tx_reset_done),
    .gt_rxresetdone           (gt_rx_reset_done),
    .gt_rxdisperr             (),
    .gt_rxnotintable          (),
    .gt_eyescanreset          (gt_eyescan_reset_reg),
    .gt_eyescandataerror      (),
    .gt_eyescantrigger        (reg0),
    .gt_rxcdrhold             (gt_rxcdrhold_reg),
    .gt_txpmareset            (gt_tx_pma_reset_reg),
    .gt_txpcsreset            (gt_tx_pcs_reset_reg),
    .gt_rxpmareset            (gt_rx_pma_reset_reg),
    .gt_rxpcsreset            (gt_rx_pcs_reset_reg),
    .gt_rxbufreset            (reg0),
    .gt_rxpmaresetdone        (gt_rx_pma_reset_done),
    .gt_rxbufstatus           (),
    .gt_txbufstatus           (),
    .gt_rxrate                (reg3),
    .gt_cpllrefclksel         (reg3),
    .gt_gtrefclk1             (xcvr_gtrefclk1),
    .gt_pcsrsvdin             (reg16),
    .gt_dmonitorout           (),

    .gtpowergood              (xcvr_gtpowergood_out),
    .signal_detect            (reg0)
);

endmodule

`resetall
