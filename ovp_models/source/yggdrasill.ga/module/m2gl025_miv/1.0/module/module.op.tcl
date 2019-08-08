# Binary Translator Bedouins were here
#
# yggdrasill.ga
#

#### PLATFORM
set vendor yggdrasill.ga
set library module
set name m2gl025_miv
set version 1.0

ihwnew -name $name -vendor $vendor -library $library -version $version -purpose module

iadddocumentation -name Licensing   -text "No license"
iadddocumentation -name Description -text "IGLOO2 M2GL025 Creative Development Board."
iadddocumentation -name Description -text "The processor is MiV Soft Core (RISCV)."
iadddocumentation -name Limitations -text "Designed to boot Zephyr OS v1.14.1-rc1"

#### Memory map
# plic@40000000     reg = <0x0 0x40000000 0x0 0x04000000>;
# timer@4400bff8    reg = <0x0 0x4400bff8 0x0 0x00000008>;
# timercmp@44004000 reg = <0x0 0x44004000 0x0 0x00000008>;
# uart0@70001000    reg = <0x0 0x70001000 0x0 0x00000018>;
# flash@80000000    reg = <0x0 0x80000000 0x0 0x00040000>;
# sram0@80040000    reg = <0x0 0x80040000 0x0 0x00040000>;

#### PROCESSOR
ihwaddprocessor \
  -instancename hart0 \
  -vendor microsemi.ovpworld.org \
  -library processor \
  -type riscv \
  -version 1.0 \
  -variant MiV_RV32IMA

ihwaddbus \
  -instancename bus0 -addresswidth 32

ihwconnect \
  -bus bus0 -instancename hart0 -busmasterport INSTRUCTION

ihwconnect \
  -bus bus0 -instancename hart0 -busmasterport DATA

#### MEMORY
# FLASH
set flash0_lo  0x80000000
set flash0_sz     0x40000
set flash0_hi [expr $flash0_lo + $flash0_sz - 1]

ihwaddmemory \
  -instancename flash0 -type ram

ihwconnect \
  -bus bus0 -instancename flash0 -busslaveport sp1 \
  -loaddress $flash0_lo -hiaddress $flash0_hi

# SRAM0
set sram0_lo 0x80040000
set sram0_sz    0x40000
set sram0_hi [expr $sram0_lo + $sram0_sz - 1]

ihwaddmemory \
  -instancename sram0 -type ram

ihwconnect \
  -bus bus0 -instancename sram0 -busslaveport sp1 \
  -loaddress $sram0_lo -hiaddress $sram0_hi

#### PERIPHERAL
# PLIC
set plic_lo 0x40000000
set plic_sz  0x4000000
set plic_hi [expr $plic_lo + $plic_sz - 1]

ihwaddperipheral \
  -instancename plic -type PLIC \
  -vendor riscv.ovpworld.org -library peripheral -version 1.0

ihwconnect \
  -instancename plic -busslaveport port0 -bus bus0 \
  -loaddress $plic_lo -hiaddress $plic_hi

ihwsetparameter \
  -handle plic -name num_priorities -value 11 -type uns32

# UART0
set uart0_lo 0x70001000
set uart0_sz       0x18
set uart0_hi [expr $uart0_lo + $uart0_sz - 1]

ihwaddperipheral \
  -instancename uart0 -type CoreUARTapb \
  -vendor microsemi.ovpworld.org -library peripheral -version 1.0

ihwconnect \
  -instancename uart0 -busslaveport port0 -bus bus0 \
  -loaddress $uart0_lo -hiaddress $uart0_hi

set lol_port 5000
ihwsetparameter -handle uart0 -name portnum            -value $lol_port -type uns32
ihwsetparameter -handle uart0 -name finishOnDisconnect -value True      -type bool

# TIMER STUBS
ihwaddmemory \
  -instancename timer0 -type ram

ihwconnect \
  -bus bus0 -instancename timer0 -busslaveport sp1 \
  -loaddress 0x4400bff8 -hiaddress 0x4400bfff

ihwaddmemory \
  -instancename timercmp0 -type ram

ihwconnect \
  -bus bus0 -instancename timercmp0 -busslaveport sp1 \
  -loaddress 0x44004000 -hiaddress 0x44004008
