
class ImageLoader:
  @staticmethod
  def load_image(filename, soc):
    min_address = 0
    min_addr_init = False
    soc_ram_size_in_bytes = soc.get_soc_ram_size()
    # allocate array of zeroes
    bytes_to_write = ["00"] * soc_ram_size_in_bytes
    words_to_write = []
    words_to_read = []
    data = map(lambda x: x.strip(), open(filename, "r").readlines())
    # update the array
    address = 0
    for line in data:
        if line[0] == '@':
            address = int(line[1:], 16)
            if not min_addr_init:
                min_address = address
                min_addr_init = True
            if min_addr_init >= address:
                min_address = address
        else:
            bytes_split = line.split()
            for byte in range(0, len(bytes_split)):
                bytes_to_write[address] = bytes_split[byte]
                address += 1
    soc._min_address = min_address
    # write the whole memory
    for k in range(0, len(bytes_to_write), 4):
        word = int("".join(bytes_to_write[k:k+4][::-1]), 16)
        words_to_write.append(word)

    address = 0
    for word in words_to_write:
        soc.write_word_ram(address, word)
        address += 4

    for addr in range(0, soc_ram_size_in_bytes, 4):
        word = soc.read_word_ram(addr)
        words_to_read.append(word)

#    assert(len(words_to_write) == len(words_to_read))
#    for idx in range(len(words_to_write)):
#        if words_to_write[idx] != words_to_read[idx]:
#            print("Data mismatch!")
#            print("Written 0x{:08X}, read 0x{:08X}".format(words_to_write[idx],  words_to_read[idx]))
#        assert(words_to_write[idx] == words_to_read[idx])
    assert(words_to_write == words_to_read)
