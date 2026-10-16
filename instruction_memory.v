module instruction_memory #(
    parameter integer ADDRESS_WIDTH = 11,
    parameter integer PROGRAM_WORDS = 2048
) (
    input  wire                     clk,
    input  wire [ADDRESS_WIDTH-1:0] address,
    output reg  [31:0]              instruction
);

    localparam [31:0] HALT = 32'hF0000000;

    (* ramstyle = "M10K, no_rw_check" *) reg [31:0] memory [0:PROGRAM_WORDS-1];

    initial begin
        $readmemh("program.hex", memory);
    end

    always @(posedge clk) begin
        if (address < PROGRAM_WORDS)
            instruction <= memory[address];
        else
            instruction <= HALT;
    end

endmodule