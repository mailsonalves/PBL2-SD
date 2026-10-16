module compositor (
    input  wire [7:0] bg_pixel,
    input  wire [7:0] sp_pixel,
    output reg  [7:0] final_pixel_index
);
    always @(*) begin
        // Sprite sempre se sobrepõe se não for transparente
        if (sp_pixel != 8'h00)
            final_pixel_index = sp_pixel;
        else
            final_pixel_index = bg_pixel;
    end
endmodule