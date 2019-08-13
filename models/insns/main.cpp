#include "div.h"
#include "testbench.h"

int main()
{
    Testbench<DivModel <true>> ().runTestbench ();
    Testbench<DivModel <false>> ().runTestbench ();
}
