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

#pragma once

#include "ovpworld.org/modelSupport/tlmProcessor/1.0/tlm/tlmProcessor.hpp"
#include "ovpworld.org/modelSupport/tlmBusPort/1.0/tlm/tlmBusPort.hpp"
#include "ovpworld.org/modelSupport/tlmNetPort/1.0/tlm/tlmNetPort.hpp"

using namespace sc_core;
using namespace cw;

class riscv_RV64GCN : public tlmProcessor
{
  private:
    params paramsForProc(params p) {
        p.set("variant", "RV64GCN");
        return p;
    }

    const char *getModel() {
        return opVLNVString (NULL, "riscv.ovpworld.org", "processor", "riscv", "1.0", OP_PROCESSOR, 1);
    }

  public:
    tlmBusMasterPort     INSTRUCTION;
    tlmBusMasterPort     DATA;
    tlmNetInputPort      reset;
    tlmNetInputPort      nmi;
    tlmNetInputPort      USWInterrupt;
    tlmNetInputPort      SSWInterrupt;
    tlmNetInputPort      MSWInterrupt;
    tlmNetInputPort      UTimerInterrupt;
    tlmNetInputPort      STimerInterrupt;
    tlmNetInputPort      MTimerInterrupt;
    tlmNetInputPort      UExternalInterrupt;
    tlmNetInputPort      SExternalInterrupt;
    tlmNetInputPort      MExternalInterrupt;

    riscv_RV64GCN(tlmModule &parent, sc_module_name name)
    : tlmProcessor(parent, getModel(), name)
    , INSTRUCTION (parent, this, "INSTRUCTION", 56)
    , DATA (parent, this, "DATA", 56)
    , reset(parent, this, "reset")
    , nmi(parent, this, "nmi")
    , USWInterrupt(parent, this, "USWInterrupt")
    , SSWInterrupt(parent, this, "SSWInterrupt")
    , MSWInterrupt(parent, this, "MSWInterrupt")
    , UTimerInterrupt(parent, this, "UTimerInterrupt")
    , STimerInterrupt(parent, this, "STimerInterrupt")
    , MTimerInterrupt(parent, this, "MTimerInterrupt")
    , UExternalInterrupt(parent, this, "UExternalInterrupt")
    , SExternalInterrupt(parent, this, "SExternalInterrupt")
    , MExternalInterrupt(parent, this, "MExternalInterrupt")
    {
    }

    riscv_RV64GCN(tlmModule &parent, sc_module_name name, params p, Uns32 INSTRUCTIONWidth=56, Uns32 DATAWidth=56)
    : tlmProcessor(parent, getModel(), name, paramsForProc(p))
    , INSTRUCTION (parent, this, "INSTRUCTION", INSTRUCTIONWidth)
    , DATA (parent, this, "DATA", DATAWidth)
    , reset(parent, this, "reset")
    , nmi(parent, this, "nmi")
    , USWInterrupt(parent, this, "USWInterrupt")
    , SSWInterrupt(parent, this, "SSWInterrupt")
    , MSWInterrupt(parent, this, "MSWInterrupt")
    , UTimerInterrupt(parent, this, "UTimerInterrupt")
    , STimerInterrupt(parent, this, "STimerInterrupt")
    , MTimerInterrupt(parent, this, "MTimerInterrupt")
    , UExternalInterrupt(parent, this, "UExternalInterrupt")
    , SExternalInterrupt(parent, this, "SExternalInterrupt")
    , MExternalInterrupt(parent, this, "MExternalInterrupt")
    {
    }

    void before_end_of_elaboration() {
        DATA.bindIfNotBound();
    }

    void dmi(bool on) {
        INSTRUCTION.dmi(on);
        DATA.dmi(on);
    }
}; /* class riscv_RV64GCN */

