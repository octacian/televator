-- televator/init.lua

local delay = {}

local itemset
if minetest.get_modpath("default") then
  itemset = {
    steel = "default:steel_ingot",
    gold = "default:gold_ingot",
    copper = "default:copper_ingot",
    glass = "default:glass",
  }
end

---
--- Functions
---

-- [function] Get near elevators
local function get_near_elevators(pos, which)
  for i = 1, 16 do
    local cpos = vector.new(pos)

    if which == "above" then
      cpos.y = cpos.y + i
    elseif which == "below" then
      cpos.y = cpos.y - i
    end

    local name =  minetest.get_node(cpos).name
    if (which == "above" and name == "televator:elevator")
        or (which == "below" and i ~= 1 and name == "televator:elevator") then
      cpos.y = cpos.y + 1
      return cpos
    elseif name ~= "air" and name ~= "televator:elevator" then
      return
    end
  end
end

-- [function] Elevator safe
local function is_safe(pos)
  for i = 0, 1 do
    local tpos = vector.new(pos)
    tpos.y = tpos.y + i

    if minetest.get_node(tpos).name ~= "air" then
      return
    end
  end

  return true
end

---
--- Registrations
---

-- [register] Elevator node
minetest.register_node("televator:elevator", {
  description = "Elevator\n"..
      minetest.colorize("grey","Can be placed up to 16 nodes apart\n"
          .."Jump to go up, sneak to go down"),
  tiles = {"televator_elevator.png"},
  groups = {cracky = 2, disable_jump = 1},
  after_place_node = function(pos)
    -- Set infotext
    minetest.get_meta(pos):set_string("infotext", "Elevator")
  end,
})

-- [register] Recipe
if itemset then
  minetest.register_craft({
    output = "televator:elevator 2",
    recipe = {
      {itemset.steel, itemset.glass, itemset.steel},
      {itemset.steel, itemset.gold, itemset.steel},
      {itemset.steel, itemset.copper, itemset.steel,}
    },
  })
end

-- [register] Globalstep
minetest.register_globalstep(function(dtime)
  for _, player in pairs(minetest.get_connected_players()) do
    local pos  = player:get_pos()
    local name = player:get_player_name()

    if not delay[name] then
      delay[name] = 0.5
    else
      delay[name] = delay[name] + dtime
    end

    if not delay[name] or delay[name] > 0.5 then
      if minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z}).name == "televator:elevator" then
        local where
        local controls = player:get_player_control()
        if controls.jump then
          where = "above"
        elseif controls.sneak then
          where = "below"
        else return end

        local epos = get_near_elevators(pos, where)
        if epos and is_safe(epos) then
          player:set_pos(epos) -- Update player position

          -- Play sound
          minetest.sound_play("televator_whoosh", {
            gain = 0.75,
            pos = epos,
            max_hear_distance = 5,
          })
        elseif epos then
          minetest.chat_send_player(name, "Elevator blocked by obstruction")
        else
          minetest.chat_send_player(name, "Could not find elevator")
        end

        delay[name] = 0      -- Restart delay
      end
    end
  end
end)
