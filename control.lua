util = require("util")
--------------------------------------------------
-- Main Menu
--------------------------------------------------
local function toggle_game_setting_ui(player)
    storage.geoguessr = storage.geoguessr or {}
	storage.geoguessr[player.index] = storage.geoguessr[player.index] or {}
	storage.geoguessr[player.index].round_active = storage.geoguessr[player.index].round_active or false
	storage.geoguessr[player.index].setting = storage.geoguessr[player.index].setting or {}

    if storage.geoguessr[player.index].round_active then
        player.print("Finish the current round(s) first!")
        return
    end

    if player.gui.screen.geo_frame then
        player.gui.screen.geo_frame.destroy()
        player.set_shortcut_toggled("geo-toggle", false)
        return
    end

    local frame = player.gui.screen.add{
        type = "frame",
        name = "geo_frame",
        direction = "vertical"
    }
    frame.auto_center = true
	-- Title bar
	local titlebar = frame.add{
		type = "flow",
		direction = "horizontal"
	}

	titlebar.add{
		type = "label",
		caption = {"geoguessr.geoguessr-menu"},
		style = "frame_title"
	}

	local filler = titlebar.add{
		type = "empty-widget",
		style = "draggable_space_header"
	}
	filler.style.horizontally_stretchable = true
	filler.style.height = 24
	filler.style.width = 160
	filler.drag_target = frame
	
	titlebar.add{
		type = "sprite-button",
		name = "geo_close_main",
		sprite = "utility/close",
		style = "frame_action_button"
	}

    -- Time input label
    util.add_centered_dropdown(frame, {"geoguessr.round-time"}, "geo_time_dropdown",
		{
			{"geoguessr.round-time-five-seconds"},
			{"geoguessr.round-time-fifteen-seconds"},
			{"geoguessr.round-time-thirty-seconds"},
			{"geoguessr.round-time-one-minute"},
			{"geoguessr.round-time-two-minutes"},
			{"geoguessr.round-time-three-minutes"},
			{"geoguessr.round-time-five-minutes"},
			{"geoguessr.round-time-ten-minutes"}
		},
		storage.geoguessr[player.index].setting.minutes_index or 5,
		{"geoguessr.round-time-tooltip"}
	)
	
	-- Rounds label
	util.add_centered_dropdown(frame, {"geoguessr.rounds"}, "geo_rounds_dropdown",
		{"1", "3", "5", "10", "15"},
		storage.geoguessr[player.index].setting.rounds_index or 2,
		{"geoguessr.rounds-tooltip"}
	)
	
	-- Surface label
	util.add_centered_dropdown(frame, {"geoguessr.surfaces"}, "geo_surfaces_dropdown",
		{{"geoguessr.surfaces-current"}, {"geoguessr.surfaces-all"}},
		storage.geoguessr[player.index].setting.surface_index or 1,
		{"geoguessr.surfaces-tooltip"}
	)
	
	-- Blacklisted Surfaces
	util.add_centered_textfield(frame, {"geoguessr.blacklisted-surfaces"}, "geo_blacklisted_surfaces_textfield",
		storage.geoguessr[player.index].setting.geo_blacklisted_surfaces or "",
		{"geoguessr.blacklisted-surfaces-tooltip"}
	)
	
	-- Zoom label
	util.add_centered_dropdown(frame, {"geoguessr.zoom"}, "geo_preview_zoom_dropdown",
		{"5", "4", "3", "2", "1"},
		storage.geoguessr[player.index].setting.zoom_level_index or 2,
		{"geoguessr.zoom-tooltip"}
	)

	-- Entities count
	util.add_centered_dropdown(frame, {"geoguessr.entities-required"}, "geo_player_entities_count_dropdown",
		{"0", "5", "10", "20", "30"},
		storage.geoguessr[player.index].setting.entities_count_index or 2,
		{"geoguessr.entities-required-tooltip"}
	)
	
	-- Blacklisted Entities
	util.add_centered_textfield(frame, {"geoguessr.blacklisted-entities"}, "geo_blacklisted_entities_textfield",
		storage.geoguessr[player.index].setting.geo_blacklisted_entities or "",
		{"geoguessr.blacklisted-entities-tooltip"}
	)
	
	-- Hide map settings
	util.add_centered_checkbox(frame, {"geoguessr.hide-map-settings"}, "geo_hide_map_settings_checkbox", 
		storage.geoguessr[player.index].setting.geo_hide_map_settings or false,
		{"geoguessr.hide-map-settings-tooltip"}
	)
	
	-- Distance unit
	util.add_centered_dropdown(frame, {"geoguessr.distance-unit"}, "geo_distance_unit_dropdown",
		{
			{"geoguessr.distance-unit-chunk"},
			{"geoguessr.distance-unit-meter"}
		},
		storage.geoguessr[player.index].setting.distance_unit_index or 2,
		{"geoguessr.distance-unit-tooltip"}
	)
	
    local button_flow = frame.add{
		type = "flow",
		direction = "horizontal"
	}
	button_flow.style.horizontally_stretchable = true
	button_flow.style.horizontal_align = "center"
	button_flow.add{
		type = "button",
		name = "geo_start",
		caption = {"geoguessr.start"}
	}

    player.set_shortcut_toggled("geo-toggle", true)
end

script.on_event(defines.events.on_lua_shortcut, function(e)
    if e.prototype_name ~= "geo-toggle" then return end
    local player = game.get_player(e.player_index)
    if not player then return end
    toggle_game_setting_ui(player)
end)

script.on_event("geo-toggle", function(e)
    local player = game.get_player(e.player_index)
    if not player then return end
    toggle_game_setting_ui(player)
end)

--------------------------------------------------
-- Gameplay View
--------------------------------------------------
local function create_gameplay_view(player, surface, chunk)
    if player.gui.screen.geo_gameplay_frame then
        player.gui.screen.geo_gameplay_frame.destroy()
    end

    local center = {
        x = chunk[2].x,
        y = chunk[2].y
    }

    local frame = player.gui.screen.add{
        type = "frame",
        name = "geo_gameplay_frame",
        direction = "vertical"
    }
    frame.auto_center = true
	
	-- Title bar
	local titlebar = frame.add{
		type = "flow",
		direction = "horizontal"
	}

	titlebar.add{
		type = "label",
		caption = {"geoguessr.mystery-location"},
		style = "frame_title"
	}

	local filler = titlebar.add{
		type = "empty-widget",
		style = "draggable_space_header"
	}
	filler.style.horizontally_stretchable = true
	filler.style.height = 24
	filler.drag_target = frame

	local close_button = titlebar.add{
		type = "sprite-button",
		name = "geo_close_gameplay_frame",
		sprite = "utility/close",
		style = "frame_action_button"
	}

    local top_flow = frame.add{
        type = "flow",
        direction = "vertical",
		name = "info"
    }
	
    -- Timer label and progress bar
    top_flow.add{
        type = "label",
        name = "geo_timer_label",
        caption = "00:00"
    }

    top_flow.add{
        type = "progressbar",
        name = "geo_timer_bar",
        size = 100,
        value = 1
    }

    -- Camera view
    local cam = frame.add{
        type = "camera",
        position = center,
        surface_index = surface.index,
        zoom = storage.geoguessr[player.index].zoom_level or 0.4
    }

    cam.style.size = {400, 400}
end

--------------------------------------------------
-- Round Summary View
--------------------------------------------------
local function show_round_summary(player, round_index, rounds_total, score, total_score, distance)
    -- Destroy old summary frame if exists
    if player.gui.screen.geo_summary_frame then
        player.gui.screen.geo_summary_frame.destroy()
    end

    local frame = player.gui.screen.add{
        type = "frame",
        name = "geo_summary_frame",
        caption = {"geoguessr.round-summary"},
        direction = "vertical"
    }
    frame.auto_center = true
	flow = frame.add{
		type = "flow",
		direction = "vertical"
	}
	flow.style.horizontally_stretchable = true
	flow.style.horizontal_align = "center"
    flow.add{
        type = "label",
        caption = {"geoguessr.rounds-number", round_index, rounds_total},
    }
	if storage.geoguessr[player.index].distance_unit_index then
		flow.add{
			type = "label",
			caption = {"geoguessr.rounds-distance", string.format("%.2f", distance)},
		}
	else
		flow.add{
			type = "label",
			caption = {"geoguessr.rounds-distance-meters", distance},
		}
	end

    flow.add{
        type = "label",
        caption = {"geoguessr.rounds-score", score},
    }

    flow.add{
        type = "label",
        caption = {"geoguessr.rounds-total-score", total_score},
    }

    flow.add{
        type = "button",
        name = "geo_summary_close",
        caption = {"geoguessr.close"}
    }
end

--------------------------------------------------
-- GUI CLICK HANDLER
--------------------------------------------------
script.on_event(defines.events.on_gui_click, function(e)
    local player = game.get_player(e.player_index)
    if not player then return end

	-- Close main UI
	if e.element.name == "geo_close_main" then
		if player.gui.screen.geo_frame then
			player.gui.screen.geo_frame.destroy()
		end
		player.set_shortcut_toggled("geo-toggle", false)
		return
	end

	-- Close camera UI
	if e.element.name == "geo_close_gameplay_frame" then
		if player.gui.screen.geo_gameplay_frame then
			player.gui.screen.geo_gameplay_frame.destroy()
		end
		util.reset_game(player)
		return
	end

    -- Start round button
    if e.element.name == "geo_start" then

        -- Round duration minutes
		local minutes = util.parse_time_to_minutes(player.gui.screen.geo_frame.geo_time_dropdown_h_flow.dropdown_flow.geo_time_dropdown.selected_index)
        local duration = minutes * 60 * 60  -- ticks
		
		-- Number of rounds
		local rounds = tonumber(player.gui.screen.geo_frame.geo_rounds_dropdown_h_flow.dropdown_flow.geo_rounds_dropdown.get_item(player.gui.screen.geo_frame.geo_rounds_dropdown_h_flow.dropdown_flow.geo_rounds_dropdown.selected_index))
		
		-- Surface
		local surface = player.gui.screen.geo_frame.geo_surfaces_dropdown_h_flow.dropdown_flow.geo_surfaces_dropdown.selected_index == 1
		
		-- Zoom
		local zoom_level = tonumber(player.gui.screen.geo_frame.geo_preview_zoom_dropdown_h_flow.dropdown_flow.geo_preview_zoom_dropdown.get_item(player.gui.screen.geo_frame.geo_preview_zoom_dropdown_h_flow.dropdown_flow.geo_preview_zoom_dropdown.selected_index)) / 5
		
		-- Minimum number of player entities to be considered for guessing
		local entities_count = tonumber(player.gui.screen.geo_frame.geo_player_entities_count_dropdown_h_flow.dropdown_flow.geo_player_entities_count_dropdown.get_item(player.gui.screen.geo_frame.geo_player_entities_count_dropdown_h_flow.dropdown_flow.geo_player_entities_count_dropdown.selected_index))
		
		-- Hides Tags, Train Stations, etc.
		local hide_map_settings = player.gui.screen.geo_frame.geo_hide_map_settings_checkbox_h_flow.checkbox_flow.geo_hide_map_settings_checkbox.state
		
		-- Blacklisted Surfaces are excluded from being picked
		local blacklisted_surfaces, err = util.split_csv(player.gui.screen.geo_frame.geo_blacklisted_surfaces_textfield_h_flow.textfield_flow.geo_blacklisted_surfaces_textfield.text, {"geoguessr.blacklisted-surfaces"})
		
		if blacklisted_surfaces == nil then
			player.print(err)
			return
		end
		
		-- Blacklisted Entities are excluded from being picked
		local blacklisted_entities, err = util.split_csv(player.gui.screen.geo_frame.geo_blacklisted_entities_textfield_h_flow.textfield_flow.geo_blacklisted_entities_textfield.text, {"geoguessr.blacklisted-entities"})
		
		if blacklisted_entities == nil then
			player.print(err)
			return
		end
		
		local distance_unit = player.gui.screen.geo_frame.geo_distance_unit_dropdown_h_flow.dropdown_flow.geo_distance_unit_dropdown.selected_index == 1
		
        -- Setting up the storage variables
        storage.geoguessr[e.player_index].round_active = true
		storage.geoguessr[e.player_index].round_duration = duration
		storage.geoguessr[e.player_index].rounds_total = rounds
		storage.geoguessr[e.player_index].round_surface = surface
		storage.geoguessr[e.player_index].zoom_level = zoom_level
		storage.geoguessr[e.player_index].entities_count = entities_count
		storage.geoguessr[e.player_index].blacklisted_surfaces = blacklisted_surfaces
		storage.geoguessr[e.player_index].blacklisted_entities = blacklisted_entities
		storage.geoguessr[e.player_index].round_index = 1
		storage.geoguessr[e.player_index].total_score = 0
		storage.geoguessr[e.player_index].guess = nil
		storage.geoguessr[e.player_index].hide_map_settings = hide_map_settings
		storage.geoguessr[e.player_index].distance_unit = distance_unit
		storage.geoguessr[e.player_index].setting = {
			minutes_index = player.gui.screen.geo_frame.geo_time_dropdown_h_flow.dropdown_flow.geo_time_dropdown.selected_index,
			rounds_index = player.gui.screen.geo_frame.geo_rounds_dropdown_h_flow.dropdown_flow.geo_rounds_dropdown.selected_index,
			surface_index = player.gui.screen.geo_frame.geo_surfaces_dropdown_h_flow.dropdown_flow.geo_surfaces_dropdown.selected_index,
			zoom_level_index = player.gui.screen.geo_frame.geo_preview_zoom_dropdown_h_flow.dropdown_flow.geo_preview_zoom_dropdown.selected_index,
			entities_count_index = player.gui.screen.geo_frame.geo_player_entities_count_dropdown_h_flow.dropdown_flow.geo_player_entities_count_dropdown.selected_index,
			distance_unit_index = player.gui.screen.geo_frame.geo_distance_unit_dropdown_h_flow.dropdown_flow.geo_distance_unit_dropdown.selected_index,
			geo_hide_map_settings = player.gui.screen.geo_frame.geo_hide_map_settings_checkbox_h_flow.checkbox_flow.geo_hide_map_settings_checkbox.state,
			geo_blacklisted_surfaces = player.gui.screen.geo_frame.geo_blacklisted_surfaces_textfield_h_flow.textfield_flow.geo_blacklisted_surfaces_textfield.text,
			geo_blacklisted_entities = player.gui.screen.geo_frame.geo_blacklisted_entities_textfield_h_flow.textfield_flow.geo_blacklisted_entities_textfield.text
		}
		
        -- Close start UI
        if player.gui.screen.geo_frame then
            player.gui.screen.geo_frame.destroy()
        end

		-- Disable game view for character and remote view
		player.set_zoom_limits(defines.controllers.character, { furthest = {zoom=0.003} , furthest_game_view = {distance=1, max_distance = 1}})
		player.set_zoom_limits(defines.controllers.remote, { furthest = {zoom=0.003} , furthest_game_view = {distance=1, max_distance = 1}})
		
		-- Put the player in remote view and disable player views
		player.set_controller({type=defines.controllers.remote})
		storage.geoguessr[e.player_index].view_setting = {
			show_minimap = player.game_view_settings.show_minimap,
			show_research_info = player.game_view_settings.show_research_info,
			show_entity_info = player.game_view_settings.show_entity_info,
			show_map_view_options = player.game_view_settings.show_map_view_options,
			show_entity_tooltip = player.game_view_settings.show_entity_tooltip,
			show_quickbar = player.game_view_settings.show_quickbar,
			show_shortcut_bar = player.game_view_settings.show_shortcut_bar,
			show_crafting_queue = player.game_view_settings.show_crafting_queue,
			show_tool_bar = player.game_view_settings.show_tool_bar,
			show_hotkey_suggestions = player.game_view_settings.show_hotkey_suggestions,
			update_entity_selection = player.game_view_settings.update_entity_selection,
			show_side_menu = player.game_view_settings.show_side_menu
		}
		player.game_view_settings.show_minimap = false
		player.game_view_settings.show_research_info = false
		player.game_view_settings.show_entity_info = false
		player.game_view_settings.show_map_view_options = false
		player.game_view_settings.show_entity_tooltip = false
		player.game_view_settings.show_quickbar = false
		player.game_view_settings.show_shortcut_bar = false
		player.game_view_settings.show_crafting_queue = false
		player.game_view_settings.show_tool_bar = false
		player.game_view_settings.show_hotkey_suggestions = false
		player.game_view_settings.update_entity_selection = false
		player.game_view_settings.show_side_menu = false
		
		if hide_map_settings then
			player.map_view_settings = {
				["show-logistic-network"] = false,
				["show-electric-network"] = false,
				["show-turret-range"] = false,
				["show-pollution"] = false,
				--["show-networkless-logistic-members"] = false,
				["show-train-station-names"] = false,
				["show-player-names"] = false,
				["show-tags"] = false,
				["show-worker-robots"] = false,
				["show-rail-signal-states"] = false,
				["show-recipe-icons"] = false,
				["show-pipelines"] = false,
				--["show-non-standard-map-info"] = false,
			}
		end
		
		-- Start the game :D
		if start_round(player) == -1 then
			return
		end
		
        -- Keep shortcut active during round
        player.set_shortcut_toggled("geo-toggle", true)
		
		-- Give player the tool to guess the position
		util.give_player_geoguessr_tool(player)
		return
    end

    -- Guess confirm
    if e.element.name == "geo_guess_confirm" and storage.geoguessr[e.player_index].guess ~= nil then

		local score = util.calculate_score(e.player_index, game.get_player(e.player_index).surface)
		storage.geoguessr[e.player_index].total_score = (storage.geoguessr[e.player_index].total_score or 0) + score[2]

        -- Close confirmation and camera GUI
        if player.gui.screen.geo_confirm_frame then
            player.gui.screen.geo_confirm_frame.destroy()
        end
        if player.gui.screen.geo_gameplay_frame then
            player.gui.screen.geo_gameplay_frame.destroy()
        end
		
		player.print({"geoguessr.target-text", util.gps_tag(storage.geoguessr[e.player_index].round_chunk[1], storage.geoguessr[e.player_index].round_chunk[2])})

		-- Show round summary
		show_round_summary(
			player,
			storage.geoguessr[e.player_index].round_index,
			storage.geoguessr[e.player_index].rounds_total,
			score[2],
			storage.geoguessr[e.player_index].total_score,
			score[1]
		)
		
		storage.geoguessr[e.player_index].round_index = storage.geoguessr[e.player_index].round_index + 1
		storage.geoguessr[e.player_index].round_active = false
		return
	end
	
	if e.element.name == "geo_summary_close" then
		if player.gui.screen.geo_summary_frame then
			player.gui.screen.geo_summary_frame.destroy()
		end

		-- Start next round if more rounds remain
		if storage.geoguessr[e.player_index].round_index > storage.geoguessr[e.player_index].rounds_total then
			--player.print("Game finished! Total score: " .. storage.geoguessr[e.player_index].total_score)
			util.reset_game(player)
		else
			storage.geoguessr[e.player_index].guess = nil
			if start_round(player) == -1 then
				return
			end
			storage.geoguessr[e.player_index].round_active = true
			util.give_player_geoguessr_tool(player)
		end
		return
	end

    -- Guess cancel
    if e.element.name == "geo_guess_cancel" then
        if player.gui.screen.geo_confirm_frame then
            player.gui.screen.geo_confirm_frame.destroy()
        end
        storage.geoguessr[e.player_index].guess = nil
		util.give_player_geoguessr_tool(player)
    end
end)


function start_round(player)
	local max_attempts = 100
	
	for attempt = 1, max_attempts do
		local surface = storage.geoguessr[player.index].round_surface and player.surface or util.get_random_surface(player)
		
		if surface then
			
			local chunk = util.get_random_player_position(surface, player)
			if chunk then
				storage.geoguessr[player.index].round_chunk = chunk
				storage.geoguessr[player.index].round_end_tick = game.tick + storage.geoguessr[player.index].round_duration

				create_gameplay_view(player, surface, chunk)
				return
			end
		end
	end
	util.reset_game(player)
	player.print("{geoguessr.error-cannot-find-valid-location}")
	return -1


    --player.print("Round " .. storage.geoguessr[player.index].round_index .. " / " .. storage.geoguessr[player.index].rounds_total)
end

--------------------------------------------------
-- TIMER LOOP (once per second)
--------------------------------------------------
script.on_nth_tick(60, function()
    if not storage.geoguessr then return end
	
	for player_index, geoguessr in pairs(storage.geoguessr) do
		if geoguessr.round_active then
			local remaining = geoguessr.round_end_tick - game.tick
			remaining = math.max(0, remaining)  -- clamp to 0

			-- Compute minutes/seconds
			local total_seconds = math.floor(remaining / 60)
			local minutes = math.floor(total_seconds / 60)
			local seconds = total_seconds % 60

			local player = game.get_player(player_index)
			local frame = player.gui.screen.geo_gameplay_frame
			if frame then
				local label = frame.info.geo_timer_label
				local bar = frame.info.geo_timer_bar
				--game.print(label)
				if label then
					label.caption = string.format("%02d:%02d", minutes, seconds)
				end

				if bar then
					local progress = remaining / geoguessr.round_duration
					progress = math.min(math.max(progress, 0), 1)
					bar.value = progress
				end
			end

			-- End round
			if remaining <= 0 then
				show_round_summary(
					player,
					storage.geoguessr[player_index].round_index,
					storage.geoguessr[player_index].rounds_total,
					0,
					storage.geoguessr[player_index].total_score,
					0
				)
				storage.geoguessr[player_index].round_index = storage.geoguessr[player_index].round_index + 1
				geoguessr.round_active = false
			end
		end
	end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	--game.print(tostring(storage.geoguessr[event.player_index].round_active) .. " wtf " .. tostring(event.player_index))
	if storage.geoguessr and storage.geoguessr[event.player_index] and storage.geoguessr[event.player_index].round_active then
		local player = game.get_player(event.player_index)
		local cursor = player.cursor_stack
		
		if not (cursor and cursor.valid_for_read and cursor.name == "geo-guess-tool") and storage.geoguessr[event.player_index].guess == nil then 
			util.give_player_geoguessr_tool(player)
		end
	end
end)

-- When player selects a location with the tool
script.on_event(prototypes.custom_input["geo-guess"], function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read) then return end
    if cursor.name ~= "geo-guess-tool" then return end
    if not storage.geoguessr[event.player_index].round_active then return end

    -- Store guessed position temporarily
    storage.geoguessr[event.player_index].guess = {player.surface.name, event.cursor_position}

	-- Ping guessed location
	player.print({"geoguessr.guess-text", util.gps_tag(player.surface.name, event.cursor_position)})
	
    -- Show confirmation GUI
    if player.gui.screen.geo_confirm_frame then
        player.gui.screen.geo_confirm_frame.destroy()
    end

    local frame = player.gui.screen.add{
        type = "frame",
        name = "geo_confirm_frame",
        caption = {"geoguessr.confirm-guess"},
        direction = "vertical"
    }
    frame.auto_center = true

    frame.add{
        type = "label",
        caption = {"geoguessr.confirm-guess-text", string.format("%.0f",storage.geoguessr[event.player_index].guess[2].x), string.format("%.0f",storage.geoguessr[event.player_index].guess[2].y) }
    }

    local button_flow = frame.add{
        type = "flow",
        direction = "horizontal"
    }

    button_flow.add{
        type = "button",
        name = "geo_guess_confirm",
        caption = {"geoguessr.confirm"}
    }

    button_flow.add{
        type = "button",
        name = "geo_guess_cancel",
        caption = {"geoguessr.close"}
    }
	
	
	if player.cursor_stack.valid_for_read and player.cursor_stack.name == "geo-guess-tool" then
		player.cursor_stack.clear()
	end
end)