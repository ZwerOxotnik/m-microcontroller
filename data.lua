require('stdlib/table')
require('constants')
require('prototypes/style')

if data.raw["custom-input"]["open-gui"] == nil then
    data.raw["custom-input"]["open-gui"] = {
        type = "custom-input",
        name = "open-gui",
        key_sequence = "",
        linked_game_control = "open-gui"
    }
end

data:extend{
    table.merge(table.deepcopy(data.raw['arithmetic-combinator']['arithmetic-combinator']), {
        name = "microcontroller",
        minable = {hardness = 0.2, mining_time = 0.5, result = "microcontroller"},
        order = 'a'
    }),
    table.merge(table.deepcopy(data.raw['constant-combinator']['constant-combinator']), {
        name = "microcontroller-ram",
        minable = {hardness = 0.2, mining_time = 0.5, result = "microcontroller-ram"},
        item_slot_count = 4,
        order = 'b'
    }),
    {
        type = "item",
        name = "microcontroller",
        place_result = 'microcontroller',
        icon = "__m-microcontroller__/graphics/microchip.png",
        icon_size = 32,
        stack_size = 20,
        subgroup = "circuit-network",
        order = 'zz'
    },
    {
        type = "item",
        name = "microcontroller-ram",
        place_result = 'microcontroller-ram',
        icon = "__m-microcontroller__/graphics/ram.png",
        icon_size = 32,
        stack_size = 40,
        subgroup = "circuit-network",
        order = 'zz'
    },
    {
        type = "technology",
        name = "microcontroller",
        icon_size = 128,
        icon = "__m-microcontroller__/graphics/microchip_large.png",
        effects = {
            {
                type = "unlock-recipe",
                recipe = "microcontroller",
            },
            {
                type = "unlock-recipe",
                recipe = "microcontroller-ram",
            },
        },
        prerequisites = { "circuit-network", "advanced-electronics" },
        unit = {
            count = 250,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
            },
            time = 30,
        },
        localised_description = {"microcontroller.doc.overview_description"},
        order = "c-g-b",
    },
    {
        type = "recipe",
        name = "microcontroller",
        enabled = false,
        ingredients = {{"arithmetic-combinator", 3}, {"decider-combinator", 3}},
        energy_required = 1,
        results = {{"microcontroller", 1}}
    },
    {
        type = "recipe",
        name = "microcontroller-ram",
        enabled = false,
        ingredients = {{"arithmetic-combinator", 3}, {"advanced-circuit", 2}},
        energy_required = 1,
        results = {{"microcontroller-ram", 1}}
    },
    {
        type = "custom-input",
        name = "microcontroller-close",
        key_sequence = "E",
    },
    {
        type = "font",
        name = "default-mono",
        from = "default-mono",
        size = 16
    },
}

data:extend{
    {
        type = "sprite",
        name = "microcontroller-play-sprite",
        filename = "__m-microcontroller__/graphics/play.png",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "microcontroller-stop-sprite",
        filename = "__m-microcontroller__/graphics/stop.png",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "microcontroller-next-sprite",
        filename = "__m-microcontroller__/graphics/next.png",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "microcontroller-exit-sprite",
        filename = "__m-microcontroller__/graphics/cancel.png",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "microcontroller-copy-sprite",
        filename = "__m-microcontroller__/graphics/copy.png",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "microcontroller-paste-sprite",
        filename = "__m-microcontroller__/graphics/draft.png",
        width = 32,
        height = 32
    },

    {
        type = "virtual-signal",
        name = "signal-mc-halt",
        icon = "__m-microcontroller__/graphics/signal_halt.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[A]"
    },
    {
        type = "virtual-signal",
        name = "signal-mc-run",
        icon = "__m-microcontroller__/graphics/signal_run.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[B]"
    },
    {
        type = "virtual-signal",
        name = "signal-mc-step",
        icon = "__m-microcontroller__/graphics/signal_step.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[C]"
    },
    {
        type = "virtual-signal",
        name = "signal-mc-sleep",
        icon = "__m-microcontroller__/graphics/signal_sleep.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[D]"
    },
    {
        type = "virtual-signal",
        name = "signal-mc-jump",
        icon = "__m-microcontroller__/graphics/signal_jump.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[E]"
    },
}

for i = 1, MC_LINES do
    local y = ((i-1) * 21)
    if i >= 11 then
        y = y - 1
    end
    local h = 21
    data:extend{
        {
            type = "sprite",
            name = "microcontroller-line-sprite-default-"..i,
            filename = "__m-microcontroller__/graphics/lines.png",
            width = 42,
            height = h,
            x = 0,
            y = y
        }
    }
    data:extend{
        {
            type = "sprite",
            name = "microcontroller-line-sprite-active-"..i,
            filename = "__m-microcontroller__/graphics/lines.png",
            width = 42,
            height = h,
            x = 42,
            y = y
        }
    }
    data:extend{
        {
            type = "sprite",
            name = "microcontroller-line-sprite-error-"..i,
            filename = "__m-microcontroller__/graphics/lines.png",
            width = 42,
            height = h,
            x = 84,
            y = y
        }
    }
end
