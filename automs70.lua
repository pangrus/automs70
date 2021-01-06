-- automs70
--
-- ZOOM MS-70 CDR
-- automation system
--
-- K2 toggle value/destination
-- E1 select
-- E2/E3 change values
--
-- V1.1
-- @pangrus 2020

-- variables
local knob = {}
local knobsNumber = 9
local knobIndex = 1
local selected = 1
local shift = false
local editMode = "range"
local minValue
local maxValue
local value
local newValue
local parameterEditEnable = {0xf0, 0x52, 0x00, 0x61, 0x50, 0xf7}
local parameterEdit = {0xf0, 0x52, 0x00, 0x61, 0x31, 1, 1, 0, 0, 0xf7}
local patchSelect = {0xc0, patch}

-- multistomp connect
local MULTISTOMP = midi.connect(1)

-- midi clock management
local MIDI_Clock = require "beatclock"
local clk = MIDI_Clock.new()
local clk_midi = midi.connect(2)

-- midi cc device
local cc_device = midi.connect(3)

function init()
    -- enable MS-70 parameters editing
    MULTISTOMP:send(parameterEditEnable)

    -- reduce encoders sensitivity
    norns.enc.sens(1, 3)
    -- norns.enc.sens(2, 3)
    -- norns.enc.sens(3, 3)

    -- clock management
    clk_midi.event = function(data)
        clk:process_midi(data)
    end
    clk.on_step = Automate
    clk.on_select_internal = function()
        clk:start()
    end
    clk.on_select_external = external
    clk:start()

    -- parameters
    params:add_separator()
    params:add_separator("clock")
    clk:add_clock_params()

    params:add_separator()
    params:add_separator("MS type")
    params:add_option("MS type", "MS type", {"MS-70 CDR", "MS-50G"}, 1)
    params:set_action(
        "MS type",
        function(x)
            if params:get("MS type") == 1 then
                parameterEditEnable = {0xf0, 0x52, 0x00, 0x61, 0x50, 0xf7}
                MULTISTOMP:send(parameterEditEnable)
                print("MS-70 CDR editing enabled")
            elseif params:get("MS type") == 2 then
                parameterEditEnable = {0xf0, 0x52, 0x00, 0x58, 0x50, 0xf7}
                MULTISTOMP:send(parameterEditEnable)
                print("MS-50G editing enabled")
            end
        end
    )

    params:add_separator()
    params:add_separator("controllers")
    for i = 1, knobsNumber do
        params:add_group("controller " .. i, 6)

        params:add {
            type = "number",
            id = "knob " .. i .. " min",
            name = "knob " .. i .. " min",
            min = 0,
            max = 1280,
            default = 0,
            action = function()
                knob[selected].value = params:get("knob " .. selected .. " min")
                knob[selected].newValue = params:get("knob " .. selected .. " min")
                if params:get("knob " .. selected .. " min") >= params:get("knob " .. selected .. " max") then
                    params:set("knob " .. selected .. " max", params:get("knob " .. selected .. " min") + 1)
                end
            end
        }
        params:add {
            type = "number",
            id = "knob " .. i .. " max",
            name = "knob " .. i .. " max",
            min = 1,
            max = 1280,
            default = 100,
            action = function()
                knob[selected].value = params:get("knob " .. selected .. " max")
                knob[selected].newValue = params:get("knob " .. selected .. " max")
                if params:get("knob " .. selected .. " max") <= params:get("knob " .. selected .. " min") then
                    params:set("knob " .. selected .. " min", params:get("knob " .. selected .. " max") - 1)
                end
            end
        }
        params:add {
            type = "number",
            id = "knob " .. i .. " effect",
            name = "knob " .. i .. " effect",
            min = 1,
            max = 5,
            default = 0,
            action = function()
            end
        }
        params:add {
            type = "number",
            id = "knob " .. i .. " destination",
            name = "knob " .. i .. " destination",
            min = 1,
            max = 9,
            default = 0,
            action = function()
            end
        }
        params:add {
            type = "number",
            id = "knob " .. i .. " Midi CC",
            name = "knob " .. i .. " Midi CC",
            min = 1,
            max = 127,
            default = 79 + i,
            action = function()
            end
        }
        params:add {
            type = "number",
            id = "knob " .. i .. " Midi Channel",
            name = "knob " .. i .. " Midi Channel",
            min = 1,
            max = 127,
            default = 1,
            action = function()
            end
        }
    end
    Init_knobs()
end

function Init_knobs()
    for i = 1, knobsNumber do
        minValue = params:get("knob " .. i .. " min")
        maxValue = params:get("knob " .. i .. " max")
        value = math.floor(math.random(maxValue - minValue)) + minValue
        newValue = math.floor(math.random(maxValue - minValue)) + minValue
        knob[i] = {
            value = value,
            newValue = newValue
        }
    end
    params:set("knob 1 effect", 1)
    params:set("knob 2 effect", 1)
    params:set("knob 3 effect", 1)
    params:set("knob 4 effect", 2)
    params:set("knob 5 effect", 2)
    params:set("knob 6 effect", 2)
    params:set("knob 7 effect", 3)
    params:set("knob 8 effect", 3)
    params:set("knob 9 effect", 3)
    params:set("knob 1 destination", 1)
    params:set("knob 2 destination", 2)
    params:set("knob 3 destination", 3)
    params:set("knob 4 destination", 1)
    params:set("knob 5 destination", 2)
    params:set("knob 6 destination", 3)
    params:set("knob 7 destination", 1)
    params:set("knob 8 destination", 2)
    params:set("knob 9 destination", 3)
end

function Automate()
    if
        knob[knobIndex].value == knob[knobIndex].newValue or
            knob[knobIndex].value > params:get("knob " .. knobIndex .. " max") or
            knob[knobIndex].value < params:get("knob " .. knobIndex .. " min")
     then
        knob[knobIndex].newValue =
            math.floor(
            math.random(params:get("knob " .. knobIndex .. " max") - params:get("knob " .. knobIndex .. " min"))
        ) +
            params:get("knob " .. knobIndex .. " min") -
            1
    end
    if knob[knobIndex].value > knob[knobIndex].newValue then
        knob[knobIndex].value = knob[knobIndex].value - 1
    end
    if knob[knobIndex].value < knob[knobIndex].newValue then
        knob[knobIndex].value = knob[knobIndex].value + 1
    end
    local parameterMSB = math.floor(knob[knobIndex].value / 128)
    local parameterLSB = math.floor(knob[knobIndex].value - parameterMSB * 128)

    if params:get("MS type") == 1 then
        parameterEdit = {
            0xf0,
            0x52,
            0x00,
            0x61,
            0x31,
            params:get("knob " .. knobIndex .. " effect") - 1,
            params:get("knob " .. knobIndex .. " destination") + 1,
            parameterLSB,
            parameterMSB,
            0xf7
        }
    elseif params:get("MS type") == 2 then
        parameterEdit = {
            0xf0,
            0x52,
            0x00,
            0x58,
            0x31,
            params:get("knob " .. knobIndex .. " effect") - 1,
            params:get("knob " .. knobIndex .. " destination") + 1,
            parameterLSB,
            parameterMSB,
            0xf7
        }
    end

    -- send edit command to MS multieffect
    MULTISTOMP:send(parameterEdit)

    -- MIDI control change
    local ccValue = knob[knobIndex].value
    if ccValue > 127 then
        ccValue = 127
    end
    cc_device:cc(
        params:get("knob " .. knobIndex .. " Midi CC"),
        ccValue,
        params:get("knob " .. knobIndex .. " Midi Channel")
    )

    knobIndex = knobIndex + 1
    if knobIndex > knobsNumber then
        knobIndex = 1
    end

    redraw()
end

function external()
    clk:reset()
end

function Randomize_knobs()
    for i = 1, knobsNumber do
        minValue = math.floor(math.random(50))
        maxValue = math.floor(math.random(50)) + 50
        params:set("knob " .. i .. " min", minValue)
        params:set("knob " .. i .. " max", maxValue)
        value = math.floor(math.random(maxValue - minValue)) + minValue
        newValue = math.floor(math.random(maxValue - minValue)) + minValue
        knob[i].value = value
        knob[i].newValue = newValue
    end
end

function key(n, z)
    if n == 1 and z == 1 then
        shift = true
    else
        shift = false
    end
    if n == 2 and z == 1 then
        if editMode == "range" then
            editMode = "destination"
        else
            editMode = "range"
        end
    end
    if n == 3 and z == 1 then
        Randomize_knobs()
    end
end

function enc(n, d)
    -- selection
    if n == 1 then
        selected = util.clamp(selected + d, 1, knobsNumber)
    end
    -- min/max
    if editMode == "range" then
        if n == 2 then
            params:delta("knob " .. selected .. " min", d)
        end
        if n == 3 then
            params:delta("knob " .. selected .. " max", d)
        end
    end
    -- effect/desination Knob
    if editMode == "destination" then
        if n == 2 then
            params:delta("knob " .. selected .. " effect", d)
        end
        if n == 3 then
            params:delta("knob " .. selected .. " destination", d)
        end
    end
end

function redraw()
    screen.clear()
    for i = 1, knobsNumber do
        screen.level(selected == i and 10 or 2)
        local x = (i + 2) % 3
        local y = math.floor((i - 1) / 3)
        screen.rect(32 + 21 * x, 21 * y + 2, 19, 19)
        screen.stroke()
        local scaleFactor = 19 / (params:get("knob " .. i .. " max") - params:get("knob " .. i .. " min"))
        screen.move(32 + 21 * x, 21 * y - (knob[i].value - params:get("knob " .. i .. " min") * scaleFactor))
        screen.line(0, 18)
        screen.rect(
            32 + 21 * x,
            21 * y + 9,
            knob[i].value * scaleFactor - params:get("knob " .. i .. " min") * scaleFactor,
            3
        )
        screen.fill()
        screen.level(15)
        if editMode == "range" then
            screen.move(41 + 21 * x, 6 + y * 21 + 2)
            screen.text_center(params:get("knob " .. i .. " min"))
            screen.move(41 + 21 * x, 16 + y * 21 + 2)
            screen.text_center(params:get("knob " .. i .. " max"))
        end

        if editMode == "destination" then
            screen.move(41 + 21 * x, 6 + y * 21 + 2)
            screen.text_center("E" .. params:get("knob " .. i .. " effect"))
            screen.move(41 + 21 * x, 16 + y * 21 + 2)
            screen.text_center("K" .. params:get("knob " .. i .. " destination"))
        end
    end
    screen.update()
end
