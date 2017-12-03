using Base.Test
using mqtt

@testset "mqttheader" begin
    header = mqtt.mqttheader()
    @test header.data == 0x030
end

@testset "mqttPacketType" begin
    header = mqtt.mqttheader()
    @test header.data > 4
end

@testset "getRetained" begin
    header = mqtt.mqttheader()
    @test mqtt.getRetained() == header.data & 0x01
end

@testset "getQos" begin
    header = mqtt.mqttheader()
    @test header.data > 4
end
