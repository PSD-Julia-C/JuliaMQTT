using Base.Test
using mqtt

try
    @testset "mqtt.getPacketLen" begin
        @test mqtt.getPacketLen(77) == 77+2
        @test mqtt.getPacketLen(0) == 2+0
        @test mqtt.getPacketLen(128) == 3+128
        @test mqtt.getPacketLen(8984) == 3+8984
        @test mqtt.getPacketLen(20000) == 4+20000
        @test mqtt.getPacketLen(3000000) == 5+3000000
    end
    @testset "encodePacketLen" begin
        buf = Vector{UInt8}(20)
        mqtt.encodePacketLen(view(buf,1:20),17)
        @test buf[1] == 17
        mqtt.encodePacketLen(view(buf,1:20),321)
        @test buf[1:2] == [193, 2]
        mqtt.encodePacketLen(view(buf,1:20),268435455)
        @test buf[1:4] == [0xff , 0xff , 0xff, 0x7f]
    end
    @testset "decodePacketLen" begin
        buf = Vector{UInt8}(20)
        buf[1] = 17
        @test mqtt.decodePacketLen(view(buf,1:4)) == (1,17)
        buf[1:2] = [193, 2]
        @test mqtt.decodePacketLen(view(buf,1:2)) == (2,321)
        buf[1:4] = [0xff , 0xff , 0xff, 0x7f]
        @test mqtt.decodePacketLen(view(buf,1:4)) == (4,268435455)
    end
    @testset "readInt" begin
        buf = Vector{UInt8}(20)
        buf[1:2] = [1,1]
        @test mqtt.readInt(view(buf,1:2)) == (257,2)
    end
    @testset "readString" begin
        buf = Vector{UInt8}()
        string = "Hello World"
        append!(buf, [0,length(string)])
        append!(buf, string)
        @test mqtt.readString(view(buf,1:length(buf))) == (string,length(string)+2)
    end
    @testset "writebuf" begin
        buf = Vector{UInt8}(20)
        @test mqtt.writebuf(view(buf,1:20), UInt8(42)) == 1
        @test buf[1] == 42
        @test mqtt.writebuf(view(buf,1:20), 42) == 2
        @test buf[1:2] == [0,42]
        @test mqtt.writebuf(view(buf,7:20), UInt8(42)) == 1
        @test buf[7] == 42
        readbuf = Vector{UInt8}(5)
        readbuf[1:5] = [i for i=1:5]
        @test mqtt.writebuf(view(buf,7:20),readbuf) == 7
        @test buf[7:13] == [0,5,1,2,3,4,5]
        @test mqtt.writebuf(view(buf,1:20),b"hello") == 7
        @test buf[1:7] == [0x00, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f]
        @test mqtt.writebuf(view(buf,7:20),"hello") == 7
        @test buf[7:13] == [0x00, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f]
        mypayload = mqtt.Payload([0x68, 0x65, 0x6c, 0x6c, 0x6f])
        @test mqtt.writebuf(view(buf,1:20),mypayload) == 7
        @test buf[1:7] ==  [0x00, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f]
        mypayload = mqtt.Payload("hello")
        @test mqtt.writebuf(view(buf,1:20),mypayload) == 7
        @test buf[1:7] ==  [0x00, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f]
    end
catch
end
