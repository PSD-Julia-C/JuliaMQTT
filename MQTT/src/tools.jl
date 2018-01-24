
function getPacketLen(rem_len::Int)
	rem_len += 1

	if rem_len < 128
		rem_len += 1
	elseif rem_len < 16384
		rem_len += 2
	elseif rem_len < 2097151
		rem_len += 3
	else
		rem_len += 4
	end
	return rem_len
end


function encodePacketLen(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, length::Int)
	rc::Int = 0
	while true
		(length, d::Int) = divrem(length, 128)

		# if there are more digits to encode, set the top bit of this digit
		if length > 0
			d |= 0x80
		end
		buf[rc += 1] = d

		length > 0 || break
	end
	return rc
end

function decodePacketLen(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true})

	multiplier = 1
	value = 0
	len = 1
	for len=1:4
		c = buf[len]
		value += (c & 127) * multiplier
		multiplier *= 128
		if (c & 128) == 0
			break
		end
	end
	return len,value
end

function readString(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true})
   	# the first two bytes are the length of the string */
    str = String(buf[1:length(buf)])
	return str
end

function readInt(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true})
   	# the first two bytes are the length of the string */
    len = Int(buf[1]) << 8 + Int(buf[2])
    return len, 2
end

function readPayload(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true})
		len = length(buf)
    return BufPayload(len, buf[1:length(buf)])
end

function readByte(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true})
   	# the first two bytes are the length of the string */
    value = buf[1]
    return value, 1
end


function writebuf(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, byte::UInt8)
	buf[1] = byte
	return 1
end

function writebuf(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true},string::Vector{UInt8} )
    len = length(string)
  	buf[1:2] = [UInt8(i) for i in divrem(len,256)]
	for i=1:len
		buf[i+2] = string[i]
	end
	return len+2
end

function writebuf(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true},num::Int)
	buf[1:2] = [UInt8(i) for i in divrem(num,256)]
	return 2
end

function writebuf(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true},string::String)
	len = length(string)
    buf[1:2] = [UInt8(i) for i in divrem(len,256)]
	for i=1:len
		buf[i+2] = string[i]
	end
	return len+2
end

function writebuf(buf::SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true},payload::Payload)
	len = payload.len
    buf[1:2] = [UInt8(i) for i in divrem(len,256)]
	for i=1:len
		buf[i+2] = payload.load[i]
	end
	return len+2
end
