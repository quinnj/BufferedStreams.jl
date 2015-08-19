
module BufferedStreams

export BufferedInputStream,
       BufferedOutputStream,
       EmptyStreamSource,
       fillbuffer!,
       anchor!,
       upanchor!,
       takeanchored!


include("bufferedinputstream.jl")
include("bufferedoutputstream.jl")
include("sources.jl")


end # module BufferedStreams


