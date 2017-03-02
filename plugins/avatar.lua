--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local avatar = {}

local mattata = require('mattata')
local json = require('dkjson')

function avatar:init()
    avatar.commands = mattata.commands(
        self.info.username
    ):command('avatar').table
    avatar.help = [[/avatar <user> [offset] - Sends the profile photos of the given user, of which can be specified by username or numerical ID. If an offset is given after the username (which must be a numerical value), then the nth profile photo is sent (if available).]]
end

function avatar:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        input = inline_query.from.id
    end
    local selected_photo = false
    if tostring(input):match('^.- %d*$') then
        selected_photo = tostring(input):match('^.- (%d*)$')
        input = tostring(input):match('^(.-) %d*$')
    end
    local success = true
    local old_input = input
    if tonumber(input) == nil then
        input = mattata.get_user(input)
        if not input then
            success = false
        else
            input = input.result.id
        end
    end
    if success then
        success = mattata.get_user_profile_photos(input)
    end
    if not success then
        return mattata.send_inline_article(
            inline_query.id,
            'An error occured!',
            [[I couldn't retrieve the profile photos for that user, please ensure you specified a valid username or numerical ID.]]
        )
    elseif success.result.total_count == 0 then
        return mattata.send_inline_article(
            inline_query.id,
            'An error occured!',
            [[That user doesn't have any profile photos.]]
        )
    elseif selected_photo then
        if tonumber(selected_photo) < 1 or tonumber(selected_photo) > success.result.total_count then
            return mattata.send_inline_article(
                inline_query.id,
                'An error occured!',
                [[That user doesn't have that many profile photos!]]
            )
        end
    end
    local results = {}
    local count = 1
    for i = (tonumber(selected_photo) or 1), (tonumber(selected_photo) or success.result.total_count) do
        table.insert(
            results,
             {
                ['type'] = 'photo',
                ['id'] = tostring(count),
                ['photo_file_id'] = success.result.photos[i][#success.result.photos[i]].file_id,
                ['caption'] = string.format(
                    'User: %s\nPhoto: %s/%s\nSend /avatar %s [offset] to @%s to view a specific photo of this user',
                    old_input,
                    i,
                    success.result.total_count,
                    old_input,
                    self.info.username
                )
            }
        )
        count = count + 1
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(results)
    )
end

function avatar:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            avatar.help
        )
    end
    local selected_photo = 1
    if input:match(' %d*$') then
        selected_photo = tonumber(input:match(' (%d*)$'))
        input = input:match('^(.-) %d*$')
    end
    local success = true
    local old_input = input
    if tonumber(input) == nil then
        input = mattata.get_user(input)
        if not input then
            success = false
        else
            input = input.result.id
        end
    end
    if success then
        success = mattata.get_user_profile_photos(input)
    end
    if not success then
        return mattata.send_reply(
            message,
            [[I couldn't retrieve the profile photos for that user, please ensure you specified a valid username or numerical ID.]]
        )
    elseif success.result.total_count == 0 then
        return mattata.send_reply(
            message,
            [[That user doesn't have any profile photos.]]
        )
    elseif tonumber(selected_photo) < 1 or tonumber(selected_photo) > success.result.total_count then
        return mattata.send_reply(
            message,
            [[That user doesn't have that many profile photos!]]
        )
    end
    local highest_res = success.result.photos[selected_photo][#success.result.photos[selected_photo]].file_id
    local caption = string.format(
        'User: %s\nPhoto: %s/%s\nUse /avatar %s [offset] to view a specific photo of this user',
        old_input,
        selected_photo,
        success.result.total_count,
        old_input
    )
    return mattata.send_photo(
        message.chat.id,
        highest_res,
        caption
    )
end

return avatar