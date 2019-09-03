# Binary Translator Bedouins were here
#
# yggdrasill.ga
#

#### PLATFORM
set vendor yggdrasill.ga
set library module
set name beehive_riscv32
set version 1.0

ihwnew -name $name -vendor $vendor -library $library -version $version -purpose module

iadddocumentation -name Licensing   -text "No license"
iadddocumentation -name Description -text "The operating system Paradise"

#### Memory map
# sram0@00000000 reg = <0x0 0x00000000 0x0 0x40000000>;
# timer@40000000 reg = <0x0 0x40000000 0x0 0x00000018>;
# uart0@80000000 reg = <0x0 0x80000000 0x0 0x40000000>;

#### PROCESSOR
ihwaddprocessor \
  -instancename hart0 \
  -vendor yggdrasill.ga \
  -library processor \
  -type riscv \
  -variant RV32IMC \
  -version 1.0

ihwaddbus \
  -instancename bus0 -addresswidth 32

ihwconnect \
  -bus bus0 -instancename hart0 -busmasterport INSTRUCTION

ihwconnect \
  -bus bus0 -instancename hart0 -busmasterport DATA

#### MEMORY
# SRAM0
set sram0_lo 0x00000000
set sram0_sz 0x40000000
set sram0_hi [expr $sram0_lo + $sram0_sz - 1]

ihwaddmemory \
  -instancename sram0 -type ram

ihwconnect \
  -bus bus0 -instancename sram0 -busslaveport sp1 \
  -loaddress $sram0_lo -hiaddress $sram0_hi

#### PERIPHERAL
# UART0
set uart0_lo 0x80000000
set uart0_sz       0x18
set uart0_hi [expr $uart0_lo + $uart0_sz - 1]

ihwaddperipheral \
  -instancename uart0 -type BeehiveUART \
  -vendor yggdrasill.ga -library peripheral -version 1.0

ihwconnect \
  -instancename uart0 -busslaveport port0 -bus bus0 \
  -loaddress $uart0_lo -hiaddress $uart0_hi

# TIMER STUB
set timer0_lo 0x40000000
set timer0_sz 0x40000000
set timer0_hi [expr $timer0_lo + $timer0_sz - 1]

ihwaddmemory \
  -instancename timer0 -type ram

ihwconnect \
  -bus bus0 -instancename timer0 -busslaveport sp1 \
  -loaddress $timer0_lo -hiaddress $timer0_hi
