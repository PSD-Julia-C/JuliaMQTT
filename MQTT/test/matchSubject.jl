using Base.Test
using mqtt

try
  @testset "serialize" begin
    @test mqtt.isTopicMatched("/hugo", "/hugo")
  end

  @testset "connect" begin
    @test mqtt.isTopicMatched("Hello","Hello")
  end

  @testset "subscribe" begin
    @test mqtt.isTopicMatched("foo/bar", "foo/#")
  end

  @testset "subscribe" begin
    #s = "non/match"
    m = mqtt.isTopicMatched("non/match", "non/+/+")
    @test m == false
  end
catch
end
