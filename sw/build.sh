#!/bin/sh
# Assemble every sw/asm_tests/*.S into sw/compiled_hex/*.hex
# Needs a RISC-V GCC toolchain (riscv64-unknown-elf-* or riscv32-unknown-elf-*).
# Run from the sw/ folder:  sh build.sh
PFX=riscv64-unknown-elf
command -v $PFX-gcc >/dev/null 2>&1 || PFX=riscv32-unknown-elf
mkdir -p compiled_hex
for s in asm_tests/*.S; do
    n=$(basename "$s" .S)
    $PFX-gcc -march=rv32i_zicsr_zifencei -mabi=ilp32 -nostdlib -nostartfiles -Wl,-Ttext=0x0 -o compiled_hex/$n.elf "$s" || exit 1
    $PFX-objcopy -O binary compiled_hex/$n.elf compiled_hex/$n.bin
    python3 bin2hex.py compiled_hex/$n.bin compiled_hex/$n.hex
    $PFX-objdump -d compiled_hex/$n.elf > compiled_hex/$n.dump
    rm -f compiled_hex/$n.bin
    echo "built compiled_hex/$n.hex"
done
