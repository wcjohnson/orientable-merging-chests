local data_util = require("lib.core.data-util")
local create_sprite = require("scripts.sprite_generation")

--------------------------------------------------------------------------------
-- PROXY ENTITY CREATION
--------------------------------------------------------------------------------

local segments = {
	entity = {
		filename = "__WideChests__/graphics/gray_rounded.png",

		-- Use the same 1x1 tile source for every 9-slice position
		top_left = { x = 0, y = 0 },
		top = { x = 0, y = 0 },
		top_right = { x = 0, y = 0 },

		left = { x = 0, y = 0 },
		middle = { x = 0, y = 0 },
		right = { x = 0, y = 0 },

		bottom_left = { x = 0, y = 0 },
		bottom = { x = 0, y = 0 },
		bottom_right = { x = 0, y = 0 },

		-- T = 64 is correct: gray_rounded.png is 64x64
		widths = { left = 64, middle = 64, right = 64 },
		heights = { top = 64, middle = 64, bottom = 64 },

		-- Required by sprite_generation.lua
		shift = { x = 0, y = 0 },

		-- 64px source rendered as 1 game tile (32px base) => scale 0.5
		scale = 0.5,
	},
}

---@type data.Sprite
local proxy_sprite = {
	filename = "__WideChests__/graphics/gray_rounded.png",
	width = 256,
	height = 256,
}

---@type data.RotatedSprite
local proxy_pictures = {
	layers = {
		data_util.sprite_to_rotated(proxy_sprite),
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
	local sprite = { layers = create_sprite(width, height, segments) }
	local opp_sprite = { layers = create_sprite(height, width, segments) }

	---@type data.ConstantCombinatorPrototype
	local proto = {
		-- PrototypeBase
		type = "constant-combinator",
		name = table.concat({ "WideChests-proxy", width, height }, "-"),
		hidden_in_factoriopedia = true,

		-- ConstantCombinatorPrototype
		circuit_wire_connection_points = {
			ZERO_CONNECTION_POINT,
			ZERO_CONNECTION_POINT,
			ZERO_CONNECTION_POINT,
			ZERO_CONNECTION_POINT,
		},
		activity_led_light_offsets = {
			ZERO_VECTOR,
			ZERO_VECTOR,
			ZERO_VECTOR,
			ZERO_VECTOR,
		},
		sprites = {
			north = sprite,
			east = opp_sprite,
			south = sprite,
			west = opp_sprite,
		},
		circuit_wire_max_distance = default_circuit_wire_max_distance
			+ math.max(width, height),
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

	for width = 1, math.min(mod_settings.max_width, mod_settings.max_area) do
		for height = 1, math.min(mod_settings.max_height, mod_settings.max_area) do
			if MergingChests.is_size_allowed(width, height) then
				data:extend({
					make_proxy_entity(width, height),
				})
			end
		end
	end
end
