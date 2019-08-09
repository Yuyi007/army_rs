class('LoadingHelper', function(self) end)

local m = LoadingHelper

local isEditor = game.editor()
local isIos = game.ios()
local match = string.match

function m.default_ttl(uri)
  if uri and
    (match(uri, 'scenes/game/') ) then
    --  Do not unload scene bundles, to force unload later
    return -1
  elseif isIos then
    return 20
  else
    return 20
  end
end

function m.isForceUnloadBundle(uri, keepBundlesList)
  local unload, unloadAsset, unloadKeep = m._isForceUnloadBundle(uri)
  -- 2
  -- some bundle assets should be unloaded, regardless of whether in keep list
  -- otherwise they will leak. e.g. particles, particle textures
  if unload and not unloadKeep then
    if keepBundlesList and keepBundlesList[uri] then
      -- logd('keep bundle %s', uri)
      unload, unloadAsset = false, false
    end
  end
  return unload, unloadAsset
end

function m._isForceUnloadBundle(uri)
  if match(uri, 'scenes/game/') and not match(uri, 'scenes/game/empty') then
    return true, true
  elseif match(uri, 'particles/effects') then
    if m.shouldOptimizeSceneLoading() then
      --  this was unloaded before preloading levels
      return false, false
    else
      return true, true, true
    end
  elseif match(uri, 'prefab/misc') then
    -- 2 have to unload particles because it leaks a lot
    return true, true, true
  elseif match(uri, 'prefab/model') then
    -- 2 this relies on textures in particles/effects too
    return true, true, true
  elseif match(uri, 'prefab/ui') then
    -- evepoe: unload prefab bundles (but not the asset), so they will be forcebly reloaded if the next time it's required
    return true, false
  elseif match(uri, 'prefab/') then
    return true, true
  end

  return false, false
end


function m.expandAssetBundles(assets)
  local all = {}
  local list = {}
  local bundles = {}

  for i, a in ipairs(assets) do
    local bundlePath = nil
    if a.bundle then
      bundlePath = a.bundle
    else
      local prefabPath = a.go or a.ui or a.prefab or a.character or a.cutscene or a.prefabDry

      if prefabPath then
        bundlePath = cfg:prefabBundlePath(prefabPath)
      end

      if a.sound then
        bundlePath = cfg:soundBundlePath(a.sound)
      end

      if a.sheet then
        bundlePath = cfg:spriteAssetBundlePath(a.sheet)
      end

      if a.scene then
        if game.editor() then
          bundlePath = nil
        else
          bundlePath = cfg:sceneBundlePath(a.scene)
        end
      end
    end

    local asset = a.go or a.ui or a.view or a.prefab or a.sound or a.character or a.sheet or a.cutscene or a.scene or a.setTTL or a.setPatternTTL
    asset = asset or a.efx or a.copyBundle or a.func or a.enterRoom or a.setPoolMax

    local bundleExist = false 
    if bundlePath then
      bundleExist = unity.bundleExists(bundlePath)
    end
    logd("bundle bundlePath:%s bundleExist:%s", tostring(bundlePath), tostring(bundleExist))
    if not game.shouldLoadAssetInEditor() and bundlePath and bundleExist then

      if not bundlePath:match('%.ab') then
        bundlePath = bundlePath .. '.ab'
      end


      if not all[bundlePath] then
        all[bundlePath] = true
        local o = {bundle = bundlePath, ttl = a.ttl}
        table.insert(list, o)
        bundles[bundlePath] = true
      end

      local depends = unity.getAllDependencies(bundlePath)
      logd("get all depends for %s", peek(bundlePath))
      for _, path in ipairs(depends) do
        if not all[path] then
          all[path] = true
          local o = {bundle = path, ttl = a.ttl}
          logd('depends %s', peek(path))
          table.insert(list, o)
          bundles[path] = true
        end
      end
    end

    if asset and not all[asset] then
      all[asset] = true
      a.yield = true
      table.insert(list, a)
    end
  end

  logd('list = %s', peek(list))
  logd('bundles = %s', peek(bundles))
  return list, bundles
end

function m.getPreloadAssets()
  local assets = {
    -- { scene = 'scenes/game/hero_scene'},
    { setTTL = 'fonts/artfont', ttl = -1},
    { setTTL = 'fonts/cn', ttl = -1},
    { setTTL = 'images/ui/9symbols', ttl = -1},
    { setTTL = 'images/ui/bgs01', ttl = -1},
    { setTTL = 'images/ui/bgs02', ttl = -1},
    { setTTL = 'images/ui/bgs04', ttl = -1},
    { setTTL = 'images/ui/pic01', ttl = -1},
    { setTTL = 'images/ui/pic02', ttl = -1},
    { setTTL = 'scenes/game/empty', ttl = -1},
    { setTTL = 'animator/ui_animator/loading', ttl = -1},
    { setTTL = 'shaders', ttl = -1},
    { ui = 'prefab/ui/common/combat_loading', global = true},
    -- { ui = 'prefab/ui/room/vs_loading_ui', global = true},
    -- { ui = 'prefab/ui/efx/rl_vs_efx_ui', global = true},
    -- { ui = 'prefab/ui/efx/rl_ready_efx_ui', global = true},

    { func = function () ObjectFactory.preloadAll(true) end, name = 'ObjectFactory' },
  }
  -- for group, opts in pairs(ViewFactory.groupOptions) do
  --   if opts.global then
  --     assets[#assets + 1] = { name = group, func = function ()
  --       ViewFactory.preload(group, opts)
  --     end }
  --   end
  -- end

  return m.expandAssetBundles(assets)
end


function m.makeMainSceneTree(view)
  local assets = {
    -- { scene = 'scenes/game/hero_scene'},
    -- { ui = 'prefab/ui/room/main_room_ui'},
    -- { ui = 'prefab/ui/room/add_room_ui'},
    -- { ui = 'prefab/ui/room/list_con_slot'},
    -- { ui = 'prefab/ui/room/match_team_ui'},
    -- { ui = 'prefab/ui/room/matching_ui'}
    -- { ui = 'prefab/ui/efx/matching_efx_ui'}

  }
  m.addMainTextAssets(assets)
  -- m.addAvatarData(assets)

  local allAssets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(allAssets, bundles)
end

function m.addAvatarData(assets)
  local inst = md:curInstance()
  local equipeds = inst.avatar_data.equipped_data
  local hid = inst.avatar_data.selected_car
  -- logd("[equipped_data] :%s",inspect(equipeds))
  -- logd("")
  local avatar = equipeds[hid]

  -- for hid, avatar in pairs(equipeds) do 
    local s_scheme = avatar.selected_scheme
    s_scheme = s_scheme + 1
    local aid = avatar.schemes[s_scheme]["body"]
    if aid and aid ~= "" then
      local cfgAvatar = cfg.avatar[aid]
      if not cfgAvatar then
        loge("[LoadingHelper] could not add part body:%s",tostring(aid))
        return
      end
      local res = BundleUtil.getEntityAvatarFileH(hid, cfgAvatar["pos"], cfgAvatar["model_res"])
      table.insert(assets, { prefab = res })

      local frameworkRes = "Prefab/entity/"..hid.."_body/"..hid.."_h_framework"
      table.insert(assets, { prefab = frameworkRes})
    end

    aid = avatar.schemes[s_scheme]["wheel"]
    if aid and aid ~= "" then
      local cfgAvatar = cfg.avatar[aid]
      if not cfgAvatar then
        loge("[LoadingHelper] could not add part wheel:%s",tostring(aid))
        return
      end
      local res = BundleUtil.getEntityAvatarFileH(hid, cfgAvatar["pos"], cfgAvatar["model_res"])
      table.insert(assets, { prefab = res })  
    end

    aid = avatar.schemes[s_scheme]["decoration_f"]
    if aid and aid ~= "" then
      local cfgAvatar = cfg.decoration[aid] 
      if not cfgAvatar then
        loge("[LoadingHelper] could not add part decoration_f:%s",tostring(aid))
        return
      end
      local pos = "decoration_"..cfgAvatar["pos"]
      local res = BundleUtil.getEntityDecorateFileH(pos, cfgAvatar["model_res"])
      table.insert(assets, { prefab = res })
    end

    aid = avatar.schemes[s_scheme]["decoration_b"]
    if aid and aid ~= "" then
      local cfgAvatar = cfg.decoration[aid] 
      if not cfgAvatar then
        loge("[LoadingHelper] could not add part decoration_b:%s",tostring(aid))
        return
      end
      local pos = "decoration_"..cfgAvatar["pos"]
      local res = BundleUtil.getEntityDecorateFileH(pos, cfgAvatar["model_res"])
      table.insert(assets, { prefab = res })
    end

  -- end
end

function m.addMainTextAssets(assets)
  assets[#assets + 1] = { name = 'mainTexts', func = function ()
    ViewFactory.preload('text_normal')
    ViewFactory.preload('text_framed')
    ViewFactory.preload('text_icon')
  end }

  return assets
end

function m.makeSelectHeroSceneTree(view)
  local assets = {
    { scene = 'scenes/game/xuanche'},
    { sheet = 'images/ui/icon031'},
    { ui = 'prefab/ui/room/room_hero_ui'}
  }

  m.addAvatarData(assets)

  local allAssets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(allAssets, bundles)
end

function m.makeCombatSceneTree(view)
  local assets = {
    { scene = 'scenes/game/combat_scene_pbr01'},
    { prefab = "prefab/entity/ball/ball"},
    { ui = "prefab/ui/combat/combat_ui"},  -- { ui = "prefab/ui/room/combateverui" },
    { prefab = "prefab/misc/football/shadow" },
    { prefab="prefab/misc/competitive/effect_goal1"},
    { prefab="prefab/misc/competitive/effect_goal2"},
    { ui = "prefab/ui/room/game_set" }
  }
  --Add low car model
  for k,v in pairs(cfg.heroes) do 
    local prefab = "prefab/entity/"..v["model_res"]
    table.insert(assets, { prefab = prefab })
  end

  local allAssets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(allAssets, bundles)
end

function m.makeCompetitiveSceneTree(view, scene_name, efxTids)
  local assets = {
    { scene = 'scenes/game/' .. scene_name},
    { prefab = "prefab/entity/ball/ball"},
    { sheet = 'images/ui/icon031'},
    { ui = "prefab/ui/combat/competitive_ui"},
    { ui = "prefab/ui/others/settlement-ui" },
    { ui = "prefab/ui/combat/dmg_text" },
    { ui = "prefab/ui/room/game_set" },
    { prefab="prefab/misc/competitive/effect_goal1"},
    { prefab="prefab/misc/competitive/effect_goal2"},

    { prefab = "prefab/misc/competitive/car_dead"},
    { prefab = "prefab/misc/competitive/ball_dribbled"},
    { prefab = "prefab/misc/competitive/ball_born"},
    { prefab = "prefab/misc/competitive/ball_shoot_tail"},
    { prefab = "prefab/misc/competitive/ball_shoot_surround"},
    { prefab = "prefab/misc/competitive/chain"},
    { prefab = "prefab/misc/competitive/chain_car"},
    { prefab = "prefab/misc/competitive/ball_surround"},
    { prefab = "prefab/misc/competitive/ball_dribble_range"}

  }
  --Add low car model
  -- for k,v in pairs(cfg.heroes) do
  --   local prefab = "prefab/entity/"..v["model_res"]
  --   table.insert(assets, { prefab = prefab })
  -- end

  m.addCombatTextAssets(assets)
  m.addSkillEfxAssets(assets, efxTids)

  local allAssets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(allAssets, bundles)
end

function m.addSkillEfxAssets(assets, efxTids)
  if not cc then return end
  local members = cc:getMembers()
  for _, side in pairs(members) do
    for _, seat in pairs(side) do
      if seat ~= -1 then
        local hid = seat["tid"]
        if hid then
          local cfgHero = cfg.heroes[hid]
          local sid = cfgHero["skilla"]
          m.addOneSkillEfxAssets( hid, sid, assets, efxTids)
          sid       = cfgHero["skillb"]
          m.addOneSkillEfxAssets( hid, sid, assets, efxTids )
          sid       = cfgHero["skillu"]
          m.addOneSkillEfxAssets( hid, sid, assets, efxTids )
          sid       = cfgHero["skillr"]
          m.addOneSkillEfxAssets( hid, sid, assets, efxTids )
        end
      end
    end
  end
end

function m.addOneSkillEfxAssets(hid, sid, assets, efxTids)
  local cfgSkill  = cfg.skills[sid]
  --技能预警特效
  local tid = cfgSkill["effect"]
  if tid then
    local comDir = cfgSkill["alerm_effect_com"] or hid
    local name = comDir.."/"..tid
    local prefab = BundleUtil.getEffectBundleFile(name)
    table.insert(assets,  { prefab = prefab})
    table.insert(efxTids, {tid = tid, comDir = comDir})
  end

  --技能自身特效
  tid = cfgSkill["effect"]
  if tid then
    local comDir = cfgSkill["effect_com"] or hid
    local name = comDir.."/"..tid
    local prefab = BundleUtil.getEffectBundleFile(name)
    table.insert(assets,  { prefab = prefab})
    table.insert(efxTids, {tid = tid, comDir = comDir})
  end

  local function addBuffEfxAssets(bid)
    local cfgBuff = cfg.buffs[bid]
    local efxes = cfgBuff["effects"]
    for k, efx in pairs(efxes) do 
      local tid = efx["res"]
      if tid then
        local comDir = efx["com"] or hid
        local name = comDir.."/"..tid
        local prefab = BundleUtil.getEffectBundleFile(name)
        table.insert(assets,  { prefab = prefab})
        table.insert(efxTids, {tid = tid, comDir = comDir})
      end
    end

    --buff 触发buff
    local buffs = cfgBuff["tri_add_buffs"]
    if buffs then
      for i,bid in pairs(buffs) do 
        addBuffEfxAssets(bid)
      end
    end
  end

  --技能命中buff特效
  local buffs = cfgSkill["add_buffs"]
  if buffs then
    for i,bid in pairs(buffs) do 
      addBuffEfxAssets(bid)
    end
  end

  local projectiles = cfgSkill["bullets"]
  if projectiles then
    for i,proj in pairs(projectiles) do 
      local pid = proj["tid"]
      local cfgProj = cfg.projectiles[pid]

      --弹道自身特效
      local tid = cfgProj["effect"]
      if tid then
        local comDir = cfgProj["effect_com"] or hid
        local name = comDir.."/"..tid
        local prefab = BundleUtil.getEffectBundleFile(name)
        table.insert(assets,  { prefab = prefab})
        table.insert(efxTids, {tid = tid, comDir = comDir})
      end

      --弹道命中buff特效  
      local buffs = cfgProj["hit_buffs"]
      if buffs then
        for i,bid in pairs(buffs) do 
          addBuffEfxAssets(bid)
        end
      end

      --弹道触发buff特效
      buffs = cfgProj["tri_add_buffs"]
      if buffs then
        for i,bid in pairs(buffs) do 
          addBuffEfxAssets(bid)
        end
      end
    end
  end
end


function m.shouldOptimizeSceneLoading()
  -- 
  -- today's testing did not finds memory leaks, enable this opt for all devices for the moment
  return game.platform == 'android' or game.platform == 'editor'
end

function m.makeSubTreeByAssets(assets, bundles)
  -- func nodes should start after all asset nodes loaded
  -- since asset nodes are loaded async, but the views created by func nodes are loaded sync
  -- there would be load bundle errors if they are running in parallel
  local root          = LoadBranchNode.new {name = "load_asset_root", parallel_count = 5}
  local p0            = LoadBranchNode.new {name = 'load_asset_p0', parallel_count = 1}
  local loadAssetNode = LoadBranchNode.new {name = 'load_asset_node', parallel_count = 1}
  local loadFuncNode  = LoadBranchNode.new {name = 'load_func_node', parallel_count = 5}

  for i, v in ipairs(assets) do
    if v.scene then
      if m.shouldOptimizeSceneLoading() then
        -- preload scene and bundles to be parrallel with gc and bundles unloading
        -- this can save 2~3 seconds for loading
        root.optimizeSceneLoading = function ()
          local startTime = engine.realtime()
          -- unload these bundle first because next levels needs them, e.g. fx_screen and car lights
          unity.unloadBundle('particles/effects', true)
          logd('preloading scene %s...', v.scene)
          unity.loadLevelAsync(v.scene, function ()
            logd('preloading scene %s done', v.scene)
          end, function(t, p)
            logd("preloading scnee percent:%s", tostring(p))
          end)
        end
        local taskNode = LoadIntervalUpdateNode.new({
          name = string.format('wait preload of %s', v.scene),
          func = function (taskNode)
            if not unity.isLoadingLevel then taskNode:finish() end
          end,
          interval = 0.1,
          yield = v.yield,
        })
        root:addChildNode(taskNode)
      else

        -- Date:   Tue Dec 5 18:26:20 2017 +0800
        -- load scene should not start in the getLoadTree, keep it a task node for safety issue.
        -- also there could be memory leak when not loading an empty scene in between.
        -- e.g. https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&ved=0ahUKEwigjcKO0_LXAhVB_oMKHYdkBmAQFgg2MAE&url=http%3A%2F%2Fhutonggames.com%2Fplaymakerforum%2Findex.php%3Ftopic%3D12400.0&usg=AOvVaw075KKZH_tYvGf3E04U387U
        -- it can be proven if you use memory profiler, see some ui textures not properly unloaded

        local taskNode = LoadAssetNode.new({asset = v, name = v.name, yield = v.yield})
        root:addChildNode(taskNode)
      end
    elseif v.func or v.setPoolMax then
      local taskNode = LoadAssetNode.new({asset = v, name = v.name, yield = v.yield})
      loadFuncNode:addChildNode(taskNode)
    else
      --: do not load these assets to speed up 1~2 secs
      local taskNode = LoadAssetNode.new({asset = v, name = v.name, yield = v.yield})
      loadAssetNode:addChildNode(taskNode)
    end
  end

  if loadAssetNode:childCount() > 0 then
    p0:addChildNode(loadAssetNode)
  end

  if loadFuncNode:childCount() > 0 then
    p0:addChildNode(loadFuncNode)
  end

  if p0:childCount() > 0 then
    root:addChildNode(p0)
  end

  root.bundles = bundles
  return root
end

function m.makePreloadTree()
  local assets, bundles = m.getPreloadAssets()
  return m.makeSubTreeByAssets(assets, bundles)
end

function m.makeTreeWithAssets(assets)
  local assets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(assets, bundles)
end

function m.addCombatTextAssets(assets)
  assets[#assets + 1] = { name = 'combatTexts', func = function ()
    ViewFactory.preload('text_dmg')
  end }

  return assets
end

function m.makeTestEnterSceneTree(view)
  local assets = {
    { scene = 'scenes/test/TestEnter'},
    { ui = 'prefab/ui/server/Test1'},
    { scene = 'scenes/test/testscene1'}
  }
  local allAssets, bundles = m.expandAssetBundles(assets)
  return m.makeSubTreeByAssets(allAssets, bundles)
end

