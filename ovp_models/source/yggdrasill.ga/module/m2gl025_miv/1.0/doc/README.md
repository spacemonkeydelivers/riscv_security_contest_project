# Microsemi Creative Development Board module

This model is designed to mimic M2GL025 board with MiV Soft Core RISCV
processor. This model can boot Zephyr.

# Zephyr build

Zephyr already has M2GL025 board in presets. Please, follow [wiki](https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv_core/wikis/Building-Zephyr), then select `m2gl025_miv` as target board: 

```
west build -b m2gl025_miv samples/hello_world
```

# OVP run

Our own VLNV model library is not ready yet. You can copy the folder with the
model and build it manually with just `make`. Then:

```
harness.exe --modulefile model.so --program zephyr.elf
```

Hello world sample builded for M2GL025 board waits for connection to UART.
The model is configured so that it's possible to connect with telnet to "UART"
module. Just run `telnet localhost 5000` in other console window.

There are many parametres that can be overridden. To show all use:

```
harness.exe --modulefile model.so --showoverrides --nosimulation
```

To use override:

```
harness.exe --modulefile model.so --program zephyr.elf \
  --override m2gl025_miv/uart0/portnum=5001 \
  
```
