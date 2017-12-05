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
 """@testset "deserializeAck" begin
      buffer = Vector{UInt8}(30)
      @test mqtt.deserialiseAck(buffer,4) ==(0,false)
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
end"""
  @testset "getSubscribeLength" begin
  @test mqtt.getSubscribeLength("Hello") == 10
end
@testset "serializeUnsubscribeLength" begin
  @test mqtt.serializeUnsubscribeLength("Hello") == 9
end
@testset "serializeSubscribe" begin
  buffer = Vector{UInt8}(20)
  reqQos = mqtt.MqttQoS(2)
  bufflen = 20
  packet = 1
  actual = mqtt.serializeSubscribe(buffer, bufflen, false, packet, "Hello",reqQos)
  @test actual == 12
end
@testset "serializeUnsubscribe" begin
  buffer = Vector{UInt8}(20)
  bufflen = 20
  packet = 1
  actual = mqtt.serializeUnsubscribe(buffer, bufflen, packet, "Hello")
  @test actual == 11
end
catch
end
