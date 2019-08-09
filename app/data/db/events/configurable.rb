# Configurable.rb

module Configurable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Used in GameEventsDb
    # Generate event related methods
    def gen_config(name, clazz)
      fail "invalide class #{clazz}" unless clazz < GameEvent::ConfigBase

      m = %{

        # cache the method thats called the most
        gen_static_cached 600, :get_#{name}_configs
        gen_static_invalidate_cache :get_#{name}_configs

        def self.create_#{name}_config(data)
          create_config(data, #{clazz})
        end

        def self.update_#{name}_config(data)
          update_config(data, #{clazz})
        end

        def self.delete_#{name}_config(id)
          delete_config(id, #{clazz})
        end

        def self.get_#{name}_configs
          get_configs(#{clazz})
        end

        def self.get_#{name}_config(id)
          get_config(id, #{clazz})
        end

        def self.delete_all_#{name}_config
          delete_all_config(#{clazz})
        end

        def self.get_#{name}_config_by_tid(tid)
          get_config_by_tid(tid, #{clazz})
        end

        def self.delete_#{name}_config_by_tid(tid)
          delete_config_by_tid(tid, #{clazz})
        end

      }

      class_eval m
    end

    # Used in CosProxy
    # Generate config related methods
    def gen_proxy_config(name)
      m = %{
      def get_#{name}_config(id)
        GameEventsDb.get_#{name}_config(id)
      end

      def publish_#{name}_config_invalidate_cache
        Channel.publish_system_invalidate_cache(:GameEventsDb, 'get_#{name}_configs')
      end

      def get_#{name}_config_by_tid(tid)
        GameEventsDb.get_#{name}_config_by_tid(tid)
      end

      def get_#{name}_configs
        GameEventsDb.get_#{name}_configs
      end

      def save_#{name}_config(data)
        res = GameEventsDb.update_#{name}_config(data)
        if res['success']
          publish_#{name}_config_invalidate_cache
        end
        res
      end

      def delete_#{name}_config_by_tid(tid)
        res = GameEventsDb.delete_#{name}_config_by_tid(tid)
        if res['success']
          publish_#{name}_config_invalidate_cache
        end
        res
      end

      def delete_#{name}_config(id)
        res = GameEventsDb.delete_#{name}_config(id)
        if res['success']
          publish_#{name}_config_invalidate_cache
        end
        res
      end

      def create_#{name}_config(data)
        res, data = GameEventsDb.create_#{name}_config(data)
        if res['success']
          publish_#{name}_config_invalidate_cache
        end
        res
      end

      }

      class_eval m
    end
  end
end
