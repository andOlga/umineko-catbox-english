import numpy
import sys

with open("exefs_texts.txt", 'r') as f:
    Offsets = [line.split("\t", -1)[0] for line in f]
    f.seek(0,0)
    Texts = [line.split("\t", -1)[1] for line in f]
    f.seek(0,0)
    TextsCheck = [line.strip("\r\n").strip("\n").split("\t", -1)[2] for line in f]

print("Validating...")

for i in range(0, len(Offsets)):
    if (len(bytes(Texts[i].encode("UTF-8"))) > len(bytes(TextsCheck[i].encode("UTF-8")))):
        print("Incorrect size. Line: %d, Max allowed: %d B, detected: %d B" % (i+1, len(bytes(TextsCheck[i].encode("UTF-8"))), len(bytes(Texts[i].encode("UTF-8")))))
        input("Press Enter to continue...")
        sys.exit()

print("Writing patch...")

with open("7616F8963DACCD70E20FF3904E13367F96F2D9B3000000000000000000000000.ips", "wb") as f:
    f.write(b"IPS32")

    with open("remove_tips_length_limit.ips", "rb") as extra:
        extra.seek(-4, 2) # EEOF
        pos = extra.tell()
        extra.seek(5) # IPS32
        extra_len = pos - 5
        extra_patch_data = extra.read(extra_len)
        f.write(extra_patch_data)
        print("Wrote", extra_len, "extra patch bytes")

    for i in range(0, len(Offsets)):
        f.write(numpy.uint32(int(Offsets[i], 16)+0x100).byteswap())
        f.write(numpy.uint16(len(Texts[i].encode("UTF-8"))+1).byteswap())
        f.write(bytes(Texts[i].encode("UTF-8")))
        f.write(numpy.uint8(0))
    f.write(b"EEOF")

print("Patch has been created.")
