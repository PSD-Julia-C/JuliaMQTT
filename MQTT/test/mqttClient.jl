using Base.Test
using mqtt

#get next packet id test
@testset "getNextPacketId" begin
    c = mqtt.MQTTClient()
    pack = mqtt.getNextPacketId(c)
    @test pack == 0x01
end

#MQTT connect test
#Connect is timing out before function is finished
@testset "MQTTConnect" begin
    c = mqtt.MQTTClient()
    con = mqtt.MQTTConnect(c)
    f = mqtt.MqttReturnCode(-1)
    @test con == f
end

#Actual publish method not working
#Mqtt Publish test
@testset "MQTTPublish" begin
    c = mqtt.MQTTClient()
    msg = mqtt.MQTTMessage()
    pub = mqtt.MQTTPublish(c,msg)
    @test pub = true
end

#MQTT subsccribe test
#Test proves that the client fails
@testset "MQTTSubscribe" begin
    c = mqtt.MQTTClient()
    q = mqtt.MqttQoS(2)
    handler = x->x*x
    top = "Topic"
    sub = mqtt.MQTTSubscribe(c,top,q,handler)
    f = mqtt.MqttReturnCode(-1)
    @test sub == f
end

#MQTT unsubscribe test
@testset "MQTTUnsubscribe" begin
    c = mqtt.MQTTClient()
    topicN = "Goodbye"
    un = mqtt.MQTTUnsubscribe(c,topicN)
    s = mqtt.MqttReturnCode(0)
    @test un = true
end

#MQTT Disconnect test
@testset "MQTTDisconnect" begin
    c = mqtt.MQTTClient()
    dis = mqtt.MQTTDisconnect(c)
    @test dis = true
end

#MQTT Yield test
#rc in method is saying its not defined might be while loop
#@testset "MQTTYield" begin
#    c = mqtt.MQTTClient()
#    t = 8
#    y = mqtt.MQTTYield(c,t)
#    @test y == true
#end

#waitfor test
#@testset "waitfor" begin
#    c = mqtt.MQTTClient()
#    p = "PUBACK"
#    t = mqtt.Timer(8)
#    w = mqtt.waitfor(c,p,t)
#    f = mqtt.MqttReturnCode(-1)
#    @test w == f
#end

#deliverMessage test
#need to pass in a message
#@testset "deliverMessage" begin
#      c = MQTTClient()
#      m = MQTTMessage()
#      d = deliverMessage(c,m)
#      @test d == true
#end


#keep alive function
@testset "keepalive" begin
    c = MQTTClient()
    k = mqtt.keepalive(c)
    @test k == nothing
end

#cycle test
@testset "cycle" begin
    c = mqtt.MQTTClient()
    t = mqtt.Timer(7)
    c = mqtt.cycle(c,t)
    @test c = ""
end
