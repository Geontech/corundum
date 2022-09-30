create_ip -name gig_ethernet_pcs_pma -vendor xilinx.com -library ip -version 16.2 -module_name gig_ethernet_pcs_pma_0

set_property -dict [list \
    CONFIG.Management_Interface {false} \
    CONFIG.Auto_Negotiation {false} \
    CONFIG.SupportLevel {Include_Shared_Logic_in_Core} \
    CONFIG.TransceiverControl {true} \
    CONFIG.RefClkRate {156.25} \
    CONFIG.DrpClkRate {62.5} \
] [get_ips gig_ethernet_pcs_pma_0]

