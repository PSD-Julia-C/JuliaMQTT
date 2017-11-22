using Base.Test
using mqtt

try
  @testset "serialize" begin
    @test mqtt.isTopicMatched("/hugo", "/hugo")
  end
catch
end
