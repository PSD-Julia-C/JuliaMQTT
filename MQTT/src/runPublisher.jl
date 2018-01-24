include("load.jl")

function runPublish(args)
   if length(args) == 0
   		println("No topic or message supplied, exiting")
   		exit(1)
   end

   println("Publishing the following topic & message:")
   @show args

   topic=args[1]
   message=args[2]

	connectionData = MQTTPacketConnectData( StructId(['M','Q','T','C']), 0,
	    MqttVersion(MQTTv311), "MqttPublisherTest", 300, false, false,
	    MQTTPacketWillOptions(), false, Nullable{String}(),  Nullable{String}() )

	client=MQTTClient()
	MQTTConnect(client,connectionData)

	message =  MQTTMessage(StructId(['M','Q','T','M']), 0, MqttQoS(FireAndForget), false, false, 0, topic, Payload(message))
	MQTTPublish(client,message)
	MQTTDisconnect(client)
end

runPublish(ARGS) #ARGS is a special julia keyword which takes an array of all command line arguments passed e.g. ARGS = ["cli arg1","cli arg2"] etc
