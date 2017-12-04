using Base.Test
using mqtt
#Mqtt header test
@testset "mqttheader" begin
    header = mqtt.mqttheader()
    @test header.data == 0x030
end

#What does it equal???
#PUBLISH::mqtt.MsgType = 3
#FIX THIS TeST
@testset "mqttPacketType" begin
    head = mqtt.mqttheader()
    header = mqtt.mqttPacketType(head)
    @test header != 3
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
#Onceandonlyonce::mqtt.MqttQos = 3
@testset "getQos" begin
    head = mqtt.mqttheader()
    h = mqtt.getQos(head)
    @test h != 3
end

#ConnectFlags test
@testset "ConnectFlags" begin
      flag = mqtt.ConnectFlags()
      @test flag.flags == 0x08
end
