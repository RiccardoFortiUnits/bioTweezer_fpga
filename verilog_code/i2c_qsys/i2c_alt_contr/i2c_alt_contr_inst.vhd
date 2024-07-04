	component i2c_alt_contr is
		port (
			i2c_0_csr_address          : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- address
			i2c_0_csr_read             : in  std_logic                     := 'X';             -- read
			i2c_0_csr_write            : in  std_logic                     := 'X';             -- write
			i2c_0_csr_writedata        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			i2c_0_csr_readdata         : out std_logic_vector(31 downto 0);                    -- readdata
			i2c_0_i2c_serial_sda_in    : in  std_logic                     := 'X';             -- sda_in
			i2c_0_i2c_serial_scl_in    : in  std_logic                     := 'X';             -- scl_in
			i2c_0_i2c_serial_sda_oe    : out std_logic;                                        -- sda_oe
			i2c_0_i2c_serial_scl_oe    : out std_logic;                                        -- scl_oe
			i2c_0_interrupt_sender_irq : out std_logic;                                        -- irq
			clk_clk                    : in  std_logic                     := 'X';             -- clk
			reset_reset_n              : in  std_logic                     := 'X'              -- reset_n
		);
	end component i2c_alt_contr;

	u0 : component i2c_alt_contr
		port map (
			i2c_0_csr_address          => CONNECTED_TO_i2c_0_csr_address,          --              i2c_0_csr.address
			i2c_0_csr_read             => CONNECTED_TO_i2c_0_csr_read,             --                       .read
			i2c_0_csr_write            => CONNECTED_TO_i2c_0_csr_write,            --                       .write
			i2c_0_csr_writedata        => CONNECTED_TO_i2c_0_csr_writedata,        --                       .writedata
			i2c_0_csr_readdata         => CONNECTED_TO_i2c_0_csr_readdata,         --                       .readdata
			i2c_0_i2c_serial_sda_in    => CONNECTED_TO_i2c_0_i2c_serial_sda_in,    --       i2c_0_i2c_serial.sda_in
			i2c_0_i2c_serial_scl_in    => CONNECTED_TO_i2c_0_i2c_serial_scl_in,    --                       .scl_in
			i2c_0_i2c_serial_sda_oe    => CONNECTED_TO_i2c_0_i2c_serial_sda_oe,    --                       .sda_oe
			i2c_0_i2c_serial_scl_oe    => CONNECTED_TO_i2c_0_i2c_serial_scl_oe,    --                       .scl_oe
			i2c_0_interrupt_sender_irq => CONNECTED_TO_i2c_0_interrupt_sender_irq, -- i2c_0_interrupt_sender.irq
			clk_clk                    => CONNECTED_TO_clk_clk,                    --                    clk.clk
			reset_reset_n              => CONNECTED_TO_reset_reset_n               --                  reset.reset_n
		);

