

function getConnectLength( options::MQTTPacketConnectData )

	if options.MQTTVersion == MqttVersion(MQTTv31)
		len = 12  # variable depending on MQTT or MQIsdp */
	elseif options.MQTTVersion == MqttVersion(MQTTv311)
		len = 10
	else
		len = 0
	end

	len += length(options.clientID)+2
	if options.willFlag
		len += length(options.will.topicName)+2 + length(options.will.message)+2
	end
	if !isnull(options.username)
		len += length(get(options.username))+2
	end
	if !isnull(options.password)
		len += length(get(options.password))+2
	end
	return len
end

function serializeConnect(buf::Vector{UInt8}, buflen::Int, options::MQTTPacketConnectData)
	ip = 1
	len = getConnectLength(options)

	if getPacketLen(len) > buflen
		throw(MqttPacketException(MQTTPACKET_BUFFER_TOO_SHORT))
	end

	header = mqttheader(msgtype=CONNECT)
	ip += writebuf( view(buf,ip:buflen), header.data)
	ip += encodePacketLen( view(buf,ip:buflen), len)  #  write remaining length
	if options.MQTTVersion == MQTTv311
		ip += writebuf( view(buf,ip:buflen), b"MQTT")
	else
		ip += writebuf( view(buf,ip:buflen), b"MQIsdp")
	end

	if options.MQTTVersion == MQTTv311
		ip += writebuf(view(buf,ip:buflen), UInt8(options.MQTTVersion) )
	end

	connectflags = ConnectFlags(
		cleansession = options.cleansession,
		will = options.willFlag,
		willQoS = options.willFlag ? options.will.qos:0,
		willRetain= options.willFlag ? options.will.retained:false,
		password=!isnull(options.password),
		username=!isnull(options.username)
		)

	ip += writebuf( view(buf,ip:buflen), connectflags.flags)

	ip += writebuf( view(buf,ip:buflen), options.keepAliveInterval)

	ip += writebuf( view(buf,ip:buflen), options.clientID)

	if options.willFlag
		ip += writebuf( view(buf,ip:buflen), options.will.topicName)
		ip += writebuf( view(buf,ip:buflen), options.will.message)
	end
	if !isnull(options.username)
		ip += writebuf( view(buf,ip:buflen), options.username)
	end
	if !isnull(options.password)
		ip += writebuf( view(buf,ip:buflen), options.password)
	end
	return ip-1
end

function getPublishLength(qos::MqttQoS, topicName::String, payload::Payload)
	return 2 + 2 + length(topicName) + 2 + payload.len + (qos != MqttQosNONE ? 2 : 0)
end

function serializePublish(buf::Vector{UInt8}, buflen::Int, msg::MQTTMessage)

    len = getPublishLength(qos, msg.topicName, msg.payload)

	if getPacketLen(len) > buflen
		throw(MqttPacketException(MQTTPACKET_BUFFER_TOO_SHORT))
	end
    header = mqttheader(msgtype=PUBLISH, qos=msg.qos, retained=msg.retained, dup=msg.dup )
    ip = 1
	ip += writebuf( view(buf,ip:buflen), header.data)
	ip += encodePacketLen(view(buf,ip:buflen), len)  #  write remaining length
	ip += writeBuf(view(buf,ip:buflen), topicName)

	if msg.qos != MqttQosNONE
		ip += writeBuf(view(buf,ip:buflen), msg.msgid)
    end
	ip += writeBuf(view(buf,ip:buflen), msg.payload)

	return ip-1
end

function getSubscribeLength( topicFilter::String )
	return 2 + 2 + length(topicFilter) + 1 # Header + length + topic + req_qos
end

function serializeSubscribe(buf::Vector{UInt8}, buflen::Int, dup::Bool, packetId::Int,
		topicFilter::String, requestedQoSs::MqttQoS)

	len = getSubscribeLength(topicFilter)

	if getPacketLen(len) > buflen
		throw(MqttPacketException(MQTTPACKET_BUFFER_TOO_SHORT))
	end

	header = mqttheader(msgtype=SUBSCRIBE, qos=FireAndForget )

	ip = 1
	ip += writebuf(view(buf,ip:buflen), header.data)
	ip += encodePacketLen(view(buf,ip:buflen), len) #  write remaining length
	ip += writebuf(view(buf,ip:buflen), packetId)
	ip += writebuf(view(buf,ip:buflen), topicFilter)
	ip += writebuf(view(buf,ip:buflen), UInt8(requestedQoSs))

	return ip-1
end

function serializeUnsubscribeLength(topicFilter::String)
	return 2 + 2 + length(topicFilter)
end

function serializeUnsubscribe(buf::Vector{UInt8}, buflen::Int, packetId::Int, topicFilter::String)

	len = getSubscribeLength(topicFilter)

	if getPacketLen(len) > buflen
		throw(MqttPacketException(MQTTPACKET_BUFFER_TOO_SHORT))
	end

	header = mqttheader(msgtype=UNSUBSCRIBE)

	ip = 1
	ip += writebuf( view(buf,ip:buflen), header.data)
	ip += encodePacketLen(view(buf,ip:buflen), len) #  write remaining length
	ip += writebuf(view(buf,ip:buflen), packetId)
	ip += writebuf(view(buf,ip:buflen), topicFilter)

	return ip-1
end


function serializeAck(buf::Vector{UInt8}, buflen::Int, packettype::MsgType, packetId::Int, dup::Bool=false)

    if buflen < 4
        throw(MqttPacketException(MQTTPACKET_BUFFER_TOO_SHORT))
    end
    ackQos = packettype == PUBREL? FireAndForget : MqttQosNONE
    header = mqttheader(msgtype=packettype, qos=ackQos, dup=dup )
    ip = 1
    ip += writebuf( view(buf,ip:buflen), header.data)
    ip += encodePacketLen(view(buf,ip:buflen), 2)
    ip += writebuf(view(buf,ip:buflen), packetId)
    return ip-1
end

function deserializeConnack(buf::Vector{UInt8}, buflen::Int)
	header = Header(buf[1])

	if (mqttPacketType(header) != CONNACK)
		throw(MqttReturnException(MQTTCLIENT_FAILURE))
	end

	(len, mylen) = decodePacketLen(view(buf,2:4)) # read remaining length */
	if len + mylen < 2
		throw(MqttReturnException(MQTTCLIENT_FAILURE))
	end
	sessionPresent = buf[1+len] & 0x1 == 1 ? true : false
	connack_rc = buf[2+len]
	return connack_rc, sessionPresent
end

function deserializePublish(buf::Vector{UInt8}, buflen::Int)
    header = MQTTHeader(buf[1])
    msg = MQTTMessage()

    if mqttPacketType(header) != PUBLISH
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end
    msg.dup = getDup(header)
    msg.qos = getQos(header)
    msg.retained = getRetained(header)
    offset = 2
    (mylen,len) = decodePacketLen(view(buf,offset:buflen))
    offset += mylen
    (msg.topicName,mylen)  = readString(view(buf,offset:len))
    offset += mylen
    if msg.qos != MqttQosNONE
        (msg.msgid,mylen) = readInt(view(buf,offset:len))
        offset += mylen
    end
    msg.payload = readPayload(view(buf,offset:len))
end

function deserializeAck(buf::Vector{UInt8}, buflen::Int)
    header = MQTTHeader(buf[1])
    offset = 2
    (mylen,len) = decodePacketLen(view(buf,offset:buflen))
    offset += mylen
    (packetId, mylen) = readInt(view(buf,offset:len))
	return mqttPacketType(header), getDup(header), packetId
end

function deserializeSuback(buf::Vector{UInt8}, buflen::Int)
	if mqttPacketType(MQTTHeader(buf[1])) != SUBACK
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end

	offset = 2
	(mylen,len) = decodePacketLen(view(buf,offset:buflen))
	offset += mylen
	(packetId, mylen) = readInt(view(buf,offset:len))
	offset += mylen
	grantedQoS = readByte(view(buf,offset:len))

	return packetId, grantedQoS
end

function deserializeUnSuback(buf::Vector{UInt8}, buflen::Int)
	(magtype, dup, packetId) = deserializeAck(buf, buflen);
	if mqttPacketType(MQTTHeader(buf[1])) != SUBACK
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end
	return packetId
end
