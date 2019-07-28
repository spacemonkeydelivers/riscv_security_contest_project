#include <boost/python.hpp>

#include <iostream>

#include "soc.h"

BOOST_PYTHON_MODULE(libbench)
{
    using namespace boost::python;
    class_<RV_SOC>("RV_SOC", init<const char*>())
        .def("tick", &RV_SOC::tick)
        .def("reset", &RV_SOC::reset)
        .def("dumpRam", &RV_SOC::dumpRam);
                                    ;
}

