-- This caches the sprites for the spritesheets for faster lookup
class('SpriteSheetCache', function(self)
  self:init()
end)

local m = SpriteSheetCache
local Sprite = UnityEngine.Sprite
local unity = unity
local is_null, not_null = is_null, not_null

function m:init()
  self.sheets = {}
  self.asyncs = {}
end

function m:clear()
  unity.beginSample('SpriteSheetCache.clear')

  each(function(_, v) v:clear() end, self.asyncs)

  self:purgeSheets()
  table.clear(self.asyncs)

  unity.endSample()
end


local UNLOADSHEETS = {
  ['images/icons/doober']            = true,
  ['images/icons/campaigns']         = true,
  ['images/icons/combatskill']       = true,
  ['images/icons/npcrelation']       = true,
  ['images/icons/work']              = true,
  ['images/icons/activity']          = true,
  ['images/icons/npc']               = true,
  ['images/icons/technology']        = true,
  ['images/icons/creation_portrait'] = true,
  ['images/ui/creation']             = true,
  ['images/ui/ad']                   = true,
}

local UNLOADPATTERN = {
  'images/map/',
  'images/news/',
  'images/uianim/vr',
  'images/icons/leader_counterpart/',
  'images/icons/practic_counterpart/',
  'images/icons/food/',
  'images/icons/sns/',
  'images/icons/guild/',
  'images/icons/coach/',
  'images/icons/wushuhall/',
}

function m:shouldUnload(sheetPath)
  if UNLOADSHEETS[sheetPath] then return true end
  for i, v in ipairs(UNLOADPATTERN) do
    if sheetPath:match(v) then
      return true
    end
  end
  return false
end

function m:purgeSheets(destroy)
  logd('SpriteSheetCache: purgeSheets destroy=%s', tostring(destroy))
  local sheets = self.sheets
  for path, sheet in pairs(sheets) do
    if self:shouldUnload(path) then
      logd('[SpriteSheetCache] unload sheet %s', path)

      sheet:Unload()
      unity.Resources.UnloadAsset(sheet)
    else
      -- loge('[SpriteSheetCache] not unloading sheet %s', path)
    end

    sheets[path] = nil
  end
end

function m:unloadSheet(sheetPath)
  local sheet = self.sheets[sheetPath]
  if sheet then
    logd('[SpriteSheetCache] unload sheet %s', sheetPath)
    sheet:Unload()
    unity.Resources.UnloadAsset(sheet)
  end

  self.sheets[sheetPath] = nil
end

function m:getSheetLoader(uri)
  local loader = self.asyncs[uri]
  if not loader then
    loader = CachedAssetLoader.new(uri, self.sheets, unity.loadSpriteAsset, unity.loadSpriteAssetAsync)
    self.asyncs[uri] = loader
  end
  return loader
end

function m:getSheetAsync(path, onComplete)
  local loader = self:getSheetLoader(path)
  loader:loadAsync(onComplete)
end

function m:getSheet(path)
  local loader = self:getSheetLoader(path)
  return loader:load()
end

function m:getSprite(path, spriteName)
  local sheet = self:getSheet(path)
  if not_null(sheet) then
    local sprite = sheet:GetSprite(spriteName)
    local mat = nil
    if not sprite then
      loge('sprite %s not found in %s', spriteName, path)
    else
      mat = sheet:get_material()
      if is_null(mat) then
        mat = unity.loadSpriteMat(path)
        sheet:set_material(mat)
      else
        -- loge('mat = %s', tostring(mat))
      end
    end

    return sprite, mat
  end

  return nil, nil
end

function m:getSpriteTexture(spriteName)
  local path = cfg.sprites[spriteName]
  if not path then return nil end

  local sheet = self:getSheet(path)

  if not_null(sheet) then
    local sprite = sheet:GetSprite(spriteName)
    if not sprite then
      return nil, nil
    else
      return sprite:get_texture(), sprite
    end
  end

  return nil
end

function m:getSpriteAsync(path, spriteName, onComplete)
  self:getSheetAsync(path, function(sheet)
    if not_null(sheet) then
      -- loge('path=%s spriteName=%s', path, spriteName)
      local sprite = sheet:GetSprite(spriteName)

      if sprite then
        local mat = sheet:get_material()
        if is_null(mat) then
          -- loge('path = %s', path)
          mat = unity.loadSpriteMat(path)
          sheet:set_material(mat)
        end
        onComplete(sprite, mat)
      else
        -- loge('sprite %s not found in %s', spriteName, path)
      end
    end
  end)
end
