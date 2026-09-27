module baud_rate_generator_tb();
reg pclk,preset_n;
reg [1:0] spi_mode_i;
reg spiswai_i;
reg [2:0]sppr_i;
reg [2:0] spr_i;
reg cpol_i,cpha_i,ss_i;
wire sclk_o;
wire [11:0]BaudRateDivisor_o;
wire miso_receive_sclk_o;
wire miso_receive_sclk0_o;
wire mosi_send_sclk_o;
wire mosi_send_sclk0_o;
integer i,j,k,l;
baud_rate_generator dut (pclk,preset_n, spi_mode_i,spiswai_i,sppr_i,spr_i,cpol_i,cpha_i,ss_i,sclk_o,BaudRateDivisor_o,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_0);
initial begin
	pclk=1'b0;
	forever #20 pclk=~pclk;
end

task initialize();
	begin
		cpol_i=1'b1;
		cpha_i=1'b0;
		spiswai_i=1'b0;
		spi_mode_i=2'b00;
	end
endtask
task reset();
	begin
		@(negedge pclk)preset_n=1'b0;
		@(negedge pclk)preset_n=1'b1;
	end
endtask

task clock(input a,input b);
	begin
		cpol_i=a;
		cpha_i=b;
	end
endtask

task mode();
	begin
		spiswai_i=1'b0;//wait mode
		spi_mode_i=2'b00;//run mode
		ss_i=1'b0;//active low signal
	end
endtask

task baudrate(input [2:0]c,input [2:0]d);
	begin
		sppr_i=c;
		spr_i=d;
	end
endtask

initial begin
	initialize();
	reset();
	mode();
	baudrate(1,1);
	clock(0,0);
	#1000;
	baudrate(2,1);
	clock(1,0);
	#1000;
	baudrate(2,2);
	clock(0,0);
	#1000;
	baudrate(2,0);
	clock(1,1);
	#1000;
/*	for(i=0;i<2;i=i+1)begin
		//clock(i,j);
		for(j=0;j<2;j=j+1)begin
			for(k=1;k<4;k=k+1)begin	
				for(l=1;l<4;l=l+1)begin
					clock(i,j);
					
					baudrate(k,l);
					#5000;
				end
			end
		end
	end */
	
	#10000 $finish;
end
endmodule
