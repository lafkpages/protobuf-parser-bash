def consumestream($arr): # Reads stream elements from stdin until we have enough elements to build one object and returns them as array
input as $inp 
| if $inp|has(1) then consumestream($arr+[$inp]) # input=keyvalue pair => Add to array and consume more
  elif ($inp[0]|has(1)) then consumestream($arr) # input=closing subkey => Skip and consume more
  else $arr end; # input=closing root object => return array

def convert2obj($stream): # Converts an object in stream notation into an object, and merges the values of duplicate keys into arrays
reduce ($stream[]) as $kv ({}; # This function is based on http://stackoverflow.com/a/36974355/2606757
      $kv[0] as $k
      | $kv[1] as $v
      | (getpath($k)|type) as $t # type of existing value under the given key
      | if $t == "null" then setpath($k;$v) # value not existing => set value
        elif $t == "array" then setpath($k; getpath($k) + [$v] ) # value is already an array => add value to array
        else setpath($k; [getpath($k), $v ]) # single value => put existing and new value into an array
        end);

def mainloop(f):  (convert2obj(consumestream([input]))|f),mainloop(f); # Consumes streams forever, converts them into an object and applies the user provided filter
def mergeduplicates(f): try mainloop(f) catch if .=="break" then empty else error end; # Catches the "break" thrown by jq if there's no more input

#---------------- User code below --------------------------    

mergeduplicates(.) # merge duplicate keys in input, without any additional filters

#mergeduplicates(select(.layers)|.layers.frame) # merge duplicate keys in input and apply some filter afterwards
