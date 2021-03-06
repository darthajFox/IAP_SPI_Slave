transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/workspace/IAP_SPI_Slave/spi_slave_fw/hdl {D:/workspace/IAP_SPI_Slave/spi_slave_fw/hdl/spi_xcvr.v}
vlog -vlog01compat -work work +incdir+D:/workspace/IAP_SPI_Slave/spi_slave_fw/hdl {D:/workspace/IAP_SPI_Slave/spi_slave_fw/hdl/programmer.v}
vlog -vlog01compat -work work +incdir+D:/workspace/IAP_SPI_Slave/spi_slave_fw/ip/buffer_fifo {D:/workspace/IAP_SPI_Slave/spi_slave_fw/ip/buffer_fifo/buffer_fifo.v}

vlog -vlog01compat -work work +incdir+D:/workspace/IAP_SPI_Slave/spi_slave_fw/testbench {D:/workspace/IAP_SPI_Slave/spi_slave_fw/testbench/programmer_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  programmer_tb

do D:/workspace/IAP_SPI_Slave/spi_slave_fw/simulation/modelsim/programmer_wave.do
