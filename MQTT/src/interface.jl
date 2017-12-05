function mqttread(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
    println("Entered mqttread")
    buffer[1] = 27  #this line needs to do something (set the buffer to a realistic value)
    println(string("read buffer contains : ",buffer))
    return 1
end

function mqttwrite(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
  println("MQTT buffer contain")
    println(buffer)
    # throw(MqttReturnException(MQTTCLIENT_FAILURE))
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
