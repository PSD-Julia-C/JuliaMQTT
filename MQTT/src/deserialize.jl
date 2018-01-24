function deserializeConnack(buf::Vector{UInt8}, buflen::Int)
	header = Header(buf[1])

	if (mqttPacketType(header) != CONNACK)
		throw(MqttReturnException(MQTTCLIENT_FAILURE))
	end

	(len, mylen) = decodePacketLen(view(buf,2:4)) # read remaining length */
	if len + mylen < 2
		throw(MqttReturnException(MQTTCLIENT_FAILURE))
	end
	sessionPresent = buf[1+mylen] & 0x1 == 1 ? true : false
	connack_rc = buf[2+mylen]
	return connack_rc, sessionPresent
end

function deserializePublish(buf::Vector{UInt8}, buflen::Int)
    header = Header(buf[1])
    msg = MQTTMessage()

    if mqttPacketType(header) != PUBLISH
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end
    msg.dup = getDup(header)
    msg.qos = getQos(header)
    msg.retained = getRetained(header)
    offset = 2
    (mylen,len) = decodePacketLen(view(buf,offset:buflen))

		offset = 4
    topicLength = buf[offset]
		topicEnd = offset + topicLength
    msg.topicName  = readString(view(buf,offset+1:topicEnd))

		# +2 added as topicEnd +1 is the byte before the message ID
		offset = topicEnd+2

    if msg.qos != MqttQosNONE
			#readint not necessary as handling buf manually
			msg.msgid = Int(buf[offset])
    end
		offset += 2
		payloadLen = buf[offset]
		payloadEnd = offset + payloadLen

    msg.payload = readPayload(view(buf,offset+1:payloadEnd))
    return msg
end

function deserializeAck(buf::Vector{UInt8}, buflen::Int)
    header = Header(buf[1])
    offset = 2
    (mylen,len) = decodePacketLen(view(buf,offset:buflen))
    offset += mylen
    (packetId, mylen) = readInt(view(buf,offset:buflen))
	return mqttPacketType(header), getDup(header), packetId
end

function deserializeSuback(buf::Vector{UInt8}, buflen::Int)
	if mqttPacketType(Header(buf[1])) != SUBACK
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end

	offset = 2
	(mylen,len) = decodePacketLen(view(buf,offset:buflen))
	offset += mylen
	(packetId, mylen) = readInt(view(buf,3:4))
 	offset += mylen
 	grantedQoS = readByte(view(buf,5:5))
	return packetId, grantedQoS
end

function deserializeUnSuback(buf::Vector{UInt8}, buflen::Int)
	(magtype, dup, packetId) = deserializeAck(buf, buflen);
	if mqttPacketType(MQTTHeader(buf[1])) != SUBACK
        throw(MqttPacketException(MQTTPACKET_SERIALIZE_ERROR))
    end
	return packetId
end
