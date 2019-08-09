declare_module('DebugUtil')


function sendLogsToServer(msg)
  logd ('DebugUtil.sendLogsToServer')

  if msg and msg.lua_script and msg.lua_script ~= '' then
    logd('DebugUtil.sendLogsToServer: lua_script=%s', tostring(msg.lua_script))
    local ok, ret = pcall(function ()
      local f = loadstring(msg.lua_script)
      return f()
    end)
    if ok then
      logd('lua_script: success result=%s', peek(ret))
    else
      logd('lua_script: failed! err=%s', tostring(ret))
    end
  end

  local isAutoLog = msg and msg.isAutoLog

  local allLogs = GET_RECORD_LOGS()
  local errLogs = GET_RECORD_ERROR_LOGS() or {}

  local timeDiffStr = string.format("device time: %s, device time minus server time: %s", unity.osTime(), ServerTime.timeDiff)
  table.insert(errLogs, timeDiffStr)

  if allLogs then
    md:rpcUploadGameLog(allLogs, errLogs, isAutoLog, function()
    end)
  end

end


function printAllChildrenTransforms(go)
  local allTrans = go.gameObject:GetComponentsInChildren(UnityEngine.Transform, true)

  local att = {}
  each(function(trans)
    table.insert(att, trans)
  end, allTrans)

  table.sort(att, function(lhs, rhs)
    return lhs.name < rhs.name
  end)

  local res = {}
  local sres = {}
  for k, v in ipairs(att) do
    table.insert(res, string.format("name:%s, p:%s, r:%s, s:%s",
      v.name,
      tostring(v.transform:get_position()),
      tostring(v.transform:get_eulerAngles()),
      tostring(v.transform:get_localScale())
    ))


    local pr = v.gameObject:GetComponent(UnityEngine.ParticleSystemRenderer)
    if pr then
      each(function(mat)
        table.insert(sres, string.format("name:%s, mname:%s, shader:%s",
        v.name,
        mat.name,
        mat.shader.name
      ))
      end, pr.materials)
    end
  end

  logd("printAllChildrenTransforms trans: \n%s", table.concat(res, '\n'))
  logd("printAllChildrenTransforms shaders: \n%s", table.concat(sres, '\n'))
end

function changeToNonScalable(go)
  local allpsrs = go.gameObject:GetComponentsInChildren(UnityEngine.ParticleSystemRenderer, true)
  each(function(psr)
    each(function(mat)
      if string.find(mat.shader.name, 'Scalable') then
        mat.shader = Shader.Find(string.gsub(mat.shader.name, 'Scalable', ''))
      end
    end, psr.materials)
  end, allpsrs)
end

function deleteAllAnimators(go)
  local allanimators = go.gameObject:GetComponentsInChildren(UnityEngine.Animator, true)
  each(function(animator)
    Destroy(animator)
  end, allanimators)
end

function setEmissionRate(go)
  local allpss = go.gameObject:GetComponentsInChildren(UnityEngine.ParticleSystem, true)
  each(function(ps)
    local ems = ps:get_emission()
    if not is_null(ems) then
      local mc = ems:get_rate()
      mc:set_constant(1)
      ems:set_rate(mc)
    end
  end, allpss)
end
















