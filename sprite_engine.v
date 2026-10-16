module sprite_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [8:0]  pixel_x,
    input  wire [7:0]  pixel_y,
    
    // Interface de comandos (vindo do cmd_decoder)
    input  wire        sat_we,
    input  wire [4:0]  sat_addr,
    input  wire [31:0] sat_data,
    
    // Interface com a Pattern VRAM
    output reg  [13:0] sp_vram_addr,
    input  wire [7:0]  sp_vram_data, // Dado bruto retornado pela VRAM
    
    // Saída final tratada para o Compositor
    output reg  [7:0]  sp_pixel
);

    // OAM (Object Attribute Memory): Guarda as infos de 32 sprites
    reg [31:0] oam [0:31];
    
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < 32; k = k + 1) oam[k] <= 32'd0;
        end else if (sat_we) begin
            oam[sat_addr] <= sat_data;
        end
    end

    // Atraso de 1 ciclo nas coordenadas para alinhar com a leitura da tilemap_ram no bg_engine
    reg [8:0] px_d1;
    reg [7:0] py_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_d1 <= 9'd0;
            py_d1 <= 8'd0;
        end else begin
            px_d1 <= pixel_x;
            py_d1 <= pixel_y;
        end
    end

    // Fios para calcular colisão e endereços de cada sprite
    wire [13:0] sprite_addrs [0:31];
    wire        sprite_hit [0:31];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_sprites
            wire [31:0] attr    = oam[i];
            wire        enable  = attr[31];
            wire        flip_x  = attr[30];
            wire        flip_y  = attr[29];
            wire [8:0]  sp_x    = attr[24:16];
            wire [7:0]  sp_y    = attr[15:8];
            wire [7:0]  base_id = attr[7:0];
            
            // Comparação com 10 bits em X e 9 bits em Y para não estourar quando sp_x > 496 (ex: X=504 no program.hex)
            wire inside_x = ({1'b0, px_d1} >= {1'b0, sp_x}) && ({1'b0, px_d1} < ({1'b0, sp_x} + 10'd16));
            wire inside_y = ({1'b0, py_d1} >= {1'b0, sp_y}) && ({1'b0, py_d1} < ({1'b0, sp_y} + 9'd16));
            wire hit      = enable && inside_x && inside_y;
            
            // Diferença exata de 4 bits dentro do sprite 16x16
            wire [8:0] diff_x = px_d1 - sp_x;
            wire [7:0] diff_y = py_d1 - sp_y;
            
            // Aplica espelhamento horizontal/vertical caso ativado
            wire [3:0] dx = flip_x ? ~diff_x[3:0] : diff_x[3:0];
            wire [3:0] dy = flip_y ? ~diff_y[3:0] : diff_y[3:0];
            
            wire [1:0] quad    = {dy[3], dx[3]};
            wire [7:0] tile_id = base_id + {6'd0, quad};
            
            assign sprite_addrs[i] = {tile_id, dy[2:0], dx[2:0]};
            assign sprite_hit[i]   = hit;
        end
    endgenerate

    // Seleciona o sprite ativo com maior prioridade (ID menor)
    integer j;
    reg any_hit;
    always @(*) begin
        sp_vram_addr = 14'd0;
        any_hit = 1'b0;
        for (j = 31; j >= 0; j = j - 1) begin
            if (sprite_hit[j]) begin
                sp_vram_addr = sprite_addrs[j];
                any_hit = 1'b1;
            end
        end
    end

    // Atraso de 1 ciclo de clock para alinhar a transparência com o tempo de leitura da VRAM
    reg hit_delay;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) hit_delay <= 1'b0;
        else        hit_delay <= any_hit;
    end

    // Saída filtrada: só passa cor se houver colisão na caixa
    always @(*) begin
        if (hit_delay) sp_pixel = sp_vram_data;
        else           sp_pixel = 8'h00; // Transparente para deixar o fundo passar
    end

endmodule