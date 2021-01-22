module Target(DEVSEL, Clk, Frame, CBE, TRDY, IRDY, AddressDataLine, oe,Rst);
input Clk, Frame, oe, IRDY;
input Rst; // reset boolean
input [3:0] CBE;
inout  [31:0] AddressDataLine;
output reg DEVSEL,TRDY;
parameter mem_size = 4; //number of addresses in the memore
reg[31 : 0] Buffer [0 : (mem_size-1)];
reg[31 : 0] Memory[0 : 5];
reg [2:0] Counter=0;
parameter StartMem = 32'd0;
parameter EndMem = 32'd3;
//reg [1:0] memRange [0:1] <= {; };
/*memRange [0] = ;
memRange [1] = 2'd3;
*/
parameter Read = 4'b0110, Write = 4'b0111;


parameter Location_0 = 2'd0 ;
parameter Location_1 = 2'd1;  
parameter Location_2 = 2'd2;
parameter Location_3 = 2'd3;
/*parameter Location_4 = 2'd4;  
parameter Location_5 = 2'd5;  
parameter Location_6 = 2'd6;  
parameter Location_7 = 2'd7;
*/
reg [31:0] Address;
reg [31:0] Data;
reg [3:0] Command;
reg Dataphase; //flag for differ the states of reading data or address


//To store data in address line at the change of data
//oe =0 AddressDataLine output write
assign AddressDataLine = (Command == Read && !oe)? Data : 32'bz;


always @(negedge Rst) begin
    TRDY <= 1;
    DEVSEL <= 1;
    //Data <= 32'bz;
end

//at negedge of frame: read address , command && Devsel , Trdy toggle
always @(negedge Frame) begin
    //Initialize dataphase 
    Dataphase <= 0;

    //oe =0 AddressDataLine input read
    if(oe)begin
     Address <= AddressDataLine;
    end 

    if(( AddressDataLine> StartMem && AddressDataLine < EndMem )|| AddressDataLine == EndMem || AddressDataLine == StartMem) begin
	Command <= CBE;
        #10
        TRDY <= 0;
        DEVSEL <= 0;
        Dataphase <= 1; //ready to read
    end	   
	if (CBE==Write)
	Counter=0;
end

//at posedge of frame: read data , 
always @(posedge Frame) begin
    //continue reading after the frame is 1 by one cycle	
    if( Command == Read) begin 
      Data <= Buffer [Address];
    end

    //continue writing after the frame is 1 by one cycle	
    else if( Command == Write) begin
	
      if(CBE[0]==1'b1) begin
              Buffer[Address][7:0] <= AddressDataLine[7:0];
            end
            if(CBE[1]==1'b1) begin
               Buffer[Address][15:8] <= AddressDataLine[15:8];
            end
            if(CBE[2]==1'b1) begin
              Buffer[Address][23:16] <= AddressDataLine[23:16];
            end
            if(CBE[3]==1'b1) begin
              Buffer[Address][31:24] <= AddressDataLine[31:24];
            end
    end

    #10
    TRDY <= 1;
    DEVSEL <= 1;
    Data <= 32'bz;
end

//for each neg edge of cycle: read or write
always @(negedge Clk or negedge DEVSEL) begin
 if(Frame == 0) begin
  case(Command)
    Read :begin 
	if(oe == 0  && TRDY == 0 && Dataphase == 1) begin
	if( IRDY == 0 )begin 
              Data <= Buffer [Address];
  	      Address <= Address + 1;
	      if(Address >= (mem_size-1)) begin 
		Address <= 0;
              end
        end
	end
	if (IRDY == 1) begin
  	Data <= Buffer [Address];
	#10
  	      Address <= Address + 1;
	      if(Address >= (mem_size-1)) begin 
		Address <= 0;
              end
	end
    end
      
    Write :begin
      //if(Address > (n-1)) Address <= 0;
	
      if(Dataphase == 1 && IRDY == 0 && TRDY == 0) begin
	
            if(CBE[0]==1'b1) begin
              Buffer[Address][7:0] <= AddressDataLine[7:0];
            end
            if(CBE[1]==1'b1) begin
               Buffer[Address][15:8] <= AddressDataLine[15:8];
            end
            if(CBE[2]==1'b1) begin
              Buffer[Address][23:16] <= AddressDataLine[23:16];
            end
            if(CBE[3]==1'b1) begin
              Buffer[Address][31:24] <= AddressDataLine[31:24];
            end
	    Address <= Address + 1;
	    Counter<=Counter+1;
		if(Address >= 3) begin 
		Address <= 0;
                end
	if(Counter >3)begin
	 TRDY<=1;
	
	Memory[0]<=Buffer[0];
	Memory[1]<=Buffer[1];
	Memory[2]<=Buffer[2];
	Memory[3]<=Buffer[3];
	Counter<=0;
	#10;
	TRDY<=0;
	
	end
       end
    end
  endcase   
 end
end
 
endmodule




module ClockGen (Clock);
 output Clock;
 reg Clock;
 initial
  Clock = 0;
 always
  #5 Clock = ~Clock;
endmodule
