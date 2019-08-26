# Memory tagging Extention

**Disclaimer:** The design of this extension is "heavily inspired" (it's
actially a rip-off with cosmetic changes) by "Armv8.5 Memory Tagging Extension"
(see ARM ARM, chapter D6).

## Introduction

The idea of Memory Tagging Extention is that physical memory locations can be
marked (**tagged**) with a number (a tag) and this number becomes the property
of this memory location. A good analogy would be that we can mark a memory
location with a certain "color". Every operation which accesses the memory is
extended in such a way that along with the address of a location we can specify
the expected "color" (tag) of the physical location being accessed. Is the
expected color (tag) does not match the actual one - a security violation is
detected in the form of a synchronous or asynchronous exception. 

In our implementation, the granularity with which we can mark (tag) physical
locations of memory is a sequence of 16 naturally-aligned bytes. Such minimal
taggable locations are called "**tag granule**". The tags which are used to
mark the physical locations are stored in a dedicated memory which is
accessible only by special instructions (load/store tag: **lt**/**st**) -
ordinary instructions can't access this memory. 

In order to extend the existing memory operations to be able to associate the
expected tag with memory access performed the following technique is used. The
**tag** is encoded in the virtual address of the memory reference, like this:
```
VA (32-bit) looks as follows:
 |31:30 | 29:26 | 25:0|
 | PASS |  TAG  |  LA |
- PASS: physical address space select. Can be used (depending on a situation
        and/or chip configuration) as either auxiliary bits to logical address
        or as an "address space identifier" to enable access to peripheral devices.
- TAG:  bits 29:26 contain the expected memory tag (color) of the performed memory reference
- LA:   logical address (aka virtual on systems with virtual memory).
```
The described scheme also implies that when memory tagging extension is
activated our hart can address up to 32 MB of memory (more if PASS bits are
used as an extension the LA).

## ISA changes / HW features 

**Control interface:** non-standard CSR "tags".
```
name: tags
id: 0x345
fields:
| ... |   2    |  1   |   0   |
|     | ICEN   | IACK |  LSEN |
- ICEN: enables tag checking on instruction fetch
- IACK: write of a non-zero value acknowledges pending "Secure Monitor Panic" interrupt.
- LSEN: enables tag checkin on load/store operation.
```
**New Interrupt:** "Secure Monitor Panic"
```
name: "Secure Monitor Panic"
mcause: 0x8000_0010
Once signal becomes pending requires to be acknowledged by writing "1" to tags[IACK].
```
**New Instructions:** **lt** (load tags), **st** (store tags).

- **lt** operation:
```
mnemonic: lt
format: lt dst, (offset)[base]
```
Used to load a tag for a particular granule from tag memory. Semantically is
similar to load instruction. The address of the lt should correspond to the
granule address, loading register would contain the desired tag value in lower
4 bits.

- **st** operation:
```
mnemonic: st
format: st src, (offset)[base]
```
Used to store a tag for a particular granule into tag memory. Semantically is
similar to store instructions. The address of the st should correspond to the
granule address, storing register should contain the desired tag to be stored
in lower 4 bits.

