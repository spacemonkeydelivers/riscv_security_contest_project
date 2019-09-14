#include <boost/python.hpp>
#include <boost/python/enum.hpp>


#include <iostream>

#include <platform/soc_enums.h>

#include "soc.h"

BOOST_PYTHON_MODULE(libbench)
{
    using namespace boost::python;

#define D_GENERATE_SOC_ENUMS
    #include <platform/soc_enums.h>

    class_<RV_SOC>("RV_SOC", init<const char*>())
        .def("tick", &RV_SOC::tick)
        .def("reset", &RV_SOC::reset)
        .def("writeWord", &RV_SOC::writeWord)
        .def("readWord", &RV_SOC::readWord)
        .def("ramSize", &RV_SOC::getRamSize)
        .def("regFileSize", &RV_SOC::getRegFileSize)
        .def("writeReg", &RV_SOC::writeReg)
        .def("readReg", &RV_SOC::readReg)
        .def("PC", &RV_SOC::getPC)
        .def("setPC", &RV_SOC::setPC)
        .def("readTxByte", &RV_SOC::getUartTxData)
        .def("uartTxValid", &RV_SOC::validUartTxTransaction)
        .def("pcValid", &RV_SOC::validPc)
        .def("cpuState", &RV_SOC::cpu_state)
        .def("switchBusMasterToExternal", &RV_SOC::switchBusMasterToExternal)
        .def("toggleCpuReset", &RV_SOC::toggleCpuReset)
        .def("writeWordExt", &RV_SOC::writeWordExt)
        .def("readWordExt", &RV_SOC::readWordExt)
        .def("enableVcdTrace", &RV_SOC::enableVcdTrace)
        .def("counterGetTick", &RV_SOC::counterGetTick)
        .def("counterGetStep", &RV_SOC::counterGetStep)
        .def("wordSize", &RV_SOC::getWordSize);
}

