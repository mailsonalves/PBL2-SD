module cmd_decoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cmd_data,
    input  wire        cmd_valid,
    output wire        cmd_ready,
    
    output reg         pal_we,
    output reg  [7:0]  pal_addr,
    output reg  [23:0] pal_data,
    
    output reg         tm_we,
    output reg  [5:0]  tm_x,
    output reg  [4:0]  tm_y,
    output reg  [7:0]  tm_tile_id,
    
    output reg  [8:0]  scroll_x,
    output reg  [7:0]  scroll_y,
    
    output reg         sat_we,
    output reg  [4:0]  sat_addr,
    output reg  [31:0] sat_data
);

    wire [3:0] opcode = cmd_data[31:28];
    assign cmd_ready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pal_we     <= 1'b0;
            pal_addr   <= 8'd0;
            pal_data   <= 24'd0;
            tm_we      <= 1'b0;
            tm_x       <= 6'd0;
            tm_y       <= 5'd0;
            tm_tile_id <= 8'd0;
            scroll_x   <= 9'd0;
            scroll_y   <= 8'd0;
            sat_we     <= 1'b0;
            sat_addr   <= 5'd0;
            sat_data   <= 32'd0;
        end else begin
            pal_we <= 1'b0;
            tm_we  <= 1'b0;
            sat_we <= 1'b0;

            if (cmd_valid && cmd_ready) begin
                case (opcode)
                    4'h3: begin // WRITE_TILEMAP
                        tm_we      <= 1'b1;
                        tm_x       <= cmd_data[21:16];
                        tm_y       <= cmd_data[12:8];
                        tm_tile_id <= cmd_data[7:0];
                    end
                    4'h5: begin // SET_SCROLL
                        scroll_x <= cmd_data[16:8];
                        scroll_y <= cmd_data[7:0];
                    end
                    4'h6: begin // UPDATE_SPRITE
                        sat_we   <= 1'b1;
                        sat_addr <= cmd_data[27:23]; 
                        // Formato: {Enable(1), FlipX(0), FlipY(0), Rsv(4), X(9), Y(8), 2'b00, Tile(6)}
                        sat_data <= {1'b1, 1'b0, 1'b0, 4'd0, cmd_data[22:14], cmd_data[13:6], 2'b00, cmd_data[5:0]};
                    end
                    4'hA: begin // INC_SCROLL_X
                        scroll_x <= (scroll_x >= 9'd319) ? 9'd0 : scroll_x + 9'd1;
                    end
                    default: ;
                endcase
            end
        end
    end
endmodule