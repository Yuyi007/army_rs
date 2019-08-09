class('BundleUtil')

local m = BundleUtil

function m.getEntityBundleFile(uri)
  return string.format('prefab/entity/%s', uri)
end

function m.getEntityBundleFileHigh(uri)
  return string.format('prefab/entity/%s_h', uri)
end

function m.getEffectBundleFile(efx)
  return string.format('prefab/misc/%s', efx)
end

function m.getShadowBundleFile(uri)
  return string.format('prefab/entity/shadow/%s', uri)
end

function m.getEntityAvatarFile(hid, part, name)
	return string.format("prefab/entity/%s_%s/%s", tostring(hid), tostring(part), tostring(name))
end

function m.getEntityDecorateFile(part, name)
	return string.format("prefab/entity/%s/%s", tostring(part), tostring(name))
end

function m.getEntityAvatarFileH(hid, part, name)
	return string.format("prefab/entity/%s_%s/%s_h", tostring(hid), tostring(part), tostring(name))
end

function m.getEntityDecorateFileH(part, name)
	return string.format("prefab/entity/%s/%s_h", tostring(part), tostring(name))
end

function m.getPaintFileH(cid,name)
	return string.format("paint/%s/%s_h",tostring(cid),tostring(name))
end

function m.getPaintFile(cid,name)
	return string.format("paint/%s/%s",tostring(cid),tostring(name))
end