utils = {}
utils.concat_percents = function(percent1, percent2)
  if percent1 == nil or percent1 < 0 then
    percent1 = 0
  end
  if percent2 == nil or percent2 < 0 then
    percent2 = 0
  end
  
  local sum = percent1 + percent2
  if sum > 100 then
    sum = 100
  end
  
  return sum
end

-- Main object, wraps all grinder related functions, variables.
local grinder = {
  fuel_percent = 0,
  item_percent = 0,
  MAX_WATER_LVL = 100, -- max water level (should be no more than 100 as it also represent percent on formspec)
  MIN_WATER_LVL = 5 -- min water level required for processing ores
}

-- Constants
grinder.GUI_BACKGROUND = default.gui_bg
grinder.GUI_BACKGROUND_IMG = default.gui_bg_img
grinder.GUI_SLOTS_IMG = default.gui_slots
grinder.GUI_FUEL_TEXTURE_FG = "default_water.png"
grinder.GUI_FUEL_TEXTURE_BG = "grinder_liquid_bg.png"
grinder.GUI_PROGRESS_BAR_TEXTURE_FG = "gui_furnace_arrow_fg.png"
grinder.GUI_PROGRESS_BAR_TEXTURE_BG = "gui_furnace_arrow_bg.png"

-- From spec, defines grinder UI menu
grinder.formspec = function(fuel_percent, item_percent)
  local form = "size[8,8.5]" ..
    grinder.GUI_BACKGROUND ..
    grinder.GUI_BACKGROUND_IMG ..
    grinder.GUI_SLOTS_IMG ..

    -- Processed item slot
    "list[current_name;src;0.75,1;1,1;]" ..
    
    -- Fuel slot with remaining water/fuel background
    "image[0.75,2.1;1,1;" .. grinder.GUI_FUEL_TEXTURE_BG .. "^[lowpart:"..
    (fuel_percent) .. ":" .. grinder.GUI_FUEL_TEXTURE_FG .. "]" ..
    "list[current_name;fuel;0.75,2.1;1,1;]" ..
    
    -- Progress bar
    "image[2.25,1.5;1,1;" .. grinder.GUI_PROGRESS_BAR_TEXTURE_BG .. "^[lowpart:" ..
    (item_percent) .. ":" .. grinder.GUI_PROGRESS_BAR_TEXTURE_FG .. "^[transformR270]" ..

    -- Finished product items slots
    "list[current_name;dst;3.75,1.5;4,1;]"..
    
    -- Player inventory
    "list[current_player;main;0,4.25;8,1;]"..
    "list[current_player;main;0,5.5;8,3;8]"..
    
    default.get_hotbar_bg(0, 4.25)
  
  return form
end    
    
grinder.allow_metadata_inventory_put = function (pos, listname, index, stack, player)
  
  -- List of all supported 'fuels' (water sources)
  if listname == "fuel" then
  
    if stack:get_name() == "bucket:bucket_water" then
      return stack:get_count()
    end
  
  end

  -- List of all supported ores
  if listname == "src" then
  
    if stack:get_name() == "default:stone_with_iron" then
      return stack:get_count()
    end
  
  end

  return 0
end

grinder.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

grinder.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  return stack:get_count()
end

grinder.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end

minetest.register_node("grinder:industrial_grinder", {
  description = "Industrial Grinder",
  stack_max = 1,
  tiles = {"grinder_side.png", "grinder_side.png", "grinder_side.png",
           "grinder_side.png", "grinder_side.png", "grinder_active_front.png"},
  paramtype2 = "facedir",
  groups = {cracky=2},
  legacy_facedir_simple = true,
  is_ground_content = false,
  sounds = default.node_sound_stone_defaults(),
  
  can_dig = grinder.can_dig,
  
  allow_metadata_inventory_put = grinder.allow_metadata_inventory_put,
  allow_metadata_inventory_move = grinder.allow_metadata_inventory_move,
  allow_metadata_inventory_take = grinder.allow_metadata_inventory_take,
  
  on_construct = function (pos)
    local meta = minetest.get_meta(pos)
    meta:set_float("water_level", 0)
    meta:set_float("progress_level", 0)
    meta:set_string("formspec", grinder.formspec(0, 0))
    meta:set_string("infotext", "Industrial Grinder\nLevel 1")
    
    local inv = meta:get_inventory()
    for listname, size in pairs({
        src = 1,
        fuel = 1,
        dst = 4,
    }) do
      if inv:get_size(listname) ~= size then
        inv:set_size(listname, size)
      end
    end
    
  end
})

local function swap_node(pos, name)
  local node = minetest.get_node(pos)
  if node.name == name then
    return
  end
  node.name = name
  minetest.swap_node(pos, node)
end

minetest.register_abm({
  nodenames = {"grinder:industrial_grinder"},
  interval = 1.0,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    local meta = minetest.get_meta(pos)
    local water_level = meta:get_float("water_level") or 0
    local progress_level = meta:get_float("progress_level") or 0
    local inv = meta:get_inventory()
    local srclist = inv:get_list("src")
    local fuellist = inv:get_list("fuel")
    local dstlist = inv:get_list("dst")

    if #fuellist > 0 then
      local fuel_stack = fuellist[1]
      local fuel_name = fuel_stack:get_name();
      
      if fuel_name == "bucket:bucket_water" and water_level < grinder.MAX_WATER_LVL then
        local WATER_LVL_FROM_BUCKET = 40
        
        -- determine if there are remaining space in destiny inventory slots (if not stop adding water)
        local leftover_stack = inv:add_item("dst", ItemStack("bucket:bucket_empty"))
        if leftover_stack:is_empty() then
          water_level = utils.concat_percents(water_level, WATER_LVL_FROM_BUCKET)
          inv:remove_item("fuel", fuel_stack:take_item())
        end
      end
    end
    
    if #srclist > 0 then
      local ore_stack = srclist[1]
      local ore_name = ore_stack:get_name();
      
      if progress_level == 100 then
        progress_level = 0
        
        if ore_name == "default:stone_with_iron" then
          local leftover_stack = inv:add_item("dst", ItemStack("default:iron_lump 2"))
          if leftover_stack:is_empty() then
            inv:remove_item("src", ore_stack:take_item())
          end
        end
      elseif ore_name == "default:stone_with_iron" and water_level >= grinder.MIN_WATER_LVL then
        water_level = water_level - grinder.MIN_WATER_LVL
        progress_level = utils.concat_percents(progress_level, 10)
      end
    end
    
    meta:set_float("water_level", water_level)
    meta:set_float("progress_level", progress_level)
    meta:set_string("formspec", grinder.formspec(water_level, progress_level))
    
  end,
})
