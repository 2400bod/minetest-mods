local timer = -1

local item_entity = minetest.registered_entities["__builtin:item"]
local old_on_activate = item_entity.on_activate or function()end

item_entity.on_activate = function(self, staticdata, dtime_s)
	old_on_activate(self, staticdata, dtime_s)
	timer = -1
end

minetest.register_globalstep(function(dtime)
	timer = timer+dtime
	if timer < 0.1 then
		return
	end
	timer = 0
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		pos.y = pos.y+0.5
		local inv = player:get_inventory()

		for _,object in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
			if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
				local str = object:get_luaentity().itemstring
				local item = ItemStack(str)
				if inv and inv:room_for_item("main", item) then
					if str ~= "" then
						minetest.sound_play("item_drop_pickup", { to_player = player:get_player_name(), })
						object:get_luaentity().itemstring = ""
						inv:add_item("main", item)
					end
					object:remove()
				end
			end
		end
	end
end)


if minetest.setting_get("log_mods") then
	minetest.log("action", "item_drop loaded")
end
