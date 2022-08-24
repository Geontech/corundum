create_ip -name gig_ethernet_pcs_pma -vendor xilinx.com -library ip -version 16.2 -module_name gig_ethernet_pcs_pma_0

set_property -dict [list \
    CONFIG.EMAC_IF_TEMAC {TEMAC} \
    CONFIG.Standard {1000BASEX} \
    CONFIG.TransceiverControl {true} \
    CONFIG.Auto_Negotiation {false} \
    CONFIG.Physical_Interface {Transceiver} \
    CONFIG.Management_Interface {false} \
    CONFIG.RefClkRate {125} \
    CONFIG.DrpClkRate {62.5} \
    CONFIG.RxGmiiClkSrc {TXOUTCLK} \
] [get_ips gig_ethernet_pcs_pma_0]

