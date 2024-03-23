# Creates a Hou-style rom file from an existing folder structure.

load './toolkit.rb'

f = KalRom2File.new(0x322a00, 1, 0)

# Arguments:
# 1. folder containing files to be packed
# 2. location where the rom file will be written
source_folder, target = ARGV

f.files = load_packed_file_from_folder_recursive(source_folder).content
f.write(target)
