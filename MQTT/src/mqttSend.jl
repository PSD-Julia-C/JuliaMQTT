function sendPacket(client::MQTTClient, len::Int, timer::Timer)
    sent::Int = 1
    while sent <= len && !TimerIsExpired(timer)
        sent += client.ipstack.mqttwrite(client.ipstack, view(client.buf,sent:len), len, TimerLeftMS(timer))
    end
    if sent >= len
        TimerCountdown(client.ping_timer, client.keepAliveInterval) # record the fact that we have successfully sent the packet
    else
        throw(MqttReturnException(MQTTCLIENT_FAILURE))
    end
end

# function readPacket(client::MQTTClient, timer::Timer)
#   println("Entered readPacket")
#   println("Calling mqttread First time")
#     #/* 1. read the header byte.  This has the packet type in it */
#     #client.ipstack.mqttread(client.ipstack, view(client.readbuf, 1:1), 1, TimerLeftMS(timer)) #intended difference between readbuf and buffer   ---First Read
#     mqttread(client.ipstack, view(client.readbuf, 1:1),1,TimerLeftMS(timer))
#     #/* 2. read the remaining length.  This is variable in itself */
#     (len, rem_len) = getPacketLen(client, TimerLeftMS(timer))
#     len = 2 + encodePacketLen(view(client.readbuf,2:client.readbuf_size), rem_len) # /* put the original remaining length back into the buffer */
#     #/* 3. read the rest of the buffer using a callback to supply the rest of the data */
#     readlen = mqttread(client.ipstack, view(client.readbuf,len:client.readbuf_size),rem_len,TimerLeftMS(timer))  #client.ipstack.mqttread
#     println("Set readlen from mqttread second call")
#     if rem_len > 0 && readlen != rem_len
#       println(string("Remaining length is ",rem_len))
#       println(string("Read length is ",readlen))
#       println("Throwing rem_len != readlen exception now")
#         throw(MqttReturnException(MQTTCLIENT_FAILURE)) #throwing this exception
#     end
#
#     header = Header(client.readbuf[1])
#     return mqttPacketType(header)
# end

function readPacketTemp(client::MQTTClient, timer::Timer)
  mqttreadTemp(client.ipstack,view(client.readbuf, 1:1),1,TimerLeftMS(timer))

  #bitshift should go here

  packetLength = getRemainingReadCount(client.readbuf[1])

  mqttreadTemp(client.ipstack,view(client.readbuf, 2:client.readbuf_size),packetLength,TimerLeftMS(timer))

  header = Header(client.readbuf[1])

  println("Finished Reading, Returning header")

  return mqttPacketType(header)
end

function getRemainingReadCount(headerByte::UInt8)
  println("Header byte contains ",headerByte)
  headerByte = headerByte >> 4
  
    if any(headerByte .== (UInt8(CONNACK), UInt8(PUBACK), UInt8(PUBREL), UInt8(PUBCOMP), UInt8(PINGRESP), UInt8(UNSUBACK), UInt8(PINGREQ), UInt8(DISCONNECT) ))
    println("Packet Read")
    return 3 #return number of time it has to read
  elseif headerByte == UInt8(SUBACK)
    println("Type is SUBACK - Still needs to be implemented")
  else
    println("Unknown header")
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
