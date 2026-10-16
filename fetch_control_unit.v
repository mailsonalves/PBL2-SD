module fetch_control_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vsync,
    input  wire        rast_busy,
    output reg  [31:0] cmd_data,
    output reg         cmd_valid,
    input  wire        cmd_ready,
    output wire [10:0] pc_out
);

    reg [10:0] pc;
    assign pc_out = pc;

    wire [31:0] rom_instruction;
    reg vsync_d;
    wire vblank_start = (!vsync && vsync_d);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) vsync_d <= 1'b1;
        else        vsync_d <= vsync;
    end

    instruction_memory #(.PROGRAM_WORDS(2048), .ADDRESS_WIDTH(11)) u_rom (
        .clk      (clk),
        .address  (pc),
        .instruction (rom_instruction)
    );

    localparam S_FETCH  = 2'd0;
    localparam S_EXEC   = 2'd1;
    localparam S_VBLANK = 2'd2;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc        <= 11'd0;
            cmd_data  <= 32'd0;
            cmd_valid <= 1'b0;
            state     <= S_FETCH;
        end else begin
            cmd_valid <= 1'b0;

            case (state)
                S_FETCH: begin
                    cmd_data <= rom_instruction;
                    state    <= S_EXEC;
                end

                S_EXEC: begin
                    case (cmd_data[31:28])
                        4'hE: state <= S_VBLANK; // WAIT_VBLANK
                        4'hF: begin              // JUMP
                            pc    <= cmd_data[10:0]; // Extrai 11 bits do payload
                            state <= S_FETCH;
                        end
                        default: begin
                            if (cmd_ready && !rast_busy) begin
                                cmd_valid <= 1'b1;
                                pc        <= pc + 11'd1;
                                state     <= S_FETCH;
                            end
                        end
                    endcase
                end

                S_VBLANK: begin
                    if (vblank_start) begin
                        pc    <= pc + 11'd1;
                        state <= S_FETCH;
                    end
                end

                default: state <= S_FETCH;
            endcase
        end
    end
endmodule