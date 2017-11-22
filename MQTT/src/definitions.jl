

"""Message Type"""
@enum( MsgType,
    NONE=0x0,
    CONNECT=0x1, CONNACK=0x2, PUBLISH=0x3, PUBACK=0x4, PUBREC=0x5, PUBREL=0x6,
    PUBCOMP=0x7, SUBSCRIBE=0x8, SUBACK=0x9, UNSUBSCRIBE=0xA, UNSUBACK=0xB,
    PINGREQ=0xC, PINGRESP=0xD, DISCONNECT=0xE)

"""Log Level"""
@enum( LogLevel,
  MQTT_LOG_INFO=0x01, MQTT_LOG_NOTICE=0x02, MQTT_LOG_WARNING=0x04,
  MQTT_LOG_ERR=0x08, MQTT_LOG_DEBUG=0x10)

"""Connack Codes"""
@enum( ConnackCode,
  ACCEPTED=0, PROTOCOL_VERSION=1, IDENTIFIER_REJECTED=2,
  SERVER_UNAVAILABLE=3, BAD_USERNAME_PASSWORD=4, NOT_AUTHORIZED=5)

"""Connection state"""
@enum( ConnectionState,
  cs_new=0, connected=1,
  disconnecting=2, connect_async=3)

"""Message state"""
@enum( MsgState,
  invalid=0, publish=1, wait_for_puback=2, wait_for_pubrec=3,
  resend_pubrel=4, wait_for_pubrel=5, resend_pubcomp=6,
  wait_for_pubcomp=7, send_pubrec=8, queued = 9)

"""Error values"""
@enum( ErrVal,
  AGAIN=-1, SUCCESS=0, NOMEM=1, PROTOCOL=2, INVAL=3,
  NO_CONN=4, CONN_REFUSED=5, NOT_FOUND=6, CONN_LOST=7,
  TLS=8, PAYLOAD_SIZE=9, NOT_SUPPORTED=10, AUTH=11,
  ACL_DENIED=12, UNKNOWN=13, ERRNO=14, QUEUE_SIZE=15)

struct MqttConnectionException <: Exception
    errCode::ErrVal
end


"""Return, Codes"""
@enum( MqttReturnCode,
  MQTTCLIENT_SUCCESS=0, MQTTCLIENT_FAILURE=-1, MQTTCLIENT_PERSISTENCE_ERROR=-2,
  MQTTCLIENT_DISCONNECTED=-3, MQTTCLIENT_MAX_MESSAGES_INFLIGHT=-4,
  MQTTCLIENT_BAD_UTF8_STRING=-5, MQTTCLIENT_NULL_PARAMETER=-6,
  MQTTCLIENT_TOPICNAME_TRUNCATED=-7, MQTTCLIENT_BAD_STRUCTURE=-8,
  MQTTCLIENT_BAD_QOS=-9)

  struct MqttReturnException <: Exception
      returnCode::MqttReturnCode
  end

"""QoS Level"""
@enum( MqttQoS,
  MqttQosNONE=0,FireAndForget=1, AtLeastOnce=2, OnceAndOnlyOne=3)

""" Connect options"""
@enum( ConnectOptions,
  NoSSL=0, NoServerURI=1, NoMqttVersion=2, NoReturnedValues=3, Standard=4)

"""Mqtt Version"""
@enum( MqttVersion,
  MQTTDefault=0, MQTTv31=3, MQTTv311=4)

"""Mqtt Read and Write Codes"""
@enum( MqttPacketError,
    MQTTPACKET_SERIALIZE_ERROR=-3,
	MQTTPACKET_BUFFER_TOO_SHORT=-2,
	MQTTPACKET_READ_ERROR=-1,
	MQTTPACKET_READ_COMPLETE=0)

struct MqttPacketException <: Exception
    errCode::MqttPacketError
end

const MAX_PACKET_ID = 65535

"""Mqtt Erkennungsmarker"""
struct StructId
  id::Vector{UInt8}
end
