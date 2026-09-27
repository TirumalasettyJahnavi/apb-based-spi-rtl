module shift_register_tb();
		      reg pclk;
		      reg preset_n;
                      reg ss_i;
		      reg send_data_i;
		      reg lsbfe_i;
		      reg cpha_i;
		      reg cpol_i;
		      reg miso_receive_sclk_o;
		      reg miso_receive_sclk0_o;
		      reg mosi_send_sclk_o;
		      reg mosi_send_sclk0_o;
		      reg [7:0]data_mosi;
		      reg miso_i;
		      reg receive_data_i;
		      wire mosi_o;
		      wire [7:0]data_miso_o;

		     

shift_register dut( pclk,preset_n,ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o,data_mosi,miso_i,receive_data_i, mosi_o,data_miso_o);

//baud_rate_generator
reg [2:0]spr_i,sppr_i;
reg [1:0] spi_mode_i;
reg spiswai_i;
wire [15:0]BaudRateDivisor_o;
reg sclk_o;
reg mstr_i;
reg [11:0] count_s;
wire pre_sclk;

//slave select
reg [15:0]count_s2;
wire [15:0]target_s;
reg rcv_s;
//reg tip_o;

//baud rate generator rtl for flags
//

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
				sclk_o<=~sclk_o;
				count_s<=12'h0;
			end
			else if(count_s<=((BaudRateDivisor_o/2)-1))
		begin
				sclk_o<=sclk_o;
				count_s<=count_s+1'b1;
			end
			else
				count_s<=0;
		end
	 else
		begin
			sclk_o<=pre_sclk;
			count_s<=12'h0;
		end
end

//receiver flags
//miso_receiver_sclk_0, miso_recevier_sclk0_o
always@(posedge pclk)begin
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
always@(posedge pclk)begin
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



//slave select rtl for ss_i and receive data signal
//



assign target_s=BaudRateDivisor_o *8;
//assign tip_o=~ss_i;

always@(posedge pclk , negedge preset_n)
begin
	if(!preset_n)
	begin
		//count_s<=16'hffff;
		ss_i<=1;
	end
	else
	begin	
		if((spi_mode_i ==2'b00 ||( spi_mode_i==2'b01 && !spiswai_i)) && mstr_i)

		begin
			if(send_data_i)
			begin
				ss_i<=1'b0;
			end
			else if(count_s2<target_s)
			begin
				ss_i<=0;
			end
			else
			begin
				ss_i<=1'b1;
			end
		end
		else
		begin
			ss_i<=1'b1;
		end
	end
end

always@(posedge pclk ,negedge preset_n)
begin
	if(!preset_n)
	begin
		count_s2<=16'hffff;
	end
	else
	begin
		if((spi_mode_i ==2'b00 ||( spi_mode_i==2'b01 && !spiswai_i)) && mstr_i)
		begin
			if(send_data_i)
			begin
				count_s2<=1'b0;
			end
			else if(count_s2<target_s)
			begin
				count_s2<=count_s2+1;
			end
			else
			begin
				count_s2<=16'hffff;
			end
		end
		else
		begin
			count_s2<=16'hffff; 
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
		if(count_s2==target_s)
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
		receive_data_i<=1'b0;
	end
	else
		receive_data_i<=rcv_s;
end




//task initializing the inputs 

task initialize ();
	begin
		//preset_n=1'b1;
		//send_data_i=1'b1;
		lsbfe_i=1'b0;
		cpha_i=1'b1;
		cpol_i=1'b1;
		mstr_i=1'b1;
		spiswai_i=1'b0;
		spi_mode_i=2'b00;
		spr_i=1'b1;
		sppr_i=1'b1;
	end
endtask

/*task polarity(input a,input b);
	begin
		cpha_i=a;
		cpol_i=b;
	end
endtask
*/

initial begin
	pclk=1'b0;
	forever #20 pclk=~pclk;
end

task stimuli_mosi(input [7:0]i);
	begin
		data_mosi=i;
	end
endtask

task stimuli_miso(input j);
	begin
		@(negedge pclk);
		miso_i=j;
	end
endtask

task reset();
	begin
		@(negedge pclk)preset_n=1'b0;
		@(negedge pclk)preset_n=1'b1;
	end
endtask

task send();
	begin
		@(negedge pclk)send_data_i=1'b1;
		@(negedge pclk)send_data_i=1'b0;
	end
endtask

//integer k;
initial begin
	initialize();
	reset();
	/*stimuli_mosi(8'b10101011);#100;
	polarity(0,1);
	send();
	stimuli_miso(1);#200;
	stimuli_miso(1);#150;
#300;*/
	stimuli_mosi(8'b11110001);#100;
	//polarity(1,1);
	send();
	stimuli_miso(1);#100;
	stimuli_miso(0);#150;
	stimuli_miso(0);#100;
	stimuli_miso(1);#100;
	stimuli_miso(1);#100;
#300;
	//stimuli_miso(1);#50;
	//stimuli_miso(1);#50;
	//stimuli_miso(0);#50;
       
	
//$finish;
	
end

initial
#3000 $finish;

endmodule

