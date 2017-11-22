function mqttread(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
    buffer[1] =27
    return 1
end

function mqttwrite(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
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
    return false
end

function TimerInit(timer::Timer)
end
