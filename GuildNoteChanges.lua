-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2011.09.20					---
--- Version: 0.6 [2012.03.20]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/guildnotechanges
--- WoWInterface	http://www.wowinterface.com/downloads/info20322-GuildNoteChanges.html

local NAME = ...
local VERSION = 0.6

local db, rank
local viewOfficer, officerColor

local format = format
local GetGuildRosterInfo = GetGuildRosterInfo

	---------------
	--- Caching ---
	---------------

local cache = setmetatable({}, {__index = function(t, k)
	local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[k] or RAID_CLASS_COLORS[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

local function RefreshColor()
	wipe(cache)
end

	-------------
	--- Frame ---
	-------------

local delay, cd = 0, {}

local f = CreateFrame("Frame")

-- delay initialization, because some guild API does not yet
-- return the correct information (even after ADDON_LOADED)
function f:OnUpdate(elapsed)
	delay = delay + elapsed
	if delay > 5 then
		if IsInGuild() then
			local realm = GetRealmName()
			local guild = GetGuildInfo("player")
			GuildNoteChangesDB[realm] = GuildNoteChangesDB[realm] or {}
			GuildNoteChangesDB[realm][guild] = GuildNoteChangesDB[realm][guild] or {}
			db = GuildNoteChangesDB[realm][guild]
			db.rank = db.rank or {}
			rank = db.rank
			
			viewOfficer = CanViewOfficerNote()
			local officer = ChatTypeInfo.OFFICER
			officerColor = format("%02X%02X%02X", officer.r*255, officer.g*255, officer.b*255)
			
			if CUSTOM_CLASS_COLORS then
				CUSTOM_CLASS_COLORS:RegisterCallback(RefreshColor)
			end
			
			self:RegisterEvent("GUILD_ROSTER_UPDATE")
			self:RegisterEvent("GUILD_RANKS_UPDATE")
		end
		self:SetScript("OnUpdate", nil)
	end
end

function f:ADDON_LOADED(name)
	if name == NAME then
		GuildNoteChangesDB = GuildNoteChangesDB or {}
		GuildNoteChangesDB.version = VERSION
		self:UnregisterEvent("ADDON_LOADED")
		self:SetScript("OnUpdate", f.OnUpdate)
	end
end

function f:GUILD_ROSTER_UPDATE()
	if time() > (cd[1] or 0) then -- throttle
		cd[1] = time() + 5
		for i = 1, GetNumGuildMembers() do
			local name, _, _, _, _, _, publicNote, officerNote, _, _, class = GetGuildRosterInfo(i)
			if not name then return end -- sanity check
			db[name] = db[name] or {}
			local classColor = cache[class]
			local publicdb, officerdb = db[name][1], db[name][2]
			if publicdb and publicdb ~= publicNote then
				local text = (publicdb == "") and publicNote or format("%s |cff%s->|r %s", publicdb, classColor, (publicNote == "") and "|cffFF0000"..NONE.."|r" or publicNote)
				print(format("|cff%s|Hplayer:%s|h[%s]|h|r %s", classColor, name, name, text))
			end
			if viewOfficer then
				if officerdb and officerdb ~= officerNote then
					local text = (officerdb == "") and officerNote or format("%s |cff%s->|r %s", officerdb, classColor,  (officerNote == "") and "|cffFF0000"..NONE.."|r" or officerNote)
					print(format("|cff"..officerColor.."[%s]|r |cff%s|Hplayer:%s|h[%s]|h|r %s", OFFICER_NOTE_COLON, classColor, name, name, text))
				end
				db[name][2] = officerNote
			end
			db[name][1] = publicNote
		end
	end
end

function f:GUILD_RANKS_UPDATE()
	if time() > (cd[2] or 0) then
		cd[2] = time() + 60
		for i = 1, GuildControlGetNumRanks() do
			local rankdb = rank[i]
			local rankName = GuildControlGetRankName(i)
			if rankdb and rankdb ~= rankName and rankName ~= "" then
				print(format("|cff%s[%s]|r |cff71D5FF#%s|r %s |cff%s->|r %s", officerColor, GUILDCONTROL_GUILDRANKS, i, rankdb, officerColor, rankName))
			end
			rank[i] = rankName
		end
	end
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
	f[event](self, ...)
end)
