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

#ifndef RISCV_OVPWORLD_ORG_PROCESSOR_RISCV_RV64GCN__1_0
#define RISCV_OVPWORLD_ORG_PROCESSOR_RISCV_RV64GCN__1_0

#include "ovpworld.org/modelSupport/tlmProcessor/1.0/tlm2.0/tlmProcessor.hpp"
using namespace sc_core;

class riscv_RV64GCN : public icmCpu
{
  private:
    const char *getModel() {
        return icmGetVlnvString (NULL, "riscv.ovpworld.org", "processor", "riscv", "1.0", "model");
    }

  public:
    icmCpuMasterPort     INSTRUCTION;
    icmCpuMasterPort     DATA;
    icmCpuInterrupt      reset;
    icmCpuInterrupt      nmi;
    icmCpuInterrupt      USWInterrupt;
    icmCpuInterrupt      SSWInterrupt;
    icmCpuInterrupt      MSWInterrupt;
    icmCpuInterrupt      UTimerInterrupt;
    icmCpuInterrupt      STimerInterrupt;
    icmCpuInterrupt      MTimerInterrupt;
    icmCpuInterrupt      UExternalInterrupt;
    icmCpuInterrupt      SExternalInterrupt;
    icmCpuInterrupt      MExternalInterrupt;

    riscv_RV64GCN(
        sc_module_name        name,
        const unsigned int    ID,
        icmNewProcAttrs       attrs         = ICM_ATTR_DEFAULT,
        icmAttrListObject    *attrList      = NULL,
        const char           *semiHost      = NULL,
        Uns32                 addressBits   = 32,
        bool                  dmi           = true,
        Uns32                 cpuFlags      = 0,
        double                mips          = 100
     )
    : icmCpu(name, ID, "riscv", getModel(), 0, semiHost, attrs, attrList, addressBits, dmi, cpuFlags, mips)
    , INSTRUCTION (this, "INSTRUCTION", 56)
    , DATA (this, "DATA", 56)
    , reset("reset", this)
    , nmi("nmi", this)
    , USWInterrupt("USWInterrupt", this)
    , SSWInterrupt("SSWInterrupt", this)
    , MSWInterrupt("MSWInterrupt", this)
    , UTimerInterrupt("UTimerInterrupt", this)
    , STimerInterrupt("STimerInterrupt", this)
    , MTimerInterrupt("MTimerInterrupt", this)
    , UExternalInterrupt("UExternalInterrupt", this)
    , SExternalInterrupt("SExternalInterrupt", this)
    , MExternalInterrupt("MExternalInterrupt", this)
    {
    }

    void before_end_of_elaboration() {
        DATA.bindIfNotBound();
    }

    void dmi(bool on) {
        m_dmi = on;
        if(!on) {
            INSTRUCTION.invalidateDMI();
            DATA.invalidateDMI();
        }
    }
}; /* class riscv_RV64GCN */

#endif
