local default_gui = data.raw["gui-style"].default

default_gui["mc_notice_textbox"] = {
    type = "textbox_style",
    parent = "textbox",
    font = "default-mono",
    font_color = {r=0, g=1, b=0},
    disabled_font_color = {r=0, g=0, b=0},
    selection_background_color = {r=0, g=0, b=0},
    rich_text_setting = "disabled",
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
    -- parent = "textbox",
    font = "default-mono",
    font_color = {r=0, g=0.9, b=0},
    disabled_font_color = {r=0, g=1, b=0},
    selection_background_color = {r=0.32, g=0.32, b=0.32},
    rich_text_setting = "disabled",
    maximal_height = 0, -- not limited
    minimal_width = 280,
    natural_width = 0,
    maximal_width = 0,
    word_wrap = false,
    padding = 0,
    horizontally_stretchable = "on",
    vertically_stretchable = "on",
    active_background = {
        filename = "__m-microcontroller__/graphics/black.png",
        width = 1,
        height = 1
    },
    default_background = {
      filename = "__m-microcontroller__/graphics/input.png",
      width = 1,
      height = 1
    }
}
