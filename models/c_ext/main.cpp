#include <iostream>
#include <cstdint>
#include <vector>


enum class en_state {
    prefetch,
    fetch_word,
    fetch_more,
    decode32,
    decode16,
    exec,
};

std::ostream& operator << (std::ostream& s, en_state state) {
    switch (state) {
    case en_state::decode32:
        s << "decode32";
        break;
    case en_state::decode16:
        s << "decode16";
        break;
    case en_state::prefetch:
        s << "prefetch";
        break;
    case en_state::fetch_word:
        s << "fetch_word";
        break;
    case en_state::fetch_more:
        s << "fetch_more";
        break;
    case en_state::exec:
        s << "exec";
        break;
    default:
        s << "unknown";
    }
    return s;
}

enum class itype {
    fetch4,
    fetch2_0,
    fetch2_1,
    fetch2_2,
};

class CpuContext {

public:
    typedef std::vector<std::uint32_t> t_mem;
    bool exec(t_mem& mem);

private:
    bool _do_fetch(t_mem& mem);
    bool _do_more(t_mem& mem);
    bool _do_exec(t_mem& mem);
    bool _do_decode32(t_mem& mem);
    bool _do_decode16(t_mem& mem);
    bool _do_prefetch(t_mem& mem);

private:
    std::uint32_t pc_ = 0;
    std::uint32_t next_pc_ = 0;
    std::uint32_t decode_slot_;
    std::uint16_t parcel_low_;
    std::uint16_t parcel_high_;
    std::uint32_t fetched_data_;
    bool reuse_high_ = false;
    en_state state_ = en_state::fetch_word;
};

bool CpuContext::exec(std::vector<std::uint32_t>& mem) {
    if (state_ == en_state::prefetch) {
        std::cout << "\n";
    }
    std::cout << "tick: " << state_ << "\n";
    switch(state_) {
    case en_state::fetch_word:
        if (pc_ >= mem.size()) {
            return false;
        }
        return _do_fetch(mem);
    case en_state::fetch_more:
        return _do_more(mem);
    case en_state::exec:
        return _do_exec(mem);
    case en_state::prefetch:
        return _do_prefetch(mem);
    case en_state::decode16:
        return _do_decode16(mem);
    case en_state::decode32:
        return _do_decode32(mem);
    default:
        std::cerr << "FATAL ERROR";
        std::exit(42);
    }
    return false;
}
bool CpuContext::_do_decode32(t_mem& mem) {
    state_ = en_state::exec;
    std::cout << "   decode_slot(32): 0x" << std::hex << decode_slot_ << "\n";
    next_pc_ = pc_ + 1;
    return true;
}
bool CpuContext::_do_decode16(t_mem& mem) {
    state_ = en_state::exec;
    std::cout << "   decode_slot(16): 0x" << std::hex << decode_slot_ << "\n";
    return true;
}
bool CpuContext::_do_fetch(t_mem& mem) {
    fetched_data_ = mem.at(pc_);
    parcel_low_  = fetched_data_ & 0xffff;
    parcel_high_ = fetched_data_ >> 16;
    std::cout << " pc: " << std::dec << pc_ << ", fetched_data: 0x" <<
        std::hex << fetched_data_ << "\n";

    if (parcel_low_ == 0x3) {
        decode_slot_ = fetched_data_;
        reuse_high_ = false;
        state_ = en_state::decode32;
    }
    else {
        reuse_high_ = true;
        decode_slot_ = parcel_low_;
        state_ = en_state::decode16;
    }
    return true;
}
bool CpuContext::_do_more(t_mem& mem) {
    fetched_data_ = mem.at(next_pc_);
    std::cout << " pc: " << std::dec << pc_ << ".5, fetched_data: 0x" <<
        std::hex << fetched_data_ << "\n";
    decode_slot_ = parcel_high_ | ((fetched_data_ & 0xffff) << 16);
    parcel_high_ = fetched_data_ >> 16;
    reuse_high_ = true;
    state_ = en_state::decode32;
    return true;
}
bool CpuContext::_do_exec(t_mem& mem) {
    state_ = en_state::prefetch;
    return true;
}
bool CpuContext::_do_prefetch(t_mem& mem) {
    pc_ = next_pc_;
    if (reuse_high_ && (parcel_high_ == 0x3)) {
        reuse_high_ = false;
        state_ = en_state::fetch_more;
        next_pc_ = pc_ + 1;
    }
    else if (reuse_high_) {
        std::cout << "reusing high_parcel\n";
        state_ = en_state::decode16;
        decode_slot_ = parcel_high_;
        reuse_high_ = false;
        next_pc_ = pc_ + 1;
    }
    else {
        state_ = en_state::fetch_word;
    }
    return true;
}

int main () {
    std::vector<std::uint32_t> memory;

    memory.push_back(0x00000003); //fetch4
    memory.push_back(0x00020011); //fetch2_0
    memory.push_back(0x00030001); //fetch2_0
    memory.push_back(0x00000001); //fetch2_1
    memory.push_back(0x00000002); //fetch2_2
    memory.push_back(0x00000000); //fetch2_0
    memory.push_back(0x00000001); //fetch2_1
    memory.push_back(0x00000000); //fetch2_0
    memory.push_back(0x00000003); //fetch4
    memory.push_back(0x00000001); //fetch2_0
    memory.push_back(0x00000003); //fetch4
    memory.push_back(0x00000001); //fetch2_0
    memory.push_back(0x00000003); //fetch4
    memory.push_back(0x00030001); //fetch2_0
    memory.push_back(0x00000001); //fetch2_0

    /*
       pc: 2, fetched_data: 0x30001
       pc: 4, fetched_data: 0x2
       pc: 5, fetched_data: 0x0
       pc: 6, fetched_data: 0x1
       pc: 7, fetched_data: 0x0
       pc: 8, fetched_data: 0x3
       pc: 9, fetched_data: 0x1
       pc: 10, fetched_data: 0x3
       pc: 11, fetched_data: 0x1
       pc: 12, fetched_data: 0x3
       pc: 13, fetched_data: 0x30001
    */


    CpuContext cpu;
    int counter = 0;
    while (true) {
        if (!cpu.exec(memory)) {
            break;
        }
        ++counter;
        if (counter > 100) {
            std::cout << "\naborted\n";
            std::exit(42);
        }
    }
    std::cout << "exit";
    return 0;
}
