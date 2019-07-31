#include <boost/python.hpp>

#include <iostream>

#include "soc.h"

BOOST_PYTHON_MODULE(libbench)
{
    using namespace boost::python;
    class_<RV_SOC>("RV_SOC", init<const char*>())
        .def("tick", &RV_SOC::tick)
        .def("reset", &RV_SOC::reset)
        .def("writeWord", &RV_SOC::writeWord)
        .def("readWord", &RV_SOC::readWord)
        .def("ramSize", &RV_SOC::getRamSize)
        .def("wordSize", &RV_SOC::getWordSize);
                                    ;
}

