###################################################################################################
###################################################################################################

variable sys_cpu_interconnect_index
variable sys_hp0_interconnect_index
variable sys_hp1_interconnect_index
variable sys_hp2_interconnect_index
variable sys_hp3_interconnect_index
variable sys_mem_interconnect_index
variable xcvr_parameter_list
variable xcvr_rx_bufg_enable
variable xcvr_rx_ref_clk
variable xcvr_rx_lane_rate
variable xcvr_tx_bufg_enable
variable xcvr_tx_ref_clk
variable xcvr_tx_lane_rate
variable xcvr_master_or_slave_n
variable xcvr_master_instance

###################################################################################################
###################################################################################################

set sys_cpu_interconnect_index 0
set sys_hp0_interconnect_index -1
set sys_hp1_interconnect_index -1
set sys_hp2_interconnect_index -1
set sys_hp3_interconnect_index -1
set sys_mem_interconnect_index -1
set xcvr_parameter_list {}
set xcvr_rx_bufg_enable 1
set xcvr_rx_ref_clk 500.000
set xcvr_rx_lane_rate 10.000
set xcvr_tx_bufg_enable 1
set xcvr_tx_ref_clk 500.000
set xcvr_tx_lane_rate 10.000
set xcvr_master_or_slave_n 1
set xcvr_master_instance {NONE}

###################################################################################################
###################################################################################################

proc ad_ip_instance {i_ip i_name} {

  create_bd_cell -type ip -vlnv [get_ipdefs -all -filter "VLNV =~ *:${i_ip}:* && \
    design_tool_contexts =~ *IPI* && UPGRADE_VERSIONS == \"\""] ${i_name}
}

proc ad_ip_parameter {i_name i_param i_value} {

  set_property ${i_param} ${i_value} [get_bd_cells ${i_name}]
}

###################################################################################################
###################################################################################################

proc ad_connect_type {p_name} {

  set m_name ""

  if {$m_name eq ""} {set m_name [get_bd_intf_pins  -quiet $p_name]}
  if {$m_name eq ""} {set m_name [get_bd_pins       -quiet $p_name]}
  if {$m_name eq ""} {set m_name [get_bd_intf_ports -quiet $p_name]}
  if {$m_name eq ""} {set m_name [get_bd_ports      -quiet $p_name]}
  if {$m_name eq ""} {set m_name [get_bd_intf_nets  -quiet $p_name]}
  if {$m_name eq ""} {set m_name [get_bd_nets       -quiet $p_name]}

  return $m_name
}

proc ad_connect {p_name_1 p_name_2} {

  if {($p_name_2 eq "GND") || ($p_name_2 eq "VCC")} {
    set p_size 1
    set p_msb [get_property left [get_bd_pins $p_name_1]]
    set p_lsb [get_property right [get_bd_pins $p_name_1]]
    if {($p_msb ne "") && ($p_lsb ne "")} {
      set p_size [expr (($p_msb + 1) - $p_lsb)]
    }
    set p_cell_name [regsub -all {/} $p_name_1 "_"]
    set p_cell_name "${p_cell_name}_${p_name_2}"
    if {$p_name_2 eq "VCC"} {
      set p_value -1
    } else {
      set p_value 0
    }
    ad_ip_instance xlconstant $p_cell_name
    set_property CONFIG.CONST_WIDTH $p_size [get_bd_cells $p_cell_name]
    set_property CONFIG.CONST_VAL $p_value [get_bd_cells $p_cell_name]
    puts "connect_bd_net $p_cell_name/dout $p_name_1"
    connect_bd_net [get_bd_pins $p_cell_name/dout] [get_bd_pins $p_name_1]
    return
  }

  set m_name_1 [ad_connect_type $p_name_1]
  set m_name_2 [ad_connect_type $p_name_2]

  if {$m_name_1 eq ""} {
    if {[get_property CLASS $m_name_2] eq "bd_intf_pin"} {
      puts "create_bd_intf_net $p_name_1"
      create_bd_intf_net $p_name_1
    }
    if {[get_property CLASS $m_name_2] eq "bd_pin"} {
      puts "create_bd_net $p_name_1"
      create_bd_net $p_name_1
    }
    set m_name_1 [ad_connect_type $p_name_1]
  }

  if {[get_property CLASS $m_name_1] eq "bd_intf_pin"} {
    puts "connect_bd_intf_net $m_name_1 $m_name_2"
    connect_bd_intf_net $m_name_1 $m_name_2
    return
  }

  if {[get_property CLASS $m_name_1] eq "bd_pin"} {
    puts "connect_bd_net $m_name_1 $m_name_2"
    connect_bd_net $m_name_1 $m_name_2
    return
  }

  if {[get_property CLASS $m_name_1] eq "bd_net"} {
    puts "connect_bd_net -net $m_name_1 $m_name_2"
    connect_bd_net -net $m_name_1 $m_name_2
    return
  }
}

proc ad_disconnect {p_name_1 p_name_2} {

  set m_name_1 [ad_connect_type $p_name_1]
  set m_name_2 [ad_connect_type $p_name_2]

  if {[get_property CLASS $m_name_1] eq "bd_net"} {
    disconnect_bd_net $m_name_1 $m_name_2
    return
  }

  if {[get_property CLASS $m_name_1] eq "bd_port"} {
    delete_bd_objs -quiet [get_bd_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_1]]
    delete_bd_objs -quiet $m_name_1
    return
  }

  if {[get_property CLASS $m_name_1] eq "bd_pin"} {
    delete_bd_objs -quiet [get_bd_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_1]]
    delete_bd_objs -quiet $m_name_1
    return
  }
}

proc ad_reconnect {p_name_1 p_name_2} {

  set m_name_1 [ad_connect_type $p_name_1]
  set m_name_2 [ad_connect_type $p_name_2]

  if {[get_property CLASS $m_name_1] eq "bd_pin"} {
    delete_bd_objs -quiet [get_bd_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_1]]
    delete_bd_objs -quiet [get_bd_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_2]]
  }

  if {[get_property CLASS $m_name_1] eq "bd_intf_pin"} {
    delete_bd_objs -quiet [get_bd_intf_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_1]]
    delete_bd_objs -quiet [get_bd_intf_nets -quiet -of_objects \
      [find_bd_objs -relation connected_to $m_name_2]]
  }

  ad_connect $p_name_1 $p_name_2
}

###################################################################################################
###################################################################################################

proc ad_xcvr_parameter {i_type i_value} {

  global xcvr_parameter_list
  global xcvr_rx_bufg_enable
  global xcvr_rx_ref_clk
  global xcvr_rx_lane_rate
  global xcvr_tx_bufg_enable
  global xcvr_tx_ref_clk
  global xcvr_tx_lane_rate
  global xcvr_master_or_slave_n
  global xcvr_master_instance

  if {$i_type eq "number_of_lanes"} {
    lappend xcvr_parameter_list CONFIG.C_LANES $i_value
    return
  }

  if {$i_type eq "rx_bufg_enable"} {
    set xcvr_rx_bufg_enable $i_value
    return
  }

  if {$i_type eq "rx_ref_clk_frequency"} {
    set i_value [regsub -all {[^0-9\.]} $i_value ""]
    set xcvr_rx_ref_clk $i_value
    return
  }

  if {$i_type eq "rx_lane_rate"} {
    set i_value [regsub -all {[^0-9\.]} $i_value ""]
    set xcvr_rx_lane_rate $i_value
    return
  }

  if {$i_type eq "tx_bufg_enable"} {
    set xcvr_tx_bufg_enable $i_value
    return
  }

  if {$i_type eq "tx_ref_clk_frequency"} {
    set i_value [regsub -all {[^0-9\.]} $i_value ""]
    set xcvr_tx_ref_clk $i_value
    return
  }

  if {$i_type eq "tx_lane_rate"} {
    set i_value [regsub -all {[^0-9\.]} $i_value ""]
    set xcvr_tx_lane_rate $i_value
    return
  }

  if {$i_type eq "master_or_slave_n"} {
    set xcvr_master_or_slave_n $i_value
    return
  }

  lappend xcvr_parameter_list $i_type $i_value
}

proc ad_xcvr_instance {i_name} {

  global xcvr_parameter_list
  global xcvr_rx_bufg_enable
  global xcvr_rx_ref_clk
  global xcvr_rx_lane_rate
  global xcvr_tx_bufg_enable
  global xcvr_tx_ref_clk
  global xcvr_tx_lane_rate
  global xcvr_master_or_slave_n
  global xcvr_master_instance

  if {$xcvr_master_or_slave_n == 1} {
    set xcvr_master_instance $i_name
  }

  ad_ip_instance jesd204_phy $i_name
  set xcvr_type [get_property CONFIG.Transceiver [get_bd_cells $i_name]]

  lappend xcvr_parameter_list CONFIG.Config_Type 1
  lappend xcvr_parameter_list CONFIG.SupportLevel $xcvr_master_or_slave_n

  if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
    lappend xcvr_parameter_list CONFIG.Min_Line_Rate 4
    lappend xcvr_parameter_list CONFIG.Max_Line_Rate 16
  } else {
    lappend xcvr_parameter_list CONFIG.Min_Line_Rate 1
    lappend xcvr_parameter_list CONFIG.Max_Line_Rate 16
  }

  set xcvr_rx_pll 3
  set xcvr_rx_lane_rate [regsub {0*$} $xcvr_rx_lane_rate ""]
  set xcvr_rx_lane_rate [regsub {\.$} $xcvr_rx_lane_rate ""]
  if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
    set xcvr_rx_pll 1
    set xcvr_rx_ref_clk [regsub {0*$} $xcvr_rx_ref_clk ""]
    set xcvr_rx_ref_clk [regsub {\.$} $xcvr_rx_ref_clk ""]
  }
  if {$xcvr_rx_lane_rate < 6.25} {
    set xcvr_rx_pll 0
  }

  lappend xcvr_parameter_list CONFIG.RX_GT_REFCLK_FREQ $xcvr_rx_ref_clk
  lappend xcvr_parameter_list CONFIG.RX_GT_Line_Rate $xcvr_rx_lane_rate
  lappend xcvr_parameter_list CONFIG.RX_PLL_SELECTION $xcvr_rx_pll

  set xcvr_tx_pll 3
  set xcvr_tx_lane_rate [regsub {0*$} $xcvr_rx_lane_rate ""]
  set xcvr_tx_lane_rate [regsub {\.$} $xcvr_rx_lane_rate ""]
  if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
    set xcvr_tx_pll 1
    set xcvr_tx_ref_clk [regsub {0*$} $xcvr_tx_ref_clk ""]
    set xcvr_tx_ref_clk [regsub {\.$} $xcvr_tx_ref_clk ""]
  }
  if {($xcvr_tx_lane_rate < 6.25) && ($xcvr_rx_pll > 0)} {
    set xcvr_tx_pll 0
  }

  lappend xcvr_parameter_list CONFIG.GT_REFCLK_FREQ $xcvr_tx_ref_clk
  lappend xcvr_parameter_list CONFIG.GT_Line_Rate $xcvr_tx_lane_rate
  lappend xcvr_parameter_list CONFIG.C_PLL_SELECTION $xcvr_tx_pll

  set_property -dict $xcvr_parameter_list [get_bd_cells $i_name]
  set xcvr_parameter_list {}

  if {$xcvr_master_or_slave_n == 1} {
    if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
      create_bd_port -dir I -type clk ${i_name}_qpll0_ref_clk
      create_bd_port -dir I -type clk ${i_name}_qpll1_ref_clk
      ad_connect ${i_name}_qpll0_ref_clk $i_name/qpll0_refclk
      ad_connect ${i_name}_qpll1_ref_clk $i_name/qpll1_refclk
    } else {
      create_bd_port -dir I -type clk ${i_name}_qpll_ref_clk
      ad_connect ${i_name}_qpll_ref_clk $i_name/qpll_refclk
    }
  } else {
    if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
      ad_connect $xcvr_master_instance/common0_qpll0_out $i_name/common0_qpll0_in
      ad_connect $xcvr_master_instance/common0_qpll1_out $i_name/common0_qpll1_in
    } else {
      ad_connect $xcvr_master_instance/common0_qpll_out $i_name/common0_qpll_in
    }
  }

  create_bd_port -dir I -type clk ${i_name}_cpll_ref_clk
  ad_connect ${i_name}_cpll_ref_clk $i_name/cpll_refclk
  ad_connect sys_cpu_clk $i_name/drpclk

  ad_connect sys_cpu_reset $i_name/rx_sys_reset
  ad_connect sys_cpu_reset $i_name/rx_reset_gt
  if {$xcvr_rx_bufg_enable == 1} {
    ad_connect ${i_name}_rx_core_clk $i_name/rx_core_clk
    if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
      ad_ip_instance util_ds_buf ${i_name}_rx_bufg
      ad_ip_parameter ${i_name}_rx_bufg CONFIG.C_BUF_TYPE {BUFG_GT}
      ad_connect ${i_name}_rx_core_clk ${i_name}_rx_bufg/BUFG_GT_O
      ad_connect $i_name/rxoutclk ${i_name}_rx_bufg/BUFG_GT_I
      ad_connect ${i_name}_rx_bufg/BUFG_GT_CE VCC
      ad_connect ${i_name}_rx_bufg/BUFG_GT_CLR GND
      ad_connect ${i_name}_rx_bufg/BUFG_GT_DIV GND
      ad_connect ${i_name}_rx_bufg/BUFG_GT_CEMASK GND
      ad_connect ${i_name}_rx_bufg/BUFG_GT_CLRMASK GND
    } else {
      ad_ip_instance util_ds_buf ${i_name}_rx_bufg
      ad_ip_parameter ${i_name}_rx_bufg CONFIG.C_BUF_TYPE {BUFG}
      ad_connect ${i_name}_rx_core_clk ${i_name}_rx_bufg/BUFG_O
      ad_connect $i_name/rxoutclk ${i_name}_rx_bufg/BUFG_I
    }
  }

  ad_connect sys_cpu_reset $i_name/tx_sys_reset
  ad_connect sys_cpu_reset $i_name/tx_reset_gt
  if {$xcvr_tx_bufg_enable == 1} {
    ad_connect ${i_name}_tx_core_clk $i_name/tx_core_clk
    if {($xcvr_type eq "GTHE4") || ($xcvr_type eq "GTHE3")} {
      ad_ip_instance util_ds_buf ${i_name}_tx_bufg
      ad_ip_parameter ${i_name}_tx_bufg CONFIG.C_BUF_TYPE {BUFG_GT}
      ad_connect ${i_name}_tx_core_clk ${i_name}_tx_bufg/BUFG_GT_O
      ad_connect $i_name/txoutclk ${i_name}_tx_bufg/BUFG_GT_I
      ad_connect ${i_name}_tx_bufg/BUFG_GT_CE VCC
      ad_connect ${i_name}_tx_bufg/BUFG_GT_CLR GND
      ad_connect ${i_name}_tx_bufg/BUFG_GT_DIV GND
      ad_connect ${i_name}_tx_bufg/BUFG_GT_CEMASK GND
      ad_connect ${i_name}_tx_bufg/BUFG_GT_CLRMASK GND
    } else {
      ad_ip_instance util_ds_buf ${i_name}_tx_bufg
      ad_ip_parameter ${i_name}_tx_bufg CONFIG.C_BUF_TYPE {BUFG}
      ad_connect ${i_name}_tx_core_clk ${i_name}_tx_bufg/BUFG_O
      ad_connect $i_name/txoutclk ${i_name}_tx_bufg/BUFG_I
    }
  }

  set xcvr_no_of_lanes [get_property CONFIG.C_LANES [get_bd_cells $i_name]]
  set xcvr_no_of_lanes [expr $xcvr_no_of_lanes - 1]

  create_bd_port -dir I -from $xcvr_no_of_lanes -to 0 ${i_name}_rx_data_p
  create_bd_port -dir I -from $xcvr_no_of_lanes -to 0 ${i_name}_rx_data_n
  ad_connect ${i_name}_rx_data_p ${i_name}/rxp_in
  ad_connect ${i_name}_rx_data_n ${i_name}/rxn_in

  create_bd_port -dir O -from $xcvr_no_of_lanes -to 0 ${i_name}_tx_data_p
  create_bd_port -dir O -from $xcvr_no_of_lanes -to 0 ${i_name}_tx_data_n
  ad_connect ${i_name}/txp_out ${i_name}_tx_data_p
  ad_connect ${i_name}/txn_out ${i_name}_tx_data_n
}

###################################################################################################
###################################################################################################

proc ad_mem_hp0_interconnect {p_clk p_name} {

  global sys_zynq

  if {($sys_zynq == 0) && ($p_name eq "sys_ps7/S_AXI_HP0")} {return}
  if {$sys_zynq == 0} {ad_mem_hpx_interconnect "MEM" $p_clk $p_name}
  if {$sys_zynq >= 1} {ad_mem_hpx_interconnect "HP0" $p_clk $p_name}
}

proc ad_mem_hp1_interconnect {p_clk p_name} {

  global sys_zynq

  if {($sys_zynq == 0) && ($p_name eq "sys_ps7/S_AXI_HP1")} {return}
  if {$sys_zynq == 0} {ad_mem_hpx_interconnect "MEM" $p_clk $p_name}
  if {$sys_zynq >= 1} {ad_mem_hpx_interconnect "HP1" $p_clk $p_name}
}

proc ad_mem_hp2_interconnect {p_clk p_name} {

  global sys_zynq

  if {($sys_zynq == 0) && ($p_name eq "sys_ps7/S_AXI_HP2")} {return}
  if {$sys_zynq == 0} {ad_mem_hpx_interconnect "MEM" $p_clk $p_name}
  if {$sys_zynq >= 1} {ad_mem_hpx_interconnect "HP2" $p_clk $p_name}
}

proc ad_mem_hp3_interconnect {p_clk p_name} {

  global sys_zynq

  if {($sys_zynq == 0) && ($p_name eq "sys_ps7/S_AXI_HP3")} {return}
  if {$sys_zynq == 0} {ad_mem_hpx_interconnect "MEM" $p_clk $p_name}
  if {$sys_zynq >= 1} {ad_mem_hpx_interconnect "HP3" $p_clk $p_name}
}

###################################################################################################
###################################################################################################

proc ad_mem_hpx_interconnect {p_sel p_clk p_name} {

  global sys_zynq
  global sys_ddr_addr_seg
  global sys_hp0_interconnect_index
  global sys_hp1_interconnect_index
  global sys_hp2_interconnect_index
  global sys_hp3_interconnect_index
  global sys_mem_interconnect_index

  set p_name_int $p_name
  set p_clk_source [get_bd_pins -filter {DIR == O} -of_objects [get_bd_nets $p_clk]]

  if {$p_sel eq "MEM"} {
    if {$sys_mem_interconnect_index < 0} {
      ad_ip_instance axi_interconnect axi_mem_interconnect
    }
    set m_interconnect_index $sys_mem_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_mem_interconnect]
    set m_addr_seg [get_bd_addr_segs -of_objects [get_bd_cells axi_ddr_cntrl]]
  }

  if {($p_sel eq "HP0") && ($sys_zynq == 1)} {
    if {$sys_hp0_interconnect_index < 0} {
      set p_name_int sys_ps7/S_AXI_HP0
      set_property CONFIG.PCW_USE_S_AXI_HP0 {1} [get_bd_cells sys_ps7]
      ad_ip_instance axi_interconnect axi_hp0_interconnect
    }
    set m_interconnect_index $sys_hp0_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp0_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps7/S_AXI_HP0/HP0_DDR_LOWOCM]
  }

  if {($p_sel eq "HP1") && ($sys_zynq == 1)} {
    if {$sys_hp1_interconnect_index < 0} {
      set p_name_int sys_ps7/S_AXI_HP1
      set_property CONFIG.PCW_USE_S_AXI_HP1 {1} [get_bd_cells sys_ps7]
      ad_ip_instance axi_interconnect axi_hp1_interconnect
    }
    set m_interconnect_index $sys_hp1_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp1_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps7/S_AXI_HP1/HP1_DDR_LOWOCM]
  }

  if {($p_sel eq "HP2") && ($sys_zynq == 1)} {
    if {$sys_hp2_interconnect_index < 0} {
      set p_name_int sys_ps7/S_AXI_HP2
      set_property CONFIG.PCW_USE_S_AXI_HP2 {1} [get_bd_cells sys_ps7]
      ad_ip_instance axi_interconnect axi_hp2_interconnect
    }
    set m_interconnect_index $sys_hp2_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp2_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps7/S_AXI_HP2/HP2_DDR_LOWOCM]
  }

  if {($p_sel eq "HP3") && ($sys_zynq == 1)} {
    if {$sys_hp3_interconnect_index < 0} {
      set p_name_int sys_ps7/S_AXI_HP3
      set_property CONFIG.PCW_USE_S_AXI_HP3 {1} [get_bd_cells sys_ps7]
      ad_ip_instance axi_interconnect axi_hp3_interconnect
    }
    set m_interconnect_index $sys_hp3_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp3_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps7/S_AXI_HP3/HP3_DDR_LOWOCM]
  }

  if {($p_sel eq "HP0") && ($sys_zynq == 2)} {
    if {$sys_hp0_interconnect_index < 0} {
      set p_name_int sys_ps8/S_AXI_HP0_FPD
      set_property CONFIG.PSU__USE__S_AXI_GP2 {1} [get_bd_cells sys_ps8]
      ad_ip_instance axi_interconnect axi_hp0_interconnect
    }
    set m_interconnect_index $sys_hp0_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp0_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps8/S_AXI_HP0_FPD/PLLPD_DDR_LOW]
  }

  if {($p_sel eq "HP1") && ($sys_zynq == 2)} {
    if {$sys_hp1_interconnect_index < 0} {
      set p_name_int sys_ps8/S_AXI_HP1_FPD
      set_property CONFIG.PSU__USE__S_AXI_GP3 {1} [get_bd_cells sys_ps8]
      ad_ip_instance axi_interconnect axi_hp1_interconnect
    }
    set m_interconnect_index $sys_hp1_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp1_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps8/S_AXI_HP1_FPD/HP0_DDR_LOW]
  }

  if {($p_sel eq "HP2") && ($sys_zynq == 2)} {
    if {$sys_hp2_interconnect_index < 0} {
      set p_name_int sys_ps8/S_AXI_HP2_FPD
      set_property CONFIG.PSU__USE__S_AXI_GP4 {1} [get_bd_cells sys_ps8]
      ad_ip_instance axi_interconnect axi_hp2_interconnect
    }
    set m_interconnect_index $sys_hp2_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp2_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps8/S_AXI_HP2_FPD/HP1_DDR_LOW]
  }

  if {($p_sel eq "HP3") && ($sys_zynq == 2)} {
    if {$sys_hp3_interconnect_index < 0} {
      set p_name_int sys_ps8/S_AXI_HP3_FPD
      set_property CONFIG.PSU__USE__S_AXI_GP5 {1} [get_bd_cells sys_ps8]
      ad_ip_instance axi_interconnect axi_hp3_interconnect
    }
    set m_interconnect_index $sys_hp3_interconnect_index
    set m_interconnect_cell [get_bd_cells axi_hp3_interconnect]
    set m_addr_seg [get_bd_addr_segs sys_ps8/S_AXI_HP3_FPD/HP2_DDR_LOW]
  }

  set i_str "S$m_interconnect_index"
  if {$m_interconnect_index < 10} {
    set i_str "S0$m_interconnect_index"
  }

  set m_interconnect_index [expr $m_interconnect_index + 1]

  set p_intf_name [lrange [split $p_name_int "/"] end end]
  set p_cell_name [lrange [split $p_name_int "/"] 0 0]
  set p_intf_clock [get_bd_pins -filter "TYPE == clk && (CONFIG.ASSOCIATED_BUSIF == ${p_intf_name} || \
    CONFIG.ASSOCIATED_BUSIF =~ ${p_intf_name}:* || CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name} || \
    CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name}:*)" -quiet -of_objects [get_bd_cells $p_cell_name]]
  if {[find_bd_objs -quiet -relation connected_to $p_intf_clock] ne "" ||
      $p_intf_clock eq $p_clk_source} {
    set p_intf_clock ""
  }

  regsub clk $p_clk resetn p_rst
  if {[get_bd_nets -quiet $p_rst] eq ""} {
    set p_rst sys_cpu_resetn
  }

  if {$m_interconnect_index == 0} {
    set_property CONFIG.NUM_MI 1 $m_interconnect_cell
    set_property CONFIG.NUM_SI 1 $m_interconnect_cell
    ad_connect $p_rst $m_interconnect_cell/ARESETN
    ad_connect $p_clk $m_interconnect_cell/ACLK
    ad_connect $p_rst $m_interconnect_cell/M00_ARESETN
    ad_connect $p_clk $m_interconnect_cell/M00_ACLK
    ad_connect $m_interconnect_cell/M00_AXI $p_name_int
    if {$p_intf_clock ne ""} {
      ad_connect $p_clk $p_intf_clock
    }
  } else {
    set_property CONFIG.NUM_SI $m_interconnect_index $m_interconnect_cell
    ad_connect $p_rst $m_interconnect_cell/${i_str}_ARESETN
    ad_connect $p_clk $m_interconnect_cell/${i_str}_ACLK
    ad_connect $m_interconnect_cell/${i_str}_AXI $p_name_int
    if {$p_intf_clock ne ""} {
      ad_connect $p_clk $p_intf_clock
    }
    assign_bd_address $m_addr_seg
  }

  if {$m_interconnect_index > 1} {
    set_property CONFIG.STRATEGY {2} $m_interconnect_cell
  }

  if {$p_sel eq "MEM"} {set sys_mem_interconnect_index $m_interconnect_index}
  if {$p_sel eq "HP0"} {set sys_hp0_interconnect_index $m_interconnect_index}
  if {$p_sel eq "HP1"} {set sys_hp1_interconnect_index $m_interconnect_index}
  if {$p_sel eq "HP2"} {set sys_hp2_interconnect_index $m_interconnect_index}
  if {$p_sel eq "HP3"} {set sys_hp3_interconnect_index $m_interconnect_index}

}

###################################################################################################
###################################################################################################

proc ad_cpu_interconnect {p_address p_name} {

  global sys_zynq
  global sys_cpu_interconnect_index

  set i_str "M$sys_cpu_interconnect_index"
  if {$sys_cpu_interconnect_index < 10} {
    set i_str "M0$sys_cpu_interconnect_index"
  }

  if {$sys_cpu_interconnect_index == 0} {
    ad_ip_instance axi_interconnect axi_cpu_interconnect
    if {$sys_zynq == 2} {
      ad_connect sys_cpu_clk sys_ps8/maxihpm0_lpd_aclk
      ad_connect sys_cpu_clk axi_cpu_interconnect/ACLK
      ad_connect sys_cpu_clk axi_cpu_interconnect/S00_ACLK
      ad_connect sys_cpu_resetn axi_cpu_interconnect/ARESETN
      ad_connect sys_cpu_resetn axi_cpu_interconnect/S00_ARESETN
      ad_connect axi_cpu_interconnect/S00_AXI sys_ps8/M_AXI_HPM0_LPD
    }
    if {$sys_zynq == 1} {
      ad_connect sys_cpu_clk sys_ps7/M_AXI_GP0_ACLK
      ad_connect sys_cpu_clk axi_cpu_interconnect/ACLK
      ad_connect sys_cpu_clk axi_cpu_interconnect/S00_ACLK
      ad_connect sys_cpu_resetn axi_cpu_interconnect/ARESETN
      ad_connect sys_cpu_resetn axi_cpu_interconnect/S00_ARESETN
      ad_connect axi_cpu_interconnect/S00_AXI sys_ps7/M_AXI_GP0
    }
    if {$sys_zynq == 0} {
      ad_connect sys_cpu_clk axi_cpu_interconnect/ACLK
      ad_connect sys_cpu_clk axi_cpu_interconnect/S00_ACLK
      ad_connect sys_cpu_resetn axi_cpu_interconnect/ARESETN
      ad_connect sys_cpu_resetn axi_cpu_interconnect/S00_ARESETN
      ad_connect axi_cpu_interconnect/S00_AXI sys_mb/M_AXI_DP
    }
  }

  if {$sys_zynq == 2} {
    set sys_addr_cntrl_space [get_bd_addr_spaces sys_ps8/Data]
  }
  if {$sys_zynq == 1} {
    set sys_addr_cntrl_space [get_bd_addr_spaces sys_ps7/Data]
  }
  if {$sys_zynq == 0} {
    set sys_addr_cntrl_space [get_bd_addr_spaces sys_mb/Data]
  }

  set sys_cpu_interconnect_index [expr $sys_cpu_interconnect_index + 1]


  set p_cell [get_bd_cells $p_name]
  set p_intf [get_bd_intf_pins -filter "MODE == Slave && VLNV == xilinx.com:interface:aximm_rtl:1.0"\
    -of_objects $p_cell]

  set p_hier_cell $p_cell
  set p_hier_intf $p_intf

  while {$p_hier_intf != "" && [get_property TYPE $p_hier_cell] == "hier"} {
    set p_hier_intf [find_bd_objs -boundary_type lower \
      -relation connected_to $p_hier_intf]
    if {$p_hier_intf != {}} {
      set p_hier_cell [get_bd_cells -of_objects $p_hier_intf]
    } else {
      set p_hier_cell {}
    }
  }

  set p_intf_clock ""
  set p_intf_reset ""

  if {$p_hier_cell != {}} {
    set p_intf_name [lrange [split $p_hier_intf "/"] end end]

    set p_intf_clock [get_bd_pins -filter "TYPE == clk && \
      (CONFIG.ASSOCIATED_BUSIF == ${p_intf_name} || \
      CONFIG.ASSOCIATED_BUSIF =~ ${p_intf_name}:* || \
      CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name} || \
      CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name}:*)" \
      -quiet -of_objects $p_hier_cell]
    set p_intf_reset [get_bd_pins -filter "TYPE == rst && \
      (CONFIG.ASSOCIATED_BUSIF == ${p_intf_name} || \
       CONFIG.ASSOCIATED_BUSIF =~ ${p_intf_name}:* ||
       CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name} || \
       CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name}:*)" \
       -quiet -of_objects $p_hier_cell]

    if {($p_intf_clock ne "") && ($p_intf_reset eq "")} {
      set p_intf_reset [get_property CONFIG.ASSOCIATED_RESET [get_bd_pins ${p_intf_clock}]]
      if {$p_intf_reset ne ""} {
        set p_intf_reset [get_bd_pins -filter "NAME == $p_intf_reset" -of_objects $p_hier_cell]
      }
    }

    # Trace back up
    set p_hier_cell2 $p_hier_cell

    while {$p_intf_clock != {} && $p_hier_cell2 != $p_cell && $p_hier_cell2 != {}} {
      puts $p_intf_clock
      puts $p_hier_cell2
      set p_intf_clock [find_bd_objs -boundary_type upper \
        -relation connected_to $p_intf_clock]
      if {$p_intf_clock != {}} {
        set p_intf_clock [get_bd_pins [get_property PATH $p_intf_clock]]
        set p_hier_cell2 [get_bd_cells -of_objects $p_intf_clock]
      }
    }

    set p_hier_cell2 $p_hier_cell

    while {$p_intf_reset != {} && $p_hier_cell2 != $p_cell && $p_hier_cell2 != {}} {
      set p_intf_reset [find_bd_objs -boundary_type upper \
        -relation connected_to $p_intf_reset]
      if {$p_intf_reset != {}} {
        set p_intf_reset [get_bd_pins [get_property PATH $p_intf_reset]]
        set p_hier_cell2 [get_bd_cells -of_objects $p_intf_reset]
      }
    }
  }


  if {[find_bd_objs -quiet -relation connected_to $p_intf_clock] ne ""} {
    set p_intf_clock ""
  }
  if {$p_intf_reset ne ""} {
    if {[find_bd_objs -quiet -relation connected_to $p_intf_reset] ne ""} {
      set p_intf_reset ""
    }
  }

  set_property CONFIG.NUM_MI $sys_cpu_interconnect_index [get_bd_cells axi_cpu_interconnect]

  ad_connect sys_cpu_clk axi_cpu_interconnect/${i_str}_ACLK
  if {$p_intf_clock ne ""} {
    ad_connect sys_cpu_clk ${p_intf_clock}
  }
  ad_connect sys_cpu_resetn axi_cpu_interconnect/${i_str}_ARESETN
  if {$p_intf_reset ne ""} {
    ad_connect sys_cpu_resetn ${p_intf_reset}
  }
  ad_connect axi_cpu_interconnect/${i_str}_AXI ${p_intf}

  set p_seg [get_bd_addr_segs -of_objects $p_hier_cell]
  set p_index 0
  foreach p_seg_name $p_seg {
    if {$p_index == 0} {
      set p_seg_range [get_property range $p_seg_name]
      if {$p_seg_range < 0x1000} {
        set p_seg_range 0x1000
      }
      if {$sys_zynq == 2} {
        if {($p_address >= 0x40000000) && ($p_address <= 0x4fffffff)} {
          set p_address [expr ($p_address + 0x40000000)]
        }
        if {($p_address >= 0x70000000) && ($p_address <= 0x7fffffff)} {
          set p_address [expr ($p_address + 0x20000000)]
        }
      }
      create_bd_addr_seg -range $p_seg_range \
        -offset $p_address $sys_addr_cntrl_space \
        $p_seg_name "SEG_data_${p_name}"
    } else {
      assign_bd_address $p_seg_name
    }
    incr p_index
  }
}

###################################################################################################
###################################################################################################

proc ad_cpu_interrupt {p_ps_index p_mb_index p_name} {

  global sys_zynq

  if {$sys_zynq == 0} {set p_index_int $p_mb_index}
  if {$sys_zynq >= 1} {set p_index_int $p_ps_index}

  set p_index [regsub -all {[^0-9]} $p_index_int ""]
  set m_index [expr ($p_index - 8)]

  if {($sys_zynq == 2) && ($p_index <= 7)} {
    set p_net [get_bd_nets -of_objects [get_bd_pins sys_concat_intc_0/In$p_index]]
    set p_pin [find_bd_objs -relation connected_to [get_bd_pins sys_concat_intc_0/In$p_index]]

    puts "delete_bd_objs $p_net $p_pin"
    delete_bd_objs $p_net $p_pin
    ad_connect sys_concat_intc_0/In$p_index $p_name
  }

  if {($sys_zynq == 2) && ($p_index >= 8)} {
    set p_net [get_bd_nets -of_objects [get_bd_pins sys_concat_intc_1/In$m_index]]
    set p_pin [find_bd_objs -relation connected_to [get_bd_pins sys_concat_intc_1/In$m_index]]

    puts "delete_bd_objs $p_net $p_pin"
    delete_bd_objs $p_net $p_pin
    ad_connect sys_concat_intc_1/In$m_index $p_name
  }

  if {$sys_zynq <= 1} {

    set p_net [get_bd_nets -of_objects [get_bd_pins sys_concat_intc/In$p_index]]
    set p_pin [find_bd_objs -relation connected_to [get_bd_pins sys_concat_intc/In$p_index]]

    puts "delete_bd_objs $p_net $p_pin"
    delete_bd_objs $p_net $p_pin
    ad_connect sys_concat_intc/In$p_index $p_name
  }
}

###################################################################################################
###################################################################################################

