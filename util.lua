local util = {}

function util.get_random_player_position(surface, min_entity, force)
    local chunks = {}
	-- get any chartera area if we don't care about player entity
	if min_entity == 0 then
		for chunk in surface.get_chunks() do
			local pos = {x = chunk.x, y = chunk.y}

			if force.is_chunk_charted(surface, pos) then
				table.insert(chunks, chunk)
			end
		end
	else 
		for chunk in surface.get_chunks() do
			local area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}
			local entities = surface.find_entities_filtered {area = area, force = "player"}
			if #entities > (min_entity or 10) then
				table.insert(chunks, chunk)
			end
		end
	end
    if #chunks == 0 then
        return nil
    end
    return chunks[math.random(#chunks)]
end

function util.get_random_surface()
    local surfaces = {}

    for _, surface in pairs(game.surfaces) do
        if surface.valid and
			surface.name ~= "aai-signals" and -- no aai signal allowed :<
			not surface.name:find("starmap") and -- begone starmap!
			not surface.name:find("transformer") and
			not surface.name:find("editor") and
			not surface.name:find("cutscene")
         then
            table.insert(surfaces, surface)
        end
    end

    if #surfaces == 0 then
        return nil
    end
    return surfaces[math.random(#surfaces)]
end

function util.reset_game(player)
    storage.geoguessr[player.index].round_active = false
    storage.geoguessr[player.index].round_duration = nil
    storage.geoguessr[player.index].rounds_total = nil
    storage.geoguessr[player.index].round_surface = nil
    storage.geoguessr[player.index].zoom_level = nil
    storage.geoguessr[player.index].entities_count = nil
    storage.geoguessr[player.index].round_index = nil
    storage.geoguessr[player.index].total_score = nil
    storage.geoguessr[player.index].guess_position = nil

	-- reset zoom_level	
	player.set_zoom_limits(defines.controllers.character, {})
	player.set_zoom_limits(defines.controllers.remote, {})
			
	-- remove geo guessr tool
    player.set_shortcut_toggled("geo-toggle", false)
    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "geo-guess-tool" then
        player.cursor_stack.clear()
    end
end

function util.calculate_score(player_index)
    local guess = storage.geoguessr[player_index].guess_position
    local target_chunk = storage.geoguessr[player_index].round_chunk

    -- Distance in chunks
    local dx = guess.x / 32 - (target_chunk.x + 0.5)
    local dy = guess.y / 32 - (target_chunk.y + 0.5)
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Exponential distance score
    local max_score = 5000
    local decay_rate = 0.15
    local distance_score = max_score * math.exp(-decay_rate * distance)

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


function util.add_centered_dropdown(frame, label_caption, dropdown_name, items, selected_index)
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
        caption = label_caption
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

return util
