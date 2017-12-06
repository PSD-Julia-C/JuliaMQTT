using Base.Test
using mqtt

try
  # Get length functions

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

  @testset "getPublishLength" begin
    @test mqtt.getPublishLength(mqtt.FireAndForget, "hugo", mqtt.Payload("hugo")) == 16
  end

  @testset "getSubscribeLength" begin
    @test mqtt.getSubscribeLength("hugo") == 9
  end

  @testset "serializeUnsubscribeLength" begin
    @test mqtt.serializeUnsubscribeLength("hugo") == 8
  end
  
  @testset "serializeConnect" begin
    buffer = Vector{UInt8}(30)
    len = mqtt.serializeConnect(buffer,30, mqtt.MQTTPacketConnectData())
    @test len == 14
    @test buffer[1:14] == Vector{UInt8}([0x10, 12, 0, 4, UInt8('M'), UInt8('Q'), UInt8('T'),UInt8('T'), 4, 0, 0, 10, 0, 0])
  end
  
  # Serialize Acknowlegements
  
  @testset "serializeAckConnect" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serializeAck(buffer,30,mqtt.CONNACK, 42) == 4
      #@test buffer[1:4] == Vector{UInt8}([0x40, 2, 0, 42])
    end
  @testset "serializeAckPublish" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serializeAck(buffer, 30, mqtt.PUBACK, 42) == 4
    end

  @testset "serializeAckSubscribe" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serializeAck(buffer, 30, mqtt.SUBACK, 42) == 4
    end

  @testset "serializeAckUnsubscribe" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serializeAck(buffer, 30, mqtt.UNSUBACK, 42) == 4
    end
  
     @testset "deserializeConnack" begin
     buffer = Vector{UInt8}([0x20, 2, 0, 0])
     @test mqtt.deserializeConnack(buffer,4) == (0,false)
 end

 #deserialiseAck Test method
  @testset "deserializeAck" begin
      buffer = Vector{UInt8}(30)
      header = mqtt.mqttheader()
      mqtt.serializeAck(buffer, 30, mqtt.PUBLISH, 42)
      dup = mqtt.getDup(header)
      packettype = mqtt.mqttPacketType(header)
      @test mqtt.deserializeAck(buffer, 30) == (packettype, dup, 42)

 end  
  
  @testset "deserializeUnSuback" begin
    buffer = Vector{UInt8}(30)
    header = mqtt.mqttheader(msgtype = mqtt.SUBACK)
    mqtt.serializeAck(buffer, 30, mqtt.SUBACK, 42)
    dup = mqtt.getDup(header)
    packettype = mqtt.mqttPacketType(header)
    @test mqtt.deserializeAck(buffer, 30) == (packettype, dup, 42)
  end
  

 @testset "deserializeSuback" begin
    buffer = Vector{UInt8}(30)
    header = mqtt.mqttheader(msgtype = mqtt.UNSUBACK)
    mqtt.serializeAck(buffer, 30, mqtt.UNSUBACK, 42)
    dup = mqtt.getDup(header)
    packettype = mqtt.mqttPacketType(header)
    @test mqtt.deserializeAck(buffer, 30) == (packettype, dup, 42)
  end
  
#get publish length test method
 @testset "getPublishLength" begin
      @test mqtt.GetPublishLength(mqtt.mqttPacketType()) == 2
      options = mqtt.GetPacketType()
 end
#serialsie publish test method
 @testset "serialisePublish" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.serialisePublish(buffer,30,mqtt.CONNACK,42)==4
      @test buffer[1:4] == Vector{UInt8}([0x40,2,0,42])
 end
#deserialise publish test method
 @testset "deserialisePublish" begin
    buffer = Vector{UInt8}(30)
    @test mqtt.deserialisePublish(buffer,4) ==(0,false)
  end
  @testset "getSubscribeLength" begin
  @test mqtt.getSubscribeLength("Hello") == 10
end
@testset "serializeSubscribe" begin
  buffer = Vector{UInt8}(30)
  len = mqtt.serializeSubscribe("Hello")
  @test len == 10
  @test buffer[1:10] == Vector{UInt8}([0x80, 12, 0, 4, UInt8('M'), UInt8('Q'), UInt8('T'),UInt8('T'), 4, 0, 0, 10, 0, 0])
end
@testset "serializeUnsubscribeLength" begin
  @test mqtt.serializeUnsubscribeLength("Hello") == 9
end
catch
end
