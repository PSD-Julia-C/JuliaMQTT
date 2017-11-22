
"""Check whether a topic matches a subscription.
For example:
foo/bar would match the subscription foo/# or +/bar
non/matching would not match the subscription non/+/+
"""
function isTopicMatched(topic::String, sub::String)
      slen = length(sub)
      tlen = length(topic)

       if slen > 0 && tlen > 0
           if (sub[1] == '$' && topic[1] != '$') || (topic[1] == '$' && sub[1] != '$')
              return false
           end
       end

     spos = 1
     tpos = 1
     multilevel_wildcard = false
     result = true

     while spos <= slen && tpos <= tlen
         if sub[spos] == topic[tpos]
                 if tpos == tlen
                         # Check for e.g. foo matching foo/#
                   if spos == slen-2 && sub[spos+1] == '/' && sub[spos+2] == '#'
                      multilevel_wildcard = true
                      break
                   end
                 end

                 spos += 1
                 tpos += 1

                 if tpos > tlen && spos == slen && sub[spos] == '+'
                       spos += 1
                       break
                 end
         else
               if sub[spos] == '+'
                   spos += 1
                   while tpos <= tlen && topic[tpos] != '/'
                         tpos += 1
                         if tpos > tlen && spos > slen
                             break
                         end
                   end
               elseif sub[spos] == '#'
                   multilevel_wildcard = true
                   if spos < slen
                       result = false
                   end
                   break
               else
                   result = false
                   break
               end
           end
     end
     if !multilevel_wildcard && (tpos <= tlen || spos <= slen)
         result = false
      end
      return result

end
