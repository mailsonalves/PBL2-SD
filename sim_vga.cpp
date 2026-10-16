#include <SDL2/SDL.h>
#include <iostream>
#include "Vgpu_de1_soc_top.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vgpu_de1_soc_top* top = new Vgpu_de1_soc_top;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "Falha ao inicializar SDL: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "Simulador VGA DE1-SoC - 640x480",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        640, 480, SDL_WINDOW_SHOWN
    );

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_Texture* texture = SDL_CreateTexture(
        renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 640, 480
    );

    uint32_t pixels[640 * 480];
    for (int i = 0; i < 640 * 480; ++i) pixels[i] = 0xFF000000;

    // Inicialização da porta restante
    top->CLOCK_50 = 0;
    top->KEY = 1;  // Reset inativo (solto, agora com apenas 1 bit)

    std::cout << "[INFO] Aplicando Reset..." << std::endl;
    
    // 1. Pulso Longo de Reset Automático
    for (int i = 0; i < 1000; ++i) {
        top->CLOCK_50 = !top->CLOCK_50;
        top->KEY = (i < 500) ? 0 : 1; // 0 nos primeiros 500 ciclos gera o reset
        top->eval();
    }

    int x = 0, y = 0;
    int prev_hsync = 1, prev_vsync = 1;
    bool running = true;
    SDL_Event event;
    int frame_count = 0;

    std::cout << "[INFO] Iniciando varredura VGA..." << std::endl;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
        }

        // Executa ciclos para 1 frame (800 * 525 * 2 = 840.000 transições de 50MHz)
        for (int step = 0; step < 840000; ++step) {
            top->CLOCK_50 = !top->CLOCK_50;
            top->eval();

            // Só processa dados de video no clock de 25MHz
            if (top->CLOCK_50 && top->VGA_CLK) {
                
                // Sincronismo Vertical
                if (prev_vsync && !top->VGA_VS) {
                    y = 0;
                }
                
                // Sincronismo Horizontal
                if (prev_hsync && !top->VGA_HS) {
                    x = 0;
                    y++;
                }

                prev_hsync = top->VGA_HS;
                prev_vsync = top->VGA_VS;

                // Captura do feixe visível (640x480)
                if (x >= 0 && x < 640 && y >= 0 && y < 480) {
                    if (top->VGA_BLANK_N) {
                        uint8_t r = top->VGA_R;
                        uint8_t g = top->VGA_G;
                        uint8_t b = top->VGA_B;
                        pixels[y * 640 + x] = (255 << 24) | (r << 16) | (g << 8) | b;
                    } else {
                        // Fora da area ativa, pinta de preto
                        pixels[y * 640 + x] = 0xFF000000;
                    }
                }
                x++;
            }
        }

        frame_count++;
        if (frame_count == 1) {
            std::cout << "[INFO] Primeiro frame capturado e renderizado!" << std::endl;
        }

        SDL_UpdateTexture(texture, NULL, pixels, 640 * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    delete top;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}