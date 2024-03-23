# Classes and utils for creating rom files

require 'stringio'
require 'digest'

# Represents an individual file or folder to be packed into a rom file.
# `name`: the filename or folder name, not including parent folders.
# `folder?`: whether this should be packed as a folder.
# `content`: can be either raw binary data or an array of `FileToPack`.
FileToPack = Struct.new(:name, :folder?, :content)

# `name`: name of this folder
# `files_to_pack`: array of `FileToPack` — files and folders to pack as part of this folder
# `parent_name`: name of the parent folder (important for `..` references)
# `root?`: whether this folder is the root folder
FolderToProcess = Struct.new(:name, :files_to_pack, :parent_path, :root?)

# `position`: position in bytes where the offset should be stored
# `path`: full path of folder to store the offset for
FolderOffset = Struct.new(:position, :path)

# `path`: full path of folder that was written
# `data`: header section data representing this folder's contents
# `size`: size of aforementioned data in bytes
# `other_folder_offsets`: Array of `FolderOffset` — Offsets within the `data` where the entries for subfolders were stored,
#                         so that the correct offset of the folder data within the rom file can be written there later
# `subfolders_to_process`: Array of `FolderToProcess` — subfolders that were found and need to be written as well
WrittenFolder = Struct.new(:path, :data, :size, :other_folder_offsets, :subfolders_to_process)

# A folder that was packed into a rom file
# `data`: the binary data representing the folder's contents, for the header section
# `size`: size of aforementioned data in bytes
# `flat_location`: location where this folder will be stored in the header, flattened (`location >> FOLDER_ALIGNMENT`)
PackedFolder = Struct.new(:data, :size, :flat_location)

class KalRom2File
  FILE_ALIGNMENT = 9 # Files are aligned to 2**9 bytes in rom files
  FOLDER_ALIGNMENT = 4 # Folders are aligned to 2**4 bytes

  attr_accessor :files

  def initialize(header_size = 0x24600, val1 = 1, val2 = 1)
    # With the way we are writing files, the maximum size of the header must be known in advance.
    # It is possible to repack rom files in two passes, where first the header is written and
    # then filled in with the content addresses later, but this method is far simpler.
    @header_size = header_size
    @next_file = header_size # where the next file should be written (at the end of the header, initially)

    # Write the initial bytes of the rom file
    @s = StringIO.new
    @s.binmode
    @s.write("ROM2") # Magic bytes
    @s.write([val1, val2].pack('S<S<')) # two unknown values that differ by game
    @header_pos = @s.pos # Position where the header will be written

    @files = []
    @folder_data = {}
  end

  def write(path)
    # Initialise memory where we will write the header
    header = StringIO.new
    header.binmode

    # Start by writing @files (which will contain all other files and folders as entries/subfolders)
    folders_to_process = [FolderToProcess.new(:root, @files, nil, true)]
    folder_offsets = []

    until folders_to_process.empty?
      new_folders_to_process = []

      folders_to_process.each do |folder_to_process|
        location = header.pos

        # This is where the magic happens: turn the folder to process into binary data to be put into the
        # header section, extracting relevant information about subfolders wherever necessary.
        written_folder = write_folder(folder_to_process)

        # Add location of current folder in the header to all offsets, as the
        # references to other folders are relative to the header
        folder_offsets += written_folder.other_folder_offsets.map do |offset|
          FolderOffset.new(offset.position + location, offset.path)
        end

        new_folders_to_process += written_folder.subfolders_to_process

        header.write(written_folder.data)
        puts "Wrote folder #{folder_to_process.name} to header"
        align = (1 << FOLDER_ALIGNMENT) - 1
        header.seek((header.pos + align) & ~align) # align next folder to 0x10
        @folder_data[written_folder.path] = PackedFolder.new(written_folder.data, written_folder.size, location >> FOLDER_ALIGNMENT)
      end

      folders_to_process = new_folders_to_process
    end

    p folder_offsets

    folder_offsets.each do |offset|
      f = @folder_data[offset.path]
      header.seek(offset.position)
      header.write([f.flat_location, f.size].pack('L<L<'))
    end

    # Pad the end of the header with zero bytes for the correct alignment
    header.seek(0, IO::SEEK_END)
    align = (1 << FOLDER_ALIGNMENT) - 1
    fill = ((header.length + align) & ~align) - header.length
    header.write("\x00" * fill)

    # Here we find out whether we have exceeded the predefined size...
    raise "Header size too big" if header.length > @header_size

    # Write the length of the header at its start
    @s.seek(@header_pos)
    puts "Length of header: 0x#{header.length.to_s(16)}"
    @s.write([header.length].pack('L<'))

    # Write some extra values in the header
    # Thanks to TellowKrinkle for letting me know what these values are!
    @s.write [1 << FILE_ALIGNMENT].pack('L<') # The number of bytes to which files are aligned (may as well be constant)
    digest = Digest::MD5.digest(header.string) # MD5 of the header section
    @s.write digest
    puts "MD5 of header: #{Digest.hexencode(digest)}"

    # Write the bulk of the header itself
    @s.write(header.string)

    puts "Writing to string..."
    full_data = @s.string

    align = (1 << FILE_ALIGNMENT) - 1
    fill = ((full_data.length + align) & ~align) - full_data.length
    puts "Got data, writing to file..."
    f = File.open(path, 'wb')
    f.write(full_data)
    f.write("\x00" * fill)
    puts "Done"
  end

  private

  def join_paths(path1, path2)
    return path2 if path1 == :root
    path1 + "/" + path2
  end

  def write_folder(folder_to_process)
    puts "write_folder #{folder_to_process.name}"

    # The root folder has no parent
    if folder_to_process.root?
      path = parent_path = folder_to_process.name
    else
      parent_path = folder_to_process.parent_path
      path = join_paths(parent_path, folder_to_process.name)
    end

    result = StringIO.new
    result.binmode

    name_offsets = [] # Locations where references to file/folder names must be written

    other_folder_offsets = [] # Offsets where we stored data for subfolders
    subfolders_to_process = [] # Subfolders we have found in the entries, that need to be written in the next iteration

    # We have to not only write the files that we want in the folder, but also the references to the current
    # and parent folder.
    entries_to_write = [
      FileToPack.new('.', true, nil),
      FileToPack.new('..', true, nil)
    ] + folder_to_process.files_to_pack

    # First of all, write the number of entries within this folder (including references)
    result.write([entries_to_write.length].pack('L<'))

    # Next, write the section with file/folder flags and the offsets to the data
    entries_to_write.each do |file|
      # The beginning of each file entry is a three(?)-byte pointer to the location where the name is stored.
      # As we are only going to write the name section later, we store zeroes here for now and keep track
      # of the location, so we can write the address later
      name_offsets << result.pos
      result.write("\x00" * 3)

      if file.folder?
        result.write("\x80") # 0x80 = folder flag
        case file.name
        when '.'
          # Reference to self
          other_folder_offsets << FolderOffset.new(result.pos, path)
        when '..'
          # Reference to parent folder
          other_folder_offsets << FolderOffset.new(result.pos, parent_path)
        else
          # Actual subfolder
          puts "add folder #{file.name}"
          subfolders_to_process << FolderToProcess.new(file.name, file.content, path, false)
          other_folder_offsets << FolderOffset.new(result.pos, join_paths(path, file.name))
        end

        # Remaining unused bytes
        result.write("\x00" * 8)
      else
        result.write("\x00") # no flags. It does not seem like any flags other than the folder one are used in practice
        length = file.content.bytes.length
        file_offset = @next_file

        # Write file content
        @s.seek(file_offset)
        @s.write(file.content)

        align = (1 << FILE_ALIGNMENT) - 1
        @s.seek((@s.pos + align) & ~align) # align next file
        @next_file = @s.pos

        flat_offset = file_offset >> FILE_ALIGNMENT
        result.write([flat_offset, length].pack('L<L<'))
      end
    end

    # Lastly, write the section containing file and subfolder names
    entries_to_write.each_with_index do |file, i|
      # Write the name itself, making sure to note where it was written
      name_location = result.pos
      result.write(file.name + "\x00")

      # Seek to the place that should reference the location of the written name
      cur = result.pos
      result.seek(name_offsets[i])

      # Write the location. It is (apparently) stored in three bytes, so we just convert the value to
      # four bytes and truncate the last byte
      name_location_bytes = [name_location].pack('L<')
      raise "Too many bytes" if name_location_bytes[3] != "\x00" # Sanity check so we don't introduce subtle errors
      result.write(name_location_bytes[0..2])

      # Seek back to the original location before we wrote the pointer to the name
      result.seek(cur)
    end

    our_size = result.length
    WrittenFolder.new(path, result.string, our_size, other_folder_offsets, subfolders_to_process)
  end
end

# Recursive method to turn a folder structure into nested FileToPacks, to be
# used for KalRom2File
def load_packed_file_from_folder_recursive(path, name = :root, replacements = {})
  result = []

  Dir.entries(path).sort.each do |entry|
    next if ['.', '..'].include? entry

    entry_path = File.join(path, entry)
    if File.directory?(entry_path)
      result << load_packed_file_from_folder_recursive(entry_path, entry, replacements)
    else
      if replacements.key?(entry)
        puts "Performing replacement: #{entry}"
        result << FileToPack.new(entry, false, replacements[entry])
      else
        result << FileToPack.new(entry, false, File.read(entry_path))
      end
    end
  end

  FileToPack.new(name, true, result)
end
