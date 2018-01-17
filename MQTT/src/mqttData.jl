
"""Payload Definition"""
abstract type Payload end
struct NoneP <: Payload end
struct BufPayload <: Payload
    len::Int
    load::Vector{UInt8}
end

function Payload(buf::Vector{UInt8})
    BufPayload(length(buf), buf)
end

function Payload(str::String)
    BufPayload(length(str), [UInt8(i) for i in str])
end

mutable struct Network
	sock::TCPSocket
	mqttreadTemp::Function
	mqttwrite::Function
	addr::String
	port::Int
end
Network() = Network(TCPSocket(), mqttreadTemp, mqttwrite, String("localhost"), 7777) #String("test.mosquitto.org"), 1883) #localhost 7777


"""payload and attributes"""
mutable struct MQTTMessage
	struct_id::StructId
	struct_version::Int
	qos::MqttQoS
	retained::Bool
	dup::Bool
	msgid::Int
	topicName::String
	payload::Payload
end
MQTTMessage() = MQTTMessage(StructId(['M','Q','T','M']), 0, MqttQoS(FireAndForget), false, false, 0, "test", Payload("TEST MESSAGE"))

struct MQTTAckMessage
	msgtype::MsgType
	qos::MqttQoS
	retained::Bool
	dup::Bool
	msgid::Int
end

mutable struct MQTTClient
	next_packetid::Int
	command_timeout_ms::Int
	buf_size::Int
	readbuf_size::Int
	buf::Vector{UInt8}
	readbuf::Vector{UInt8}
	keepAliveInterval::Int
	ping_outstanding::Bool
	isconnected::Bool
	messageHandlers::Dict{String, Function}
	defaultMessageHandler::Function
	ipstack::Network
	ping_timer::Timer
    mutex::ReentrantLock
end

function emptyfunc end

MQTTClient() = MQTTClient(0,1000,256,256, Vector{UInt8}(256),Vector{UInt8}(256), 100, false, false, Dict{String, Function}(), emptyfunc, Network(), Timer(100),ReentrantLock())


"""Last Will and Testament"""
mutable struct MQTTPacketWillOptions
	"""The eyecatcher for this structure.  must be MQTW."""
	struct_id::StructId
	"""The version number of this structure.  Must be 0"""
	struct_version::Int
	"""The LWT topic to which the LWT message will be published."""
	topicName::String
	"""The LWT payload."""
	message::String
	"""The retained flag for the LWT message (see MQTTAsync_message.retained)."""
	retained::Bool
	""" The quality of service setting for the LWT message """
	qos::MqttQoS
end
MQTTPacketWillOptions() =  MQTTPacketWillOptions(StructId(['M','Q','T','W']), 0, String(""), String(""), false, MqttQoS(FireAndForget))

mutable struct MQTTPacketConnectData
	"""The eyecatcher for this structure.  must be MQTC."""
	struct_id::StructId
	"""The version number of this structure.  Must be 0"""
	struct_version::Int
	"""Version of MQTT to be used.  3 = 3.1 4 = 3.1.1 """
	MQTTVersion::MqttVersion

	clientID::String
	keepAliveInterval::Int
	cleansession::Bool
	reliable::Bool
	will::MQTTPacketWillOptions
	willFlag::Bool
	username::Nullable{String}
	password::Nullable{String}
end

MQTTPacketConnectData() = MQTTPacketConnectData( StructId(['M','Q','T','C']), 0,
    MqttVersion(MQTTv311), "cncID", 10, false, false,
    MQTTPacketWillOptions(), false, Nullable{String}(),  Nullable{String}() )

struct MQTTConnackFlags
	flags::UInt8
end
