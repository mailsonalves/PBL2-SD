module color_palette (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  wr_addr,
    input  wire [23:0] wr_data,
    input  wire [7:0]  rd_addr,
    output reg  [23:0] rgb_out
);

    reg [23:0] clut_ram [0:255];
    integer i;

    initial begin
        // Preenche índices altos (usados no sombreamento das bocas dos canos) com Verde do Cano
        for (i = 0; i < 256; i = i + 1)
            clut_ram[i] = 24'h5EE270;

        // ==========================================
        // PALETA DO BACKGROUND E ELEMENTOS GERAIS
        // ==========================================
        clut_ram[8'h00] = 24'h000000; // Preto (Contorno dos canos e faixa do chão)
        clut_ram[8'h01] = 24'h4EC0CA; // Azul Celeste
        clut_ram[8'h02] = 24'hFFFFFF; // Branco (Nuvens)
        clut_ram[8'h03] = 24'h5EE270; // Verde Claro
        clut_ram[8'h04] = 24'hD4F0F0; // Sombra suave das nuvens / contorno prédios
        clut_ram[8'h05] = 24'hDDE870; // Grama Clara
        clut_ram[8'h06] = 24'hE0B860; // Prédios (Amarelo/Bege Urbano)
        clut_ram[8'h07] = 24'hC89820; // Detalhe Prédios
        clut_ram[8'h08] = 24'h98D8E0; // Transição Nuvem / Céu
        clut_ram[8'h09] = 24'h80D040; // Arbustos Verdes (abaixo dos prédios)
        clut_ram[8'h0A] = 24'h5EE270;
        clut_ram[8'h0B] = 24'h5EE270;
        clut_ram[8'h0C] = 24'h5EE270;
        clut_ram[8'h0D] = 24'h009028;
        clut_ram[8'h0E] = 24'hDED895; // Chão de Terra / Areia (parte inferior)
        clut_ram[8'h0F] = 24'h009028;

        // Cores dos Sprites (Flappy Bird)
        clut_ram[8'h10] = 24'h000000; // Preto (Contorno do pássaro e olhos)
        clut_ram[8'h11] = 24'hFFFFFF; // Branco (Olhos, Asas e Nuvem Sprite)
        clut_ram[8'h12] = 24'hF8D820; // Amarelo Vivo (Corpo do Flappy Bird)
        clut_ram[8'h13] = 24'hC89820; // Ocre (Sombra do corpo)
        clut_ram[8'h14] = 24'hF85820; // Laranja (Bico do Flappy Bird / Detalhe)
        clut_ram[8'h15] = 24'h4EC0CA; // Céu Azul Celeste (usado em todo o fundo no .hex)

        // Gradiente Horizontal dos Canos (0x16 a 0x3B)
        clut_ram[8'h16] = 24'h70E878; // Borda esquerda clara
        clut_ram[8'h17] = 24'h98F898; // Brilho principal esquerdo
        clut_ram[8'h18] = 24'h5EE270; // Verde médio-claro
        clut_ram[8'h19] = 24'h5EE270; // Verde base
        clut_ram[8'h1A] = 24'h48C050; // Transição sombra
        clut_ram[8'h1B] = 24'h009028; // Verde escuro
        clut_ram[8'h1C] = 24'h98F898; // Brilho principal
        clut_ram[8'h1D] = 24'h48C050;
        clut_ram[8'h1E] = 24'h48C050;
        clut_ram[8'h1F] = 24'h5EE270;
        clut_ram[8'h20] = 24'h5EE270;
        clut_ram[8'h21] = 24'h5EE270;
        clut_ram[8'h22] = 24'h48C050;
        clut_ram[8'h23] = 24'h009028;
        clut_ram[8'h24] = 24'h5EE270;
        clut_ram[8'h25] = 24'h5EE270;
        clut_ram[8'h26] = 24'h009028;
        clut_ram[8'h27] = 24'h48C050;
        clut_ram[8'h28] = 24'h009028;
        clut_ram[8'h29] = 24'h009028;
        clut_ram[8'h2A] = 24'h007820; // Sombra direita
        clut_ram[8'h2B] = 24'h005814; // Extrema direita escura
        clut_ram[8'h2C] = 24'h009028;
        clut_ram[8'h2D] = 24'h009028;
        clut_ram[8'h2E] = 24'h5EE270;
        clut_ram[8'h2F] = 24'h70E878;
        clut_ram[8'h30] = 24'h48C050;
        clut_ram[8'h31] = 24'h5EE270;
        clut_ram[8'h32] = 24'h70E878;
        clut_ram[8'h33] = 24'h5EE270;
        clut_ram[8'h34] = 24'h5EE270;
        clut_ram[8'h35] = 24'h009028;
        clut_ram[8'h36] = 24'h48C050;
        clut_ram[8'h37] = 24'h48C050;
        clut_ram[8'h38] = 24'h005814;
        clut_ram[8'h39] = 24'h009028;
        clut_ram[8'h3A] = 24'h70E878;
        clut_ram[8'h3B] = 24'h009028;

        // Sombras escuras das bordas horizontais da boca do cano (presentes nos tiles 15..19 e 44..47)
        clut_ram[8'h4B] = 24'h005814;
        clut_ram[8'h4F] = 24'h005814;
        clut_ram[8'h5C] = 24'h005814;
        clut_ram[8'h5F] = 24'h005814;
        clut_ram[8'h60] = 24'h005814;
        clut_ram[8'h68] = 24'h005814;
        clut_ram[8'h6B] = 24'h005814;
        clut_ram[8'h76] = 24'h005814;
        clut_ram[8'h95] = 24'h80D040;
        clut_ram[8'h9C] = 24'h80D040;
        clut_ram[8'hEC] = 24'h58A828; // Borda superior da faixa do chão
        clut_ram[8'hFC] = 24'h005814;
        clut_ram[8'hFF] = 24'h005814;
    end

    always @(posedge clk) begin
        if (we) clut_ram[wr_addr] <= wr_data;
        rgb_out <= clut_ram[rd_addr];
    end

endmodule