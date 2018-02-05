-- Pre defined strings
local strings = {
  kicked = "Kicked by %s, Reason: %q",
  banned = "You have been banned from this server.\nReason: %q",
  reason_add = ";%s;%q", -- ;[admin name];[playername]
  connecting_banned = "You are banned from the server."
}

local dir = Config.settings.saves_directory
local banfile = Config.settings.banlist_file

-- KICK PLAYER EVENT
RegisterServerEvent("skadmin:kickPlayer")
AddEventHandler("skadmin:kickPlayer", function(id, reason)
  local adminName = GetPlayerName(source)
  local playerName = GetPlayerName(id)
  --DropPlayer(id, string.format(strings.kicked, playerName, reason))
  if Config.settings.event_messages_console ~= nil then print(adminName .. " kicked " .. playerName .. ". Reason: " .. reason) end
  if Config.settings.event_messages ~= nil then TriggerClientEvent("chatMessage", -1, "Server", Config.color.blue, playerName .. " kicked from server by " .. adminName .. ".") end
end)

-- BAN PLAYER EVENT
RegisterServerEvent("skadmin:banPlayer")
AddEventHandler("skadmin:banPlayer", function(player, reason)
  local playerIdent = GetPlayerIdentifiers(player["serverID"])
  local adminName = string.gsub(GetPlayerName(source), ";", "") -- filter out characters that may break this
  local playerName = string.gsub(player["name"], ";", "")
  reason = string.gsub(reason, ";", "")

  for i, ident in ipairs(playerIdent) do

    if string.find(ident, "license:") then
      local save_reason = reason.. string.format(strings.reason_add, adminName, playerName)
      DATA:appendToFile(dir .. banfile ,ident..";"..save_reason .. "\r\n") -- [license];[reason];[admin name];[playername]
      -- DropPlayer(player["serverID"], string.format(strings.banned, reason))
      if Config.settings.event_messages_console ~= nil then print(adminName .. " banned " .. playerName .. ". Reason: " .. reason) end
      if Config.settings.event_messages ~= nil then TriggerClientEvent("chatMessage", -1, "Server", Config.color.blue, playerName .. " banned from server by " .. adminName .. ".") end
    end
  end
end)

-- PLAYER CONNECTION
AddEventHandler("playerConnecting", function(playerName, setKickReason)
  local bansIterator = DATA:getLineIterator(dir .. banfile)
  local idents = GetPlayerIdentifiers(source)
  for _, ident in ipairs(idents) do
    if string.find(ident, "license:") then
      local id = ident

      for line in bansIterator do
        local index = string.find(line, ";")
        if index then
          local savedId = string.sub(line, 1, index-1) -- minus 1, because it includes
          if id == savedId then
            setKickReason(strings.connecting_banned)
            CancelEvent()
          end
        end
      end
    end
  end
end)

-- Returns a table with all the names of players banned
-- Returns empty table if no players are banned or if file does not exists
RegisterServerEvent("skadmin:getBanList")
AddEventHandler("skadmin:getBanList", function()
  local bansIterator = DATA:getLineIterator(dir .. banfile)
  banlist = {}

  if bansIterator ~= nil then
    for line in bansIterator do
      local index = 0
      index = string.find(line, ";", index+1)

      local license = string.sub(line, 1, index-1)

      for i=1, 2, 1 do
        index = string.find(line, ";", index+1)
      end

      local name = string.sub(line, index+1, #line)

      local ban = {
        license = license,
        name = name
      }

      table.insert(banlist, ban)
    end
  end

  TriggerClientEvent("skadmin:updateGuiBanList", source, banlist)
end)

-- UNBAN PLAYER EVENT
RegisterServerEvent("skadmin:unbanPlayer")
AddEventHandler("skadmin:unbanPlayer", function(license, playerName)
  if license ~= nil then
    local adminName = GetPlayerName(source)

    DATA:removeLine(dir .. banfile, license)
    if Config.settings.event_messages_console ~= nil then print(adminName .. " unbanned " .. playerName) end
  end
end)
