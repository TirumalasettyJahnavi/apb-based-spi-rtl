module top_module(
		input pclk,
		input preset_n,
		input [2:0]PADDR_i,
		input PWRITE_i,
		input PSEL_i,
		input PENABLE_i,
		input [7:0] PWDATA_i,
		input miso_i,
		output  ss_o,
		output  sclk_o,
		output  spi_interrupt_request,
		output  mosi_o,
		output  [7:0]PRDATA_o,
		output  PREADY_o,
		output  PSLVERR_o);

wire [1:0] spi_mode;
wire spiswai;
wire [2:0] sppr;
wire [2:0]spr;
wire cpol;
wire cpha;
wire miso_receive_sclk,miso_receive_sclk0,mosi_send_sclk,mosi_send_sclk0;
wire [11:0]BaudRateDivisor;

wire send_data;
wire lsbfe;
wire [7:0]data_mosi;
wire receive_data;
wire [7:0] data_miso;
wire mstr;
wire tip;



baud_rate_generator b1 (.pclk(pclk),.preset_n(preset_n),.spi_mode_i(spi_mode),.spiswai_i(spiswai),.sppr_i(sppr),.spr_i(spr),.cpol_i(cpol),.cpha_i(cpha),.ss_i(ss_o),.sclk_o(sclk_o),.BaudRateDivisor_o(BaudRateDivisor),.miso_receive_sclk_o(miso_receive_sclk),.miso_receive_sclk0_o(miso_receive_sclk0),.mosi_send_sclk_o(mosi_send_sclk),.mosi_send_sclk0_o(mosi_send_sclk0));

//baudrate generator

shift_register b2 (.pclk(pclk),.preset_n(preset_n),.ss_i(ss_o),.send_data_i(send_data),.lsbfe_i(lsbfe),.cpha_i(cpha),.cpol_i(cpol),.miso_receive_sclk_i(miso_receive_sclk),.miso_receive_sclk0_i(miso_receive_sclk0),.mosi_send_sclk_i(mosi_send_sclk),.mosi_send_sclk0_i(mosi_send_sclk0),.data_mosi(data_mosi),.miso_i(miso_i),.receive_data_i(receive_data),.mosi_o(mosi_o),.data_miso_o(data_miso));


slave_control_select b3(.pclk(pclk),.preset_n(preset_n),.mstr_i(mstr),.spiswai_i(spiswai),.spi_mode_i(spi_mode),.send_data_i(send_data),.BaudRateDivisor_i(BaudRateDivisor),.receive_data_o(receive_data),.ss_o(ss_o),.tip_o(tip));



apb_slave_interface b4 (.pclk(pclk),.preset_n(preset_n),.PADDR_i(PADDR_i),.PWRITE_i(PWRITE_i),.PSEL_i(PSEL_i),.PEnable_i(PENABLE_i),.PWDATA_i(PWDATA_i),.ss_i(ss_o),.miso_data_i(data_miso),.receive_data_i(receive_data),.tip_i(tip),.PRDATA_o(PRDATA_o),.mstr_o(mstr),.cpol_o(cpol),.cpha_o(cpha),.lsbfe_o(lsbfe),.spiswai_o(spiswai),.sppr_o(sppr),.spr_o(spr),.spi_intrupt_req_o(spi_interrupt_request),.PReady_o(PREADY_o),.PSLVERR_o(PSLVERR_o),.send_data_o(send_data),.mosi_data_o(data_mosi),.spi_mode_o(spi_mode));

endmodule
