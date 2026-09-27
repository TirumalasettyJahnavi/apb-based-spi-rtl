module apb_slave_interface_tb();
		           reg pclk;
			   reg preset_n;
			   reg [2:0]PADDR_i;
			   reg PWRITE_i;
			   reg PSEL_i;
			   reg PEnable_i;
			   reg [7:0]PWDATA_i;
			   reg ss_i;
			   reg [7:0]miso_data_i;
			   reg receive_data_i;
			   reg tip_i;
			   wire [7:0]PRDATA_o;
			   wire mstr_o;
			   wire cpol_o;
			   wire cpha_o;
			   wire lsbfe_o;
			   wire spiswai_o;
			   wire [2:0]sppr_o;
			   wire [2:0]spr_o;
			   wire spi_intrupt_req_o;
			   wire PReady_o;
			   wire PSLVERR_o;
			   wire send_data_o;
			   wire [7:0]mosi_data_o;
			   wire [1:0]spi_mode_o;
			   
apb_slave_interface dut(pclk,preset_n,PADDR_i,PWRITE_i,PSEL_i,PEnable_i,PWDATA_i,ss_i,miso_data_i,receive_data_i,tip_i,PRDATA_o,mstr_o,cpol_o,cpha_o,lsbfe_o,spiswai_o,sppr_o,spr_o,spi_intrupt_req_o,PReady_o,PSLVERR_o,send_data_o,mosi_data_o,spi_mode_o);


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

task initialize;
	begin
		pclk=1'b0;
		preset_n=1'b0;
		PADDR_i=3'b000;
		PWRITE_i=1'b0;
		PSEL_i=1'b1;
		PEnable_i=1'b0;
		PWDATA_i=8'b0;
		ss_i=1'b1;
		miso_data_i=8'b0;
		receive_data_i=1'b0;
		tip_i=1'b0;
	end
endtask

task write_registers(input [7:0] ctrl_reg1,input [7:0] ctrl_reg2,input [7:0] baud_reg);
	begin
	@(negedge pclk)
	PADDR_i=3'b000;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//setup state 
	PEnable_i=1'b0;
	PWDATA_i=ctrl_reg1;

	@(negedge pclk)
	PADDR_i=3'b000;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//enable state
	PEnable_i=1'b1;
	PWDATA_i=ctrl_reg1;

	@(negedge pclk)
	wait(PReady_o)
		PEnable_i=1'b0;//idle

	@(negedge pclk)
	PADDR_i=3'b001;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//enable
	PEnable_i=1'b1;
	PWDATA_i=ctrl_reg2;//reg 2

	@(negedge pclk)
	wait(PReady_o)
		PEnable_i=1'b0;
	
	
	@(negedge pclk)
	PADDR_i=3'b010;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//enable
	PEnable_i=1'b1;
	PWDATA_i=baud_reg;//spi_baud_reg

	@(negedge pclk)
	wait(PReady_o)
		PEnable_i=1'b0;
	end
endtask


task write_data_reg(input [7:0]data_reg);
	begin
	@(negedge pclk)
	PADDR_i=3'b101;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//setup state 
	PEnable_i=1'b0;
	PWDATA_i=data_reg;

	@(negedge pclk)
	PADDR_i=3'b101;
	PWRITE_i=1'b1;
	PSEL_i=1'b1;//enable state
	PEnable_i=1'b1;
	PWDATA_i=data_reg;

	@(negedge pclk)
	wait(PReady_o)
		PEnable_i=1'b0;//idle

end
endtask


task read_registers(input [2:0]address);
	begin
		@(negedge pclk)
		PADDR_i=address;
		PWRITE_i=1'b0;
		PSEL_i=1'b1;//enable state
		PEnable_i=1'b0;

		@(negedge pclk)
		PADDR_i=address;
		PWRITE_i=1'b0;
		PSEL_i=1'b1;//enable state
		PEnable_i=1'b1;

		@(negedge pclk)
		wait(PReady_o)
		PEnable_i=1'b0;//idle

	end
endtask


task read_ctrl1;
	begin
		read_registers(3'b000);
	end
endtask

task read_ctrl2;
	begin
		read_registers(3'b001);
	end
endtask

task read_baud;
	begin
		read_registers(3'b010);
	end
endtask
task read_status();
	begin
		read_registers(3'b011);
end
endtask

task data_register;
	begin
		read_registers(3'b101);
	end
endtask

task read_data;
	begin
		read_registers(3'b101);
	end
endtask


initial begin
	initialize;
	reset;
	ss_i=1'b0;
	receive_data_i=1'b1;
	tip_i=1'b1;
	miso_data_i=8'hFA;
	write_registers(8'b01011101, 8'b00000000 ,8'b00000001);
	write_data_reg(8'hAA);
	read_ctrl1;
	read_ctrl2;
	read_baud;
	read_status;
	read_data;
end


initial 
	#5000 $finish();
endmodule

