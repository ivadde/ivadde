--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local eightball = {}

local mattata = require('mattata')

function eightball:init()
    eightball.commands = mattata.commands(
        self.info.username,
        {
            '[Yy]/[Nn]%p*$'
        }
    ):command('eightball')
     :command('8ball').table
    eightball.help = [[/eightball - Makes a decision for you using the (virtual) magic 8 ball! Alias: /8ball.]]
end

function eightball:on_message(message, configuration)
    local output
    if message.text:lower():match('y/n%p?$') then
        local random = math.random(6)
        if random == 1 then
            output = '👍'
        elseif random == 2 then
            output = '👎'
        elseif random == 3 then
            output = 'Yes.'
        elseif random == 4 then
            output = 'No.'
        elseif random == 5 then
            output = 'It is likely so.'
        else
            output = 'Well, uh... I\'d ask again later, if I were you.'
        end
    else
        local answers = configuration.eightball
        output = answers[math.random(#answers)]
    end
    return mattata.send_reply(
        message,
        output
    )
end

return eightball