
"""
    bdecode(io::IO)

Bdecode the content of the IO.

# Examples
```jldoctest
julia> BitTorrent.bdecode(IOBuffer("d6:string11:hello world7:integeri42e4:listli1ei2ei3eee"))
Dict{String,Any} with 3 entries:
  "string"  => "hello world"
  "list"    => Any[1, 2, 3]
  "integer" => 42
```
"""
function bdecode(io::IO)
    c = Char(Base.peek(io)) # peek(io, Char) in Julia 1.5 and above
    if c === 'i'
        return parseint(io)
    elseif c === 'l'
        return parselist(io)
    elseif c === 'd'
        return parsedict(io)
    else
        return parsestring(io)
    end
end

function parseint(io::IO)
    @assert read(io, Char) === 'i'
    return parse(Int, readuntil(io, 'e'))
end

function parselist(io::IO)
    @assert read(io, Char) === 'l'
    r = Any[]
    while Char(Base.peek(io)) !== 'e' # peek(io, Char) !== 'e' in Julia 1.5 and above
        push!(r, bdecode(io))
    end
    @assert read(io, Char) === 'e'
    return r
end

function parsedict(io::IO)
    @assert read(io, Char) === 'd'
    r = Dict{String,Any}()
    while Char(Base.peek(io)) !== 'e' # peek(io, Char) !== 'e' in Julia 1.5 and above
        push!(r, parsestring(io) => bdecode(io))
    end
    @assert read(io, Char) === 'e'
    return r
end

function parsestring(io::IO)
    l = parse(Int, readuntil(io, ':'))
    return String(read(io, l))
end

"""
    bencode(io::IO, data)

Bencode `data` and write it to the IO.

# Examples
```jldoctest
julia> data = ["hello world", 1, 2, 3];

julia> sprint(BitTorrent.bencode, data)
"l11:hello worldi1ei2ei3ee"
```
"""
bencode(io::IO, data)

function bencode(io::IO, data::Int)
    print(io, 'i', data, 'e')
end

function bencode(io::IO, data::AbstractVector)
    print(io, 'l')
    foreach(x -> bencode(io, x), data)
    print(io, 'e')
end

function bencode(io::IO, data::AbstractDict{<:AbstractString})
    print(io, 'd')
    ks = sort(collect(keys(data)))
    foreach(x -> (bencode(io, x); bencode(io, data[x])), ks)
    print(io, 'e')
end

function bencode(io::IO, data::AbstractString)
    print(io, sizeof(data), ':', data)
end
