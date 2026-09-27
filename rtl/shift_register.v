module shift_register(input pclk,
		      input preset_n,
                      input ss_i,
		      input send_data_i,
		      input lsbfe_i,
		      input cpha_i,
		      input cpol_i,
		      input miso_receive_sclk_i,
		      input miso_receive_sclk0_i,
		      input mosi_send_sclk_i,
		      input mosi_send_sclk0_i,
		      input [7:0]data_mosi,
		      input miso_i,
		      input receive_data_i,
		      output reg mosi_o,
		      output reg [7:0]data_miso_o);
reg [7:0]shift_register;
reg [7:0]temp_register;
reg [2:0]count,count1;//mosi 
reg [2:0]count2,count3;//miso

//shift register load
always@(posedge pclk,negedge preset_n)
begin
	if(!preset_n)  
	begin
		shift_register<=1'b0;
	end
	else if(send_data_i)
		shift_register<=data_mosi; //getting from apb master i.e data_mosi
	else
		shift_register<=shift_register;
end

always@(posedge pclk,negedge preset_n)
begin
	if(!preset_n)
		data_miso_o<=8'b0;
	else if(receive_data_i)
	begin
		data_miso_o<=temp_register;
	end
	else
		data_miso_o<=data_miso_o;
end

//MOSI (getting out from spi throgh mosi_o)

//count is for LSB transfer
//count1 is fir MSB transfer

//means the data is getting out bit by bit from the shift_register(8 bit ) i.e temporary register in shift register block
//
//mosi_send flags are used hence we are sending the data

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)begin
		mosi_o<=1'b0;
		count<=3'b0;
		count1<=3'b111;
	end
	else
	begin
		if(!ss_i)
		begin 
			if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))//negedge 
			begin
				if(lsbfe_i)//0 to 7
				begin
					if(count<=3'b111)
					begin
						if(mosi_send_sclk_i)
						begin
							mosi_o<=shift_register[count];
							count<=count+1;
						end
					end
					else
					begin
						count<=3'b000;
					end
				end
				else//7 to 0
				begin
					if(count1>=0)
					begin
						if(mosi_send_sclk_i)
						begin
							mosi_o<=shift_register[count1];
							count1<=count1-1'b1;
						end
					end
					else
						count1<=3'b111;
				end
			end
			else //posedge
			begin
				if(lsbfe_i)//0 to 7
				begin
					if(count<=3'b111)
					begin
						if(mosi_send_sclk0_i)
						begin
							mosi_o<=shift_register[count];
							count<=count+1'b1;
						end
					end
					else
						count<=3'b0;
				end
				else //7 to 0
				begin
					if(count1>=3'b0)
					begin
						if(mosi_send_sclk0_i)
						begin
							mosi_o<=shift_register[count1];
							count1<=count1-1;
						end
					end
					else
					begin
						count1<=3'b111;
					end
				end
			end
		end
		else
		begin
			mosi_o<=8'b0;
			count1<=3'b111;
			count<=3'b000;
		end
	end
end



//miso
//we are getting bit by bit values from the miso_data
//so the bit by bit is stored in 8 bit temporaray register ,when the rception is complete by 8 bit(data_receive signal is 1) ,at a time the 8 bit value from temp_register is given to data_miso_o

//count2 is for LSB
//count3 is for MSB

always@(posedge pclk,negedge preset_n)begin
	if(!preset_n)begin
		temp_register<=8'b0;
		count2<=3'b0;
		count3<=3'b111;
		end
	else
	begin
		if(!ss_i)
		begin 
			if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))//negedge 
			begin
				if(lsbfe_i)//0 to 7
				begin
					if(count2<=3'b111)
					begin
						if(miso_receive_sclk_i)
						begin
							temp_register[count2]<=miso_i;
							count2<=count2+1'b1;
						end
					end
					else
					begin
						count2<=3'b0;
					end
				end
				else//7 to 0
				begin
					if(count3>=0)
					begin
						if(miso_receive_sclk_i)
						begin
							temp_register[count3]<=miso_i;
							count3<=count3-1;
						end
					end
					else
						count3<=3'b111;
				end
			end
			else //posedge
			begin
				if(lsbfe_i)//0 to 7
				begin
					if(count2<=3'b111)
					begin
						if(miso_receive_sclk0_i)
						begin
							temp_register[count2]<=miso_i;
							count2<=count2+1'b1;
						end
					end
					else
						count2<=3'b0;
				end
				else //7 to 0
				begin
					if(count3>=3'b0)
					begin
						if(miso_receive_sclk0_i)
						begin
							temp_register[count3]<=miso_i;
							count3<=count3-1;
						end
					end
					else
					begin
						count3<=3'b111;
					end
				end
			end
		end
		else
		begin
			//temp_register<=8'b0;
			count3<=3'b111;
			count2<=3'b000;
		end
	end
end

endmodule
