class('FVParticleRootDecorator')

local m = FVParticleRootDecorator
local FVParticleScaling      = LBoot.FVParticleScaling
local ParticleSystem         = UnityEngine.ParticleSystem
local uoc = rawget(_G, 'uoc')

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs(mt)
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.setGlobals()
  uoc = rawget(_G, 'uoc')
end

---------------------------------------------------------
-- 主场景内的特效不能使用禁用FVParticleRoot的方法解决
-- 美术shader选错选成scalable的问题
-- 暂时在这里先启用FVParticleRoot，以后还要让美术把特效改对！！！
---------------------------------------------------------
local hackFixEfxsInMainScene = {
}

local doNotUseFVParticleScales = {}

function m.funcs(oldMt)
  local mt = {}

  function mt.setFVScale(self, vec3Scale)
    local go = self:get_gameObject()
    local refBundle = uoc:getAttr(go, 'bundleFile')

    -- logd('setFVScale 0 %s, %s', peek(refBundle), tostring(vec3Scale))

    if not refBundle or not doNotUseFVParticleScales[refBundle] then
      -- logd('setFVScale 1')
      self:set_Scale(vec3Scale)
    else
      -- logd('setFVScale 2')
      local trans = self:get_transform()
      trans:set_localScale(vec3Scale)
    end
  end

  function mt.changeToNonScalableShaders(self, shaderChanged)
    if shaderChanged then
      return
    end

    local psrs = self:get_gameObject():GetComponentsInChildren(UnityEngine.ParticleSystemRenderer, true)
    each(function(psr)
      local mats = psr:get_sharedMaterials()
      for i = 1, #mats do local mat = mats[i]
        local shader = mat:get_shader()
        if string.find(shader:get_name(), 'AlphaScalable') then
          mat:set_shader(Shader.Find("Custom/Mobile/Particles/Alpha"))
        elseif string.find(shader:get_name(), 'AdditiveScalable') then
          mat:set_shader(Shader.Find("Custom/Mobile/Particles/Additive"))
        end
      end
    end, psrs)
  end

  function mt.setEnable(self, val, shaderChanged)
    local go = self:get_gameObject()
    local refBundle = uoc:getAttr(go, 'bundleFile')

    if not refBundle or not hackFixEfxsInMainScene[refBundle] then
      self:set_enabled(val)
    else
      logd('FVParticleRootDecorator setEnable 2')
      self:changeToNonScalableShaders(shaderChanged)
      self:set_enabled(false)
      ---------------------------------------------------------
      -- 主场景内的特效不能使用禁用FVParticleRoot的方法解决
      -- 美术shader选错选成scalable的问题
      -- 暂时在这里先启用FVParticleRoot，以后还要让美术把特效改对！！！
      ---------------------------------------------------------
    end
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })