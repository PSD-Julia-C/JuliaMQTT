
abstract type MQTTPacket
end

"""Header Definition eines MQTT Paketes"""
struct Header
    """
    retain : 1	 retained flag bit
    qos : 2    MqttQoS value, 0, 1 or 2
    dup : 1   DUP flag bit
    type : 4   message type nibble
        """
    data::UInt8
end

function mqttheader(; msgtype=PUBLISH, qos=MqttQoS(MqttQosNONE), retain=false, dup=false)
    flags::UInt8 = (retain ? 1 : 0)
    flags |= Int(qos) << 1
    flags |= (dup ? 1 : 0) << 3
    flags |= Int(msgtype) << 4
    Header(flags)
end

function mqttPacketType(h::Header)
    return MsgType(h.data >> 4)
end
function getRetained(h::Header)
    return h.data & 0x01
end
function getDup(h::Header)
    return h.data & 0x08 == 1 << 3
end

function getQos(h::Header)
    qos = MqttQoS((h.data << 4) >> 5)
    return qos
end

struct MQTTConnectFlags
    """ : 1
    cleansession : 1
    will : 1
    willQoS : 2
    willRetain : 1
    password : 1
    username : 1
    """
    flags::UInt8
end


function ConnectFlags( ;cleansession=false, will=false, willQoS=MqttQoS(FireAndForget), willRetain=false, password=false, username=false )
    flags = 	(cleansession ? 1 : 0) << 1
    flags |= 	(will ? 1 : 0) << 2
    flags |= 		Int(willQoS) << 3
    flags |= 	(willRetain ? 1 : 0) << 5
    flags |= 	(password ? 1 : 0) << 6
    flags |= 	(username ? 1 : 0) << 7
    MQTTConnectFlags(flags)
end

struct Connect <: MQTTPacket
    header::Header
    flags::MQTTConnectFlags
    protocol::String
    clientID::String
    willTopic::String
    willMsg::String
    keepAliveTimer::Int
    version::MqttVersion
end

struct Connack <: MQTTPacket
    header::Header
    flags::MQTTConnectFlags
    rc::ConnackCode
end

struct MqttPacket <: MQTTPacket
    header::Header
end

struct Subscribe <: MQTTPacket
    header::Header
    msgId::MQTTConnectFlags
    topics::Vector{String}
    qoss::Vector{MqttQoS}
    noTopics::Int #topic and qos count
end

struct Suback <: MQTTPacket
    header::Header
    msgId::Int
    qoss::Vector{MqttQoS}
end

struct Unsubscribe <: MQTTPacket
    header::Header
    msgId::Int
    topics::Vector{String}
    noTopics::Int #topic count
end

struct Publish <: MQTTPacket
    header::Header
    topic::String
    topiclen::Int
    msgId::Int
    payload::Payload
    payloadlen::Int
end

abstract type MQTTAck <: MQTTPacket end

struct Ack <: MQTTAck
    header::Header
    msgId::Int
end

struct Puback <: MQTTAck
    header::Header
    msgId::Int
end

struct Pubrec <: MQTTAck
    header::Header
    msgId::Int
end

struct Pubrel <: MQTTAck
    header::Header
    msgId::Int
end

struct Pubcomp <: MQTTAck
    header::Header
    msgId::Int
end

struct Unsuback <: MQTTAck
    header::Header
    msgId::Int
end
