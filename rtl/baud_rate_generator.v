module baud_rate_generator(
	input pclk,preset_n,
	input [1:0] spi_mode_i,
	input spiswai_i,
	input [2:0]sppr_i,
	input [2:0] spr_i,
	input cpol_i,cpha_i,ss_i,
	output reg sclk_o,
	output [11:0]BaudRateDivisor_o,
	output reg miso_receive_sclk_o,
	output reg miso_receive_sclk0_o,
	output reg mosi_send_sclk_o,
	output reg mosi_send_sclk0_o);
reg [11:0] count_s;
wire pre_sclk;
//reg s_clk;

//baud rate divisor calculation using formula
assign BaudRateDivisor_o= (sppr_i+1)*  (2**  (spr_i+1));
assign pre_sclk=(cpol_i)? 1'b1 : 1'b0;

always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		sclk_o<=pre_sclk;
		count_s<=12'h0;
	end
	else if(!ss_i && (spi_mode_i ==2'b00 || spi_mode_i==2'b01) && !spiswai_i)
		begin
			if(count_s==((BaudRateDivisor_o/2)-1))
			begin
				sclk_o <= ~sclk_o;
				count_s <= 12'h0;
			end
			else if(count_s < ((BaudRateDivisor_o/2)-1))
			begin
				sclk_o <= sclk_o;
				count_s <= count_s+1'b1;
			end
			else
				count_s <= 12'h00;
		end
	 else
		begin
			sclk_o <= pre_sclk;
			count_s <= 12'h00;
		end
end

//receiver flags
//miso_receiver_sclk_0, miso_recevier_sclk0_o
always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		miso_receive_sclk_o<=1'b0;
		miso_receive_sclk0_o<=1'b0;
	end
	else
	begin
		if((!cpha_i&& cpol_i)||(cpha_i&&!cpol_i))//cpol!=cpha-> falling edge means negative edge 1-0
		begin
			if(sclk_o && (count_s==(BaudRateDivisor_o/2)-1))//negedge
			begin
				miso_receive_sclk_o<=1'b1;//negedge
			end
			else
				miso_receive_sclk_o<=1'b0;
		end
			
		else if((!cpha_i && !cpol_i)||(cpha_i &&cpol_i))//cpha==cpol->raising edge means posedge edge 0-1
		begin
			if(!sclk_o &&(count_s==(BaudRateDivisor_o/2)-1))//posedge
			begin
				miso_receive_sclk0_o<=1'b1;//posedge
			end
			else 
				miso_receive_sclk0_o<=1'b0;
		end
		else
	       	begin
			miso_receive_sclk0_o<=1'b0;
			miso_receive_sclk_o<=1'b0;
		end

	end
end
//send flags 
//miso_send_sclk_o,miso_send_sclk0_o,
always@(posedge pclk or negedge preset_n)begin
	if(!preset_n)
	begin
		mosi_send_sclk_o<=1'b0;
		mosi_send_sclk0_o<=1'b0;
	end
	else
	begin
		if((!cpha_i&& cpol_i)||(cpha_i&&!cpol_i))//cpol!=cpha-> falling edge eans negetive edge 1-0
		begin
			if(sclk_o && (count_s==(BaudRateDivisor_o/2)-2))//error when baudrateivisor is 2.
				//sclk is negedge
			begin
				mosi_send_sclk_o<=1'b1;//negedge
			end
			else
				mosi_send_sclk_o<=1'b0;
		end
		
		else if((!cpha_i && !cpol_i)||(cpha_i &&cpol_i))//cpha==cpol->raising edge means positive edge 0-1
		begin
			if(!sclk_o &&(count_s==(BaudRateDivisor_o/2)-2))//sclk is posedge
			begin
				mosi_send_sclk0_o<=1'b1;//posedge
			end
			else 
				mosi_send_sclk0_o<=1'b0;
		end
		else begin
			mosi_send_sclk0_o<=1'b0;
			mosi_send_sclk_o<=1'b0;
		end
	end
end
endmodule
