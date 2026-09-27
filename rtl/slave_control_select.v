module slave_control_select(input pclk,
			    input preset_n,
			    input mstr_i,
			    input spiswai_i,
			    input [1:0]spi_mode_i,
			    input send_data_i,
			    input [11:0]BaudRateDivisor_i,
			    output reg receive_data_o,
			    output reg ss_o,
			    output tip_o);
reg [15:0]count_s;
wire [15:0]target_s;
reg rcv_s;

assign target_s=BaudRateDivisor_i *8;
assign tip_o=~ss_o;

always@(posedge pclk , negedge preset_n)
begin
	if(!preset_n)
	begin
		//count_s<=16'hffff;
		ss_o<=1;
	end
	else
	begin	
		if((spi_mode_i ==2'b00 ||( spi_mode_i==2'b01 && !spiswai_i)) && mstr_i)

		begin
			if(send_data_i)
			begin
				ss_o<=1'b0;
			end
			else if(count_s<target_s-1)
			begin
				ss_o<=0;
			end
			else
			begin
				ss_o<=1'b1;
			end
		end
		else
		begin
			ss_o<=1'b1;
		end
	end
end

always@(posedge pclk ,negedge preset_n)
begin
	if(!preset_n)
	begin
		count_s<=16'hffff;
	end
	else
	begin
		if((spi_mode_i ==2'b00 ||( spi_mode_i==2'b01 && !spiswai_i)) && mstr_i)
		begin
			if(send_data_i)
			begin
				count_s<=1'b0;
			end
			else if(count_s<target_s-1)
			begin
				count_s<=count_s+1;
			end
			else
			begin
				count_s<=16'hffff;
			end
		end
		else
		begin
			count_s<=16'hffff; 
		end
	end
end

always@(posedge pclk,negedge preset_n)
begin
	if(!preset_n)
	begin
		rcv_s<=1'b0;
	end
	else if((spi_mode_i ==2'b00 ||( spi_mode_i==2'b01 && !spiswai_i)) && mstr_i)
		if(count_s==target_s-1)
		begin
			rcv_s<=1'b1;
		end
		else
		begin
			rcv_s<=1'b0;
		end

	else
	begin
		rcv_s<=1'b0;
	end
end

always@(posedge pclk,negedge preset_n)
begin
	if(!preset_n)
	begin
		receive_data_o<=1'b0;
	end
	else
		receive_data_o<=rcv_s;
end
endmodule
