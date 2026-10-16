def cmd_scroll(x, y):
    return f"{(5 << 28) | ((x & 0x1FF) << 8) | (y & 0xFF):08X}\n"

def cmd_sprite(sprite_id, x, y, tile_id):
    x = x % 512
    y = y % 256
    return f"{(6 << 28) | ((sprite_id & 0x1F) << 23) | ((x & 0x1FF) << 14) | ((y & 0xFF) << 6) | (tile_id & 0x3F):08X}\n"

with open("program.hex", "w") as f:
    f.write("0F000000\n") # Clear Screen / Start

    for frame in range(300):
        # Cenário rolando para a esquerda (scroll_x avança positivamente)
        scroll_x = frame % 320

        # Flappy cai até atingir o chão em Y=190 e permanece
        flappy_y = 100 + frame
        if flappy_y > 190: 
            flappy_y = 190

        # Inimigo vindo da direita para a esquerda em Y=40
        inimigo_x = 350 - ((frame * 2) % 400)

        # Nuvens maiores vindas da direita em alturas diferentes
        nuvem1_x = 320 - (frame % 400)
        nuvem2_x = 480 - (frame % 400)

        f.write(cmd_scroll(scroll_x, 0))
        f.write(cmd_sprite(0, 70, flappy_y, 0x20))       # ID 0: Flappy Bird
        f.write(cmd_sprite(1, inimigo_x, 40, 0x24))      # ID 1: Inimigo Vermelho Invertido
        f.write(cmd_sprite(2, nuvem1_x, 20, 0x28))       # ID 2: Nuvem Grande 1
        f.write(cmd_sprite(3, nuvem2_x, 60, 0x28))       # ID 3: Nuvem Grande 2
        f.write("E0000000\n") # WAIT_VBLANK (Aplica os sprites no monitor)

    # Ao final de 300 quadros, salta de volta para a linha 1 reiniciando o loop perfeitamente
    f.write("F0000001\n") 

print("program.hex gerado com sucesso!")