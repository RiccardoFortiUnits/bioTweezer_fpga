	i2c_alt_contr u0 (
		.i2c_0_csr_address          (<connected-to-i2c_0_csr_address>),          //              i2c_0_csr.address
		.i2c_0_csr_read             (<connected-to-i2c_0_csr_read>),             //                       .read
		.i2c_0_csr_write            (<connected-to-i2c_0_csr_write>),            //                       .write
		.i2c_0_csr_writedata        (<connected-to-i2c_0_csr_writedata>),        //                       .writedata
		.i2c_0_csr_readdata         (<connected-to-i2c_0_csr_readdata>),         //                       .readdata
		.i2c_0_i2c_serial_sda_in    (<connected-to-i2c_0_i2c_serial_sda_in>),    //       i2c_0_i2c_serial.sda_in
		.i2c_0_i2c_serial_scl_in    (<connected-to-i2c_0_i2c_serial_scl_in>),    //                       .scl_in
		.i2c_0_i2c_serial_sda_oe    (<connected-to-i2c_0_i2c_serial_sda_oe>),    //                       .sda_oe
		.i2c_0_i2c_serial_scl_oe    (<connected-to-i2c_0_i2c_serial_scl_oe>),    //                       .scl_oe
		.i2c_0_interrupt_sender_irq (<connected-to-i2c_0_interrupt_sender_irq>), // i2c_0_interrupt_sender.irq
		.clk_clk                    (<connected-to-clk_clk>),                    //                    clk.clk
		.reset_reset_n              (<connected-to-reset_reset_n>)               //                  reset.reset_n
	);

