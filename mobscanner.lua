_addon.name = 'Mobscanner'
_addon.author = 'Staticvoid'
_addon.version = '1.1'
_addon.commands = {'ms','mscanner'}

require('tables')

local https  = require('ssl.https')
local ltn12  = require('ltn12')
local config = require('config')
------------------ SET THIS VARIABLE TO YOUR DISCORD CHANNEL'S WEBHOOK URL FOR ALERTS TO YOUR PHONE -----------------------
local webhook_url = ''
---------------------------------------------------------------------------------------------------------------------------
local defaults = {
    radius = 2500,
    target_names = T{},
}

local player_name = windower.ffxi.get_player().name
local settings = config.load('data/settings_'..player_name..'.xml',defaults)
local cleaned_targets = T{}

if type(settings.target_names) == 'table' then

    for _, v in pairs(settings.target_names) do

        if type(v) == 'string' then
            cleaned_targets:append(v)
        end
    end
end

settings.target_names = cleaned_targets

local addon_path = windower.addon_path
local alert = addon_path .. 'data/alert.wav'

local tracked_mobs = {}
local alert_cooldown = 30
local frame_counter = 0

local function escape_json(str)
    return str
        :gsub('\\', '\\\\')
        :gsub('"', '\\"')
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
end

local function send_discord_alert(message)

    local body = ('{"content":"%s"}'):format(
        escape_json(message)
    )

    https.request{
        url = webhook_url,
        method = 'POST',
        headers = {
            ['Content-Type']   = 'application/json',
            ['Content-Length'] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink   = ltn12.sink.table({})
    }
end

local function scan_for_mobs()

    local info = windower.ffxi.get_info()

    if not info.logged_in then
        return
    end

    if #settings.target_names == 0 then
        return
    end

    local mobs = windower.ffxi.get_mob_array()

    for _, mob in pairs(mobs) do

        if mob
        and mob.is_npc
        and mob.valid_target
        and mob.status == 0
        then

            local mob_name = mob.name and mob.name:lower()

            if mob_name then

                local matched = false

                for _, target_name in ipairs(settings.target_names) do

                    if mob_name == target_name:lower() then
                        matched = true
                        break
                    end
                end

                if matched then

                    local now = os.time()

                    if not tracked_mobs[mob.id]
                    or (now - tracked_mobs[mob.id]) >= alert_cooldown
                    then

                        tracked_mobs[mob.id] = now

                        local msg = ('MobScanner 3000 detected "%s".'):format(mob.name)

                        windower.add_to_chat(207, msg)

                        send_discord_alert(msg) 

                        windower.play_sound(alert)
                    end
                end
            end
        end
    end
end

windower.register_event('time change', function()
    scan_for_mobs()
end)

windower.register_event('zone change', function()
    tracked_mobs = {}
end)


windower.register_event('addon command', function(command, ...)

    command = command and command:lower() or ''

    local args = {...}

    if command == 'add' then

        local mob_name = table.concat(args, ' ')

        if mob_name == '' then
            windower.add_to_chat(207,
                'MobScanner 3000: Usage //malert add <mob name>'
            )
            return
        end

            -- ditch the quotes if there are any
        mob_name = mob_name:gsub('^"(.*)"$', '%1')

        -- stop duplicates
        for _, existing_name in ipairs(settings.target_names) do

            if existing_name:lower() == mob_name:lower() then

                windower.add_to_chat(207,
                    ('MobScanner 3000: "%s" already exists.'):format(mob_name)
                )

                return
            end
        end

        table.insert(settings.target_names, mob_name)

        config.save(settings)

        windower.add_to_chat(207,
            ('MobScanner 3000: Added "%s".'):format(mob_name)
        )


    elseif command == 'remove' then

        local mob_name = table.concat(args, ' ')

        mob_name = mob_name:gsub('^"(.*)"$', '%1')

        for i, existing_name in ipairs(settings.target_names) do

            if existing_name:lower() == mob_name:lower() then

                table.remove(settings.target_names, i)

                config.save(settings)

                windower.add_to_chat(207,
                    ('MobScanner 3000: Removed "%s".'):format(mob_name)
                )

                return
            end
        end

        windower.add_to_chat(207,
            ('MobScanner 3000: "%s" not found.'):format(mob_name)
        )


    elseif command == 'list' then

        if #settings.target_names == 0 then

            windower.add_to_chat(207,
                'MobScanner 3000: No mobs configured.'
            )

            return
        end

        windower.add_to_chat(207,
            'MobScanner 3000: Currently tracked mobs:'
        )

        for _, mob_name in ipairs(settings.target_names) do
            windower.add_to_chat(207, '  - ' .. mob_name)
        end


    elseif command == 'clear' then

        settings.target_names:clear()

        config.save(settings)

        windower.add_to_chat(207,
            'MobScanner 3000: Cleared mob list.'
        )


    else

        windower.add_to_chat(207, 'MobScanner 3000 Commands:')
        windower.add_to_chat(207, '//ms add <mob>')
        windower.add_to_chat(207, '//ms remove <mob>')
        windower.add_to_chat(207, '//ms list')
        windower.add_to_chat(207, '//ms clear')
    end
end)