local util = {}

function util.get_charted_chunk_bounds(surface, force)
    local min_chunk_x, max_chunk_x = math.huge, -math.huge
    local min_chunk_y, max_chunk_y = math.huge, -math.huge

    for chunk in surface.get_chunks() do
        if force.is_chunk_charted(surface, {chunk.x, chunk.y}) then
            if chunk.x < min_chunk_x then min_chunk_x = chunk.x end
            if chunk.x > max_chunk_x then max_chunk_x = chunk.x end
            if chunk.y < min_chunk_y then min_chunk_y = chunk.y end
            if chunk.y > max_chunk_y then max_chunk_y = chunk.y end
        end
    end

    -- nothing charted
    if min_chunk_x == math.huge then
        return nil
    end

    return {
        min_x = min_chunk_x * 32 + 16,
        max_x = max_chunk_x * 32 + 16,
        min_y = min_chunk_y * 32 + 16,
        max_y = max_chunk_y * 32 + 16
    }
end

function util.get_random_player_position(surface, player)
    local chunks = {}
	local min_entity = storage.geoguessr[player.index].entities_count
	local zoom_level = storage.geoguessr[player.index].zoom_level
	local blacklisted_entities = storage.geoguessr[player.index].blacklisted_entities
	
	local radius = math.floor(6.4 / zoom_level)
    local max_attempts = 100
	
	local bounds = util.get_charted_chunk_bounds(surface, player.force) -- TODO: cache this to improve performance

	if not bounds then
		return nil
	end
	
	for attempt = 1, max_attempts do
        -- pick random chunk within charted bounds
        local chunk_x = math.random(bounds.min_x, bounds.max_x)
		local chunk_y = math.random(bounds.min_y, bounds.max_y)
		
        local area = {
            {chunk_x - radius, chunk_y - radius},
            {chunk_x + radius, chunk_y + radius}
        }
		--player.print(tostring(attempt) .. serpent.block(area))

        local entities = surface.find_entities_filtered{area = area, force = "player"}

        local valid_entities = {}
        for _, entity in pairs(entities) do
            if not blacklisted_entities[entity.name] then
                table.insert(valid_entities, entity)
            end
        end
		--player.print(tostring(attempt) .. serpent.block(valid_entities))

        if #valid_entities >= min_entity then
            local chosen = valid_entities[math.random(#valid_entities)]
            return {surface.name, {x=chunk_x, y=chunk_y}}
        end
    end
	
	return nil
end

function util.get_random_surface(player)
    local surfaces = {}

    for _, surface in pairs(game.surfaces) do
        if surface.valid and
			surface.name ~= "aai-signals" and -- no aai signal allowed :<
			not surface.name:find("starmap") and -- begone starmap!
			not surface.name:find("transformer") and
			not surface.name:find("editor") and
			not surface.name:find("cutscene") and
			not storage.geoguessr[player.index].blacklisted_surfaces[surface.name]
         then
            table.insert(surfaces, surface)
        end
    end
	--game.print(serpent.block(surfaces))
    if #surfaces == 0 then
        return nil
    end
    return surfaces[math.random(#surfaces)]
end

function util.reset_game(player)
	-- Clear any renderings
	rendering.clear("geoguessr")

	-- restore player game view options
	player.game_view_settings.show_minimap = storage.geoguessr[player.index].view_setting.show_minimap
	player.game_view_settings.show_research_info = storage.geoguessr[player.index].view_setting.show_research_info
	player.game_view_settings.show_entity_info = storage.geoguessr[player.index].view_setting.show_entity_info
	player.game_view_settings.show_map_view_options = storage.geoguessr[player.index].view_setting.show_map_view_options
	player.game_view_settings.show_entity_tooltip = storage.geoguessr[player.index].view_setting.show_entity_tooltip
	player.game_view_settings.show_quickbar = storage.geoguessr[player.index].view_setting.show_quickbar
	player.game_view_settings.show_shortcut_bar = storage.geoguessr[player.index].view_setting.show_shortcut_bar
	player.game_view_settings.show_crafting_queue = storage.geoguessr[player.index].view_setting.show_crafting_queue
	player.game_view_settings.show_tool_bar = storage.geoguessr[player.index].view_setting.show_tool_bar
	player.game_view_settings.show_hotkey_suggestions = storage.geoguessr[player.index].view_setting.show_hotkey_suggestions
	player.game_view_settings.update_entity_selection = storage.geoguessr[player.index].view_setting.update_entity_selection
	player.game_view_settings.show_side_menu = storage.geoguessr[player.index].view_setting.show_side_menu

	-- clear storage: delete all except settings
    storage.geoguessr[player.index].round_active = false
    storage.geoguessr[player.index].round_duration = nil
    storage.geoguessr[player.index].rounds_total = nil
    storage.geoguessr[player.index].round_surface = nil
    storage.geoguessr[player.index].zoom_level = nil
    storage.geoguessr[player.index].entities_count = nil
    storage.geoguessr[player.index].round_index = nil
    storage.geoguessr[player.index].total_score = nil
    storage.geoguessr[player.index].guess = nil
	storage.geoguessr[player.index].hide_map_settings = nil
	storage.geoguessr[player.index].view_setting = nil
	storage.geoguessr[player.index].round_chunk = nil
	storage.geoguessr[player.index].distance_unit_index = nil
	storage.geoguessr[player.index].blacklisted_surfaces = nil
	storage.geoguessr[player.index].blacklisted_entities = nil
	
	--game.print(tostring(storage.geoguessr[player.index].round_active) .. " " .. tostring(player.index))

	-- reset zoom_level	and leave remote view
	player.set_zoom_limits(defines.controllers.character, {})
	player.set_zoom_limits(defines.controllers.remote, {})
	player.exit_remote_view()
			
	-- remove geo guessr tool
    player.set_shortcut_toggled("geo-toggle", false)
    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "geo-guess-tool" then
        player.cursor_stack.clear()
    end
end

function util.calculate_score(player_index)
    local guess = storage.geoguessr[player_index].guess
    local target_chunk = storage.geoguessr[player_index].round_chunk

	-- Guessed wrong surface
	if guess[1] ~= target_chunk[1] then
		return {-1, 0}
	end
	
    -- Distance in chunks
    local dx = guess[2].x / 32 - target_chunk[2].x / 32
    local dy = guess[2].y / 32 - target_chunk[2].y / 32
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Exponential distance score
    local max_score = 5000
    local decay_rate = 0.15
    local distance_score = max_score * math.exp(-decay_rate * distance)
	if not storage.geoguessr[player_index].distance_unit_index then
		distance = math.floor(distance * 32)
	end	
    -- Time factor
    local remaining_ticks = storage.geoguessr[player_index].round_end_tick - game.tick
    local total_ticks = storage.geoguessr[player_index].round_duration
    local time_ratio = math.max(0, remaining_ticks / total_ticks)

    -- Combine
    local final_score = distance_score * (0.5 + 0.5 * time_ratio)

    -- Apply
    local score = math.floor(final_score)

    return {distance, score}
end

function util.give_player_geoguessr_tool(player)
	if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name ~= "geo-guess-tool" then
		local inv = player.get_main_inventory()
		inv.insert(player.cursor_stack)
	end
	player.cursor_stack.set_stack{name="geo-guess-tool", count=1}
end

function util.parse_time_to_minutes(index)
	if index == 1 then
		return 5/60
	elseif index == 2 then
		return 15/60
	elseif index == 3 then
		return 30/60
	elseif index == 4 then
		return 1
	elseif index == 5 then
		return 2
	elseif index == 6 then
		return 3
	elseif index == 7 then
		return 5
	elseif index == 8 then
		return 10
	end
	
end


function util.add_centered_dropdown(frame, label_caption, dropdown_name, items, selected_index, tool_tip)
    local flow = frame.add{
        type = "flow",
        direction = "horizontal",
		name = dropdown_name .. "_h_flow",
    }
	flow.style.horizontally_stretchable = true
	local label_flow = flow.add{
        type = "flow",
        direction = "vertical"
	}
	label_flow.style.horizontally_stretchable = true
	label_flow.style.horizontal_align = "left"
    label_flow.add{
        type = "label",
        caption = label_caption,
		tooltip = tool_tip
    }
	local dropdown_flow = flow.add{
        type = "flow",
        direction = "vertical",
		name = "dropdown_flow",
	}
	dropdown_flow.style.horizontally_stretchable = true
	dropdown_flow.style.horizontal_align = "right"
    dropdown_flow.add{
        type = "drop-down",
        name = dropdown_name,
        items = items,
        selected_index = selected_index
    }
end

function util.add_centered_checkbox(frame, label_caption, checkbox_name, state, tool_tip)
    local flow = frame.add{
        type = "flow",
        direction = "horizontal",
        name = checkbox_name .. "_h_flow",
    }
    flow.style.horizontally_stretchable = true

    local label_flow = flow.add{
        type = "flow",
        direction = "vertical"
    }
    label_flow.style.horizontally_stretchable = true
    label_flow.style.horizontal_align = "left"

    label_flow.add{
        type = "label",
        caption = label_caption,
		tooltip = tool_tip
    }

    local checkbox_flow = flow.add{
        type = "flow",
        direction = "vertical",
        name = "checkbox_flow",
    }
    checkbox_flow.style.horizontally_stretchable = true
    checkbox_flow.style.horizontal_align = "right"

    checkbox_flow.add{
        type = "checkbox",
        name = checkbox_name,
        state = state
    }
end

function util.add_centered_textfield(frame, label_caption, textfield_name, text_value, tool_tip)
    local flow = frame.add{
        type = "flow",
        direction = "horizontal",
        name = textfield_name .. "_h_flow",
    }
    flow.style.horizontally_stretchable = true

    local label_flow = flow.add{
        type = "flow",
        direction = "vertical"
    }
    label_flow.style.horizontally_stretchable = true
    label_flow.style.horizontal_align = "left"

    label_flow.add{
        type = "label",
        caption = label_caption,
		tooltip = tool_tip
    }

    local textfield_flow = flow.add{
        type = "flow",
        direction = "vertical",
        name = "textfield_flow",
    }
    textfield_flow.style.horizontally_stretchable = true
    textfield_flow.style.horizontal_align = "right"

    textfield_flow.add{
        type = "textfield",
        name = textfield_name,
        text = text_value or ""
    }
end

function util.gps_tag(surface_name, position)
  return "[gps="..math.floor(position.x or position[1])..","..math.floor(position.y or position[2])..","..surface_name.."]"
end

function util.split_csv(str, label)
    if type(str) ~= "string" then
        return nil, {"geoguessr.error-not-string", label}
    end

    local result = {}

    for raw in string.gmatch(str, "([^,]+)") do
        -- trim whitespace
        local value = raw:match("^%s*(.-)%s*$")

        -- validation: non-empty after trim
        if value == "" then
            return nil, {"geoguessr.error-empty-value", label}
        end

        -- validation: allowed characters only
        if not value:match("^[%w_-]+$") then
            return nil, {"geoguessr.error-invalid-value", label}
        end

        result[value] = true
    end

    -- validation: detect trailing comma (e.g. "a,b,")
    if str:match(",%s*$") then
        return nil, {"geoguessr.error-trailing-comma", label}
    end

    return result
end

function util.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

return util
