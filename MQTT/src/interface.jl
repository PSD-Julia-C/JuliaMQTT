
function mqttreadTemp(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
  index = 1
  while index <= len
    pread = read(net.sock,UInt8)
    buffer[index] = pread
    index += 1
  end
end


function mqttwrite(net::Network, buffer::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, len::Int, timeout::Int)
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
    return false
end

function TimerInit(timer::Timer)
end
