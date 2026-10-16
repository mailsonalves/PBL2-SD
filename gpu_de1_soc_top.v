module gpu_de1_soc_top (
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,         // Apenas KEY[0] atua como reset
    output wire [9:0]  LEDR,

    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    wire rst_n = KEY[0];

    // Clock Pixel 25 MHz
    reg clk_25m;
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) clk_25m <= 1'b0;
        else        clk_25m <= ~clk_25m;
    end

    assign VGA_CLK    = clk_25m;
    assign VGA_SYNC_N = 1'b0;

    // Gerador VGA
    wire video_active;
    wire [8:0] pixel_x;
    wire [7:0] pixel_y;

    vga_sync u_vga_sync (
        .clk_25m     (clk_25m),
        .rst_n       (rst_n),
        .hsync       (VGA_HS),
        .vsync       (VGA_VS),
        .video_active(video_active),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y)
    );

    assign VGA_BLANK_N = video_active;

    // Unidade de Busca Ativa (PC com 11 bits)
    wire [31:0] cmd_data;
    wire        cmd_valid;
    wire        cmd_ready;
    wire [10:0] current_pc;
    wire        rast_busy = 1'b0; // Rasterizador não existe mais, mantemos em 0

    fetch_control_unit u_fetch_unit (
        .clk       (CLOCK_50),
        .rst_n     (rst_n),
        .vsync     (VGA_VS),
        .rast_busy (rast_busy),
        .cmd_data  (cmd_data),
        .cmd_valid (cmd_valid),
        .cmd_ready (cmd_ready),
        .pc_out    (current_pc)
    );

    // Decodificador de Instrucoes
    wire        pal_we;
    wire [7:0]  pal_addr;
    wire [23:0] pal_data;
    wire        tm_we;
    wire [5:0]  tm_x;
    wire [4:0]  tm_y;
    wire [7:0]  tm_tile_id;
    wire [8:0]  scroll_x;
    wire [7:0]  scroll_y;
    wire        sat_we;
    wire [4:0]  sat_addr;
    wire [31:0] sat_data;

    cmd_decoder u_cmd_decoder (
        .clk       (CLOCK_50),
        .rst_n     (rst_n),
        .cmd_data  (cmd_data),
        .cmd_valid (cmd_valid),
        .cmd_ready (cmd_ready),
        .pal_we    (pal_we),
        .pal_addr  (pal_addr),
        .pal_data  (pal_data),
        .tm_we     (tm_we),
        .tm_x      (tm_x),
        .tm_y      (tm_y),
        .tm_tile_id(tm_tile_id),
        .scroll_x  (scroll_x),
        .scroll_y  (scroll_y),
        .sat_we    (sat_we),
        .sat_addr  (sat_addr),
        .sat_data  (sat_data)
    );

    // Motor de Fundo (Background)
    wire [13:0] bg_vram_addr;
    wire [7:0]  bg_pixel;

    bg_engine u_bg_engine (
        .clk               (CLOCK_50),
        .pixel_x           (pixel_x),
        .pixel_y           (pixel_y),
        .scroll_x          (scroll_x),
        .scroll_y          (scroll_y),
        .we                (tm_we),
        .wr_x              (tm_x),
        .wr_y              (tm_y),
        .wr_tile_id        (tm_tile_id),
        .bg_vram_addr      (bg_vram_addr)
    );

    // Motor de Múltiplos Sprites
    wire [13:0] sp_vram_addr;
    wire [7:0]  sp_vram_data;
    wire [7:0]  sp_pixel;

    sprite_engine u_sprite_engine (
        .clk          (CLOCK_50),
        .rst_n        (rst_n),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .sat_we       (sat_we),
        .sat_addr     (sat_addr),
        .sat_data     (sat_data),
        .sp_vram_addr (sp_vram_addr),
        .sp_vram_data (sp_vram_data),
        .sp_pixel     (sp_pixel)
    );

    // VRAM Dual-Port
    pattern_vram u_patterns (
        .clk        (CLOCK_50),
        .we_a       (1'b0),
        .addr_a     (bg_vram_addr),
        .data_in_a  (8'd0),
        .data_out_a (bg_pixel),
        .addr_b     (sp_vram_addr),
        .data_out_b (sp_vram_data)
    );

    // Compositor (sem poligono)
    wire [7:0] final_pixel_idx;

    compositor u_compositor (
        .bg_pixel          (bg_pixel),
        .sp_pixel          (sp_pixel),
        .final_pixel_index (final_pixel_idx)
    );

    // Paleta de Cores
    wire [23:0] rgb_24;

    color_palette u_palette (
        .clk    (CLOCK_50),
        .we     (pal_we),
        .wr_addr(pal_addr),
        .wr_data(pal_data),
        .rd_addr(final_pixel_idx),
        .rgb_out(rgb_24)
    );

    assign VGA_R = video_active ? rgb_24[23:16] : 8'd0;
    assign VGA_G = video_active ? rgb_24[15:8]  : 8'd0;
    assign VGA_B = video_active ? rgb_24[7:0]   : 8'd0;

    assign LEDR[7:0] = current_pc[7:0];
    assign LEDR[8]   = 1'b0;
    assign LEDR[9]   = rst_n;

endmodule