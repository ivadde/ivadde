--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local flickr = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function flickr:init(configuration)
    assert(
        configuration.keys.flickr,
        'flickr.lua requires an API key, and you haven\'t got one configured!'
    )
    flickr.commands = mattata.commands(
        self.info.username
    ):command('flickr').table
    flickr.help = [[/flickr <query> - Searches Flickr for a photo matching the given search query and returns the most relevant result.]]
end

function flickr:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local jstr = https.request('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' .. configuration.keys.flickr .. '&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o&text=' .. url.escape(input))
    local jdat = json.decode(jstr)
    local results_list = {}
    local id = 1
    for n in pairs(jdat.photos.photo) do
        if jdat.photos.photo[n].url_l and jdat.photos.photo[n].url_s and jdat.photos.photo[n].url_l:match('%.jpe?g$') then
            table.insert(
                results_list,
                {
                    ['type'] = 'photo',
                    ['id'] = tostring(id),
                    ['photo_url'] = jdat.photos.photo[n].url_l,
                    ['thumb_url'] = jdat.photos.photo[n].url_s,
                    ['photo_width'] = tonumber(jdat.photos.photo[n].width_l),
                    ['photo_height'] = tonumber(jdat.photos.photo[n].height_l),
                    ['caption'] = 'You searched for: ' .. input
                }
            )
        end
        id = id + 1
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(results_list)
    )
end

function flickr:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            flickr.help
        )
    end
    local jstr, res = https.request(
        string.format(
            'https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%s&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_o&text=%s',
            configuration.keys.flickr,
            url.escape(input)
        )
    )       
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.photos.total == '0' then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    local keyboard = json.encode(
        {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = 'More Results',
                        ['url'] = 'https://www.flickr.com/search/?text=' .. url.escape(input)
                    }
                }
            }
        }
    )
    return mattata.send_photo(
        message.chat.id,
        jdat.photos.photo[1].url_o,
        nil,
        false,
        message.message_id,
        keyboard
    )
end

return flickr