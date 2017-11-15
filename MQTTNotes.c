/*
None of the code in here is ment to run
simply made as a c file to make it easier 
to read
*/

/*
Author: Dan Hederman
College: DIT & h-da

Notes to help in julia coded in C 

*/

//The algorithm for encoding a non negative integer (X) into the variable length encoding scheme is as follows:
do
              encodedByte = X % 128
              X = X / 128
             // if there are more data to encode, set the top bit of this byte
             if ( X > 0 )
                 encodedByte = encodedByte | 128
             endif
                 'output' encodedByte
        while ( X > 0 )
			
//Algorithm to decode remaining length field 

		multiplier = 1
       value = 0
       do
            encodedByte = 'next byte from stream'
            value += ( encodedByte AND 127) * multiplier
            multiplier *= 128
            if (multiplier > 128*128*128)
               throw Error(Malformed Remaining Length)
       while (( encodedByte & 128) != 0)