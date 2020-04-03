/******************************************************************
* Description
*	This is the top-level of a MIPS processor
* This processor is written Verilog-HDL. Also, it is synthesizable into hardware.
* Parameter MEMORY_DEPTH configures the program memory to allocate the program to
* be execute. If the size of the program changes, thus, MEMORY_DEPTH must change.
* This processor was made for computer organization class at ITESO.
******************************************************************/


module MIPS_Processor
#(
	parameter MEMORY_DEPTH = 64,
	parameter jump_start = 32'b1111_1111_1100_0000_0000_0000_0000_0000,
	parameter ra = 5'b11111 // 31
)

(
	// Inputs
	input clk,
	input reset,
	input [7:0] PortIn,
	// Output
	output [31:0] ALUResultOut,
	output [31:0] PortOut
);
//******************************************************************/
//******************************************************************/
assign  PortOut = 0;

//******************************************************************/
//******************************************************************/
// Data types to connect modules
wire BranchEQ_wire;
wire BranchNE_wire;
wire RegDst_wire;
wire ALUSrc_wire;
wire reg_Write_wire;
wire Zero_wire;

//Buses de wires
wire [2:0] ALUOp_wire;
wire [3:0] ALUOperation_wire;
wire [4:0] register_wire;
wire [31:0] PC_wire;
wire [31:0] Instruction_wire;
wire [31:0] ReadData1_wire;
wire [31:0] ReadData2_wire;
wire [31:0] InmmediateExtend_wire;
wire [31:0] ReadData2OrInmmediate_wire;
wire [31:0] ALUResult_wire;
wire [31:0] PC_4_wire;

//Practica 2

wire wMemRead; 
wire wMemtoReg; 
wire wMemWrite; 


wire jump_wire; // nuevo wire	
wire jr_wire; //nuevo wire		


wire [31:0] writeData_wire; 
wire [31:0] wReadData; 

wire [31:0] MUX_RamALU_wire;  
wire [31:0] BranchNE_PC_wire;  

wire [31:0] offset_start;		
wire [31:0] branch_or_jump_wire;	

wire [31:0] jump_no_concat;	
wire [31:0] ALUResult_adder_wire;	

wire [31:0] MUX_PC_wire; 
wire [4:0] Jalregister_wire;	


integer ALUStatus;
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
Control
ControlUnit
(
	.OP(Instruction_wire[31:26]),
	.func(Instruction_wire[5:0]), // para diferenciar jr de los otros tipos r
	.RegDst(RegDst_wire),
	.BranchEQ(BranchEQ_wire),
	.BranchNE(BranchNE_wire),
	
	
	.jump(jump_wire),//nuevo wire
	.jr(jr_wire),		//nuevo wire
	
	.MemRead(wMemRead),
	.MemtoReg(wMemtoReg),
	.MemWrite(wMemWrite),
	
	.ALUOp(ALUOp_wire),
	.ALUSrc(ALUSrc_wire),
	.RegWrite(reg_Write_wire)
	
);

PC_Register											
ProgramCounter
(
	.clk(clk),
	.reset(reset),
	.NewPC(MUX_PC_wire),
	.PCValue(PC_wire)
);


ProgramMemory
#(
	.MEMORY_DEPTH(MEMORY_DEPTH)
)
ROMProgramMemory
(
	.Address(PC_wire),
	
	.Instruction(Instruction_wire)
);


Adder32bits
PC_Puls_4
(
	.Data0(PC_wire),
	.Data1(4),
	.Result(PC_4_wire)
);


//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
Multiplexer2to1
#(
	.NBits(5)
)
MUX_ForRTypeAndIType
(
	.Selector(RegDst_wire),
	.MUX_Data0(Instruction_wire[20:16]),
	.MUX_Data1(Instruction_wire[15:11]),
	.MUX_Output(register_wire)

);


RegisterFile
Register_File
(
	.clk(clk),
	.reset(reset),
	.RegWrite(reg_Write_wire),
	.WriteRegister(Jalregister_wire),
	.ReadRegister1(Instruction_wire[25:21]),
	.ReadRegister2(Instruction_wire[20:16]),
	.WriteData(writeData_wire), //viene del mux agregado de jal, para escribir direccion de $ra
	.ReadData1(ReadData1_wire),
	.ReadData2(ReadData2_wire)

);


SignExtend
SignExtendForConstants
(   
	.DataInput(Instruction_wire[15:0]),
   .SignExtendOutput(InmmediateExtend_wire)
);


Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForReadDataAndInmediate
(
	.Selector(ALUSrc_wire),
	.MUX_Data0(ReadData2_wire),
	.MUX_Data1(InmmediateExtend_wire),
	
	.MUX_Output(ReadData2OrInmmediate_wire)

);


ALUControl
ArithmeticLogicUnitControl
(
	.ALUOp(ALUOp_wire),
	.ALUFunction(Instruction_wire[5:0]),
	.ALUOperation(ALUOperation_wire)

);



ALU
Arithmetic_Logic_Unit 
(
	.ALUOperation(ALUOperation_wire),
	.A(ReadData1_wire),
	.B(ReadData2OrInmmediate_wire),
	.shamt(Instruction_wire[10:6]),
	.Zero(Zero_wire),
	.ALUResult(ALUResult_wire)
);

assign ALUResultOut = ALUResult_wire;
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/


 //multiplexor para decidir si saltar o no a la direccion propuesta dependiendo si se comple el selector o no
Multiplexer2to1
#(
	.NBits(32)
)
MUX_Branch
(
	.Selector((Zero_wire && BranchEQ_wire)|| (BranchNE_wire && ~Zero_wire)), //condicion si se cumple el beq o el bne
	.MUX_Data0(PC_4_wire),
	.MUX_Data1(ALUResult_adder_wire),
	.MUX_Output(BranchNE_PC_wire)

);


//para branches
Adder32bits
ADD_ALU_RESULT
(
	.Data0(PC_4_wire),
	.Data1(InmmediateExtend_wire << 2),
	.Result(ALUResult_adder_wire)
);


ShiftLeft2
ShiftJump
(
	.DataInput({6'b0,Instruction_wire[25:0]}),
   .DataOutput(jump_no_concat)
);

Adder32bits
ADD_ALU_OFFSET //para iniciar el pc en 40000
(
	.Data0(jump_start), 
	.Data1({PC_4_wire[31:28], jump_no_concat[27:0]}),

	.Result(offset_start)
);




//multiplexor usado para saber si va a ser jump o no
Multiplexer2to1
#(
	.NBits(32)
)
MUX_JUMP
(
	.Selector(jump_wire), 
	.MUX_Data0(BranchNE_PC_wire),
	.MUX_Data1(offset_start),
	.MUX_Output(branch_or_jump_wire)

);


// este mux salta a la direccion del registro deseado siempre y cuando se
// use la instruccion jr
Multiplexer2to1
#(
	.NBits(32)
)
MUX_JR
(
	.Selector(jr_wire),
	.MUX_Data0(branch_or_jump_wire),//entra al mux la direccion de un branch o un jump
	.MUX_Data1(ReadData1_wire),//direccion del registro
	.MUX_Output(MUX_PC_wire)

);


//mux para activar el registro ra para escribir en el al hacer una instruccion jal (pc+4)
Multiplexer2to1
#(
	.NBits(5)
)
MUX_JAL
(
	.Selector(jump_wire), 
	.MUX_Data0(register_wire),
	.MUX_Data1(ra), // 31
	.MUX_Output(Jalregister_wire)
);



//mux para ver si se escribira la direccion de salto a ra, o dejar pasar el registro a ra
Multiplexer2to1
#(
	.NBits(32)
)
MUX_JAL_WRITE_RA
(
	.Selector(jump_wire),
	.MUX_Data0(MUX_RamALU_wire),
	.MUX_Data1(PC_4_wire),
	.MUX_Output(writeData_wire)

);


//mux para diferenciar entre alu y memoria
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ALUandRAM
(
	.Selector(wMemtoReg),
	.MUX_Data0(ALUResult_wire),
	.MUX_Data1(wReadData),
	.MUX_Output(MUX_RamALU_wire)

);




//memoria ram
DataMemory
#(
	.DATA_WIDTH(32),
	.MEMORY_DEPTH(256)
)
RamMemory(
	.WriteData(ReadData2_wire),
	.Address((ALUResult_wire[7:0] == 0)?0:{24'b 0,ALUResult_wire[7:0]} /4), // no jalo (ALUResult_wire - 32'h10010000) / 4
	.MemWrite(wMemWrite),
	.MemRead(wMemRead),
	.clk(clk),
	.ReadData(wReadData)
);

endmodule
