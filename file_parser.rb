require 'etc'

input = ''
output = STDOUT
threads = Etc.nprocessors
count = 10

# argv parsing
# no validation
for i in 0..ARGV.length
  if i == 0
    input = ARGV[i]
  elsif ARGV[i] == '-o'
    output = ARGV[i+1]
  elsif ARGV[i] == '-n'
    threads = ARGV[i+1].to_i
  elsif ARGV[i] == '-c'
    count = ARGV[i+1].to_i # 10 number not interesting, maybe 1000?
  end
end


# prepare
@selection = Queue.new # not good, but i need global threadsafe variable.
processed_bytes = 0

# search subroutine
search = Proc.new do |lines, offset|
  lines.each_with_index do |line, index|

    val = line.to_f
    not_simple = val < 1  # check greater then 1

    for del in (2..val-1) do # check denominators
      not_simple = true if (val/del).modulo(1) == 0

      if not_simple
        break
      end
    end

    # weight means ~ position in file
    @selection << {weight: offset+index, value: val.to_i} unless not_simple
    Thread.exit if @selection.size >= count # mayby we no need next iteration
  end
  Thread.exit # work done
end

# partial file reading
def read file, offset

  file.seek offset, IO::SEEK_SET
  bytes = file.read 65535 # 64kb chunk
  shift = offset+65535

  while bytes[-1,1] != "\n" # if line not full search for EOL
    file.seek shift
    bytes += file.read(1)
    shift += 1
  end

  {lines: bytes.split(/\n/), offset: shift} # numbers and how many bytes readed
end

# simple threadpool
workers = ThreadGroup.new
source = File.open(input)

begin
  (threads - workers.list.length).times do # if thread closed making new
    filedata = read source,processed_bytes # read chunk
    tr = Thread.new(filedata[:lines], processed_bytes) { |lin, off|
      search.call lin, off
    } # give it to worker
    workers.add tr # add worker to pool
    processed_bytes = filedata[:offset]
  end
end while @selection.length < count && source.size > processed_bytes

#we have solution
#stop all workers
workers.list.each do |thr|
  thr.exit
end

# sorting by position in file
for_sort = []
@selection.length.times do
  for_sort << @selection.pop
end
for_sort.sort! { |x, y| x[:weight] <=> y[:weight] }

# write result
out = output==STDOUT ? output : File.open(output,'w')
for_sort.each do |e|
  out.puts e[:value]
end
out.close