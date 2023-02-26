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
    table.merge(table.deepcopy(
        data.raw['arithmetic-combinator']['arithmetic-combinator']),
        {
        name = "microcontroller",
        minable = {
            hardness = 0.2,
            mining_time = 0.5,
            result = "microcontroller"
        },
        order = 'a'
    }), table.merge(table.deepcopy(
        data.raw['constant-combinator']['constant-combinator']),
        {
        name = "microcontroller-ram",
        minable = {
            hardness = 0.2,
            mining_time = 0.5,
            result = "microcontroller-ram"
        },
        item_slot_count = 4,
        order = 'b'
    }), {
        type = "item",
        name = "microcontroller",
        place_result = 'microcontroller',
        icon = "__m-microcontroller__/graphics/microchip.png",
        icon_size = 32,
        stack_size = 20,
        subgroup = "circuit-network",
        order = 'zz'
    }, {
        type = "item",
        name = "microcontroller-ram",
        place_result = 'microcontroller-ram',
        icon = "__m-microcontroller__/graphics/ram.png",
        icon_size = 32,
        stack_size = 40,
        subgroup = "circuit-network",
        order = 'zz'
    }, {
        type = "technology",
        name = "microcontroller",
        icon_size = 128,
        icon = "__m-microcontroller__/graphics/microchip_large.png",
        effects = {
            {type = "unlock-recipe", recipe = "microcontroller"},
            {type = "unlock-recipe", recipe = "microcontroller-ram"}
        },
        prerequisites = {"circuit-network", "advanced-electronics"},
        unit = {
            count = 250,
            ingredients = {
                {"automation-science-pack", 1}, {"logistic-science-pack", 1}
            },
            time = 30
        },
        localised_description = {"microcontroller.doc.overview_description"},
        order = "c-g-b"
    }, {
        type = "recipe",
        name = "microcontroller",
        enabled = false,
        ingredients = {{"arithmetic-combinator", 3}, {"decider-combinator", 3}},
        energy_required = 1,
        results = {{"microcontroller", 1}}
    }, {
        type = "recipe",
        name = "microcontroller-ram",
        enabled = false,
        ingredients = {{"arithmetic-combinator", 3}, {"advanced-circuit", 2}},
        energy_required = 1,
        results = {{"microcontroller-ram", 1}}
    },
    {type = "custom-input", name = "microcontroller-close", key_sequence = "E"},
    {type = "font", name = "default-mono", from = "default-mono", size = 16}
}

local function gen_tech(no,nb_packs_type,nb_packs,time,prerequisites)
    local ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1}
    }
    while(#ingredients > nb_packs_type) do
        table.remove(ingredients,#ingredients)
    end
    local unit={
        count=nb_packs,
        time=time,
        ingredients=ingredients
    }
    local name="microcontroller-program-size-" .. no
    local order="c-g-b-" .. string.char(96+no)
    if no>1 then
        table.insert(prerequisites,"microcontroller-program-size-" .. (no-1))
    end
    return {
        type = "technology",
        name = name,
        icon_size=128,
        icon="__m-microcontroller__/graphics/microchip_large.png",
        prerequisites = prerequisites,
        effects = {},
        unit = unit,
        order = order
    }
end

local infinite_tech=gen_tech(4,6,0,60,{"space-science-pack"})
infinite_tech.unit.count_formula="(L-3)*1000"
infinite_tech.unit.count=nil
infinite_tech.max_level="infinite"
infinite_tech.upgrade="true"
data:extend{
    gen_tech(1,3,300,40,{"microcontroller","chemical-science-pack"}),
    gen_tech(2,4,500,45,{"production-science-pack"}),
    gen_tech(3,5,750,50,{"utility-science-pack"}),
    infinite_tech
}

data:extend{
    {
        type = "sprite",
        name = "microcontroller-play-sprite",
        filename = "__m-microcontroller__/graphics/play.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-stop-sprite",
        filename = "__m-microcontroller__/graphics/stop.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-next-sprite",
        filename = "__m-microcontroller__/graphics/next.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-exit-sprite",
        filename = "__m-microcontroller__/graphics/cancel.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-copy-sprite",
        filename = "__m-microcontroller__/graphics/copy.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-paste-sprite",
        filename = "__m-microcontroller__/graphics/draft.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "sprite",
        name = "microcontroller-info-sprite",
        filename = "__m-microcontroller__/graphics/info.png",
        width = 32,
        height = 32,
        flags = {"gui-icon"}
    }, {
        type = "virtual-signal",
        name = "signal-mc-halt",
        icon = "__m-microcontroller__/graphics/signal_halt.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[A]"
    }, {
        type = "virtual-signal",
        name = "signal-mc-run",
        icon = "__m-microcontroller__/graphics/signal_run.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[B]"
    }, {
        type = "virtual-signal",
        name = "signal-mc-step",
        icon = "__m-microcontroller__/graphics/signal_step.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[C]"
    }, {
        type = "virtual-signal",
        name = "signal-mc-sleep",
        icon = "__m-microcontroller__/graphics/signal_sleep.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[D]"
    }, {
        type = "virtual-signal",
        name = "signal-mc-jump",
        icon = "__m-microcontroller__/graphics/signal_jump.png",
        icon_size = 32,
        subgroup = "virtual-signal-letter",
        order = "c[microcntroller]-[E]"
    }
}
