#include <boost/python.hpp>
#include <boost/python/enum.hpp>


#include <iostream>

#include "include/fpga.h"

BOOST_PYTHON_MODULE(libbench)
{
    using namespace boost::python;

    class_<skFpga>("skFpga", init<const char*>())
        .def("uploadBitstream", &skFpga::UploadBitstream)
        .def("writeShort", &skFpga::WriteShort)
        .def("readShort", &skFpga::ReadShort)
        .def("setReset", &skFpga::SetResetPin)
        .def("getReset", &skFpga::GetResetPin)
        .def("setIRQ", &skFpga::SetIRQPin)
        .def("getIRQ", &skFpga::GetIRQPin);
}

