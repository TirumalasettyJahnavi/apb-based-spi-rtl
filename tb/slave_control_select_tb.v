module slave_control_select_tb();
	reg pclk;
	reg preset_n;
	reg mstr_i;
	reg spiswai_i;
	reg [1:0]spi_mode_i;
	reg send_data_i;
	reg [11:0]BaudRateDivisor_i;
	wire receive_data_o;
	wire ss_o;
	wire tip_o;

slave_control_select dut(pclk,preset_n,mstr_i,spiswai_i,spi_mode_i,send_data_i,BaudRateDivisor_i,receive_data_o,ss_o,tip_o);

initial begin
	pclk=1'b0;
	forever #20 pclk=~pclk;
end

task reset();
	begin
		@(negedge pclk)preset_n=1'b0;
		@(negedge pclk)preset_n=1'b1;
	end
endtask

task initialize();
	begin
		mstr_i=1;
		spiswai_i=1'b0;
		spi_mode_i=2'b00;
	end
endtask

task send();
	begin
		@(posedge pclk)send_data_i=1'b1;
		@(posedge pclk)send_data_i=1'b0;
	end
endtask

task stimulus(input [11:0]i);
	begin
		BaudRateDivisor_i=i;
	end
endtask

initial begin
	initialize();
	reset();
	stimulus(4);#100;
	send();
	stimulus(4);#100;
	#500 $finish;
end
endmodule