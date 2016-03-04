pipes={
	names={},
	faces={[1]={x=-1,y=0,z=0},[2]={x=1,y=0,z=0},[4]={x=0,y=-1,z=0},[8]={x=0,y=1,z=0},[16]={x=0,y=0,z=1},[32]={x=0,y=0,z=-1}},
	propagate={msgid=0,msg={}},
	actives={}
}

local function dbg(v)
	return "x=".. v.x .." y=".. v.y .." Z=".. v.z
end

--[[- Hnd structure ---
	timer <--- time in MTformat
	delta <--- delta time
	data  <--- dodafkuw
	pipe  <--- pipe event handler
--]]-------------------

--[[- message structure --- (dont touch it)
	id    <--- id of message
	org   <--- pos of node org
	msg   <--- msg
	path  <--- list of node who receive message
	queue <--- list of node who wait message
	cbend <--- callback at end
--]]-----------------------

--[[- pipe event handler --
on_check=function(pos_org,pos_dest)
set_faces=function(pos,faces)
on_activation=function(pos,hnd,data)
active.init=function(pos,hnd,data)
on_propagate(pos,from,message)
on_propagate_finished(pos,message)
--]]-----------------------


--- pipes handler --- callback if overrided
function pipes.on_construct(pos)
	local node=core.get_node(pos)
	local pipe_org=pipes.names[node.name]	
	local meta_org=core.get_meta(pos)
	local faces_org=0
	meta_org:set_int("pipe:faces",0)
	for c,a in pairs(pipes.faces) do -- scan neightbore
		local vpos=vector.add(pos,a)
		local node=core.get_node(vpos)
		local pipe=pipes.names[node.name]
		if pipe then -- for pipe
			if pipe_org.on_check(pos,vpos) or pipe.on_check(vpos,pos) then
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
	if pipe_org.active then
		local hash=core.hash_node_position(pos)
		pipes.actives[hash]={pipe=pipe,timer=pipe.active.timer,delta=0,data={}}
		if pipe_org.active.init then
			pipe_org.active.init(pos,pipes.actives[hash])
		end
	end
end

function pipes.on_destruct(pos1)
	local node=core.get_node(pos1)
	local pipe=pipes.names[node.name]
	if pipe.active then
		local hash=core.hash_node_position(pos)
		pipes.actives[hash]=nil
	end

	local gates=pipes.get_gates(pos1)
	for _,pos2 in pairs(gates) do
		local node=core.get_node(pos2)
		local pipe=pipes.names[node.name]
		local dir=pipes.pos2dir(pos2,pos1)
		local meta=core.get_meta(pos2)
		local faces=meta:get_int("pipe:faces")
		dir=bit.bxor(dir,255)
		faces=bit.band(faces,dir)
		pipe.set_faces(pos2,faces)
		meta:set_int("pipe:faces",faces)
	end
end


--- Pipes public function ---
function pipes:register(n,v) -- register your own pipe (do register_node after)
	self.names[n]=v.pipe	
	if not v.on_construct then
		v.on_construct=pipes.on_construct
	end
	if not v.on_destruct then
		v.on_destruct=pipes.on_destruct
	end
	if not v.pipe.on_check then
		v.pipe.on_check=pipes.on_check
	end
	if not v.pipe.on_propagate then
		v.pipe.on_propagate=pipes.on_propagate
	end
	if not v.pipe.set_faces then
		v.pipe.set_faces=pipes.set_faces
	end	
end

function pipes:add(n,v) -- add your own pipe (instead register_node)
	pipes:register(n,v)
	minetest.register_node(n,v)
end

function pipes.pos2dir(pos1,pos2) -- return faces from pos1 to pos2 (in abspipes.faces type)
	local pos=vector.direction(pos1,pos2) -- vector.substract ?
	for a,b in pairs(pipes.faces) do
		if vector.equals(b,pos) then
			return a
		end
	end
	throw() -- (pos1 and pos2 must be side to side)
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

--- Pipes default Handler --- (dont need to callback)
function pipes.on_check(pos_org,pos_dest)
    return pipes.helper.compatible_pipes:is(pos_org,pos_dest)
end

function pipes.on_propagate(pos,from,msg)
    local gates=pipes.get_gates(pos,from)
    for a,b in pairs(gates) do
        pipes.propagate:push(pos,b,msg)
    end
end

function pipes.set_faces(pos,faces)            
	local n=pipes.prepare_swap(pos,faces)
	core.log("abspipes:pipes.set_faces: (".. dbg(pos)..") " .. n)
	core.swap_node(pos,{name=n})
	return true
end

--- Pipes propagate public function ---
function pipes.propagate:new(pos,mesg) -- make a new message
	self.msgid=self.msgid+1
	local id=self.msgid
	local hash=core.hash_node_position(pos)
	local msg={id=id,org=pos,msg=mesg,path={},queue={}}
	local node=core.get_node(pos)
	msg.cbend=pipes.names[node.name].on_propagate_finished
	msg.queue[hash]=pos
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

function pipes.propagate:kill(message)
	local pos=message.org
	self.msg[message.id].queue=nil
	local cb=message.cbend
	if cb then 
		cb(message)
	end	
	self.msg[message.id]=nil
end


--- Pipes GLOBAL ---
minetest.register_globalstep(function(delta) -- background propagate message loop
	local maxloop=100
	local msgnb=0
	for a,b in pairs(pipes.propagate.msg) do
		msgnb=msgnb+1
		local nb=0		
		for c,d in pairs(b.queue) do
			local pos=core.get_position_from_hash(c)
			core.emerge_area(pos,pos)
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
			if b.cbend then
				b.cbend(b.org,b)
			end			
			pipes.propagate.msg[a]=nil -- destroy msg
			b=nil
		end
		if maxloop==0 then
			break
		end
	end
	if msgnb==0 then
		pipes.propagate.msgid=0
	end
end)

minetest.register_globalstep(function(delta) -- background activation loop
	local maxloop=100
	for a in pairs(pipes.actives) do
		if a.timer>0 then
			a.delta=a.delta-delta
			if a.delta<=0 then
				maxloop=maxloop-1
				local pos=minetest.hash_node_position(a)
				a.pipe.on_activation(pos,a,a.data)
				if maxloop==0 then
					break
				end
				a.delta=a.timer
			end
		end
	end
end)


--- modders helper ---
function pipes.connect(pos1,pos2)
	local node=core.get_node(pos1)
	local pipe=pipes.names[node.name]
	local dir=pipes.pos2dir(pos1,pos2)
	local meta=core.get_meta(pos1)
	local faces=bit.bor(meta:get_int("pipe:faces"),dir)
	pipe.set_faces(pos1,dir)

	local node=core.get_node(pos2)
	local pipe=pipes.names[node.name]
	local dir=pipes.pos2dir(pos2,pos1)
	local meta=core.get_meta(pos2)
	local faces=bit.bor(meta:get_int("pipe:faces"),dir)
	pipe.set_faces(pos2,dir)
end

function pipes.disconnect(pos1,pos2)
	local node=core.get_node(pos1)
	local pipe=pipes.names[node.name]
	local dir=pipes.pos2dir(pos1,pos2)
	local meta=core.get_meta(pos1)
	local faces=meta:get_int("pipe:faces")
	dir=bit.bxor(dir,255)
	faces=bit.band(faces,dir)
	pipe.set_faces(pos1,dir)

	local node=core.get_node(pos2)
	local pipe=pipes.names[node.name]
	local dir=pipes.pos2dir(pos2,pos1)
	local meta=core.get_meta(pos2)
	local faces=meta:get_int("pipe:faces")
	dir=bit.bxor(dir,255)
	faces=bit.band(faces,dir)
	pipe.set_faces(pos2,dir)
end

function pipes.get_activation_hnd(pos)
	return pipes.actives[core.hash_node_position(pos)]
end

pipes.helper={compatible_pipes={}}
function pipes.helper.compatible_pipes:set(cl1,cl2)
	table.insert(self,cl1 .. "=".. cl2)
	table.insert(self,cl2 .. "=".. cl1)
end

function pipes.helper.compatible_pipes:is(pos1,pos2)
	local node=core.get_node(pos1)
	local class1=pipes.names[node.name].class
	local node=core.get_node(pos2)
	local class2=pipes.names[node.name].class
	if class1==class2 then 
		return true
	end
    local compatible=class1.."="..class2
	return self[compatible] or false	
end

function pipes.prepare_swap(pos,faces,extra) 
	local name=core.get_node(pos).name	
	local rawname=string.split(name,"_")[1]
	if not extra then 
		extra=""
	else
		extra="_" .. extra
	end
	return rawname .. "_" .. faces .. extra
end