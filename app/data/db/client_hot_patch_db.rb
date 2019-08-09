class ClientHotPatchDb
  include RedisHelper
  include Loggable
  include Cacheable

  gen_static_cached 3600, :get_patch_code
  gen_static_invalidate_cache :get_patch_code

  def self.patch_code_key
    'clientpatch:luacode:key'
  end

  def self.set_patch_code(client_lua_code)
    redis.set(patch_code_key, client_lua_code)
    ClientHotPatchDb.get_patch_code_invalidate_cache()
  end

  def self.clear_patch_code()
    redis.del(patch_code_key)
    ClientHotPatchDb.get_patch_code_invalidate_cache()
  end

  def self.get_patch_code()
    redis.get(patch_code_key)
  end

  private

  def self.redis
    get_redis(:action)
  end

end