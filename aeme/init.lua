dofile(minetest.get_modpath("abspipes").."/upipes.lua")

--- local function ---
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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
		on_propagate=function(pos,from,message)
			if message.msg.cmd==mecontroler.enum.cmd then
				message.msg.enum.cables=message.msg.enum.cables+1
			end
			pipes.on_propagate(pos,from,message)
		end
	}
}


core.log("aeme:init")
for a,b in pairs(upipes) do
    local r={}
	if a==0 then 
		r=deepcopy(me_cables)
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
		cmd="aeme:enum", -- msg={cmd="aeme:enum"...
		data={}
	}, -- callback "aeme:mec_enum"	
}

function mecontroler.enum:new(pos)
	local h=minetest.hash_node_position(pos)
	if self.data[h] then
		return false
	end
	self.data[h]={mec=0,cables=0,nb=0,freestorage=0}
	return self.data[h]
end

function mecontroler.enum:this(pos) -- helper
	local h=minetest.hash_node_position(pos)
	if self.data[h] then
		return false
	end	
	return self.data[h]
end

function mecontroler.enum:kill(pos)
	local h=minetest.hash_node_position(pos)
	self.data[h]=nil
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
		local e=mecontroler.enum:new(pos)		
		if e then 
			e.player=player:get_player_name()
			pipes.propagate:new(pos,{cmd=mecontroler.enum.cmd,enum=e})
		--else
			-- mecontrole.enum:this(pos).player
		end	
		--- test --- // absorb player items wielded & push storage msg
		local pwis=payer:get_wielded_item()
		local msg={msg=mestorage.items.cmd_push,pwis.to_table()} -- add from={from="player|me...",data=playerentity|data=pos}
		pwis:set_count(0)
		------------
	end,

	pipe={
		class="aeme:mecable",
		set_faces=function(pos,faces)
			core.log("aeme:mec set_faces")
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
				mecontroler.enum:kill(pos)
				return
			end
			if msg.cmd==mestorage.items.push then
				if msg.itemstack.count >0 then
					dbgchat(msg.enum.player,"no space found") -- todo: retrieve items					
				end
			end
		end
	}
})


--- ME STORAGE ---
mestorage={
	max_slot=63, -- like AE2 org
	inv={},
	item_push={
		cmd="aeme:mesia"
	}
}

function mestorage.inv:get(pos)
	local meta=core.get_meta(pos)
	local si=meta:get_string("aeme:mesinv")
	if not si then
		si={}
	else
		si=core.deserialize("return {".. si .."}") -- decompress ?
	end
	return si
end

function mestorage.inv:set(pos,inv)
	local meta=core.get_meta(pos)
	meta:get_string("aeme:mesinv",core.serialize(inv)) -- compress ?
end

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
		on_propagate=function(pos,from,message)			
			local meta=core.get_meta(pos)			
			if message.msg.cmd==mecontroler.enum.cmd then
				local si=mestorage.inv:get(pos)
				local es=message.msg.enum.items
				message.msg.enum.freespace=mestorage.max_slot-63
				for a,b in pairs(si) do
					local h=string.format("%s#%s#%d",b.name,b.meta,b.wear)
					if es[h] then
						es[h].count=es[h].count+b.count
					else
						es[h]={count=b.count}
					end
				end
			elseif message.msg.cmd==mestorage.item.cmd_push then
				local is=message.msg.itemstack
				local si=mestorage.inv:get(pos)
				local h=string.format("%s#%s#%d",ist.name,ist.meta,ist.wear)
				if si[h] then
					si[n].count=si[n].count+is:get_count()
					message.msg.items.count=0
					pipes.propagate:kill(message)				
					return
				end
				if #si<mestorage.max_items then
					si[h]=ist
					message.msg.items.count=0
					pipes.propagate:kill(message)
					return
				end			
			end			
			pipes.on_propagate(pos,from,message)
		end,
	}
})

