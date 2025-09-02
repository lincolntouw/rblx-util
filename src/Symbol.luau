--[[
===========================================================
Symbols
===========================================================

AUTHOR      Lincoln Touw (github.com/lincolntouw)         
CREATED     07/24/2025                

Creates unique keys for use as table keys, etc.
     
===========================================================   
]]--

local Symbol = {}
local __symbols: {[string]: userdata} = {}        

function Symbol.new(name)   
  local self = newproxy(true) :: userdata
  if name then
    if type(name) ~= "string" then
      return error('expected type string @ argument 1 "name"')   
    end
    if __symbols[name] then 
      return __symbols[name] 
    end
    __symbols[name] = self   
  end
  return self
end    

return Symbol :: {
  new: (Name: string?) -> userdata,   
}
