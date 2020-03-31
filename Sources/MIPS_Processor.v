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
	parameter PC_INCREMENT = 4,
	parameter jump_start = 32'b1111_1111_1100_0000_0000_0000_0000_0000,
	parameter ra = 31
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
wire jump_wire; // nuevo wire
wire jr_sel; //nuevo wire
wire jal_sel; //nuevo wire
wire wMemRead;
wire wMemtoReg;
wire wMemWrite;
wire ALUSRC_wire;
wire reg_write_wire;
wire zero_wire;

//Buses de wires
wire [2:0]  ALUOp_wire; 
wire [3:0]  ALUOperation_wire;
wire [4:0]  register_wire;
wire [4:0]  WriteRegister_wire;
wire [31:0] Instruction_wire;  
wire [31:0] ReadData1_wire;
wire [31:0] ReadData2_wire;
wire [31:0] InmmediateExtend_wire;
wire [31:0] ReadData2OrInmmediate_wire;
wire [31:0] ALUResult_wire;
wire [31:0] MUX_PC_wire;
wire [31:0] PC_wire;
wire [31:0] PC_4_wire;
wire [31:0] writeData_wire;
wire [31:0] wReadData;
wire [31:0] MUX_RamALU_wire;
wire [31:0] BranchNE_PC_wire;
wire [31:0] offset_start;
wire [31:0] branch_or_jump_wire;
wire [27:0] jump_sin_concatenar;
wire [31:0] inmmediate_shifted_wire;
wire [31:0] ALUResult_adder_wire;



//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/

Control
ControlUnit
(
	.OP(Instruction_wire[31:26]),
	.func(Instruction_wire[5:0]),  // para diferenciar jr de los otros tipos r
	.RegDst(RegDst_wire),
	.BranchEQ(BranchEQ_wire),
	.BranchNE(BranchNE_wire),
	.Jump(jump_wire),//nuevo wire
	.jal(jal_sel), //nuevo wire
	.jr(jr_sel),	//nuevo wire
	.MemRead(wMemRead),
	.MemtoReg(wMemtoReg),
	.MemWrite(wMemWrite),
	.ALUOp(ALUOp_wire),
	.ALUSrc(ALUSRC_wire),
	.RegWrite(reg_write_wire)
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
PC_Plus_4
(
	.Data0(PC_wire),
	.Data1(PC_INCREMENT),
	
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
	.RegWrite(reg_write_wire),
	.WriteRegister(WriteRegister_wire),
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
	.Selector(ALUSRC_wire),
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
ArithmeticLogicUnit 
(
	.ALUOperation(ALUOperation_wire),
	.A(ReadData1_wire),
	.B(ReadData2OrInmmediate_wire),
	.shamt(Instruction_wire[10:6]),
	.Zero(zero_wire),
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
	.Selector(BranchEQ_wire & zero_wire | BranchNE_wire & ~zero_wire), //condicion si se cumple el beq o el bne
	.MUX_Data0(PC_4_wire),
	.MUX_Data1(ALUResult_adder_wire),
	.MUX_Output(BranchNE_PC_wire)
);


//multiplexor usado para saber si va a ser jump o no

Multiplexer2to1
#(
	 .NBits(32)
)
MUX_JUMP
(
	.Selector(jump_wire),
	.MUX_Data0((BranchNE_PC_wire)),
	.MUX_Data1((offset_start)),
	.MUX_Output(branch_or_jump_wire)
);


Adder32bits
ADD_ALU_RESULT
(
	.Data0(PC_4_wire),
	.Data1(inmmediate_shifted_wire),
	.Result((ALUResult_adder_wire))
);

ShiftLeft2
ShiftLeft
(
	.DataInput(Instruction_wire[25:0]),
	.DataOutput(jump_sin_concatenar)
	
);


Adder32bits
ADD_ALU_OFFSET //para iniciar el pc en 40000
(
	.Data0({PC_4_wire[31:28], jump_sin_concatenar}),
	.Data1(jump_start),
	
	.Result(offset_start)
);



// agregado para dejar alineado a 4 bytes las direcciones de salto de los branches
ShiftLeft2
ShiftLeftBranch
(
	.DataInput(InmmediateExtend_wire),
	.DataOutput(inmmediate_shifted_wire)
	
);


// este mux salta a la direccion del registro deseado siempre y cuando se
// use la instruccion jr
Multiplexer2to1
#(
	 .NBits(32)
)
MUX_JR
(
	.Selector(jr_sel), 
	.MUX_Data0(branch_or_jump_wire), //entra al mux la direccion de un branch o un jump
	.MUX_Data1(ReadData1_wire), //direccion del registro
	.MUX_Output(MUX_PC_wire) 
);


//mux para activar el registro ra para escribir en el al hacer una instruccion jal
Multiplexer2to1
#(
	 .NBits(32)
)

MUX_JAL
(
	.Selector(jal_sel),
	.MUX_Data0(register_wire),
	.MUX_Data1(ra), //31 por el registro 31
	.MUX_Output(WriteRegister_wire)
);

//mux para ver si se escribira la direccion de salto a ra, o dejar pasar el registro a ra

Multiplexer2to1
#(
	.NBits(32)
)
MUX_JAL_wRITE_RA
(
	.Selector(jal_sel),
	.MUX_Data0(MUX_RamALU_wire),
	.MUX_Data1(PC_4_wire),
	
	.MUX_Output(writeData_wire)
);


//memoria ram
DataMemory
#(
	.DATA_WIDTH(32),
	.MEMORY_DEPTH(256)
)
RamMemory
(
	.WriteData(ReadData2_wire),
	.Address(ALUResult_wire),
	.MemWrite(wMemWrite),
	.MemRead(wMemRead),
	.clk(clk),
	.ReadData(wReadData)
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

endmodule

