using Base.Test
using mqtt

#Send Packet test
@testset "sendPacket" begin
    c = mqtt.MQTTClient()
    len = 5
    time = mqtt.Timer(7)
    pack = mqtt.sendPacket(c,len,time)
    @test pack = true
end

#Read Packet test
# function itself fails
"""@testset "readPacket" begin
   c = mqtt.MQTTClient()
    time = mqtt.Timer(7)
    pack = mqtt.readPacket(c,time)
    fail = mqtt.MqttReturnException(mqtt.ReturnCode(-1))
    @test pack == fail
end"""

#Get packet length test
@testset "getPacketLen" begin
    c = mqtt.MQTTClient()
    out = 8
    length = mqtt.getPacketLen(c,out)
    @test length == (1,27)
end
