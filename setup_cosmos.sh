#!/bin/bash

echo "🚀 Начинаем настройку проекта CosmOS для Motorola VIP2262E..."

# 1. Устанавливаем кросс-компилятор и утилиты
echo "📦 Устанавливаем инструменты..."
sudo apt update
sudo apt install -y gcc-mipsel-linux-gnu binutils-mipsel-linux-gnu make smartmontools

# 2. Создаём структуру папок
echo "📁 Создаём папки..."
mkdir -p ~/motorola-os/src
mkdir -p ~/motorola-os/tools
cd ~/motorola-os || exit 1

# 3. Пишем start.S (Точка входа + очистка BSS)
echo "📝 Создаём start.S..."
cat << 'EOF' > src/start.S
.section .text
.globl _start

_start:
    # Инициализация стека (уточнить по bootlog!)
    li $sp, 0x80800000
    
    # Очистка секции BSS
    la $t0, __bss_start
    la $t1, __bss_end
    beq $t0, $t1, skip_bss
clear_bss:
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    blt $t0, $t1, clear_bss
skip_bss:

    # Вызов main
    jal main
    nop
    
halt:
    j halt
    nop
EOF

# 4. Пишем main.c (Минимальный UART драйвер)
echo "📝 Создаём main.c..."
cat << 'EOF' > src/main.c
// Минимальный UART драйвер для BCM7405
// Адреса регистров UART нужно уточнить из bootlog!

#define UART_BASE 0x10400000  // ВРЕМЕННЫЙ АДРЕС
#define UART_TX   (UART_BASE + 0x00)
#define UART_LSR  (UART_BASE + 0x14)

void uart_putc(char c) {
    volatile int *lsr = (volatile int *)UART_LSR;
    while (!(*lsr & 0x20)); 
    
    volatile char *tx = (volatile char *)UART_TX;
    *tx = c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

int main() {
    uart_puts("Hello from bare metal BCM7405!\n");
    uart_puts("CosmOS is booting...\n");
    
    while (1) {
        // Бесконечный цикл
    }
    
    return 0;
}
EOF

# 5. Пишем linker.ld (С метками BSS)
echo "📝 Создаём linker.ld..."
cat << 'EOF' > tools/linker.ld
ENTRY(_start)

SECTIONS
{
    . = 0x80000000; /* Начало RAM */
    
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    __bss_start = .;
    .bss : {
        *(.bss)
        *(COMMON)
    }
    __bss_end = .;
}
EOF

# 6. Пишем Makefile (табы через printf)
echo "📝 Создаём Makefile..."
printf 'CROSS = mipsel-linux-gnu-\nCC = $(CROSS)gcc\nLD = $(CROSS)ld\nOBJCOPY = $(CROSS)objcopy\n\nCFLAGS = -march=mips32 -mno-abicalls -fno-pic -nostdlib -ffreestanding -O2\nLDFLAGS = -T tools/linker.ld -nostdlib\n\nall: kernel.bin\n\nkernel.elf: src/start.o src/main.o\n\t$(LD) $(LDFLAGS) $^ -o $@\n\nkernel.bin: kernel.elf\n\t$(OBJCOPY) -O binary $< $@\n\nsrc/start.o: src/start.S\n\t$(CC) $(CFLAGS) -c $< -o $@\n\nsrc/main.o: src/main.c\n\t$(CC) $(CFLAGS) -c $< -o $@\n\nclean:\n\trm -f src/*.o kernel.elf kernel.bin\n\n.PHONY: all clean\n' > Makefile

# 7. Проверка HDD (безопасная диагностика)
echo "💾 Проверяем HDD..."
if [ -b /dev/sda ]; then
    echo "✅ HDD /dev/sda найден"
    sudo smartctl -H /dev/sda 2>/dev/null || echo "⚠️ Не удалось проверить SMART (нужен root)"
else
    echo "ℹ️ HDD не обнаружен. Система будет работать в режиме RAM-only."
fi

echo ""
echo "✅ Проект создан в ~/motorola-os"
echo "👉 Следующие шаги:"
echo "   cd ~/motorola-os"
echo "   make"
echo ""
echo "⚠️ ВАЖНО: Адрес UART (0x10400000) временный!"
echo "   После подключения к консоли уточни адреса через bootlog."
