//------------------------------------------------------------------------------
// File       : gig_ethernet_pcs_pma_0.v
// Author     : Xilinx Inc.
//------------------------------------------------------------------------------
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 
// 
// 
//------------------------------------------------------------------------------
// Description: This Core Block Level wrapper connects the core to a  
//              Series-7 Transceiver.
//
//
//   ------------------------------------------------------------
//   |                      Core Block wrapper                  |
//   |                                                          |
//   |        ------------------          -----------------     |
//   |        |      Core      |          | Transceiver   |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
// ---------->| GMII           |--------->|           TXP |-------->
//   |        | Tx             |          |           TXN |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
//   |        |                |          |               |     |
//   |        | GMII           |          |           RXP |     |
// <----------| Rx             |<---------|           RXN |<--------
//   |        |                |          |               |     |
//   |        ------------------          -----------------     |
//   |                                                          |
//   ------------------------------------------------------------
//
//


`timescale 1 ps/1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)

//------------------------------------------------------------------------------
// The module declaration for the Core Block wrapper.
//------------------------------------------------------------------------------

module gig_ethernet_pcs_pma_0 #
   (
    parameter EXAMPLE_SIMULATION                     =  0
   )
   (
      // Transceiver Interface
      //----------------------


      input        gtrefclk,
      output       txp,                   // Differential +ve of serial transmission from PMA to PMD.
      output       txn,                   // Differential -ve of serial transmission from PMA to PMD.
      input        rxp,                   // Differential +ve for serial reception from PMD to PMA.
      input        rxn,                   // Differential -ve for serial reception from PMD to PMA.
      output       resetdone,                 // The GT transceiver has completed its reset cycle
      output       cplllock,
      output       mmcm_reset,
      output       txoutclk,
      output       rxoutclk,
      input        userclk,
      input        userclk2,
      input        rxuserclk,
      input        rxuserclk2,
      input        independent_clock_bufg,
      input        pma_reset,                 // transceiver PMA reset signal
      input        mmcm_locked,               // MMCM Locked
      // GMII Interface
      //---------------
      input [7:0]  gmii_txd,              // Transmit data from client MAC.
      input        gmii_tx_en,            // Transmit control signal from client MAC.
      input        gmii_tx_er,            // Transmit control signal from client MAC.
      output [7:0] gmii_rxd,              // Received Data to client MAC.
      output       gmii_rx_dv,            // Received control signal to client MAC.
      output       gmii_rx_er,            // Received control signal to client MAC.
      output       gmii_isolate,          // Tristate control to electrically isolate GMII.

      // Management: Alternative to MDIO Interface
      //------------------------------------------

      input [4:0]  configuration_vector,  // Alternative to MDIO interface.

      // General IO's
      //-------------
      output [15:0] status_vector,         // Core status.
      input        reset,                 // Asynchronous reset for entire core

      input   [9:0]      gt_drpaddr,
      input              gt_drpclk,
      input   [15:0]     gt_drpdi,
      output  [15:0]     gt_drpdo,
      input              gt_drpen,
      output             gt_drprdy,
      input              gt_drpwe,
      output             gt_rxcommadet,
      input              gt_txpolarity,
      input   [4:0]      gt_txdiffctrl,
      input              gt_txinhibit,
      input   [4:0]      gt_txpostcursor,
      input   [4:0]      gt_txprecursor,
      input              gt_rxpolarity,
      input              gt_rxdfelpmreset,
      input              gt_rxlpmen,
      input   [2:0]      gt_txprbssel,
      input              gt_txprbsforceerr,
      input              gt_rxprbscntreset,
      output             gt_rxprbserr,
      input   [2:0]      gt_rxprbssel,
      input   [2:0]      gt_loopback,
      output             gt_txresetdone,
      output             gt_rxresetdone,
      output  [1:0]      gt_rxdisperr,
      output  [1:0]      gt_rxnotintable,
      input              gt_eyescanreset,
      output             gt_eyescandataerror,
      input              gt_eyescantrigger,
      input              gt_rxcdrhold,
      input              gt_txpmareset      ,
      input              gt_txpcsreset,
      input              gt_rxpmareset,
      input              gt_rxpcsreset,
      input              gt_rxbufreset,
      output             gt_rxpmaresetdone ,
      output [2:0]       gt_rxbufstatus    ,
      output [1:0]       gt_txbufstatus    ,
      input  [2:0]       gt_rxrate         ,
      input  [2:0]       gt_cpllrefclksel  ,
      input              gt_gtrefclk1      ,
      input  [15:0]      gt_pcsrsvdin      ,
      output [15:0]      gt_dmonitorout     ,

      output             gtpowergood,
      input              signal_detect          // Input from PMD to indicate presence of optical input.


   );


(* CORE_GENERATION_INFO = "gig_ethernet_pcs_pma_0,gig_ethernet_pcs_pma_v16_2_6,{x_ipProduct=Vivado 2021.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=gig_ethernet_pcs_pma,x_ipVersion=16.2,x_ipCoreRevision=6,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,c_elaboration_transient_dir=.,c_component_name=gig_ethernet_pcs_pma_0,c_family=zynquplus,c_architecture=zynquplus,c_is_sgmii=false,c_enable_async_sgmii=false,c_enable_async_lvds=false,c_enable_async_lvds_rx_only=false,c_use_transceiver=true,c_use_tbi=false,c_is_2_5g=false,c_use_lvds=false,c_has_an=false,characterization=false,c_has_mdio=false,c_has_axil=false,c_has_ext_mdio=false,c_sgmii_phy_mode=false,c_dynamic_switching=false,c_sgmii_fabric_buffer=true,c_1588=0,gt_rx_byte_width=1,C_EMAC_IF_TEMAC=true,EXAMPLE_SIMULATION=0,c_support_level=false,c_RxNibbleBitslice0Used=false,c_InstantiateBitslice0=false,c_tx_in_upper_nibble=1,c_TxLane0_Placement=DIFF_PAIR_0,c_TxLane1_Placement=DIFF_PAIR_1,c_RxLane0_Placement=DIFF_PAIR_0,c_RxLane1_Placement=DIFF_PAIR_1,c_sub_core_name=gig_ethernet_pcs_pma_0_gt,c_transceiver_type=GTHE4,c_gt_type=GTH,c_rx_gmii_clk_src=TXOUTCLK,c_transceivercontrol=true,c_gtinex=false,c_xdevicefamily=xczu7ev,c_clock_selection=Sync,c_gt_dmonitorout_width=16,c_gt_drpaddr_width=10,c_gt_txdiffctrl_width=5,c_gt_rxmonitorout_width=8,c_num_of_lanes=1,c_refclkrate=125,c_drpclkrate=62.5,c_gt_loc=X0Y0,c_refclk_src=clk0,c_enable_tx_userclk_reset_port=true,c_8_or_9_family=true,VERSAL_GT_BOARD_FLOW=0}" *)
(* X_CORE_INFO = "gig_ethernet_pcs_pma_v16_2_6,Vivado 2021.2" *)

gig_ethernet_pcs_pma_0_block # ( .EXAMPLE_SIMULATION             (EXAMPLE_SIMULATION) )
inst
   (
      // Transceiver Interface
      //----------------------

      .gtrefclk                             (gtrefclk),

      .txp                                  (txp),
      .txn                                  (txn),
      .rxp                                  (rxp),
      .rxn                                  (rxn),
      .resetdone                            (resetdone),
      .cplllock                             (cplllock),
      .mmcm_reset                           (mmcm_reset),
      .txoutclk                             (txoutclk),
      .rxoutclk                             (rxoutclk),
      .userclk                              (userclk),
      .userclk2                             (userclk2),
      .rxuserclk                            (rxuserclk),
      .rxuserclk2                           (rxuserclk2),
      .independent_clock_bufg               (independent_clock_bufg),
      .pma_reset                            (pma_reset),
      .mmcm_locked                          (mmcm_locked),
      // GMII Interface
      //---------------
      .gmii_txd                             (gmii_txd),
      .gmii_tx_en                           (gmii_tx_en),
      .gmii_tx_er                           (gmii_tx_er),
      .gmii_rxd                             (gmii_rxd),
      .gmii_rx_dv                           (gmii_rx_dv),
      .gmii_rx_er                           (gmii_rx_er),
      .gmii_isolate                         (gmii_isolate),

      // Management: Alternative to MDIO Interface
      //------------------------------------------

      .configuration_vector                 (configuration_vector),

      // General IO's
      //-------------
      .status_vector                        (status_vector),
      .reset                                (reset),

      .gt0_drpaddr_in                       (gt_drpaddr),
      .gt0_drpclk_in                        (gt_drpclk),
      .gt0_drpdi_in                         (gt_drpdi),
      .gt0_drpdo_out                        (gt_drpdo),
      .gt0_drpen_in                         (gt_drpen),
      .gt0_drprdy_out                       (gt_drprdy),
      .gt0_drpwe_in                         (gt_drpwe),
      .gt0_rxcommadet_out                   (gt_rxcommadet),
      .gt0_txpolarity_in                    (gt_txpolarity),
      .gt0_txdiffctrl_in                    (gt_txdiffctrl),
      .gt0_txinhibit_in                     (gt_txinhibit),
      .gt0_txpostcursor_in                  (gt_txpostcursor),
      .gt0_txprecursor_in                   (gt_txprecursor),
      .gt0_rxpolarity_in                    (gt_rxpolarity),
      .gt0_rxdfelpmreset_in                 (gt_rxdfelpmreset),
      .gt0_rxlpmen_in                       (gt_rxlpmen),
      .gt0_txprbssel_in                     (gt_txprbssel),
      .gt0_txprbsforceerr_in                (gt_txprbsforceerr),
      .gt0_rxprbscntreset_in                (gt_rxprbscntreset),
      .gt0_rxprbserr_out                    (gt_rxprbserr),
      .gt0_rxprbssel_in                     (gt_rxprbssel),
      .gt0_loopback_in                      (gt_loopback),
      .gt0_txresetdone_out                  (gt_txresetdone),
      .gt0_rxresetdone_out                  (gt_rxresetdone),
      .gt0_rxdisperr_out                    (gt_rxdisperr),
      .gt0_rxnotintable_out                 (gt_rxnotintable),
      .gt0_eyescanreset_in                  (gt_eyescanreset),
      .gt0_eyescandataerror_out             (gt_eyescandataerror),
      .gt0_eyescantrigger_in                (gt_eyescantrigger),
      .gt0_rxcdrhold_in                     (gt_rxcdrhold),
      .gt0_txpmareset_in                    (gt_txpmareset),
      .gt0_txpcsreset_in                    (gt_txpcsreset),
      .gt0_rxpmareset_in                    (gt_rxpmareset),
      .gt0_rxpcsreset_in                    (gt_rxpcsreset),
      .gt0_rxbufreset_in                    (gt_rxbufreset),
      .gt0_rxpmaresetdone_out               (gt_rxpmaresetdone),
      .gt0_rxbufstatus_out                  (gt_rxbufstatus),
      .gt0_txbufstatus_out                  (gt_txbufstatus),
      .gt0_rxrate_in                        (gt_rxrate),
      .gt0_cpllrefclksel_in                 (gt_cpllrefclksel),
      .gt0_gtrefclk1_in                     (gt_gtrefclk1),
      .gt0_pcsrsvdin_in                     (gt_pcsrsvdin),
      .gt0_dmonitorout_out                  (gt_dmonitorout),
      .gtpowergood                          (gtpowergood),
      .signal_detect                        (signal_detect)
   );


endmodule // gig_ethernet_pcs_pma_0

