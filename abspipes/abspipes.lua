pipes={
	names={},
	faces={[1]={x=-1,y=0,z=0},[2]={x=1,y=0,z=0},[4]={x=0,y=-1,z=0},[8]={x=0,y=1,z=0},[16]={x=0,y=0,z=1},[32]={x=0,y=0,z=-1}},
	propagate={msgid=0,msg={}}
}

local function dbg(v)
	return "x=".. v.x .." y=".. v.y .." Z=".. v.z
end

--[[- pipe event handler //minimum schematic// --

-- call for checking compatibility between pos_org and pos_dest
check_pipe=function(pos_org,pos_dest)
	return true -- todo: make a complet exemple
end,

-- call at last for visual effect
set_faces=function(pos,faces)
	core.swap_node(pos,{name=..faces}) -- todo: make a complet exemple
end


--]]--------------------------------

function pipes:add(n,v)
	self.names[n]=v.pipe
	--- set default ---
	if not v.after_place_node then
		v.after_place_node=pipes.after_place_node
	end
	if not v.on_dig then
		v.on_dig=pipes.on_defacing
	end
	minetest.register_node(n,v)
end

--- pipes handler --- callback if overrided
function pipes.after_place_node(pos, placer, itemstack, pointed_thing)
	local node=core.get_node(pos)
	local meta=core.get_meta(pos)
	meta:set_int("pipe:faces",0)
	local pipe=pipes.names[node.name]
	pipes.facing(pos)
end

function pipes.on_dig(pos)
	pipes.defacing(pos)
end
---------------------

--- pipes internal function --- (u dont have to use it)
function pipes.facing(pos)
	local node=core.get_node(pos)
	local pipe_org=pipes.names[node.name]
	local meta_org=core.get_meta(pos)
	local faces_org=meta_org:get_int("pipe:faces")
	for c,a in pairs(pipes.faces) do -- scan neightbore
		local vpos=vector.add(pos,a)
		local node=core.get_node(vpos)
		local pipe=pipes.names[node.name]
		if pipe then -- for pipe
			if pipe_org.on_check_pipe(pos,vpos) or pipe.on_check_pipe(vpos,pos) then
				local meta_dest=core.get_meta(vpos)
				local faces_dest=meta_dest:get_int("pipe:faces")
				local dir=pipes.pos2dir(vpos,pos)				
				faces_dest=bit.bor(faces_dest,dir)
				pipe.set_faces(vpos,faces_dest) 
				meta_dest:set_int("pipe:faces",faces_dest)				
				faces_org=bit.bor(faces_org,c)				
			end
		end
	end
	pipe_org.set_faces(pos,faces_org)
	meta_org:set_int("pipe:faces",faces_org)
end

function pipes.defacing(pos)
	local gates=pipes.get_gates(pos)
	for _,a in pairs(gates) do
		local node=core.get_node(a.pos)
		local pipe=pipes.names[node.name]
		local meta=core.get_meta(a.pos)
		local faces=meta:get_int("pipe:faces")
		faces=faces-dir														 -- todo: use bit
		pipe.set_faces(pos_org,faces)
	end
end
-------------------------------

--- Pipes public function ---
function pipes.pos2dir(pos1,pos2) -- return face (in abspipes type)
	local pos=vector.direction(pos1,pos2)
	for a,b in pairs(pipes.faces) do
		if vector.equals(b,pos) then
			return a
		end
	end
	throw() -- what ???
end

function pipes.get_gates(pos,from) -- return list of node pointed by faces except from "from" (can be nil)
	local meta=core.get_meta(pos)
	local faces=meta:get_int("pipe:faces")
	local nodes={}
	for a,b in pairs(pipes.faces) do
		if bit.band(a,faces)==a then
			local vpos=vector.add(pos,pipes.faces[a])
			if not from or not vector.equals(vpos,from) then
				table.insert(nodes,vpos)
			end
		end
	end
	return nodes
end


--- Pipes propagate public function ---
function pipes.propagate:new(from,pos,mesg) -- make a new message
	--core.log("astas:prop:new")
	self.msgid=self.msgid+1
	local id=self.msgid
	local hash=core.hash_node_position(pos)
	local msg={id=id,org=from,msg=mesg,path={},queue={}}
	msg.queue[hash]=from
	--core.log(dump(msg))
	self.msg[id]=msg
end

function pipes.propagate:push(from,pos,msg) -- push msg to other (neighbore)
	local hash=minetest.hash_node_position(pos)
	if msg.path[hash] then
		return false
	end
	if msg.queue[hash] then
		return false
	end
	msg.queue[hash]=from
	return true
end
---------------------------------------

--- Pipes GLOBAL ---
minetest.register_globalstep(function(delta)
	local maxloop=100
	local msgnb=0
	for a,b in pairs(pipes.propagate.msg) do
		msgnb=msgnb+1
		local nb=0
		for c,d in pairs(b.queue) do
			local pos=core.get_position_from_hash(c)
			local node=core.get_node(pos)
			local pipe=pipes.names[node.name]
			nb=nb+1
			maxloop=maxloop-1
			if maxloop==0 then
				break
			end
			b.path[c]=d
			pipe.on_propagate(pos,d,b)
			b.queue[c]=nil -- table.delete ?
		end
		if nb==0 then
			b[a]=nil -- destroy msg
		end
		if maxloop==0 then
			break
		end
	end
	if msgnb==0 then 
		pipes.propagate.msgid=0
	end
end)
--------------------

-- test --

pipes:add("astas:stuff", {
	description = "stuff",
	tiles = {"bones_top.png","bones_bottom.png","bones_side.png","bones_side.png","bones_rear.png",	"bones_front.png"	},
	paramtype2 = "facedir",
	groups = {dig_immediate=2},
	on_punch=function (pos)
		local msg="totor"
		pipes.propagate:new(pos,pos,msg)
	end,
	pipe={
		on_check_pipe=function(pos_org,pos_dest)
			return true
		end,
		set_faces=function(pos,faces)
			core.log("abspipes:pipe.set_faces:"..dbg(pos).." faces:"..faces)
			return true
		end,
		on_propagate=function (pos,from,msg)
			core.log("abspipes.pipe:on_prop:" .. dbg(pos).. " from:".. dbg(from))
			local gates=pipes.get_gates(pos,from)
			for a,b in pairs(gates) do
				core.log("push:"..dbg(pos))
				pipes.propagate:push(pos,b,msg)
			end
		end,
	},
})