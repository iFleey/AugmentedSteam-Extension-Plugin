local json = require('json')
local http = require('http')
local logger = require('logger')
local millennium = require('millennium')
local fs = require('fs')

local steam_id = nil
local retrieve_url_response = nil

local DEFAULT_HEADERS = {
    Accept = '*/*',
    ['User-Agent'] = 'https://github.com/iFleey/AugmentedSteam-Extension-Plugin',
}

local function get_plugin_root()
    local backend_root = MILLENNIUM_PLUGIN_SECRET_BACKEND_ABSOLUTE or '.'
    local absolute_root = fs.absolute(backend_root .. '/..')

    if absolute_root == nil then
        return backend_root .. '/..'
    end

    return absolute_root
end

local function normalize_headers(headers)
    local result = {}
    if type(headers) ~= 'table' then
        return result
    end

    for key, value in pairs(headers) do
        local key_string = tostring(key)
        if type(value) == 'table' then
            local parts = {}
            for _, part in ipairs(value) do
                parts[#parts + 1] = tostring(part)
            end
            result[key_string] = table.concat(parts, ', ')
        else
            result[key_string] = tostring(value)
        end
    end

    return result
end

local function encode_response(status, url, headers, body)
    return json.encode({
        status = status,
        url = url,
        headers = headers,
        body = body,
    })
end

function GetPluginDir(_contentScriptQuery)
    return get_plugin_root()
end

function BackendFetch(url, _contentScriptQuery)
    local request_url = tostring(url or '')
    if request_url == '' then
        return encode_response(400, '', {}, '')
    end

    local response, err = http.get(request_url, {
        headers = DEFAULT_HEADERS,
        timeout = 30,
        follow_redirects = true,
        verify_ssl = true,
    })

    if response == nil then
        return encode_response(500, request_url, {}, tostring(err or 'No response'))
    end

    return encode_response(
        tonumber(response.status) or 500,
        tostring(response.url or request_url),
        normalize_headers(response.headers),
        tostring(response.body or '')
    )
end

function GetSteamId(_contentScriptQuery)
    if steam_id == nil then
        local ok, value = pcall(millennium.call_frontend_method, 'getSteamId')
        if ok and value ~= nil then
            steam_id = tostring(value)
        end
    end

    return steam_id or ''
end

function GetRetrieveUrlResponse(_contentScriptQuery)
    local value = retrieve_url_response
    retrieve_url_response = nil
    return value
end

function SetRetrieveUrlResponse(response, _contentScriptQuery)
    retrieve_url_response = response
end

function AugmentedSteam_LogWarn(message, _contentScriptQuery)
    logger:warn(tostring(message or ''))
end

function AugmentedSteam_LogError(message, _contentScriptQuery)
    logger:error(tostring(message or ''))
end

local plugin = {}

function plugin.on_frontend_loaded()
    return
end

function plugin.on_load()
    logger:info('Bootstrapping AugmentedSteam plugin, Millennium ' .. tostring(millennium.version()))
    millennium.ready()
end

function plugin.on_unload()
    logger:info('Unloading AugmentedSteam plugin')
end

return plugin
