using Base.Test
using mqtt

try
  @testset "getConnectLength" begin
    @test mqtt.getConnectLength(mqtt.MQTTPacketConnectData()) == 12
    options = mqtt.MQTTPacketConnectData()
    options.MQTTVersion = mqtt.MQTTv31
    @test mqtt.getConnectLength(options) == 14
    options.willFlag = true
    @test mqtt.getConnectLength(options) == 18
    options.username = "hugo"
    @test mqtt.getConnectLength(options) == 24
    options.password = "otto"
    @test mqtt.getConnectLength(options) == 30
  end
  @testset "serializeConnect" begin
    buffer = Vector{UInt8}(30)
    len = mqtt.serializeConnect(buffer,30, mqtt.MQTTPacketConnectData())
    @test len == 14
    @test buffer[1:14] == Vector{UInt8}([0x10, 12, 0, 4, UInt8('M'), UInt8('Q'), UInt8('T'),UInt8('T'), 4, 0, 0, 10, 0, 0])
  end
  @testset "serializeConnect" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serializeAck(buffer,30,mqtt.PUBACK, 42) == 4
      @test buffer[1:4] == Vector{UInt8}([0x40, 2, 0, 42])
    end
     @testset "deserializeConnack" begin
     buffer = Vector{UInt8}([0x20, 2, 0, 0])
     @test mqtt.deserializeConnack(buffer,4) == (0,false)
 end
catch
end
