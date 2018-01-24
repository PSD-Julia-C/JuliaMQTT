using Base.Test
using mqtt
#Mqtt header test
@testset "mqttheader" begin
    header = mqtt.mqttheader()
    @test header.data == 0x030
end

#Mqtt Packet Type Test
@testset "mqttPacketType" begin
    head = mqtt.mqttheader()
    header = mqtt.mqttPacketType(head)
    pub = mqtt.MsgType(0x3)
    @test header == pub
end

#Get retained test
@testset "getRetained" begin
    head = mqtt.mqttheader()
    h = mqtt.getRetained(head)
    @test h == 0x00 & 0x01
end

#Get DUP test
@testset "getDup" begin
    head = mqtt.mqttheader()
    h = mqtt.getDup(head)
    @test h == 0x00 & 0x08
end

#Get Qos test
@testset "getQos" begin
    head = mqtt.mqttheader()
    h = mqtt.getQos(head)
    q = mqtt.MqttQoS(0)
    @test h == q
end

#ConnectFlags test
@testset "ConnectFlags" begin
      flag = mqtt.ConnectFlags()
      @test flag.flags == 0x08
end
