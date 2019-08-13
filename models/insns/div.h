#pragma once
#include <iostream>
#include <tuple>

#include "testbench.h"

template <bool isSigned>
class DivModel
{
private:
    static constexpr Unsigned getMagnitude(Signed x)
    {
        return isSigned ? ((x & kSignBit) ? - Signed (x) : Signed (x)) : Unsigned (x);
    }

    static constexpr bool belowZero(Unsigned x)
    {
        return isSigned && (Signed (x) < 0);
    }

    // returns tuple<quotient, remainder>
    template <bool print>
    std::tuple <Unsigned, Unsigned> stepdiv(Unsigned a, Unsigned b)
    {
        // check for 0
        m_statCycles++;

        // division by zero - see RISC-V ISA
        if (b == 0)
        {
            return {-1, a};
        }

        // overflow - see RISC-V ISA
        if (isSigned && (b == -1) && (a == kSignBit))
        {
            return {kSignBit, 0};
        }

        // we use the same subractor for a and b, so -a or -b can be
        // received only in different cycles.
        // However, if both a and b are positive than no additional cycles are required
        bool sign = belowZero (a) != belowZero (b);

        Unsigned dividend = getMagnitude (a);
        m_statCycles++;

        Unsigned divisor = getMagnitude (b);
        m_statCycles++;

        Unsigned result = 0;

        // it is possible to replace one-hot encoding of 'order'
        // with some sealed encoding
        Unsigned order = 1;

        if (print)
        {
            std::cout << "Test : " << dividend << " / " << divisor << std::endl;
        }

        // normalization loop
        // Other option: while (!(divisor & (1u << 31)))
        while ((dividend > divisor) && !(divisor & kSignBit))
        {
            order = order << 1;
            divisor = divisor << 1;
            m_statCycles++;
        }

        if (print)
        {
            std::cout << "order = " << order << std::endl;
        }

        // main loop
        do
        {
            if (print)
            {
                std::cout << "test:" << dividend << " - " << divisor << std::endl;
            }
            // comparison and subtraction are single operation
            if (dividend >= divisor)
            {
                if (print)
                {
                    std::cout << "sub:" << dividend << " - " << divisor <<
                        " ==> " << dividend - divisor << std::endl;
                }
                dividend -= divisor;
                result |= order;
            }
            divisor = divisor >> 1;
            order = order >> 1u;
            m_statCycles++;
            if (print)
            {
                std::cout << "order:" << order << std::endl;
            }
        }
        while (order);

        result = sign ? -result : result;
        m_statCycles++;

        if (print)
        {
            std::cout << a << " / " << b << " = " << result << std::endl;
        }
        return {result, dividend};
    }

    template <class D>
    bool internalCheck(const D a, const D b)
    {
        bool overflow = isSigned && (a == kSignBit) && (b == ~0);
        bool byZero = b == 0;
        const auto result = overflow ? 0x80000000 :
            (b == 0) ? ~0 :
            a / b;
        const auto remainder = overflow ? 0 :
            byZero ? a :
            a % b;

        auto [checkDiv, checkRem] = stepdiv<false> (a, b);
        if (result != checkDiv)
        {
            stepdiv <true> (a, b);
            std::cout << a << " / " << b << " = " << checkDiv << " -> " << result << std::endl;
            return false;
        }
        return true;
    }
public:
    bool check(const Unsigned op1, const Unsigned op2)
    {
        return isSigned ?
            internalCheck <Signed> (op1, op2) :
            internalCheck <Unsigned> (op1, op2);
    }

    Counter cycles() const
    {
        return m_statCycles;
    }

private:
    Counter m_statCycles {0};
};
