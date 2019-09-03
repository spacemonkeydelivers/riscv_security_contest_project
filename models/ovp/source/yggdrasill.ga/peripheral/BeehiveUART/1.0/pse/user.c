/*
 * Copyright (c) 2005-2019 Imperas Software Ltd., www.imperas.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */


////////////////////////////////////////////////////////////////////////////////
//
//                W R I T T E N   B Y   I M P E R A S   I G E N
//
//                             Version 20190628.0
//
////////////////////////////////////////////////////////////////////////////////

#include "pse.igen.h"
#include <string.h>

#define PREFIX "UART"

////////////////////////////////    Callbacks   ////////////////////////////////

PPM_NBYTE_READ_CB(FifoRead) {
    // YOUR CODE HERE (FifoRead)
    Uns32 i;
    Uns8 *p = (Uns8*)&(port0_Reg_data.Fifo.value);
    Uns8 *q = (Uns8*)data;
    for(i =0; i < bytes; i++) {
        *q++ = *p++;
    }
}

PPM_NBYTE_READ_CB(RxDataRead) {
    // YOUR CODE HERE (RxDataRead)
    Uns32 i;
    Uns8 *p = (Uns8*)&(port0_Reg_data.RxData.value);
    Uns8 *q = (Uns8*)data;
    for(i =0; i < bytes; i++) {
        *q++ = *p++;
    }
}

PPM_NBYTE_READ_CB(SetupRead) {
    // YOUR CODE HERE (SetupRead)
    Uns32 i;
    Uns8 *p = (Uns8*)&(port0_Reg_data.Setup.value);
    Uns8 *q = (Uns8*)data;
    for(i =0; i < bytes; i++) {
        *q++ = *p++;
    }
}

PPM_NBYTE_WRITE_CB(SetupWrite) {
    // YOUR CODE HERE (SetupWrite)
    Uns32 i;
    Uns8 *p = (Uns8*)&(port0_Reg_data.Setup.value);
    Uns8 *q = (Uns8*)data;
    for(i =0; i < bytes; i++) {
        *p++ = *q++;
    }
}

PPM_NBYTE_WRITE_CB(TxDataWrite) {
    if (bytes != 1) {
        bhmMessage("F", PREFIX, 
                   "Attempt %d bytes access of TxData. Only 1 allowed.",
                   bytes);                                                           
    }
    Uns8* cptr = (Uns8*)data;
    bhmPrintf("UART write: %c\n", *cptr);

    // YOUR CODE HERE (TxDataWrite)
    Uns32 i;
    Uns8 *p = (Uns8*)&(port0_Reg_data.TxData.value);
    Uns8 *q = (Uns8*)data;
    for(i =0; i < bytes; i++) {
        *p++ = *q++;
    }
}

PPM_CONSTRUCTOR_CB(constructor) {
    // YOUR CODE HERE (pre constructor)
    periphConstructor();
    // YOUR CODE HERE (post constructor)
}

PPM_DESTRUCTOR_CB(destructor) {
    // YOUR CODE HERE (destructor)
}


PPM_SAVE_STATE_FN(peripheralSaveState) {
    bhmMessage("E", "PPM_RSNI", "Model does not implement save/restore");
}

PPM_RESTORE_STATE_FN(peripheralRestoreState) {
    bhmMessage("E", "PPM_RSNI", "Model does not implement save/restore");
}


