dofile(minetest.get_modpath("abspipes").."/upipes.lua")

--- class declaration ---

--- class itemstack ---
citemstack=class(dumpable,{name="",wear=0.0,meta="",count=0})

function citemstack:hash()
  return string.format("%s#%s#%s",self.name,self.wear,self.meta)
end

function citemstack:add(a)
  self.count=self.count+a
end

function citemstack:sub(a)
  local v=self.count
  v=v-a
  if v<0 then
    self.count=0
    return v
  end
  self.count=v
  return 0
end

function citemstack:eq(a)
  return self:hash()==a:hash()
end

--- class citemstacks ---
citemstacks=class(dumpable,{list={},slot=0,sum=0,maxslot=64,maxsum=10000})
function citemstacks:store(is)
    if is.count<1 then
        return is.count
    end
    if self.slot>=self.maxslot then
        return is.count
    end
    if self.sum>=self.maxsum then
        return is.count
    end

    local h=is:hash()
    local l=self.list[h]   
    local r=self.maxsum-self.sum

    if r<=is.count then
        local t=r
        r=is.count-r
        is.count=t
    else
        r=0
    end

    if not l then
        self.list[h]=dp(is)
        self.slot=self.slot+1
    else
        self[h].count=self[h].count+is.count        
    end

    self.sum=self.sum+is.count
    is.count=r

    return r
end


function citemstacks:ask(is)
    if is.ask<1 then
        return is.ask
    end
    local h=is:hash()
    local l=self.list[h]
    if not l then
        return is.ask
    end
    
    local r=l.count-is.ask
    if r<=0 then        
        r=is.ask-math.abs(r)                
        self.list[h]=nil
        self.slot=self.slot-1        
    else        
        r=is.ask
        l.count=l.count - is.ask        
    end
    is.ask=is.ask-r
    is.count=is.count+r    
    self.sum=self.sum-r
end

cmsgsem=class({list={}})

function cmsgsem:newmsg(sem,msg)
    if self:is(sem) then 
      return nil
    end
    local msg=cmessage:new()
    msg._semaphore={id=sem,_parent=self}
    self.list[sem]=msg
    return msg
end

function cmsgsem:is(sem)
  return self.list[sem]
end

function cmsgsem:kill(sem)
	self.list[sem]=nil
end

--- ME CABLE ---
local me_cables={
    description = "ME Cable",
    tiles = {"bones_top.png","bones_bottom.png","bones_side.png","bones_side.png","bones_rear.png","bones_front.png"},
	--drop{}
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {type="fixed"},
    groups = {dig_immediate=2,not_in_creative_inventory=1},
    pipe={
		class="aeme:mecable",
		on_propagate=function(pos,from,cmd)
			if cmd.cmd==mecontroler.enum.cmd then
				cmd.enum.cables=cmd.enum.cables+1
			end
			pipes.on_propagate(pos,from,cmd)
		end
	}
}


core.log("aeme:init")
for a,b in pairs(upipes) do
    local r={}
	if a==0 then 
		r=dpc(me_cables)
		r.groups.not_in_creative_inventory=nil
	else
		r=me_cables
	end
    r.node_box.fixed=b
	core.log("aeme: register_node aeme:mecable_"..a)
    pipes:add("aeme:mecable_"..a,r)
end

--- ME CONTROLER ---

-- Controler message ---
mecontroler={
	enum={
		cmd="aeme:enum", 
		semaphore=cmsgsem:new()
	}
}

function mecontroler.semaphore:post(pos,msg,player)
	local hash=core.hash_node_position(pos)
	local m=self:is(hash)
	if not m then
		m=self:newsem(hash,msg)
		m._semaphore.player={}
		pipes.propagates.post(msg)
	end
	table.insert(m._semaphore.players,player)	
end

local function dbgchat(p,m)
	minetest.chat_send_player(p,m)
end

core.log("aeme:register_node aeme:mecontroler")
pipes:add("aeme:mecontroler",{
    description = "ME Controller",
	groups = {dig_immediate=2},
    tiles = {"bones_top.png","bones_bottom.png","bones_side.png","bones_side.png","bones_rear.png","bones_front.png"},
    paramtype = "light",
	on_punch=function(pos, node, player, pointed_thing)		
		local cmd=ccmd:new()
		cmd.cmd=mecontroler.enum.cmd
		cmd.enum={mec=0, cables=0}
		mecontroler.semaphore:post(pos,cmd,player)
	end,

	pipe={
		class="aeme:mecable",
		set_faces=function(pos,faces)
			return true
		end,	
		on_propagate=function(pos,from,message)
			if message.msg.cmd==mecontroler.enum.cmd then
				message.msg.enum.mec=message.msg.enum.mec+1
			end
			pipes.on_propagate(pos,from,message)
		end,
		on_propagate_finished=function(pos,message)			
			local msg=message.msg	
			if msg.cmd==mecontroler.enum.cmd then				
				dbgchat(msg.enum.player ,string.format("#mec:%d #cables:%d",msg.enum.mec,msg.enum.cables))
				for a,b in pairs(msg.enum.items) do
					dbgchat(msg.enum.player ,string.format("%s x%d",b.name,b.count))
				end
				return
			end
		end
	}
})


--- ME STORAGE ---
mestorage={}

pipes:add("aeme:mestorage_items",{
    description = "ME Storage (items)",
	groups = {dig_immediate=2},
    tiles = {"bones_top.png","bones_bottom.png","bones_side.png","bones_side.png","bones_rear.png","bones_front.png"},
    paramtype = "light",

	pipe={
		class="aeme:mecable",
		set_faces=function(pos,faces)
			return true
		end,	
		on_propagate=function(pos,from,cmd)			
		end
	}
})

