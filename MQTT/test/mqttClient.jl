using Base.Test
using mqtt

#get next packet id test
@testset "getNextPacketId" begin
    c = mqtt.MQTTClient()
    pack = mqtt.getNextPacketId(c)
    @test pack == 0x01
end

#MQTT connect test
"""@testset "MQTTConnect" begin
    c = mqtt.MQTTClient()
    opt = mqtt.MQTTPacketConnectData()
    con = mqtt.MQTTConnect(c,opt)
    @test con == false
end"""

#Mqtt publish test
#not working
"""@testset "MQTTPublish" begin
    c = mqtt.MQTTClient()
    msg = mqtt.MQTTMessage()
    pub = mqtt.MQTTPublish(c,msg)
    @test pub = 0
end"""

@testset "MQTTSubscribe" begin
    c = mqtt.MQTTClient()
    top = "Topic"
    qos = mqtt.MqttQos(2)
    handler = function
    sub = mqtt.MQTTSubscribe(c,top,qos,handler)
    @test sub == 0
end
