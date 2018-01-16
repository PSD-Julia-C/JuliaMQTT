 # function mqttread(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
 #     println("Entered mqttread")
 #     testChar = read(net.sock,UInt8)
 #     println("Read Packet contains ", testChar)
 #     buffer[1] = testChar
 #     println(string("read buffer contains : ",buffer))
 #     return 1 #Have to return something of use?
 # end

function mqttreadTemp(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)

  println("Starting read loop")
  println("len contains ",len)
  println("buffer contains : ",buffer)
  index = 1
  while index <= len
    println("Read loop ",index)
    pread = read(net.sock,UInt8)
    buffer[index] = pread
    index += 1
  end
end


function mqttwrite(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
  net.sock = connect(net.addr,net.port)
  println("Network socket contains ",net.sock)
  write(net.sock,buffer)
  return len
end

function NetworkConnect(net::Network, adr::String, port::Int)
    return true
end

function TimerLeftMS(timer::Timer)
    return 100
end

function TimerCountdown(timer::Timer, timeout::Int)
    return true
end

function TimerCountdownMS(timer::Timer, timeout::Int)
end

function TimerIsExpired(timer::Timer)
    println("In timer expired")
    return false
end

function TimerInit(timer::Timer)
end
