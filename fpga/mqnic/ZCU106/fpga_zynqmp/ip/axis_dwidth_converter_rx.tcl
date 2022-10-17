create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_dwidth_converter_rx

set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {1} \
    CONFIG.M_TDATA_NUM_BYTES {8} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TUSER_BITS_PER_BYTE {1} \
] [get_ips axis_dwidth_converter_rx]
