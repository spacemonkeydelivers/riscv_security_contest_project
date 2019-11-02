find_package(Python2 COMPONENTS Interpreter Development)
message("-- Checking that all required python libraries are installed...")
execute_process(
    COMMAND "${Python2_EXECUTABLE}" -uB "${CMAKE_SOURCE_DIR}/cmake/checks/python.py"
    RESULT_VARIABLE "PYTHON_LIBS_CHECKED")

if (NOT ${PYTHON_LIBS_CHECKED} EQUAL 0)
    message(FATAL_ERROR "could not detect the required python libraries")
endif()

find_package(Boost COMPONENTS python)

