local events = require("lib.core.event")

local function widechest_dims(name)
    -- explicit NxM suffix
    local w, h = name:match("-(%d+)x(%d+)$")
    if w then
        return tonumber(w), tonumber(h)
    end

    -- wide/high N suffix
    local kind, n = name:match("^WideChests_([^%-]+)%-.*%-(%d+)$")
    n = tonumber(n)

    if kind == "wide" then
        return n, 1
    elseif kind == "high" then
        return 1, n
    end

    return nil, nil
end

events.bind("things-cooperative_blueprint_edit", function()
  local _, chests = remote.call("things-blueprint-editing-v1", "get_entities", nil, "WideChests_")
  if not chests or #chests == 0 then return end
  for _, chest in pairs(chests) do
    if chest.deleted then goto continue end
    local chest_name = chest.bp_entity.name
    local width, height = widechest_dims(chest_name)
    if (not width) or (not height) then goto continue end
    ---@type things.PartialBlueprintEntity
    local new_entity = {
      name = "WideChests-proxy-" .. width .. "-" .. height,
      tags = { original_name = chest_name }
    }
    remote.call("things-blueprint-editing-v1", "replace_entity", chest.index, new_entity)
    ::continue::
  end
end)