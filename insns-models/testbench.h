#pragma once

#include <iostream>
#include <random>

typedef int Signed;
typedef unsigned Unsigned;
constexpr Unsigned kSignBit = 1 << 31;
constexpr Unsigned kMask = 0x1F;
typedef long Counter;

template <class P>
class Testbench
{
public:
    constexpr static long kCombinations = 100000000;

private:
    template <class G>
    Unsigned rnd(G& gen)
    {
        auto type = gen ();
        switch (type & 0x3FF)
        {
            case 0x0:
                m_last = gen () & (1 << (gen () & kMask) - 1);
                break;

            case 0x1:
                m_last = 0x0;
                break;


            case 0x2:
                m_last = kSignBit;
                break;


            case 0x3:
                m_last = ~Unsigned (0);
                break;


            case 0x4:
                m_last = Unsigned (1);
                break;

            case 0x5:
                // keep last!
                break;

            default:
                m_last = gen ();
                break;

        }
        return m_last;
    }

    template <class G>
    Signed rndA(G& gen)
    {
        return rnd (gen);
    }

    template <class G>
    Signed rndB(G& gen)
    {
        return rnd (gen);
    }

public:
    void runTestbench()
    {
        Counter statCycles = 0;
        for (Counter i = 0; i < kCombinations; i++)
        {
            P binop;
            auto a = rndA (m_genA);
            auto b = rndB (m_genB);

            if (!binop.check (a, b))
            {
                m_statErrors++;
            }
            statCycles += binop.cycles ();
        }

        std::cout << "total errors = " << m_statErrors << std::endl;
        std::cout << "average cycle count " << statCycles / double (kCombinations) << std::endl;
    }

private:
    long m_statErrors {};
    std::mt19937_64 m_genA {0x123};
    std::mt19937_64 m_genB {0x345};
    Unsigned m_last;
};
