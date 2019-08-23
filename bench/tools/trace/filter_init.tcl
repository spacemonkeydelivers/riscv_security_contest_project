# This code left here as an example
# Some parts of it may be useful in the future
#
# set nfacs [ gtkwave::getNumFacs ]
# set dumpname [ gtkwave::getDumpFileName ]
# set dmt [ gtkwave::getDumpType ]
#
# puts "number of signals in dumpfile '$dumpname' of type $dmt: $nfacs"
#
# set clk48 [list]
#
# for {set i 0} {$i < $nfacs } {incr i} {
#     set facname [ gtkwave::getFacName $i ]
#     set indx [ string first opcode $facname ]
#     if {$indx != -1} {
#         puts "num: '$indx'"
#         set num_added [ gtkwave::addSignalsFromList $facname ]
#     puts "added: $num_added"
#         set num_hi [ gtkwave::highlightSignalsFromList $facname ]
#         puts "highlighted: $num_hi"
#     set num_file [ gtkwave::setCurrentTranslateFile ./filter ]
#     puts "file: $num_file"
#         set num_install [ gtkwave::installFileFilter $num_file ]
#         puts "installed: $num_install"
#     gtkwave::/Edit/Data_Format/Enum
#     }
# }


set disasm_file [ gtkwave::setCurrentTranslateFile ./filters/DISASM.flt ]
gtkwave::installFileFilter $disasm_file

set cause_file [ gtkwave::setCurrentTranslateFile ./filters/EN_MCAUSE.flt ]
gtkwave::installFileFilter $cause_file

set opcode_file [ gtkwave::setCurrentTranslateFile ./filters/EN_OPCODE.flt ]
gtkwave::installFileFilter $opcode_file

set state_file [ gtkwave::setCurrentTranslateFile ./filters/EN_STATE.flt ]
gtkwave::installFileFilter $state_file
