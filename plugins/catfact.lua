--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local catfact = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function catfact:init()
    catfact.commands = mattata.commands(
        self.info.username
    ):command('catfact').table
    catfact.help = [[/catfact - Sends a random, cat-themed fact.]]
end

function catfact:on_inline_query(inline_query)
    local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = jdat.facts[1],
                    ['description'] = 'Click to send the result.',
                    ['input_message_content'] = {
                        ['message_text'] = jdat.facts[1]
                    }
                }
            }
        )
    )
end

function catfact:on_message(message, configuration)
    local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        jdat.facts[1]
    )
end

return catfact