module top_module_tb();
		reg pclk;
		reg preset_n;
		reg [2:0]PADDR_i;
		reg PWRITE_i;
		reg PSEL_i;
		reg PENABLE_i;
		reg  [7:0] PWDATA_i;
		reg miso_i;
		wire  ss_o;
		wire  sclk_o;
		wire  spi_interrupt_request;
		wire  mosi_o;
		wire  [7:0]PRDATA_o;
		wire  PREADY_o;
		wire  PSLVERR_o;

top_module dut(pclk,preset_n,PADDR_i,PWRITE_i,PSEL_i,PENABLE_i,PWDATA_i,miso_i,ss_o,sclk_o,spi_interrupt_request,mosi_o,PRDATA_o,PREADY_o,PSLVERR_o);

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

 //task initialize
  task initialize();
  begin

    { PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i, miso_i } = 0;

  end
  endtask



   //task to write cr1, cr2, br
  task write_registers( input [7 : 0]cr1, input [7 : 0]cr2, input [7 : 0]br );
  begin
    //Writing to CR1
    @( negedge pclk );
    PADDR_i = 3'b000;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge pclk );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = cr1;

    @( negedge pclk );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

    //Writing to CR2
    @( negedge pclk );
    PADDR_i = 3'b001;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge pclk );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = cr2;

    @( negedge pclk );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;


    //writing to baud register
    @( negedge pclk );
    PADDR_i = 3'b010;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge pclk );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = br;

    @( negedge pclk );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask

  
  //task to write into data register
  task write_data_register( input [7 : 0]dr );
  begin
    //Writing to data register
    @( negedge pclk );
    PADDR_i = 3'b101;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge pclk );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = dr;

    @( negedge pclk );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask
  
  //task send stimulus
  task send_stimulus( input [ 7 : 0 ]data );
  begin
    @( negedge pclk );
    PWDATA_i = data;
  end
  endtask

  
  //task for reading registers
  task read_register( input [2 : 0]paddr );
  begin
    //Writing to data register
    @( negedge pclk );
    PADDR_i = paddr;
    PWRITE_i = 1'b0;  //pwrite signal should be low
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge pclk );
    PENABLE_i = 1'b1;  //ENABLE phase

    @( negedge pclk );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask
  
  
  //task for sending miso data bit by bit
  integer i;
  
  //task receive stimulus
  task receive_stimulus( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_o )
    for( i = 7; i >= 0; i = i - 1 )
    begin
      @( posedge sclk_o )
      begin
        miso_i = data[ i ];
      end
    end    
  
  end
  endtask


   
    initial 
    begin

    	initialize();
    	reset();
    
    	write_registers( 8'b0101_0000, 8'b0000_0000, 8'b0000_0001 );  //baud divisor is 4

	write_data_register( 8'h33 );
	
	receive_stimulus( 8'h55 );

    	read_register( 3'b000 );

    	read_register( 3'b001 );

    	read_register( 3'b010 );

    	read_register( 3'b011 );

    	read_register( 3'b101 );    	
    
    end


//  initial
    //$monitor( $time, " ns, PRDATA_O = %b, mosi_o = %b, BaudRateDivisor_o = %d ", PRDATA_o, mosi_o, DUT.Baud_Rate_Divisor_o );


    initial #3000 $finish;

    initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, top_module_tb);
end

initial begin
    $display("Simulation started");
    
    // test stimulus
    
    #3000;
    $display("Simulation finished");
    $finish;
end

  
endmodule