#!/bin/bash
set -e

echo "=== 1. Limpando compilações anteriores ==="
rm -rf obj_dir

echo "=== 2. Analisando e gerando C++ com Verilator ==="
verilator -Wall --cc --exe \
    --top-module gpu_de1_soc_top \
    vga_sync.v \
    cmd_decoder.v \
    compositor.v \
    color_palette.v \
    tilemap_ram.v \
    pattern_vram.v \
    bg_engine.v \
    sprite_engine.v \
    instruction_memory.v \
    fetch_control_unit.v \
    gpu_de1_soc_top.v \
    sim_vga.cpp \
    -CFLAGS "$(sdl2-config --cflags)" \
    -LDFLAGS "$(sdl2-config --libs)" \
    -Wno-fatal \
    -Wno-WIDTH \
    -Wno-CASEINCOMPLETE \
    -Wno-UNUSED \
    -Wno-EOFNEWLINE

echo "=== 3. Compilando binário nativo com make ==="
make -j$(nproc) -C obj_dir -f Vgpu_de1_soc_top.mk Vgpu_de1_soc_top

echo "=== 4. Executando simulação gráfica em tempo real ==="
./obj_dir/Vgpu_de1_soc_top
