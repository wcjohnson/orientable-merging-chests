local events = require("lib.core.event")
local tlib = require("lib.core.table")
local elib = require("lib.core.entities")

local EMPTY = tlib.EMPTY

---@param name string
local function widechest_dims(name)
	-- NxM form
	local prefix, w, h = name:match("^(.-)-(%d+)x(%d+)$")
	if w then
		return tonumber(w), tonumber(h), string.format("%s-%sx%s", prefix, h, w)
	end

	-- Lua only returns captures corresponding to parens, so use:
	local fullPrefix, kind, rest, n =
		name:match("^(WideChests_)(%a+)%-(.-)%-(%d+)$")

	if kind then
		n = tonumber(n)

		if kind == "wide" then
			return n, 1, fullPrefix .. "high-" .. rest .. "-" .. n
		else
			return 1, n, fullPrefix .. "wide-" .. rest .. "-" .. n
		end
	end

	return nil, nil, nil
end

--------------------------------------------------------------------------------
-- EXTRACTION
--------------------------------------------------------------------------------

events.bind("things-cooperative_blueprint_edit", function()
	local _, chests = remote.call(
		"things-blueprint-editing-v1",
		"get_entities",
		nil,
		"WideChests_"
	)
	if not chests or #chests == 0 then return end
	for _, chest in pairs(chests) do
		-- Skip irrelevant chests
		if chest.deleted then goto continue end
		local chest_name = chest.bp_entity.name

		-- Determine dimensions/chest types
		local width, height, opp = widechest_dims(chest_name)
		if (not width) or (not height) or (not opp) then goto continue end

		-- No need to replace square chests as they can already be rotated
		if width == height then goto continue end

		-- Replace rectangular chests with proxies
		---@type things.PartialBlueprintEntity
		local new_entity = {
			name = "WideChests-proxy-" .. width .. "-" .. height,
			tags = { normal = chest_name, rotated = opp },
		}
		remote.call(
			"things-blueprint-editing-v1",
			"replace_entity",
			chest.index,
			new_entity
		)
		::continue::
	end
end)

--------------------------------------------------------------------------------
-- APPLICATION
--------------------------------------------------------------------------------

local NORTH = defines.direction.north
local EAST = defines.direction.east
local SOUTH = defines.direction.south
local WEST = defines.direction.west

---@param ev EventData.script_raised_built|EventData.script_raised_revive|EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_entity_cloned|EventData.on_space_platform_built_entity
local function handle_generic_built(ev)
	local player = ev.player_index and game.get_player(ev.player_index) or nil
	local entity = ev.entity
	local is_ghost = entity.type == "entity-ghost"
	local name = is_ghost and entity.ghost_name or entity.name
	if (not name) or (name:sub(1, 16) ~= "WideChests-proxy") then return end

	local tags = (is_ghost and entity.tags or ev.tags) or EMPTY
	local position = entity.position
  local direction = entity.direction
	local surface = entity.surface
	local force = entity.force
	local wires = elib.get_wire_connections_from(entity, false)

	entity.destroy()
	local chest_name = ((direction == NORTH or direction == SOUTH) and tags.normal) or ((direction == EAST or direction == WEST) and tags.rotated) --[[@as string?]]
	if not chest_name then return end

	local replacement = nil
	if is_ghost then
		replacement = surface.create_entity({
			name = "entity-ghost",
			inner_name = chest_name,
			position = position,
			force = force,
			create_build_effect_smoke = false,
			raise_built = true,
		})
	else
		replacement = surface.create_entity({
			name = chest_name,
			position = position,
			force = force,
			create_build_effect_smoke = false,
			raise_built = true,
		})
	end

	if not replacement then return end
	elib.restore_wire_connections_from(replacement, wires, false)
end

events.bind(defines.events.on_built_entity, handle_generic_built)
events.bind(defines.events.on_robot_built_entity, handle_generic_built)
events.bind(defines.events.on_space_platform_built_entity, handle_generic_built)
events.bind(defines.events.script_raised_built, handle_generic_built)
events.bind(defines.events.script_raised_revive, handle_generic_built)
