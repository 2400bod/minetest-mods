local inbox = {}

local filename = minetest.get_worldpath() .. "/mailboxes.dat"
local mailbox = {}

screwdriver = screwdriver or {}

minetest.register_craft({
	output ="inbox:empty",
	recipe = {
		{"","default:steel_ingot",""},
		{"default:steel_ingot","","default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"}
	}
})

local mb_cbox = {
	type = "fixed",
	fixed = { -5/16, -8/16, -8/16, 5/16, 2/16, 8/16 }
}

minetest.register_node("inbox:empty", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "inbox_mailbox.obj",
	description = "Mailbox",
	tiles = {
		"inbox_red_metal.png",
		"inbox_white_metal.png",
		"inbox_grey_metal.png",
	},
	inventory_image = "mailbox_inv.png",
	selection_box = mb_cbox,
	collision_box = mb_cbox,
	paramtype2 = "facedir",
	groups = {choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	on_rotate = screwdriver.rotate_simple,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
		meta:set_string("infotext", owner.."'s Mailbox")
		local inv = inbox.get(owner)
		inbox.save()
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)	
		local player = clicker:get_player_name()
		local owner  = meta:get_string("owner")
		local inv = inbox.get(owner)
		if owner == player then
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				inbox.get_inbox_formspec(owner))
		else
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				inbox.get_inbox_insert_formspec(owner))
		end
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner")
		local inv = inbox.get(owner)
		return player:get_player_name() == owner and inv:is_empty("main")
	end,
})

function inbox.get_inbox_formspec(owner)
	local formspec =
		"size[8,9]"..
		"list[detached:".. owner .."_mailbox;main;0,0;8,4;]"..
		"list[current_player;main;0,5;8,4;]" ..
		"listring[]"
	return formspec
end

function inbox.get_inbox_insert_formspec(owner)
	local formspec =
		"size[8,9]"..
		"list[detached:".. owner .. "_mailbox;drop;3.5,2;1,1;]"..
		"list[current_player;main;0,5;8,4;]" ..
		"listring[]"
	return formspec
end

function inbox.load()
	local file = io.open(filename, "r")

	if not file then
		if inbox.save() then
			file = io.open(filename, "r")
			if not file then return end
		else
			return
		end
	end

	local data = file:read("*all")
	file:close()

	return minetest.deserialize(data)
end

function inbox.save()
	local file = io.open(filename, "w")
	if not file then return end

	local data = minetest.serialize(mailbox)

	file:write(data)
	file:close()
	return true
end

function inbox.update(player_name, inv)
	mailbox[player_name] = {}

	for index, stack in ipairs( inv:get_list("main") ) do
		if stack:to_string() ~= "" then
			mailbox[player_name][index] = stack:to_string()
		end
	end

	inbox.save()
end

function inbox.get(owner)
	local mailbox_inv = minetest.get_inventory({type="detached", name= owner .. "_mailbox"})
	if not mailbox or not next(mailbox) then mailbox = inbox.load() end

	if not mailbox_inv then
		mailbox_inv = minetest.create_detached_inventory(owner .. "_mailbox",{
			on_put = function(inv, listname, index, stack, player)
				if listname == "drop" and inv:room_for_item("main", stack) then
					inv:remove_item("drop", stack)
					inv:add_item("main", stack)
					inbox.update(owner, inv)
					minetest.log("action",
						player:get_player_name() .. " put '" .. stack:to_string() ..
						"' to mailbox " .. owner .. " at " .. minetest.pos_to_string(player:getpos()))
				end
			end,
			on_take = function(inv, listname, index, stack, player)
				inbox.update(owner, inv)
				minetest.log("action",
					player:get_player_name() .. " take '" .. stack:to_string() ..
					"' from mailbox " .. owner .. " at " .. minetest.pos_to_string(player:getpos()))
			end,
			on_move = function(inv, from_list, from_index, to_list, to_index, count, player) end,
			allow_put = function(inv, listname, index, stack, player)
				if listname == "drop" then
					return stack:get_count()
				else
					return 0
				end
			end,
			allow_take = function(inv, listname, index, stack, player)
				if listname == "main" then
					return stack:get_count()
				else
					return 0
				end
			end,
			allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
				return 0
			end,
		})

		mailbox_inv:set_size("main", 8*4)
		mailbox_inv:set_size("drop", 1)

		if mailbox[owner] then
			for _, stack in pairs( mailbox[owner] ) do
				if stack ~= "" then
					mailbox_inv:add_item("main", ItemStack(stack))
				end
			end
		else
			inbox.update(owner, mailbox_inv)
		end
	end

	return mailbox_inv
end
