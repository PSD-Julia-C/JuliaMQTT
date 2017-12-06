using Base.Test
using mqtt

#Payload buffer test
@testset "Payload" begin
    buf = Vector{UInt8}(10)
    pay = mqtt.Payload(buf)
  @test pay = true
end

#Payload string test
@testset "Payload" begin
    str = "Pay"
    pay = mqtt.Payload(str)
    @test pay = true
end
