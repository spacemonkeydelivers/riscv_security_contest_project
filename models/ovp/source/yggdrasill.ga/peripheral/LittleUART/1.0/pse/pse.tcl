# Binary Translator Bedouins were here
#
# yggdrasill.ga
#

set vendor yggdrasill.ga
set library peripheral
set name LittleUART
set version 1.0

imodelnewperipheral \
    -name $name \
    -imagefile pse.pse \
    -library $library \
    -vendor $vendor \
    -nbyteregisters \
    -constructor constructor \
    -destructor destructor \
    -releasestatus internal

# Slave ports
imodeladdbusslaveport -name port0 -size 0x18

imodeladdaddressblock -name Reg -port port0 -size 0x4 -offset 0 -width 8

set setup_off   0
set fifo_off    1
set tx_data_off 2
set rx_data_off 3

imodeladdmmregister -addressblock port0/Reg -name Setup \
    -width 8 -offset $setup_off \
    -access rw -writefunction SetupWrite -readfunction SetupRead \
    -nbyte

imodeladdmmregister -addressblock port0/Reg -name Fifo \
    -width 8 -offset $fifo_off \
    -access r -readfunction FifoRead \
    -nbyte

imodeladdmmregister -addressblock port0/Reg -name RxData \
    -width 8 -offset $rx_data_off \
    -access r -readfunction RxDataRead \
    -nbyte

imodeladdmmregister -addressblock port0/Reg -name TxData \
    -width 8 -offset $tx_data_off \
    -access w -writefunction TxDataWrite \
    -nbyte
