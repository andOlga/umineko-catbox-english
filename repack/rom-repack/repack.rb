# Creates a Kal-style rom file from an existing folder structure.
# If this script is used on the blabla.py output for Kal's data.rom, the result
# will be a bit-exact copy of that data.rom. However, different folder
# structures can also be packed without problems.

load './toolkit.rb'

f = KalRom2File.new

# Arguments:
# 1. folder containing files to be packed
# 2. location where the rom file will be written
source_folder, target = ARGV

f.files = load_packed_file_from_folder_recursive(source_folder).content
f.write(target)
