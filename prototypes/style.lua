local default_gui = data.raw["gui-style"].default

default_gui["mc_notice_textbox"] = {
    type = "textbox_style",
    parent = "textbox",
    graphical_set =
    {
        type = "none",
        opacity = 0
    },
    font = "default-mono",
    font_color = {r=0, g=1, b=0},
    disabled_font_color = {r=0, g=0, b=0},
    selection_background_color = {r=0, g=0, b=0},
    -- font_color = {r=1, g=1, b=1},
    -- selection_background_color = {r=0.66, g=0.7, b=0.83},
    padding = 0,
    active_background = {
        filename = "__m-microcontroller__/graphics/black.png",
          width = 1,
          height = 1
    },
    default_background = {
      filename = "__m-microcontroller__/graphics/grey.png",
      width = 1,
      height = 1
    }
}
default_gui["mc_program_input"] = {
    type = "textbox_style",
    parent = "textbox",
    graphical_set =
    {
        type = "none",
        opacity = 0
    },
    font = "default-mono",
    font_color = {r=0, g=1, b=0},
    disabled_font_color = {r=0, g=1, b=0},
    selection_background_color = {r=0, g=0, b=0},
    rich_text_setting = "disabled",
	maximal_width = 400,
	minimal_width = 280,
    minimal_height = 582,
	word_wrap = false,
    padding = 0,
    active_background = {
        filename = "__m-microcontroller__/graphics/black.png",
          width = 1,
          height = 1
    },
    default_background = {
      filename = "__m-microcontroller__/graphics/grey.png",
      width = 1,
      height = 1
    }
}
