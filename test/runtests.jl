using BitTorrent, Test

@testset "Bencode/Bdecode" begin
    # BitTorrent.bencode
    @test sprint(BitTorrent.bencode, 42) == "i42e"
    @test sprint(BitTorrent.bencode, [42, [1, 2], Dict("hello"=>42), "hello world"]) ==
          "li42eli1ei2eed5:helloi42ee11:hello worlde"
    @test sprint(BitTorrent.bencode, Dict("int"=>42, "list"=>[1, 2], "dict"=>Dict("key1"=>1), "string"=>"hello world")) ==
          "d4:dictd4:key1i1ee3:inti42e4:listli1ei2ee6:string11:hello worlde"
    @test sprint(BitTorrent.bencode, "hello world") == "11:hello world"
    @test sprint(BitTorrent.bencode, "\x8e\xc8\xfb\xd3") == "4:\x8e\xc8\xfb\xd3"
    # BitTorrent.bdecode
    @test BitTorrent.bdecode(IOBuffer("i42e")) == 42
    @test BitTorrent.bdecode(IOBuffer("i42e")) == 42
end
