pipes={
	names={},
	faces={[1]={x=-1,y=0,z=0},[2]={x=1,y=0,z=0},[4]={x=0,y=-1,z=0},[8]={x=0,y=1,z=0},[16]={x=0,y=0,z=1},[32]={x=0,y=0,z=-1}},        
	propagate={msgid=0,msg={}}
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


function pipes.pos2dir(pos1,pos2)
	local pos=vector.direction(pos1,pos2)        
	for a,b in pairs(pipes.faces) do		
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
		local vpos=vector.add(pos,a)
		local node=core.get_node(vpos)
		local pipe=pipes.names[node.name]
		if pipe then
			local b=false
			if pipe_org.on_facing then
				b=pipe_org.check_facing(pos,vpos)
				if b==true and pipe.on_facing then
					if pipe.on_facing(vpos,pos) then
						m=bit.bor(m,c)
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
			if not from or not vector.equals(vpos,from) then 
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

function pipes.propagate:new(from,pos,mesg)   
    --core.log("astas:prop:new")
    self.msgid=self.msgid+1
    local id=self.msgid
    local hash=core.hash_node_position(pos)
    local msg={id=id,org=from,msg=mesg,path={},queue={}}
    msg.queue[hash]=from
    --core.log(dump(msg))
    self.msg[id]=msg
end

function pipes.propagateloop()    
    local maxloop=10000
    for a,b in pairs(pipes.propagate.msg) do
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
            table.insert(b.path,c)
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
    core.after(1,pipes.propagateloop)   
end

core.after(1,pipes.propagateloop)

function pipes.propagate:push(from,pos,msg)
    local hash=minetest.hash_node_position(pos)
    if msg.path[hash] or msg.queue[hash] then 
        return false
    end
    msg.queue[hash]=from
    return true
end
-- test --

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
                on_punch=function (pos)
                        local msg="totor"
                        pipes.propagate:new(pos,pos,msg)
                end,
		pipe={
			class="test", -- type of pipe (items, liquid etc)
			--active={mode=1,timer=10},
			on_facing=function(pos_org,pos_dest) 				
				local meta=core.get_meta(pos_org)
				local m=meta:get_int("pipe:faces")
				m=bit.bor(m,pipes.pos2dir(pos_org,pos_dest))
				--core.log("astas.pipe.facing (".. debug(pos_org) .." faces :"..m)
				meta:set_int("pipe:faces",m)
				-- swap_node
				return true
			end,
			on_propagate=function (pos,from,msg)
				core.log("astas:on_prop:" .. debug(pos).. " from:".. debug(from))
                                local gates=pipes.get_gates(pos,from)
                                for a,b in pairs(gates) do
                                    pipes.propagate:push(pos,b,msg)
                                end
			end,
			on_defacing=function(pos_org,pos_dest) 
				--core.log(debug(pos_dest) .. " ask me (" .. debug(pos_org) ..") to destruct link if case")
				local meta=core.get_meta(pos_org)
				local m=meta:get_int("pipe:faces")
				m=m-pipes.pos2dir(pos_org,pos_dest) -- bit.? 
				meta:set_int("pipe:faces",m)
				-- swap_node
				return true
			end,
			check_facing=function(pos_org,pos_dest) 
				-- core.log("me (".. debug(pos_org) .. ") check if ".. debug(pos_dest) .." is compatible")
				return true
			end,
			set_faces=function(pos,faces)
				--core.log("astas:pipe.set_face (".. debug(pos).. ") faces ".. faces)
				local meta=core.get_meta(pos)
				meta:set_int("pipe:faces",faces)
				-- swap_node
			end
		},
	}
)
