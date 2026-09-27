module apb_slave_interface(input pclk,
			   input preset_n,
			   input [2:0]PADDR_i,
			   input PWRITE_i,
			   input PSEL_i,
			   input PEnable_i,
			   input [7:0]PWDATA_i,
			   input ss_i,
			   input [7:0]miso_data_i,
			   input receive_data_i,
			   input tip_i,
			   output reg [7:0]PRDATA_o,
			   output mstr_o,
			   output cpol_o,
			   output cpha_o,
			   output lsbfe_o,
			   output spiswai_o,
			   output [2:0]sppr_o,
			   output [2:0]spr_o,
			   output reg spi_intrupt_req_o,
			   output PReady_o,
			   output PSLVERR_o,
			   output reg send_data_o,
			   output reg [7:0]mosi_data_o,
			   output [1:0]spi_mode_o);
//apb states
reg [1:0]pre_state_a,next_state_a;
//spi states
reg [1:0]pre_state_s,next_state_s;
//registers
reg [7:0] SPI_cr1,SPI_cr2,SPI_br,SPI_sr,SPI_dr;
//flags
wire spe,sptef,sptie,modf,modfen,ssoe,spif;
wire wr_enb,r_enb;

parameter cr2_mask=8'b00011011;
parameter br_mask=8'b01110111;

//parameters for apb slave states and spi modes

parameter IDLE=2'b00,SETUP=2'b01,ENABLE=2'b10;
parameter RUN=2'b00,WAIT=2'b01,STOP=2'b10;

//reg values

assign mstr_o=SPI_cr1[4];
assign cpol_o=SPI_cr1[3];
assign cpha_o=SPI_cr1[2];
assign lsbfe_o=SPI_cr1[0];
assign spie=SPI_cr1[7];
assign spe=SPI_cr1[6];
assign sptie=SPI_cr1[5];
assign modfen=SPI_cr1[4];
assign spiswai_o=SPI_cr1[1];
assign sppr_o=SPI_br[6:4];
assign spr_o=SPI_br[2:0];
assign ssoe=SPI_cr1[1];

// rd_enable

assign r_enb=(!PWRITE_i &(pre_state_a==ENABLE))? 1'b1 : 1'b0;

//wr_enb

assign wr_enb=(PWRITE_i & (pre_state_a==ENABLE))? 1'b1 :1'b0;

//pslver

assign PSLVERR_o=(pre_state_a==ENABLE)? (~tip_i) : 1'b0;

//pready

assign PReady_o=(pre_state_a==ENABLE) ? 1'b1 :1'b0;

//sptef
assign sptef= (SPI_dr==8'b00000000)? 1'b1 : 1'b0;

//spif
assign spif= (SPI_dr !=8'b00000000)? 1'b1:1'b0;

//spi_mode
assign spi_mode_o=pre_state_s;


//status register
always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
		SPI_sr<=8'b00100000;
	else
		SPI_sr<={spif,1'b0,sptef,modf,4'b0};
end


//modf
assign modf=(!ss_i)&(mstr_o)&(modfen)&(!ssoe)? 1'b1 : 1'b0 ;//reduction and operation

//SPI_CR1
//

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)begin
		SPI_cr1<=8'b0000_0100;
	end
	else begin
		if(wr_enb)
		begin
			if(PADDR_i==3'b000)
			begin
				SPI_cr1<=PWDATA_i;
			end
			else
			begin
				SPI_cr1<=SPI_cr1;
			end
		end
		else
			SPI_cr1<=SPI_cr1;
	end
end

//SPI CR2

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		SPI_cr2<=8'b0000_0000;
	end
	else
	begin 
		if(wr_enb)
		begin
			if(PADDR_i==3'b001)
			begin
				SPI_cr2<=(PWDATA_i & cr2_mask);
			end
			else
				SPI_cr2<=SPI_cr2;
		end
		else
			SPI_cr2<=SPI_cr2;//doubt in microarch 8'h04
	end
end

//SPI BAUD RATE REGISTER

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
		SPI_br<=8'b0000_0000;
	else
	begin
		if(wr_enb)
		begin
			if(PADDR_i==3'b010)
			begin
				SPI_br<=(PWDATA_i & br_mask);
			end
			else
				SPI_br<=SPI_br;
		end
		else
			SPI_br<=SPI_br;
	end
end

//SPI DATA REGISTER

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
		SPI_dr<=8'b0000_0000;
	else
	begin
		if(wr_enb)
		begin
			if(PADDR_i==3'b101)
			begin
				SPI_dr<=PWDATA_i;
			end
			else
			begin
				SPI_dr<=SPI_dr;
			end
		end
		else
		begin
			if((SPI_dr==PWDATA_i)&&(SPI_dr!=miso_data_i)&&((spi_mode_o==2'b00)||(spi_mode_o==2'b01)))
			begin
				SPI_dr<=8'b0000_0000;
			end
			else
			begin 
				if((spi_mode_o==RUN)||(spi_mode_o==WAIT) && receive_data_i)
				begin
					SPI_dr<=miso_data_i;
				end
				else
				begin
					SPI_dr<=SPI_dr;
				end
			end
		end
	end
end


//apb states FSM 
always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		pre_state_a<=IDLE;
	end
	else
	begin
		pre_state_a <=next_state_a;
	end
end

always@(*)begin
	next_state_a=IDLE;
	case(pre_state_a)
		IDLE: begin
			if(PSEL_i && !PEnable_i)
			begin
				next_state_a=SETUP;
			end
			else
			begin
				next_state_a=IDLE;
			end
		end
		SETUP:begin
			if(!PSEL_i)
				next_state_a=IDLE;
			else if(PSEL_i && PEnable_i)
				next_state_a=ENABLE;
			else  //if(PSEL_i && !PEnable_i)
				next_state_a=SETUP;
		end
		ENABLE:begin
			if(!PSEL_i)
			begin
				next_state_a=IDLE;
			end
			else if(PSEL_i&& !PEnable_i)
				next_state_a=SETUP;
			else
				next_state_a=ENABLE;
		end
	endcase
end

//spi modes fsm

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		pre_state_s<=RUN;
	end
	else
		pre_state_s<=next_state_s;
end

always@(*)begin
	next_state_s=RUN;
	case(pre_state_s)
		RUN:begin
			if(!spe)
			begin
				next_state_s=WAIT;
			end
			else
				next_state_s= RUN;
		end
		WAIT:begin
			if(spiswai_o)
				next_state_s=STOP;
			else if(spe)
				next_state_s=RUN;
			else
				next_state_s=WAIT;
		end
		STOP:begin
			if(!spiswai_o)
				next_state_s=WAIT;
			else if(spe)
				next_state_s=RUN;
			else
				next_state_s=STOP;
		end
	endcase
end

//pr data
//

always@(*)begin
	if(!r_enb)
		PRDATA_o=8'b0000_0000;
	else
	begin
		case(PADDR_i)
			3'b000: PRDATA_o=SPI_cr1;
			3'b001: PRDATA_o=(SPI_cr2);
			3'b010: PRDATA_o=(SPI_br);
			3'b011: PRDATA_o=SPI_sr;
			3'b101: PRDATA_o=SPI_dr;
			default:PRDATA_o=8'b0000_0000;
		endcase
	end
end

//SPI_INTRUPT REQUEST
//
always@(*)begin
	if(!spie && !sptie)
		spi_intrupt_req_o<=1'b0;
	else
	begin
		if(!sptie && spie)
			spi_intrupt_req_o<=(spif || modf);
		else
		begin
			if(!spie && sptie)
				spi_intrupt_req_o<=sptef;
			else
				spi_intrupt_req_o<=(spif || modf || sptef);
		end
	end
end

//mosi_data

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
		mosi_data_o<=8'b0000_0000;
	else if(!wr_enb)//not in micro
	begin
		if((SPI_dr==PWDATA_i)&&(SPI_dr!=miso_data_i) &&((spi_mode_o==RUN)||(spi_mode_o==WAIT)))
			mosi_data_o<=SPI_dr;
		else
			mosi_data_o<=mosi_data_o;
	end
	else
			mosi_data_o<=mosi_data_o;//need to check
end

//send data
//doubt 

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
		send_data_o<=1'b0;
	else
	begin
		if(!wr_enb)
		begin
			if((SPI_dr==PWDATA_i)&&(SPI_dr!=miso_data_i) &&((spi_mode_o==RUN)||(spi_mode_o==WAIT)))
				send_data_o<=1'b1;
			else
				send_data_o<=1'b0;
		end
		else
			send_data_o<=1'b0;
	end
end

endmodule