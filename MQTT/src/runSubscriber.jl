include("load.jl")


function readLoop(client::MQTTClient)
	while true
		println("Listening for incoming messages...")
		timer = Timer(client.command_timeout_ms)
    	waitfor(client, PUBLISH, timer)
	end
end

function printFunction(message::MQTTMessage)
	println("RECEIVED MESSAGE: ", String(message.payload.load))
end

function runSubscribe(args)
	@show args
	if length(args) != 1
		println("Unexpected arguments. Only topic expected. Exiting...")

		exit(1)
	end

	topic=args[1]

	functionsDict = Dict{String,Function}("#"=> printFunction)


	client= MQTTClient(0,1000,256,256, Vector{UInt8}(256),Vector{UInt8}(256), 100, false, false, functionsDict, printFunction, Network(), Timer(100),ReentrantLock())

	clientId= round(Int64, time() * 1000)
	connectionData = MQTTPacketConnectData( StructId(['M','Q','T','C']), 0,
	    MqttVersion(MQTTv311), string("MqttSubscriberTest-",clientId), 300, false, false,
	    MQTTPacketWillOptions(), false, Nullable{String}(),  Nullable{String}() )

	MQTTConnect(client,connectionData)

	subscribeStatus = MQTTSubscribe(client,topic,FireAndForget,printFunction)

	if subscribeStatus == MQTTCLIENT_SUCCESS
		readLoop(client)
	else
		println("Unable to subscribe to topic. Exiting")
	end

end



runSubscribe(ARGS)
