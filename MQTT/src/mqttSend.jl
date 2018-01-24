function sendPacket(client::MQTTClient, len::Int, timer::Timer)
    sent::Int = 1

    packet_type = mqttPacketType(Header(client.buf[1]))
    println("Sending packet: ", packet_type)
    while sent <= len && !TimerIsExpired(timer)
        sent += client.ipstack.mqttwrite(client.ipstack, view(client.buf,sent:len), len, TimerLeftMS(timer))
    end
    if sent >= len
        TimerCountdown(client.ping_timer, client.keepAliveInterval) # record the fact that we have successfully sent the packet
    else
        throw(MqttReturnException(MQTTCLIENT_FAILURE))
    end
end

function readPacketTemp(client::MQTTClient, timer::Timer)
  mqttreadTemp(client.ipstack,view(client.readbuf, 1:1),1,TimerLeftMS(timer))
  header = Header(client.readbuf[1])

  offset = 2

  if (mqttPacketType(header)==PUBLISH)
    mqttreadTemp(client.ipstack,view(client.readbuf,2:2),1,TimerLeftMS(timer))
    offset += 1
  end

  packetLength = getRemainingReadCount(client.readbuf[1],client)

  mqttreadTemp(client.ipstack,view(client.readbuf, offset:client.readbuf_size),packetLength,TimerLeftMS(timer))

  return mqttPacketType(header)
end

function getRemainingReadCount(headerByte::UInt8,client::MQTTClient)
  headerByte = headerByte >> 4


  if any(headerByte .== (UInt8(CONNACK), UInt8(PUBACK), UInt8(PUBREL), UInt8(PUBCOMP), UInt8(PINGRESP), UInt8(UNSUBACK), UInt8(PINGREQ), UInt8(DISCONNECT) ))
    return 3 #return number of time it has to read
  elseif headerByte == UInt8(SUBACK)
    return 4
  elseif headerByte == UInt8(PUBLISH)
    return Int64(client.readbuf[2]) #return number of time it has to read
  else
    println("Unknown header: ",mqttPacketType(Header(headerByte)))
  end
end

function getPacketLen(client::MQTTClient, timeout::Int)
  buf=Vector{UInt8}(10) #client.readbuf -- assigning readbuffer so that not reading an empty vector
  multiplier = 1
  len::Int = 0
  const MAX_NO_OF_REMAINING_LENGTH_BYTES = 4
  println("CONSTANT MAX RL BYTES = ",MAX_NO_OF_REMAINING_LENGTH_BYTES)

  value::Int = 0
  while true
    len += 1

    if len > MAX_NO_OF_REMAINING_LENGTH_BYTES
        println("Throwing Max num bytes")
        throw(MqttPacketException(MQTTPACKET_READ_ERROR))
    end

    println("Calling mqttread from getPacketLen func")
    rc = mqttread(client.ipstack, view(buf, 1:10), 1, timeout) #Second Read 3rd 4th
    println("Read from getpacklen")

    if rc != 1
      println("RC not 1 returning. Possible bug")
      return (len, value)    # dies könnte ein Bug sein!
    end
    value += (buf[1] & 127) * multiplier
    multiplier *= 128
    (buf[1] & 128) != 0 || break
  end
  println(string("multiplier is ",multiplier))
  println(string("in GetpacketLen length is ",len))
  println(string("value is ",value))
  return (len, value)
end
