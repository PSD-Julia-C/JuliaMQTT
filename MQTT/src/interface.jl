function mqttread(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
    println("Entered mqttread function")
    testChar = read(net.sock,UInt8)
    println("Read Packet contains ", testChar)
    #buffer[1] = 27  #this line needs to do something (set the buffer to a realistic value)
    println(string("read buffer contains : ",buffer))
    return 1
end

function mqttwrite(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
  println("MQTT buffer contain")
  println(buffer)
  net.sock = connect(net.addr,net.port)
  println("network socket contains ",net.sock)
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
