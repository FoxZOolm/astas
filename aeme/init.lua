dofile(minetest.get_modpath("abspipes").."/upipes.lua")

--- class declaration ---

--- class itemstack ---
citemstack=class({name="",wear=0.0,meta="",count=0})

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
citemstacks=class({list={},slot=0,sum=0,maxslot=64,maxsum=10000})
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

--- FormSpec ---
minetest.register_on_player_receive_fields(function(player, formname, fields)	
	if formname=="aeme:mecdep" then
		
	end
end)

--- ME CONTROLER ---

-- Controler message ---
mecontroler={
	enum={
		cmd="aeme:enum", 
		semaphore=cmsgsem:new()
	}
}

function mecontroler.enum.semaphore:post(pos,msg,player)
	local hash=core.hash_node_position(pos)
	local m=self:is(hash)
	local r=true
	if not m then
		m=self:newsem(hash,msg)
		m._semaphore.players={}
		pipes.propagates.post(msg)
	else
		r=false
	end
	table.insert(m._semaphore.players,player)	
	return r
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
		local meta=core.get_meta(pos)
		local hash=core.hash_node_position(pos)
		--hash="test"
		minetest.create_detached_inventory("cdi"..hash,{})
		local inv=minetest.get_inventory({type="detached",name="cdi"..hash})
		inv:set_size("main",64)
		core.show_formspec(player:get_player_name(),"aeme:mecdep",string.format(
			"size[8,9]"..
			"list[deta
			"list[detached:cdi%s;main;0,0;8,4;]"..
			"button[0,4;8,1;deposite;deposite]"..
			"list[current_player;main;0,5;8,4;]",hash))
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		throw()
	end,
	pipe={
		class="aeme:mecable",
		set_faces=function(pos,faces)
			return true
		end,	
		on_propagate=function(pos,from,cmd)
			if cmd.cmd==mecontroler.enum.cmd then
				cmd.enum.mec=cmd.enum.mec+1
			end
			pipes.on_propagate(pos,from,cmd)
		end,
		on_propagate_finished=function(pos,cmd)						
			if cmd.cmd==mecontroler.enum.cmd then				
				for _,p in cmd.enum.players do
					dbgchat(p ,string.format("#mec:%d #cables:%d",cmd.enum.mec,cmd.enum.cables))
					for _,b in pairs(msg.enum.items) do
						dbgchat(p ,string.format("%s x%d",b.name,b.count))
					end
					return
				end
			end
		end
	}
})


--- ME STORAGE ---
mestorage={
	items={
		push={cmd="aeme:mespush"},
		pop ={cmd="aeme:mespop"}
	}
}

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
			local node=core.get_node(pos)
			local meta=core.get_meta(pos)
			if cmd.cmd==mecontroler.enum.cmd then			
				local mesis=core.deserialize("return {" .. meta:get_string("aeme:mesis") .."}")
				local is=citemstacks:new(mesis)
				for _,v in pairs(is.list) do 
					cmd.enum.items:add(v)
				end
			elseif cmd.cmd==mestorage.items.push.cmd then
				local mesis=core.deserialize("return {" .. meta:get_string("aeme:mesis") .."}")
				local is=citemstacks:new(mesis)
				is:add(cmd.itemstack)
				mesis=core.serialize(is.list)
				meta:set_string("aeme:mesis",mesis)
			elseif cmd.cmd==mestorage.items.pop.cmd then
				local mesis=core.deserialize("return {" .. meta:get_string("aeme:mesis") .."}")
				local is=citemstacks:new(mesis)
				is:sub(cmd.itemstack) -- itemstack.ask
				mesis=core.serialize(is.list)
				meta:set_string("aeme:mesis",mesis)
			end
			pipes.on_propagate(pos,from,cmd)
		end
	}
})

