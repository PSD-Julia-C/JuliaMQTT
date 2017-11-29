using Base.Test
using mqtt

@testset "mqttheader" begin
    header = mqtt.mqttheader()
    @test header.data == 0x030
end
