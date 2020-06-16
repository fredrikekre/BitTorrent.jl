"""
    BitTorrent

Julia package for working with bittorrent technology. See
https://fredrikekre.github.io/BitTorrent.jl/ for documentation.
"""
module BitTorrent

import SHA

include("bencode.jl")
include("torrent-files.jl")

end # module
