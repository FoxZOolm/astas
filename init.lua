pipes={	
	names={values={}},
	faces={[1]={x=-1,y=0,z=0},[2]={x=1,y=0,z=0},[4]={x=0,y=-1,z=0},[8]={x=0,y=1,z=0},[16]={x=0,y=0,z=1},[32]={x=0,y=0,z=-1}}
}

data={}


function pipes:add(n,v)
	pipes.names.values[n]=v.pipe.class
	v.inh_apn=v.after_place_node
	v.after_place_node=pipes.after_place_node
	minetest.register_node(n,v)
end

function pipes.after_place_node(pos, placer, itemstack, pointed_thing)
	local node=minetest.get_node(pos)
	local meta=minetest.get_meta(pos)
	meta:set_int("pipe:faces",0)
	meta:set_string("pipe:class",pipes.names[node.name])
	minetest.log("--- apn ---")
	minetest.log(dump(meta))
end

--[[ function pipes.on_place(pos)
 local m=minetest.get_meta(pos)
  
 local m=0
 for a in pairs(pipes.faces)
	local vpos=pos
	vpos.x=vpos.x+a.x
	vpos.y=vpos.y+a.y
	vpos.z=vpos.z+a.z
	local meta=minetest.get_meta(vpos)
	local node=minetest.get_node(vpos)
	
 end
end
--]]


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
		after_place_node =pipes.after_place_node,
		pipe={class="test",active=10},
		meta="testtoto"
	}
)
