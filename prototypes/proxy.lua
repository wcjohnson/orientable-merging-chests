local data_util = require("lib.core.data-util")

--------------------------------------------------------------------------------
-- PROXY ENTITY CREATION
--------------------------------------------------------------------------------

---@type data.Sprite
local invisible_sprite = {
	filename = "__WideChests__/graphics/invisible.png",
	width = 1,
	height = 1,
}

---@type data.RotatedSprite
local proxy_pictures = {
	layers = {
		data_util.sprite_to_rotated(invisible_sprite),
	},
}

local ZERO_VECTOR = { 0, 0 }

---@type data.WireConnectionPoint
local ZERO_CONNECTION_POINT = {
	wire = { green = ZERO_VECTOR, red = ZERO_VECTOR },
	shadow = { green = ZERO_VECTOR, red = ZERO_VECTOR },
}

-- Unobtainable proxy item required for blueprinting proxies
---@type data.ItemPrototype
local proxy_item = {
	-- PrototypeBase
	type = "item",
	name = "WideChests-proxy-item",
	order = "f[iber-optics]",
	subgroup = "circuit-network",
	hidden_in_factoriopedia = true,

	-- ItemPrototype
	stack_size = 50,
	icon = "__WideChests__/graphics/icons/merge-chest-selector.png",
	icon_size = 32,
	flags = { "hide-from-bonus-gui", "only-in-cursor" },
	weight = 0,
}
data:extend({ proxy_item })

local function make_proxy_entity(width, height)
	---@type data.ElectricPolePrototype
	local proto = {
		-- PrototypeBase
		type = "electric-pole",
		name = table.concat(
			{ "WideChests-proxy", width, height },
			"-"
		),
		hidden_in_factoriopedia = true,

		-- ElectricPolePrototype
		supply_area_distance = 0,
		auto_connect_up_to_n_wires = 0,
		rewire_neighbours_when_destroying = false,
		connection_points = {
			ZERO_CONNECTION_POINT,
		},
		pictures = proxy_pictures,
		maximum_wire_distance = default_circuit_wire_max_distance
			+ math.max(width, height)
			- 1,
		draw_copper_wires = false,
		draw_circuit_wires = true,

		-- EntityWithHealthPrototype
		max_health = 1,

		-- EntityPrototype
		icon = "__WideChests__/graphics/icons/merge-chest-selector.png",
		icon_size = 32,
		collision_box = {
			{ -width / 2 + 0.15, -height / 2 + 0.15 },
			{ width / 2 - 0.15, height / 2 - 0.15 },
		},
		selection_box = { { -width / 2, -height / 2 }, { width / 2, height / 2 } },
		placeable_by = { item = "WideChests-proxy-item", count = 1 },
		fast_replaceable_group = nil,
		flags = {
			"not-on-map",
			"not-deconstructable",
			"hide-alt-info",
			"not-selectable-in-game",
			"not-upgradable",
			"no-automated-item-removal",
			"no-automated-item-insertion",
			"not-in-kill-statistics",
			"placeable-player",
			"player-creation",
		},
		minable = nil,
		selection_priority = 70,
		allow_copy_paste = false,
	}
	return proto
end

function MergingChests.create_proxies()
	local mod_settings = MergingChests.get_mod_settings()

	for width = 2, math.min(mod_settings.max_width, mod_settings.max_area) do
		for height = 2, math.min(mod_settings.max_height, mod_settings.max_area) do
			if MergingChests.is_size_allowed(width, height) then
				data:extend({
					make_proxy_entity(width, height),
				})
			end
		end
	end
end
