
using BufferedStreams, FactCheck


# A few things that might not be obvious:
#   * In a few places we wrap an array in an IOBuffer before wrapping it in a
#     BufferedInputStream. This is to force the BufferedInputStream to read
#     incrementally to expose possible bugs in buffer refilling logic.
#   * Similar, we manually set the buffer size to be smaller than the default to
#     force more buffer refills.

facts("BufferedInputStream") do
    context("readbytes") do
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)
        read_data = UInt8[]
        while !eof(stream)
            push!(read_data, read(stream, UInt8))
        end
        @fact data == read_data --> true
        @fact data == readbytes(BufferedInputStream(IOBuffer(data), 1024)) --> true

        halfn = div(length(data), 2)
        @fact data[1:halfn] == readbytes(BufferedInputStream(IOBuffer(data), 1024), halfn) --> true
    end

    context("readuntil") do
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)

        true_num_zeros = 0
        zero_positions = Int[]
        for (i, b) in enumerate(data)
            if b == '\0'
                push!(zero_positions, i)
                true_num_zeros += 1
            end
        end

        num_zeros = 0
        chunk_results = Bool[]
        while true
            # are we extracting the right chunk?
            chunk = readuntil(stream, 0x00)
            first = num_zeros == 0 ? 1 : zero_positions[num_zeros]+1
            last = num_zeros < length(zero_positions) ?  zero_positions[num_zeros+1] : length(data)
            true_chunk = data[first:last]
            push!(chunk_results, true_chunk == chunk)

            if !eof(stream)
                num_zeros += 1
            else
                break
            end
        end

        @fact all(chunk_results) --> true
        @fact num_zeros == true_num_zeros --> true
    end

    context("arrays") do
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(data)
        read_data = UInt8[]
        while !eof(stream)
            push!(read_data, read(stream, UInt8))
        end
        @fact data == read_data --> true
        @fact data == readbytes(BufferedInputStream(data)) --> true
    end

    context("anchors") do
        data = rand(UInt8, 100000)

        function random_range(n)
            a = rand(1:n)
            b = rand(a:n)
            return a:b
        end

        # test that anchors work correctly by extracting random intervals from a
        # buffered stream.
        function test_anchor()
            r = random_range(length(data))
            i = 1
            stream = BufferedInputStream(IOBuffer(data), 1024)
            while !eof(stream)
                if i == r.start
                    anchor!(stream)
                end
                if i == r.stop
                    return takeanchored!(stream) == data[r]
                end
                read(stream, Uint8)
                i += 1
            end
            error("nothing extracted")
        end

        @fact all(Bool[test_anchor() for _ in 1:100]) --> true
    end
end


facts("BufferedOutputStream") do
    context("write") do
        data = rand(UInt8, 1000000)
        sink = IOBuffer()
        stream = BufferedOutputStream(sink, 1024)
        for c in data
            write(stream, c)
        end
        close(stream)

        @fact takebuf_array(sink) == data --> true
    end

    context("arrays") do
        iobuf = IOBuffer()
        stream = BufferedOutputStream()
        for _ in 1:1000
            data = rand(UInt8, rand(1:1000))
            write(iobuf, data)
            write(stream, data)
        end

        @fact takebuf_array(stream) == takebuf_array(iobuf) --> true
    end
end


