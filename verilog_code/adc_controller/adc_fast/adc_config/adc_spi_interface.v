module ADC_spi_interface(

		input 				clock_50, // 50 MHz clock input
		input 				reset,

		input [12:0] 		address,
		input 				rw,
		input [1:0]			width,
		input [7:0]			data_write,
		input 				start,
		output reg 			busy,
		output reg [7:0]	data_read,
		output reg 			data_valid,
			
		//ADC SPI
		output reg 			cs_n,
		output 				sclk,
		inout 				data_adc //

);

assign sclk = clock_5;
reg clock_5 = 1'b0;
reg [3:0] bit_counter = 4'd0;	//conta fino a 10 (genera l'SCLK)
reg [7:0] main_counter = 8'd0;	//tiene conto dei bit da scambiare con l'ADC
reg sclk_and_counter_enable = 1'b0;

localparam	bit_length = 10,
 			half_bit = 5;

//contatori
always @(posedge clock_50)
begin
	if(reset) begin
		main_counter <= 8'd0;
		bit_counter <= 4'd0;
	end
	else begin
		if(sclk_and_counter_enable) begin
			busy <= 1'b1;
			if(bit_counter == (bit_length - 1)) begin
				bit_counter <= 4'd0;
				main_counter <= main_counter + 8'd1;
			end
			else begin
				bit_counter <= bit_counter + 4'd1;
			end
		end
		else begin
			busy <= 1'b0;
			main_counter <= 8'd0;
			bit_counter <= 4'd0;
		end
	end
end

//sclk
always @(posedge clock_50)
begin
	if(sclk_and_counter_enable) begin
		if(bit_counter == (half_bit - 1) | bit_counter == (bit_length - 1))
		begin
			clock_5 <= !clock_5;
		end
	end
	else begin
		clock_5 <= 1'b0;
	end	
end

//FSM
localparam 	IDLE = 0,
			START = 1,
			SEND_ADD = 2,
			WRITE_DATA = 3,
			WAIT_SEND_ADD = 4,
			READ_DATA = 5;

reg [2:0] STATE;

reg write = 1'b0;
reg data_tx = 1'b0;
assign data_adc = (write) ?	data_tx	: 1'bZ;

wire [15:0] data = {rw,width,address};

always @(posedge clock_50) begin
	if (reset) begin
		cs_n <= 1'b1;
		write <= 1'b0;
		sclk_and_counter_enable <= 1'b0;
		STATE <= IDLE;
	end
	else begin
		case (STATE)

			IDLE: begin
				data_valid <= 1'b0;
				write <= 1'b1;
				sclk_and_counter_enable <= 1'b0;
				cs_n <= 1'b1;
				if (start) begin
					sclk_and_counter_enable <= 1'b1;
					STATE <= START;
				end
			end

			START: begin
				cs_n <= 1'b0;
				write <= 1'b1;
				STATE <= SEND_ADD;
			end

			SEND_ADD: begin
				if(bit_counter == half_bit - 3)	begin
					data_tx <= data[8'd15 - main_counter];
					if(main_counter == 8'd15) begin
						if(rw) begin
							STATE <= WAIT_SEND_ADD;
						end
						else begin
							STATE <= WRITE_DATA;
						end
					end
				end
			end

			WRITE_DATA: begin
				if(main_counter == 8'd24) begin
					data_valid <= 1'b1;
					cs_n <= 1'b1;
					STATE <= IDLE;
				end
				else if(bit_counter == half_bit - 3) begin
					data_tx <= data_write[8'd23 - main_counter];
				end
			end

			WAIT_SEND_ADD: begin
				//ci si assicura di avere scritto l'ultimo bit di scrittura
				if(bit_counter == half_bit + 2) begin
					write <= 1'b0;
					STATE <= READ_DATA;
				end
			end

			READ_DATA: begin
				//cambio di sclk (fronte di discesa) in corrispondenza di bit_length-1 si campiona il valore in ingresso allo stesso momento del fronte di discesa
				if(bit_counter == bit_length - 1) begin
					data_read[23-main_counter] <= data_adc;
					if(main_counter == 8'd23) begin
						STATE <= IDLE;
						data_valid <= 1'b1;
					end
				end
			end

		endcase
	end
end

endmodule
