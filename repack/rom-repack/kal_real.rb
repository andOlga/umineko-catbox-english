# Does the same thing as repack.rb, but allows replacing the SNR file with one
# compiled from a specified ruby script.

require_relative 'scenario.rb'
require_relative 'toolkit.rb'
require_relative 'layout.rb'

# Arguments:
# 1. ruby script to compile to SNR (e.g. minimal_example.rb in this folder)
# 2. source folder for assets to be packed into the rom file
# 3. location where the rom file will be written to
# 4. optional location where the SNR file will be written to by itself
# 5-7. optional arguments for KalSNRFile. Leave out for Kal. For Saku, use "6 19 88"
raw, source_folder, target, snr_target, val1, val2, first_table = ARGV

# Kal defaults
val1 ||= 1
val2 ||= 1
first_table ||= 0x54

snr = KalSNRFile.new(val1.to_i, val2.to_i, first_table.to_i)

load raw
raw_apply(snr)
snr.write_to(snr_target) if snr_target

f = KalRom2File.new

replacements = {
  'main.snr' => snr.data
}

f.files = load_packed_file_from_folder_recursive(source_folder, :root, replacements).content
f.write(target)
