data:extend{
  {
    type = "custom-input",
    name = "geo-toggle",
    key_sequence = "CONTROL + G",
    consuming = "game-only"
  },
  {
    type = "custom-input",
    name = "geo-guess",
    key_sequence = "",
    linked_game_control = "build",
  },
  {
    type = "shortcut",
    name = "geo-toggle",
    order = "g[geo]",
    icon = "__base__/graphics/icons/radar.png",
    icon_size = 64,
    small_icon = "__base__/graphics/icons/radar.png",
    small_icon_size = 64,
    associated_control_input = "geo-toggle",
    toggleable = true,
    action = "lua"
  }
}

data:extend({
  {
    type = "item-with-label",
    name = "geo-guess-tool",
    icon = data.raw.capsule["artillery-targeting-remote"].icon,
    stack_size = 1,
    subgroup = "tool",
    flags = {"not-stackable", "only-in-cursor", "spawnable"},
    draw_label_for_cursor_render = true,
    custom_tooltip_fields = {
        {order = 1, name = {"gui.instruction-when-in-cursor"}, value = "", show_in_tooltip = true}
    }
  }
})