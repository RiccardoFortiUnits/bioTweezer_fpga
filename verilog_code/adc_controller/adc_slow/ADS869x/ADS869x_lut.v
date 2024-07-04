module ADS869x_lut ( 
    input [4:0] 		index,

	output reg [6:0]	command,
	output reg [8:0] 	address,
	output reg [15:0]	data,

    output reg          last_index = 1'b0
);


localparam 	DEVICE_ID_REG_LS 	= 9'h000, 		
            DEVICE_ID_REG_MS    = 9'h002, 		
			RST_PWRCTL_REG_LS 	= 9'h004, 		
            RST_PWRCTL_REG_MS   = 9'h006, 		
			SDI_CTL_REG_LS 	    = 9'h008, 		
            SDI_CTL_REG_MS      = 9'h00A, 		
			SDO_CTL_REG_LS  	= 9'h00C, 		
            SDO_CTL_REG_MS      = 9'h00E, 		
			DATAOUT_CTL_REG_LS  = 9'h010, 		
            DATAOUT_CTL_REG_MS  = 9'h012, 		
			RANGE_SEL_REG_LS 	= 9'h014, 		
            RANGE_SEL_REG_MS    = 9'h016, 		
			ALARM_REG_LS 	    = 9'h020, 		
            ALARM_REG_MS        = 9'h022, 		
			ALARM_H_TH_REG_LS 	= 9'h024, 		
            ALARM_H_TH_REG_MS   = 9'h026, 		
			ALARM_L_TH_REG_LS 	= 9'h028, 		
            ALARM_L_TH_REG_MS   = 9'h02A;

localparam  CLEAR_HWORD     = 7'b1100000,
            READ_HWORD      = 7'b1100100,
            READ            = 7'b0100100,
            WRITE           = 7'b1101000,
            WRITE_MS        = 7'b1101001,
            WRITE_LS        = 7'b1101010,
            SET_HWORD       = 7'b1101100;

// FOR RANGE (RANGE_SEL_REG_LS)
localparam  bipolar_x3     = 4'b0000,
            bipolar_x2_5   = 4'b0001,
            bipolar_x1_5   = 4'b0010,
            bipolar_x1_25  = 4'b0011,
            bipolar_x0_625 = 4'b0100,
            unipolar_x3    = 4'b1000,
            unipolar_x2_5  = 4'b1001,
            unipolar_x1_5  = 4'b1010,
            unipolar_x1_25 = 4'b1011;

// FOR TEST PATTERNS (DATAOUT_CTL_REG_LS)
localparam  conv            = 3'b000,
            all0s           = 3'b100,
            all1s           = 3'b101,
            alternate01     = 3'b110,
            alternate0011   = 3'b111;

// asynchronous look-up table

always @(index) 
begin
	case (index)
        //FOR RANGE
		0: begin
            command <= WRITE;
			address <= RANGE_SEL_REG_LS;
			data <= 7'b1000001;   //disable internal reference and uses bipolar_x2_5
			last_index <= 1'b0;
		end
        //FOR TEST PATTERN
		1: begin
            command <= WRITE;
			address <= DATAOUT_CTL_REG_LS;
			//data <= 16'b0111110100001000;
			data <= conv;
            last_index <= 1'b1;
		end

		default: begin
			command <= 7'd0;
			address <= 9'd0;
			data <= 16'd0;
            last_index <= 1'b0;
		end

	endcase
end

endmodule