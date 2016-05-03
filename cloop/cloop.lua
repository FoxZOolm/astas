--- class --- v1 --- minetested 

-- multiclass
-- other object (except function) are deepcopied (inclued meta)
-- /!\ no override checked /!\
-- class can be modified on fly (and affect all herited class/instance)
-- instance can't acceed to :new() 
-- class function aren't listed in instance (except if instance overrid it)

-- modified to be compatible with minetest... 

local _class={type="class"}
_class.__index=_class

function _class.__newindex(t,k,v)  
  local typ=type(v)
  if (typ=="function") then
    t.funcs[k]=v
  else
    t.vars[k]=v
  end
end

function _class:new(v)
  local i=dpc(self.vars,v)  
  setmetatable(i,{__index=self.funcs})
  return i
end

function class(a,b,c,d,e) -- replace with function class(...)
	local arg={[1]=a,[2]=b,[3]=c,[4]=d,[5]=e} -- delete this line
	local cc={funcs={},vars={}}
	setmetatable(cc,_class)
	if not arg then
		return cc
	end
	for _,a in ipairs(arg) do
		local typ=getmetatable(a)
		if not typ then
			for k,v in pairs(a) do 
				cc[k]=v
			end
		elseif typ.type=="class" then
			for k,v in pairs(a) do 
				for kk,vv in pairs(v) do
					cc[k][kk]=vv
				end
			end
		end
	end
	return cc
end

--- plugin ---
function dpc(a,c)
  if not c then
	 c={}
  end	 
  setmetatable(c,getmetatable(a))
  for k,v in pairs(a) do
    if type(v)=="table" then
      v=dpc(v)
    end
    c[k]=v
  end
  return c
end

function cloopdump(a,o)
  local r=""	
	if not a then
		return r
	end
  for k,v in pairs(a) do
    if #r>0 then
      r=r ..", "
    end
    r=r..k.."="
    local typ=type(v)
    if typ=="table" then
      r=r .."{" .. cloopdump(v) .. "}"
    elseif typ=="string" then    
      r=r .. "\"" .. v .. "\""
    elseif typ=="function" then
        r=r.."<function>"
    else
      r=r .. v
    end
  end
  return r
end

--- common class ---
cdumpable=class()
function cdumpable:dump()
  return cloopdump(self)
end

cforeachable=class()
function cforeachable:foreach(cb)
  for k,v in pairs(self) do
    cb(self,k,v)
  end
end

--- exemple ---
------------
-- myclass=class(otherclass1,otherclass2,{
--		... dafuw...
-- })
-- function myclass:foo()... end
--
-- myinstanceofmyclass=myclass:new()
