module OrGate
(
	input equal,
	input not_Equal,
	output reg Result
);

always@(*)
	Result = equal | not_Equal;

endmodule