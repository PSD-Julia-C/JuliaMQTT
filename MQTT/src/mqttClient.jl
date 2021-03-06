using Base.Threads

include("interface.jl")
include("serialize.jl")
include("tools.jl")
include("mqttSend.jl")

function getNextPacketId(client::MQTTClient)
    return client.next_packetid = client.next_packetid == MAX_PACKET_ID ? 1 : client.next_packetid + 1
end

function MQTTConnect(client::MQTTClient, options::MQTTPacketConnectData = MQTTPacketConnectData())
    rc = MQTTCLIENT_FAILURE
    if client.isconnected
        return MQTTCLIENT_FAILURE
    end
    try
        client.ipstack.sock = connect(client.ipstack.addr,client.ipstack.port)
        client.keepAliveInterval = options.keepAliveInterval

        client.ping_timer = Timer(client.keepAliveInterval)
        len = serializeConnect(client.buf, client.buf_size, options)

        timer = Timer(client.command_timeout_ms) #changed command_timeout to command_timeout_ms
        sendPacket(client, len, timer)
        #this will be a blocking call, wait for the connack
        waitfor(client, CONNACK, timer)   #changed timer name to command_timeout_ms (errors occured)
        (rc, session) = deserializeConnack(client.readbuf, client.readbuf_size)

        if rc == UInt8(MQTTCLIENT_SUCCESS)
            client.isconnected = true
        end
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTConnect: ",ex)) #added error prints for debugging purposes
        println(catch_stacktrace())
    end

    return rc
end

function MQTTPublish(client::MQTTClient, message::MQTTMessage)
  rc = MQTTCLIENT_FAILURE
    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
      lock(client.mutex)
    try
        if message.qos == FireAndForget || message->qos == AtLeastOnce
            message.msgid = getNextPacketId(client)
        end
        client.buf=Vector{UInt8}(256)
        len = serializePublish(client.buf, client.buf_size, message)
        timer = Timer(client.command_timeout_ms)
        sendPacket(client, len, timer) # send the subscribe packet

        if  message.qos == FireAndForget && waitfor(client, PUBACK, timer) == PUBACK ||
            message.qos == AtLeastOnce && waitfor(client, PUBCOMP, timer) == PUBCOMP
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
    rc = MQTTCLIENT_FAILURE
    if !client.isconnected
      println("Client not connected")
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
        client.readbuf=Vector{UInt8}(256)
        len = serializeSubscribe(client.buf, client.buf_size, true, getNextPacketId(client),topicFilter, qos)

        timer = Timer(client.command_timeout_ms)
        sendPacket(client, len, timer)

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
    unlock(client.mutex)
    return rc
end

function MQTTUnsubscribe(client::MQTTClient, topicFilter::String)
    println("Entered the Unscribe function")
    rc=MQTTCLIENT_SUCCESS
    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
        len = serializeUnsubscribe(client.buf, client.buf_size, getNextPacketId(client), topicFilter)
        timer = Timer(client.command_timeout_ms)
        sendPacket(client, len, timer)
        waitfor(client, UNSUBACK, timer)

        deserializeUnSuback(client.readbuf, client.readbuf_size)
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTUnsubscribe: ",ex))
        println(catch_stacktrace())
    end

    unlock(client.mutex)
    return rc
    println("Successfully finished the UNSUB")
 return rc
end

function MQTTDisconnect(client::MQTTClient, options::MQTTPacketConnectData = MQTTPacketConnectData())
  rc = MQTTCLIENT_SUCCESS

    if !client.isconnected
        return MQTTCLIENT_FAILURE
    end
    lock(client.mutex)
    try
        len = serializeDisconnect(client.buf, client.buf_size, options)
        timer = Timer(client.command_timeout_ms)
        sendPacket(client, len, timer)

        client.isconnected = 0
        rc = MQTTCLIENT_SUCCESS
    catch ex
        rc = MQTTCLIENT_FAILURE
        println(string("Error occured in MQTTDisconnect: ",ex))
    end

    unlock(client.mutex)
    return rc
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
    while true
        if TimerIsExpired(timer)
        	throw(MqttReturnException(MQTTCLIENT_FAILURE))
        end
        if cycle(client, timer) == packet_type
            break
        end
    end
    return packet_type
end

function deliverMessage(client::MQTTClient, message::MQTTMessage)
    rc = MQTTCLIENT_FAILURE
    # we have to find the right message handler - indexed by topic
    for topicFilter in keys(client.messageHandlers)
        if  topicFilter != "" && message.topicName == topicFilter ||isTopicMatched(topicFilter, message.topicName)
            if !isnull(client.messageHandlers[topicFilter])
                client.messageHandlers[topicFilter](message)
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
    packet_type = readPacketTemp(client, timer)
    println("Received packet: ", packet_type)
    len = 0
    if any(packet_type .== (CONNACK, PUBACK, SUBACK, PUBCOMP, PINGRESP))
        if packet_type == PINGRESP
            client.ping_outstanding = 0
        end
        return packet_type
    end
    if packet_type == PUBLISH
        msg = deserializePublish(client.readbuf, client.readbuf_size)
        deliverMessage(client, msg)
        if msg.qos != MqttQosNONE
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
