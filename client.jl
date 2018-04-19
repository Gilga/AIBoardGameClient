__precompile__(true)

module GawihsClient
  using Images
  using ImageMagick
  #include("Move.jl")
  include("NetworkClient.jl")
  #LOGGER_OUT = "out.log"
  #open(stream -> println(stream, args...), LOGGER_OUT, "a+")

  function main(args::Array{String})
    client = nothing #NetworkClient
    image = nothing #BufferedImage
      
    try
      #image = ImageIO.read(File("src/meme.jpg"))
      image = Images.load("meme.png")
    catch ex
      # TODO Auto-generated catch block
      printStackTrace(ex)
    end
      
    client = NetworkClient("localhost", "EvilGuy", image)
      
    getMyPlayerNumber(client)
    
    getTimeLimitInSeconds(client)
    
    getExpectedNetworkLatencyInMilliseconds(client)
    
    while(true)
        move = receiveMove(client)
        if move == nothing
            #ich bin dran
            sendMove(client,Move(1,2, 3,5))
        else
            #baue zug in meine spielfeldrepräsentation ein
      end
    end
  end
end

GawihsClient.main(String[])
