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
		minetest.log(dump(fields))
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
	local alr=false
	for _,b in ipairs(m._semaphore.players) do
		if b==player then
			alr=true
			break
		end
	end
	if not alr then
		table.insert(m._semaphore.players,player)	
	end
	return r
end

local function dbgchat(p,m)
	minetest.chat_send_player(p,m)
end

local function mecmkfs(pos,player,items,machines,rech)
	local hash=core.hash_node_position(pos)
	local name="cdi"..hash
	minetest.create_detached_inventory(name,{})
	local inv=minetest.get_inventory({type="detached",name=name})
	inv:set_size("main",8)
	inv:set_size("show",1)

	local itemslist="test1,test2,test3"

local b=	"size[11.25,10]"..
			"field[0,0;0,0;id;$detinv;$detinv]"..
			"field[0.28,0.2;6.1,1.5;rech;recherche;]"..
			"button_exit[6,0.01;2,1.1;ok;refresh]"..
			"textlist[0,1;8,3;lis;$itemslist;1]"..			
			--"list[detached:%pattern%;main;8.25,1;3,3;]"..
			--"list[detached:%pattern_result%;main;8.25,5;3,1;]"..
			--"dropdown[8.25,4.1;3,2;test;%machine%,extractor;1]"..
			"list[detached:$detinv;main;0,4;5,1;]"..
			"list[detached:$detinv;show;6,4;1,1;]"..
			"button_exit[8,4;1,1;ext;ext]"..
			"button[0,5;8,1;deposite;Inventory]"..			
			"list[current_player;main;0,6;8,4;]"		
	
	b=b:gsub("$detinv",name):gsub("$itemslist",itemslist)
	core.show_formspec(player,"aeme:mec",b)
		
end

core.log("aeme:register_node aeme:mecontroler")
pipes:add("aeme:mecontroler",{
    description = "ME Controller",
	groups = {dig_immediate=2},
    tiles = {"bones_top.png","bones_bottom.png","bones_side.png","bones_side.png","bones_rear.png","bones_front.png"},
    paramtype = "light",
	on_punch=function(pos, node, player, pointed_thing)
		local cmd=ccmd:new({cmd=mecontroler.enum.cmd,mec=0,pipes=0,items=citemstacks:new({max_slot=-1,max_item=-1})})
		mecontroler.enum.semaphore.post(pos,cmd,payer:get_player_name())
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
		--			mecmkfs(pos,p,cmd.enum.items)
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

