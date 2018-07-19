--
-- Addon       zids.lua
-- Author      marcob@marcob.org
-- StartDate   19/07/2018
--
local addon, zids = ...
--
zids.addon           =  {}
zids.addon.name      =  Inspect.Addon.Detail(Inspect.Addon.Current())["name"]
zids.addon.version   =  Inspect.Addon.Detail(Inspect.Addon.Current())["toc"]["Version"]

zids.db              =  {}
zids.unknown         =  {}
zids.stillunknown    =  {}
zids.player          =  {}


local function zonechangeevent(h, t)

   print(string.format("zonechangeevent: h=%s t=%s", h, t ))

   local unitid   =  nil
   local cnt      =  1

   for unit, zone in pairs(t) do
      print(string.format("zonechangeevent: (%s) unitid=%s zone=%s", cnt, unit, zone ))
      cnt = cnt + 1
      if unitid   == nil   then
         unitid   =  unit
         zoneid   =  zone
      end
   end

   if unitid   == zids.player.unitid   then
      print("zonechangeevent: Zone change event IS for US!")

      local bool, zonedata = pcall(Inspect.Zone.Detail, zoneid)

      if zids.db[zonedata.name] ==  nil or zids.db[zonedata.name] == "" then
         zids.db[zonedata.name] =   { name=zonedata.name, id=zonedata.id, type=zonedata.type }
      end

   else
      print(string.format("zonechangeevent: Zone change event NOT for US.: \n[%s]\n[%s]", unitid, zids.player.unitid))
   end

   return
end

local function savevariables(_, addonname)

   if addon.name == addonname then

      -- Zone IDs, database
      if zids.db   ~= nil         and next(zids.db) ~= nil           then  zoneidsdb   =  zids.db           end
      if zids.stillunknown ~= nil and next(zids.stillunknown) ~= nil then  zidsunknown =  zids.stillunknown end

   end

   return
end

local function loadvariables(_, addonname)

   if addon.name == addonname then

      if zoneidsdb then
         zids.db  =  zoneidsdb
      else
         zids.db  =  {}
      end

      if zidsunknown then
         zids.unknown   =  zidsunknown
      else
         zids.unknown   =  {}
      end

      Command.Event.Detach(Event.Addon.SavedVariables.Load.End,   loadvariables,	"zids: Load Variables")
   end

   return
end

local function startup()

   Command.Event.Detach(Event.Unit.Availability.Full, startup, "zids: startup event")

   zids.player.unitid   =  Inspect.Unit.Lookup("player")

   -- Discover Unknown zoneids from ither sources,
   -- zidsunknown is an array manually pasted in
   -- ~/RIFT/Interface/Saved/SavedVariables/zids.lua
   -- it looks like this:
   --
   --    zidsunknown =  {  "z0000000CB7B53FD7",
   --       "z00000013CAF21BE3",
   --       "z00000016EB9ECBA5",
   --       "z0000001804F56C61",
   --       "z0000001B2BB9E10E",
   --       "z0000012D6EEBB377",
   --       "z0000012E087E78E1",
   --       "z0000012F14279B5A",
   --       "z019595DB11E70F58",
   --       "z1416248E485F6684",
   --       "z585230E5F68EA919",
   --       "z698CB7B72B3D69E9",
   --       "z7B2B0BB6E3EA1BEC",
   --    }
   --
   --
   local zid = nil
--    for _, zid in pairs(zids.unknown) do
   while #zids.unknown > 0 do

      zid = table.remove(zids.unknown, 1)

      local bool, zonedata = pcall(Inspect.Zone.Detail, zid)
      if bool then

         if zids.db[zonedata.name] ==  nil or zids.db[zonedata.name] == "" then
            zids.db[zonedata.name] =   { name=zonedata.name, id=zonedata.id, type=zonedata.type }
         end
      else
         table.insert(zids.stillunknown, zid)
         print(string.format("zids: zone id %s is still unknown.", zid))
      end
   end


   Command.Event.Attach(Event.Unit.Detail.Zone, function(...) zonechangeevent(...) end,   "zids: Zone Change Event")

   return
end

Command.Event.Attach(Event.Unit.Availability.Full,          startup,                   "zids: startup event")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End,   loadvariables,	            "zids: Load Variables")
Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, savevariables,             "zids: Save Variables")
