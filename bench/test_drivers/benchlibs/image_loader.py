
class ImageLoader:
  @staticmethod
  def load_image(filename, soc):
    print("ImageLoader::load_image: IMPLEMENT ME! IMPLEMENT ME! IMPLEMENT ME")
    print("ImageLoader::load_image: IMPLEMENT ME! IMPLEMENT ME! IMPLEMENT ME")
    print("ImageLoader::load_image: IMPLEMENT ME! IMPLEMENT ME! IMPLEMENT ME")
    print("ImageLoader::load_image: IMPLEMENT ME! IMPLEMENT ME! IMPLEMENT ME")
    print("ImageLoader::load_image: IMPLEMENT ME! IMPLEMENT ME! IMPLEMENT ME")

    soc_ram_size_in_bytes = soc.get_soc_ram_size()
    # allocate array of zeroes
    data_to_write = "00" * soc_ram_size_in_bytes
    data = map(lambda x: x.strip(), open(path_to_image, "r").readlines())
    # update the array
    address = 0
    for line in data:
        if line[0] == '@':
            address = int(line[1:], 16)
        else:
            bytes_split = line.split()
            for byte in range(0, len(bytes_split)):
                data_to_write[address] = byte
                address += 1
    # write the whole memory
    address = 0
    for k in range(0, len(data_to_write), 4):
        word = int("".join(b[k:k+4][::-1]), 16)
        soc.write_word(address, word)
        read_word = soc.read_word(address)
        assert(word == read_word)
        address += 4
