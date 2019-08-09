# Cacheable.rb

module Boot
  module Cacheable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Use with care, may bloat memory usage on method with very volatile params
      # Best use with methods that doesn't have arguments or with a few fixed arguments

      # params: timeout - timeout in seconds
      def gen_static_cached(timeout, *syms)
        syms.each do |sym|
          name = sym.to_s
          name_cached = "#{name}_cached"
          m = %[
            def self.#{name_cached}(*args, &blk)
              now = Time.now.to_i
              if args
                cache_sig = '#{name_cached}$' << args.join('$')
              else
                cache_sig = '#{name_cached}$'
              end
              #puts cache_sig
              @@_cacheable_cache ||= {}
              cache = (@@_cacheable_cache[cache_sig] ||= {})
              if cache['time'].nil? || now - cache['time'] > #{timeout} || cache['value'].nil?
                # puts "invalidate cache \#\{cache_sig\}"
                value = #{name} *args
                if value != nil
                  cache['time'] = now
                  cache['value'] = value
                  yield(false, value) if block_given?
                end
                value
              else
                # puts "use cache \#\{cache_sig\}"
                v = cache['value']
                yield(true, v) if block_given?
                v
              end
            end
          ]
          class_eval m
        end
      end

      # params: timeout - timeout in seconds
      def gen_static_invalidate_cache(*syms)
        syms.each do |sym|
          name = sym.to_s
          name_invalidate_cache = "#{name}_invalidate_cache"
          m = %(
            def self.#{name_invalidate_cache} *args
              now = Time.now.to_i
              @@_cacheable_cache ||= {}
              name_cached = '#{name}_cached$' << args.join('$')
              @@_cacheable_cache.each do |cache_sig, cache|
                if cache_sig.start_with? name_cached
                  # puts "#{name_invalidate_cache} with sig \#\{cache_sig\}"
                  cache.delete('value')
                  cache.delete('time')
                end
              end
            end
          )
          class_eval m
        end
      end
    end
  end
end
