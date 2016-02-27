pipes={
	names={},
	faces={[1]={x=-1,y=0,z=0},[2]={x=1,y=0,z=0},[4]={x=0,y=-1,z=0},[8]={x=0,y=1,z=0},[16]={x=0,y=0,z=1},[32]={x=0,y=0,z=-1}},
	propagate={msg={}}
}

-- mode // not implented yet
--- 1 : on_timer
--- 2 : global step
--- 3 : global step force load
--- 4 : ABM (are u sure ???)

-- pipe prop // not implented yet
--- class:string 
--- active{mode:mode,timer:int)

-- pipe method
--- on_facing(pos_org,pos_dest) 
--- check_facing(pos_org,pos_dest) 
--- set_faces(pos,faces:int)
--- on_defacing(pos_org,pos_dest) 
--- after_place_node(pos, placer, itemstack, pointed_thing) // callback
--- on_destruct(pos) // callback

local function debug(v)
	return "x=".. v.x .." y=".. v.y .." Z=".. v.z
end


function pipes.pos2dir(pos2,pos1)
	local pos=vector.direction(pos1,pos2)
	for a,b in pairs(pipes.faces) do
		--core.log("? " .. debug(pos1).."==" .. debug(b))
		if vector.equals(b,pos) then
			return a
		end
	end
	throw()
end

function pipes:add(n,v)
	self.names[n]=v.pipe
	v.after_place_node=pipes.after_place_node
	v.on_destruct=pipes.on_destruct
	core.register_node(n,v)
end

function pipes.after_place_node(pos, placer, itemstack, pointed_thing)
	local node=core.get_node(pos)
	local meta=core.get_meta(pos)
	meta:set_int("pipe:faces",0)
	local pipe=pipes.names[node.name]
	--[[if pipe.active then
		meta:set_int("pipe:active",pipe.active.mode)
		meta:set_int("pipe:timer",pipe.active.timer)
		if pipe.active.mode==1 then
			local timer=core.get_node_timer(pos)
			timer.start(pipe.active.timer)
		else
			core.log("mode not implemented yet " .. node.name)
			throw()
		end
	end--]]
	if pipe.after_place_node then -- really needed ?
		pipe.after_place_node(pos, placer, itemstack, pointed_thing)
	end
	if pipe.on_facing then
		pipes.facing(pos)
	end
end

function pipes.on_destruct(pos)
	local node=core.get_node(pos)
	local pipe=pipes.names[node.name]
	pipes.defacing(pos)
	if pipe.on_destruct then  -- really needed ?
		pipe.on_destruct(pos)
	end
end

function pipes.facing(pos)
	local node=core.get_node(pos)
	local pipe_org=pipes.names[node.name]
	local meta=core.get_meta(pos)
	local m=meta:get_int("pipe:faces")
	for c,a in pairs(pipes.faces) do
		--core.log("dir ".. c .. " " .. debug(a))
		local vpos=vector.add(pos,a)
		local node=core.get_node(vpos)
		local pipe=pipes.names[node.name]
		if pipe then
			local b=false
			if pipe_org.on_facing then
				b=pipe_org.check_facing(pos,vpos)
				if b==true and pipe.on_facing then
					if pipe.on_facing(vpos,pos) then
						m=bit.band(m,c)
					end
				end
			end
		end
	end
	if pipe_org.set_faces then 
		pipe_org.set_faces(pos,m)
	end
end

function pipes.defacing(pos)
	local node=core.get_node(pos)
	local pipe_org=pipes.names[node.name]
	local meta=core.get_meta(pos)
	for c,a in pairs(pipes.faces) do
		--core.log("dir ".. c .. " " .. dump(a))
		local vpos=vector.add(vpos,a)
		local node=core.get_node(vpos)
		local pipe=pipes.names[node.name]
		if pipe then
			local b=false
			if pipe_org.on_facing then
				b=pipe_org.check_facing(pos,vpos)
				if b==true and pipe.on_defacing then
					pipe.on_defacing(vpos,pos)
				end
			end
		end
	end
end

-- untested --

function pipes.get_gates(pos,from) -- return list of node pointer by faces except from "from" (can be nil)
	local meta=core.get_meta(pos)
	local faces=meta:get_int("pipe:faces")
	local nodes={}
	for a,b in pairs(pipes.faces) do
		if bit.band(a,faces)==a then
			local vpos=vector.add(pos,pipes.faces[a])
			if not vector.equals(vpos,from) then 
				table.insert(nodes,vpos)
			end
		end
	end
	return nodes
end

--- message
-- id (time ?)
-- org (pos of 1st)

-- on thinking --
function pipes.propagate:propagate(pos,from,msg)
	local hash=core.hash_node_position(pos)
	local p=msg.path
	if not p then 
		p={}
		p.count=0
		msg.path={}
		msg.org=pos
	elseif p[hash] then
		return false
	end 
	p.count=p.count+1
	table.insert(p,hash)
	--core.forceload(pos)
	local node=core.get_node(pos)
	local pipe=pipes.names[node.name]
	from=pos
	pipe.on_propagate(pos,from,msg)
	--core.forceload_free(pos)
end

function pipes.propagate:push(pos,from,msg)
	--table.insert(self.msg[msg.id],{pos,from,msg})
end

function pipes.propagate:pop(msg)
	msg.count=msg.count-1
	if msg.count==0 then
		msg=nil -- callback to 1st ?
	end
end

function pipes.on_propagate(pos,from,msg)
	local gates=pipes.get_gates(pos,from)
	for a,b in pairs(gates) do
		pipes.propagate:push(b,pos,msg)
	end
	pipes.propagate:pop(msg)
end




-- test --c

pipes:add("astas:stuff", {
	description = "stuff",
		tiles = {
			"bones_top.png",
			"bones_bottom.png",
			"bones_side.png",
			"bones_side.png",
			"bones_rear.png",
			"bones_front.png"
		},
		paramtype2 = "facedir",
		groups = {dig_immediate=2},
		pipe={
			class="test", -- type of pipe (items, liquid etc)
			--active={mode=1,timer=10},
			on_facing=function(pos_org,pos_dest) 
				--core.log(debug(pos_dest) .. " ask me (" .. debug(pos_org) ..") if I'm compatible with him")
				local meta=core.get_meta(pos_org)
				local m=meta:get_int("pipe:faces")
				m=m+pipes.pos2dir(pos_org,pos_dest)
				core.log("(".. debug(pos_org) .." faces :"..m)
				meta:set_int("pipe:faces",m)
				-- swap_node
				return true
			end,
			on_punch=function (pos)
				--local msg={id=1,msg="totor"}
				pipes.propagate:propagate(pos,nil,msg) -- use push instead !!!
			end,
			on_propagate=function (pos,from,msg)
				core.log("prop:" .. debug(pos).. " from:".. debug(from) .. " msg:".. msg)
			end,
			on_defacing=function(pos_org,pos_dest) 
				--core.log(debug(pos_dest) .. " ask me (" .. debug(pos_org) ..") to destruct link if case")
				local meta=core.get_meta(pos_org)
				local m=meta:get_int("pipe:faces")
				m=m-pipes.pos2dir(pos_org,pos_dest)
				core.log("(".. debug(pos_org) .." faces :"..m)
				meta:set_int("pipe:faces",m)
				-- swap_node
				return true
			end,
			check_facing=function(pos_org,pos_dest) 
				-- core.log("me (".. debug(pos_org) .. ") check if ".. debug(pos_dest) .." is compatible")
				-- face to link is obtain with pipes.pos2dir
				return true
			end,
			set_faces=function(pos,faces)
				core.log("(".. debug(pos).. ") faces ".. faces)
				local meta=core.get_meta(pos)
				meta:set_int("pipe:faces",faces)
				-- swap_node
			end
		},
	}
)
