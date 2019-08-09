# Instead of monkey patching Kernel or trying to be clever, it's
# best to confine all the helper methods in a Utils module.
module Ohm
  module Utils
    # Used by: `attribute`, `counter`, `set`, `reference`,
    # `collection`.
    #
    # Employed as a solution to avoid `NameError` problems when trying
    # to load models referring to other models not yet loaded.
    #
    # Example:
    #
    #   class Comment < Ohm::Model
    #     reference :user, User # NameError undefined constant User.
    #   end
    #
    #   # Instead of relying on some clever `const_missing` hack, we can
    #   # simply use a symbol or a string.
    #
    #   class Comment < Ohm::Model
    #     reference :user, :User
    #     reference :post, "Post"
    #   end
    #
    def self.const(context, name)
      case name
      when Symbol, String
        context.const_get(name)
      else name
      end
    end

    def self.dict(arr)
      if arr.is_a?(::Array)
        ::Hash[*arr]
      elsif arr.is_a?(::Hash)
        arr
      end
    end

    def self.sort(redis, key, options)
      redis.sort(key, options)
    end
  end
end
