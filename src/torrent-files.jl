
struct Torrent
    file::String
    content::Dict{String,Any}
end

function Torrent(file::AbstractString)
    content = open(bdecode, file)
    return Torrent(file, content)
end

function create_torrent(path; block_size=256*1024, meta::Dict=Dict{String,Any}())
    path = abspath(path)
    # Compute file information
    info = Dict{String,Any}()
    if isfile(path)
        files = [path]
        ## Populate single-file torrent keys
        info["name"] = basename(path)
        info["length"] = filesize(path)
    elseif isdir(path)
        ## Populate multi-file torrent keys
        info["name"] = splitpath(path)[end]
        files = String[]
        for (root, _, _files) in walkdir(path)
            append!(files, joinpath.(root, _files))
        end
        sort!(files; by=filesize, rev=true)
        info["files"] = [Dict{String,Any}(
            "length"=>filesize(f),
            "path" => splitpath(relpath(f, path)),
            ) for f in files]
    else
        throw(ArgumentError("path `$path` is not an existing file or folder."))
    end

    info["piece length"] = block_size # TODO: Better default block_size to make e.g. 1000 pieces or something.

    # Compute pieces hash
    total_size = sum(filesize(x) for x in files)
    npieces = ceil(Int, total_size/block_size)
    pieces = sizehint!(UInt8[], npieces * 20)
    buffer = Vector{UInt8}(undef, block_size)
    buffer_ptr = 1
    for file in files
        open(file) do io
            while !eof(io)
                nb = readbytes!(io, @view(buffer[buffer_ptr:end]))
                buffer_ptr += nb
                if buffer_ptr === block_size + 1
                    append!(pieces, SHA.sha1(buffer))
                    buffer_ptr = 1
                end
            end
        end
    end
    ## Compute the hash of the remaining bytes (if there are any in the buffer)
    if buffer_ptr > 1
        append!(pieces, SHA.sha1(@view(buffer[1:buffer_ptr-1])))
    end
    info["pieces"] = String(pieces)

    # Create content dictionary
    content = Dict{String, Any}("info" => info)
    ## Add some default values
    content["creation date"] = round(Int, time())
    content["created by"] = "BitTorrent.jl"
    ## Add user meta
    merge!(content, meta)

    # Write to disk
    torrent_file = joinpath(splitpath(path)...) * ".torrent"
    open(io -> bencode(io, content), torrent_file, "w")

    return Torrent(torrent_file, content)
end

# npieces(t::Torrent) = div(sizeof(t.content["info"]["pieces"]), 20)
# piece_length(t::Torrent) = t.content["info"]["piece length"]
# creation_date(t::Torrent) = t.content["info"]["creation date"]

function info_hash(t::Torrent)
    io = IOBuffer()
    bencode(io, t.content["info"])
    sha1 = bytes2hex(SHA.sha1(seekstart(io)))
    return sha1
end

function magnet_uri(t::Torrent)
    btih = info_hash(t)
    return "magnet:?xt=urn:btih:$(btih)"
end
