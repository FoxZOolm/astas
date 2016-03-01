dofile(minetest.get_modpath("abspipes").."/upipes.lua")

local mepipes_pipe={
    set_faces=function(pos,faces)            
            local n=pipes.prepare_swap(pos,faces)
            core.swap_node(pos,n)
            return true
    end
}

local me_pipes={
    description = "ME Cable",
    tiles = {
        "bones_top.png",
        "bones_bottom.png",
        "bones_side.png",
        "bones_side.png",
        "bones_rear.png",	
        "bones_front.png"
    },
    inventory_image="bones_top.png",
    drop={}
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type="fixed"
    },
    paramtype2 = "facedir",
    groups = {dig_immediate=2},
    pipe=mepipes_pipe
}

for a,b in pairs(upipes) do
    local r=me_pipes
    r.nodebox.fixed=upipes[a]
    pipes:add("aeme#"..a",r)
end