using Base.Threads

include("interface.jl")
include("serialize.jl")
include("tools.jl")
include("mqttSend.jl")

function getNextPacketId(client::MQTTClient)
  println("Entered getNextPacketId")
  println("next packet id contains ", client.next_packetid)
    return client.next_packetid = client.next_packetid == MAX_PACKET_ID ? 1 : client.next_packetid + 1
end

function MQTTConnect(client::MQTTClient, options::MQTTPacketConnectData = MQTTPacketConnectData())
    rc = MQTTCLIENT_FAILURE

    if client.isconnected
        return MQTTCLIENT_FAILURE
    end
    try
        client.keepAliveInterval = options.keepAliveInterval

        client.ping_timer = Timer(client.keepAliveInterval)
        len = serializeConnect(client.buf, client.buf_size, options)
        sendPacket(client, len,Timer(client.command_timeout_ms))   #changed command_timeout to command_timeout_ms

        #this will be a blocking call, wait for the connack
        waitfor(client, CONNACK, Timer(client.command_timeout_ms))   #changed timer name to command_timeout_ms (errors occured)
        (rc, session) = deserializeConnack(client.readbuf, client.readbuf_size)

        println("RC contains ",rc)
        println("MQTTCLIENT_SUCCESS is ",UInt8(MQTTCLIENT_SUCCESS))
        if rc == UInt8(MQTTCLIENT_SUCCESS)
          println("Setting client is connected")
            client.isconnected = true
        end
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTConnect: ",ex)) #added error prints for debugging purposes
    end
    println("Finished Connecting")
    return rc
end

function MQTTPublish(client::MQTTClient, message::MQTTMessage)
    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
      lock(client.mutex)
    try
        if message.qos == FireAndForget || message->qos == AtLeastOnce
            message.msgid = getNextPacketId(client)
        end

        len = serializePublish(client.buf, client.buf_size, message)
        sendPacket(client, len, timer = Timer(client.command_timeout)) # send the subscribe packet

        if  message.qos == MqttQosNONE && waitfor(c, PUBACK, timer) == PUBACK ||
            message.qos == AtLeastOnce && waitfor(c, PUBCOMP, timer) == PUBCOMP
            (packetType, dup, packetId) = deserializeAck(client.readbuf, client.readbuf_size)
        end
        rc = MQTTCLIENT_SUCCESS
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTPublish: ",ex))
    end
    unlock(client.mutex)
    return rc
end

function MQTTSubscribe(client::MQTTClient, topicFilter::String, qos::MqttQoS, handler::Function)
  println("Initiating Subscribe")
    rc = MQTTCLIENT_FAILURE
    if !client.isconnected
      println("Client not connected")
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
      println("About to attempt serializeSubscribe")
      # serializeSubscribe(buf::Vector{UInt8}, buflen::Int, dup::Bool, packetId::Int,
      # 		topicFilter::String, requestedQoSs::MqttQoS)
        println("Client Buf contains ",client.buf)
        println("client.buf_size contains",client.buf_size)
        println("topicFilter contains ", topicFilter)
        println("Qos contains ",qos)
        len = serializeSubscribe(client.buf, client.buf_size, true, getNextPacketId(client),topicFilter, qos)
        println("Serialize success")
        sendPacket(client, len, timer = Timer(client.command_timeout))

        waitfor(client, SUBACK, timer)

        (packetId, grantedQoS) = deserializeSuback(client.readbuf, client.readbuf_size)
        rc = grantedQoS # 0, 1, 2 or 0x80
        if rc != 0x80
            client.messageHandlers[topicFilter] = handler
            rc = MQTTCLIENT_SUCCESS
        else
            rc = MQTTCLIENT_FAILURE
        end
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTSubscribe: ",ex))
    end
    println("unlocking mutex")
    unlock(client.mutex)
    return rc
end

function MQTTUnsubscribe(client::MQTTClient, topicFilter::String)
    println("Entered the Unscribe function")
    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
        len = serializeUnSubscribe(client.buf, client.buf_size, getNextPacketId(client), 1, topicFilter)
        sendPacket(client, len, timer = Timer(client.command_timeout))
        println("Successfully sent the unsub packet")
        waitfor(client, UNSUBACK, timer)
        deserializeUnSuback(client.readbuf, client.readbuf_size)
        println("Successfully recieved and deserialized SUBACK")
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTUnsubscribe: ",ex))
    end

    unlock(client.mutex)
    return rc
    println("Successfully finished the UNSUB")
 return rc
end
function CheckPacketType(client::MQTTClient)
  println("Checking packet Type")
end
function MQTTDisconnect(client::MQTTClient)
  println("Entered the disconnect")
  rc = MQTTCLIENT_FAILURE
    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
        println("Entered try of disconnect")
        println(client.buf)
        println(client.buf_size)
        len = serializeDisconnect(client.buf, client.buf_size)
        println("Serialize complete")
        sendPacket(client, len, timer = Timer(client.command_timeout))
        println("Sent the disconnect packet")
        client.isconnected = 0
        rc = MQTTCLIENT_SUCCESS
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTDisconnect: ",ex))
    end

    unlock(client.mutex)
    return rc
    println("Complete")
end

function MQTTYield(client::MQTTClient, time::Int)
    timer = Timer(time)
    try
        while true
            cycle(client, timer)
            !TimerIsExpired(timer) || break
        end
        rc = MQTTCLIENT_SUCCESS
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTYield: ",ex))
    end
    return rc
end

function MQTTStartTask(client::MQTTClient)
#    return ThreadStart(client.thread, MQTTRun, client)
end

function waitfor(client::MQTTClient, packet_type, timer::Timer)

println("Waiting for Response")
    while true
        if TimerIsExpired(timer)
          println("Throwing Timer expired")
        	throw(MqttReturnException(MQTTCLIENT_FAILURE))
        end
        if cycle(client, timer) == packet_type
            break
        end
    end

    println(string("Packet contains ",packet_type))
    return packet_type
end

function deliverMessage(client::MQTTClient, message::MQTTMessage)
    rc = MQTTCLIENT_FAILURE

    # we have to find the right message handler - indexed by topic
    for topicfilter in keys(client.messageHandlers)
        if  topicFilter != "" && message.topicName == topicFilter ||isTopicMatched(topicFilter, message.topicName)
            if !isnull(client.messageHandlers[topicfilter])
                client.messageHandlers[topicfilter](message)
                rc = MQTTCLIENT_SUCCESS
            end
        end
    end

    if rc == MQTTCLIENT_FAILURE && !isnull(client.defaultMessageHandler)
        client.defaultMessageHandler(message)
        rc = MQTTCLIENT_SUCCESS
    end

    return rc
end

function keepalive(client::MQTTClient)

    if client.keepAliveInterval == 0
        return
    end

    if TimerIsExpired(client.ping_timer)

        if !client.ping_outstanding
            len = serializePingreq(client.buf, client.buf_size)
            if len > 0
                sendPacket(c, len, Timer(10)) # send the ping packet
                client.ping_outstanding = 1
            end
        end
    end
end

function cycle(client::MQTTClient, timer::Timer)
  println("Started Cycle")
    # read the socket, see what work is due
    packet_type = readPacketTemp(client, timer)

    println("finished reading packet : ",packet_type)

    len = 0
    if any(packet_type .== (CONNACK, PUBACK, SUBACK, PUBCOMP, PINGRESP ))
        println("Entered loop based on packet_type")
        if packet_type == PINGRESP
            client.ping_outstanding = 0
        end
        return packet_type
    end
    if packet_type == PUBLISH
        msg = deserializePublish(client.readbuf, client.readbuf_size)
        deliverMessage(client, msg)
        if msg.qos != QOS0
            if msg.qos == FireAndForget || msg.qos == AtLeastOnce
                len = serializeAck(client.buf, client.buf_size, PUBACK,msg.msgid)
            end
            sendPacket(client, len, timer)
        end
    end
    if packet_type == PUBREC
        (packetType, dup, packetId) = deserializeAck(client.readbuf, client.readbuf_size)
        len = serializeAck(client.buf, client.buf_size, PUBREL, packetId)
        sendPacket(client, len, timer)
    end

    keepalive(client)
    return packet_type
end
