
local bor = bit.bor

function bit.fv_bor(a1, a2, a3, a4, a5)
  if a5 then error('fv_bor: only support 4 args!') end

  if a4 then
    return bor(a4, bor(a3, bor(a2, a1)))
  elseif a3 then
    return bor(a3, bor(a2, a1))
  elseif a2 then
    return bor(a2, a1)
  else
    error('fv_bor: invalid args!')
  end

  -- local arg = {...}
  -- local res = 0
  -- for i = 1, #arg do local v = arg[i]
  --   res = bit.bor(res, v)
  -- end
  -- return res
end