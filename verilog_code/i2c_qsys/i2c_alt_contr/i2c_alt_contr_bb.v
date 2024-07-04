
module i2c_alt_contr (
	i2c_0_csr_address,
	i2c_0_csr_read,
	i2c_0_csr_write,
	i2c_0_csr_writedata,
	i2c_0_csr_readdata,
	i2c_0_i2c_serial_sda_in,
	i2c_0_i2c_serial_scl_in,
	i2c_0_i2c_serial_sda_oe,
	i2c_0_i2c_serial_scl_oe,
	i2c_0_interrupt_sender_irq,
	clk_clk,
	reset_reset_n);	

	input	[3:0]	i2c_0_csr_address;
	input		i2c_0_csr_read;
	input		i2c_0_csr_write;
	input	[31:0]	i2c_0_csr_writedata;
	output	[31:0]	i2c_0_csr_readdata;
	input		i2c_0_i2c_serial_sda_in;
	input		i2c_0_i2c_serial_scl_in;
	output		i2c_0_i2c_serial_sda_oe;
	output		i2c_0_i2c_serial_scl_oe;
	output		i2c_0_interrupt_sender_irq;
	input		clk_clk;
	input		reset_reset_n;
endmodule
