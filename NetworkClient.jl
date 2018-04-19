using Images

BufferedImage = Union{Void,AbstractArray}
Stream = Union{Void,Base.LibuvStream}

getWidth(image::AbstractArray) = size(image)[1]
getHeight(image::AbstractArray) = size(image)[2]

printStackTrace(ex) = Base.showerror(STDOUT, ex, catch_backtrace())

type Move
  fromX::Int
  fromY::Int
  toX::Int
  toY::Int
  Move(fromX::Int, fromY::Int, toX::Int, toY::Int) = new(fromX, fromY, toX, toY)
end

toString(this::Move) = string(this.fromX, ",", this.fromY, " -> ", this.toX, ",", this.toY)

type PrintWriter
  stream::Stream
end

pw_println(this::PrintWriter, args...) = println(this.stream, args...)
pw_flush(this::PrintWriter) = flush(this.stream)

type Socket
  hostname::String
  port::Int
  stream::Stream
  Socket() = new("",0,nothing)
  function Socket(hostname::String, port::Int)
    this = new(hostname,port,nothing)
    this.stream  = connect(hostname, port)
    this
  end
end

type SocketStream
  socket::Union{Void, Socket}
  SocketStream() = new(nothing)
  SocketStream(x::Socket) = new(x)
end

InputStream = SocketStream
OutputStream = SocketStream

STREAM = []

function st_read(this::InputStream)
  value = 0
  #@async if isopen(this.socket.stream) value = parse(Integer, string(read(this.socket.stream)...)) end # parse(Integer,)  while isopen(this.socket.stream) println(readline(this.socket.stream)) end
  #@async while true push!(value, read(this.socket.stream)) end
  #@async while isopen(this.socket.stream) println(readline(this.socket.stream)) end
  value = read(this.socket.stream, 1)[1]
  println("Value: ", value)
  value
end

function st_write(this::OutputStream, value::Any)
  if isopen(this.socket.stream) write(this.socket.stream,value) end
end

st_flush(this::OutputStream) = flush(this.socket.stream)

getOutputStream(this::Socket) = SocketStream(this)
getInputStream = getOutputStream

SystemCurrentTimeMillis() = Dates.time() * 1000

type NetworkClient
  jdField_a_of_type_JavaNetSocket::Socket
  jdField_a_of_type_JavaIoInputStream::InputStream
  jdField_a_of_type_JavaIoOutputStream::OutputStream
  jdField_a_of_type_Int::Int
  b::Int
  c::Int
  NetworkClient() = new(Socket(),InputStream(),OutputStream(),0,0)
end

function NetworkClient(hostname::String, teamName::String, logo::BufferedImage)
  this = NetworkClient()
  if (logo == nothing) || (getWidth(logo) != 256) || (getHeight(logo) != 256)
    throw(ErrorException("You have to provide a 256x256 image as your team logo")) #RuntimeException
  end
  this.jdField_a_of_type_JavaNetSocket = Socket(hostname, 22135)
  this.jdField_a_of_type_JavaIoOutputStream = getOutputStream(this.jdField_a_of_type_JavaNetSocket)
  this.jdField_a_of_type_JavaIoInputStream = getInputStream(this.jdField_a_of_type_JavaNetSocket)
  st_write(this.jdField_a_of_type_JavaIoOutputStream, 1)
  st_flush(this.jdField_a_of_type_JavaIoOutputStream)
  if Int8(st_read(this.jdField_a_of_type_JavaIoInputStream)) != 1
    throw(ErrorException("Outdated client software - update your client!"))
  end
  pw = PrintWriter(this.jdField_a_of_type_JavaIoOutputStream.socket.stream)
  pw_println(pw, teamName)
  pw_println(pw, encodeImageBase64(logo))
  pw_flush(pw)
  hostname = st_read(this.jdField_a_of_type_JavaIoInputStream)
  this.jdField_a_of_type_Int = (hostname & 0x3)
  this.b = trunc(hostname / 4)
  l = SystemCurrentTimeMillis()
  st_write(this.jdField_a_of_type_JavaIoOutputStream, 0)
  st_flush(this.jdField_a_of_type_JavaIoOutputStream)
  st_read(this.jdField_a_of_type_JavaIoInputStream)
  this.c = trunc(Int(SystemCurrentTimeMillis() - l) / 2)
  println("Expected network latency in milliseconds: ", this.c)
  this
end
  
function receiveMove(this::NetworkClient)::Move
  try
    i = 0
    if (i = st_read(this.jdField_a_of_type_JavaIoInputStream)) == 88 #no input
      return nothing
    end
    if i == 99 #invalid
      throw(ErrorException("You got kicked because your move was invalid!"))
    end
    j = st_read(this.jdField_a_of_type_JavaIoInputStream)
    return Move(i / 9, i % 9, j / 9, j % 9)
  catch localIOException #IOException
    throw(ErrorException(string("Failed to receive move: ", localIOException)))
  end
end

function sendMove(this::NetworkClient, move::Move)
  try
    st_write(this.jdField_a_of_type_JavaIoOutputStream, move.fromX * 9 + move.fromY)
    st_write(this.jdField_a_of_type_JavaIoOutputStream, move.toX * 9 + move.toY)
    st_flush(this.jdField_a_of_type_JavaIoOutputStream)
  catch localIOException #IOException
    throw(ErrorException(string("Failed to send move: ", localIOException)))
  end
end

getMyPlayerNumber(this::NetworkClient) = this.jdField_a_of_type_Int
getTimeLimitInSeconds(this::NetworkClient) = this.b
getExpectedNetworkLatencyInMilliseconds(this::NetworkClient) = this.c

function encodeImageBase64(image::BufferedImage)
  io = IOBuffer()
  save(Images.Stream(Images.format"PNG", io), image) # color image is still a gray image on server
  base64encode(io.data)
end

#img = Gray.(img)
#imgMatrix = vec(UInt8.(reinterpret.(channelview(img))))
#convert(Array{UInt8},Images.raw(grayImage))
#grayimg = (c -> begin g=N0f8((c.r+c.g+c.b)/3); r=RGBA(g,g,g,N0f8(1.0)); end).(img)
#save("_temp.png", img)
#content=""
#open("_temp.png") do file
#   content=readstring(file)
#end
#data = convert(Vector{UInt8},content))
