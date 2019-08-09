# Eventable.rb

module Eventable
  def self.included(base)
    base.extend ClassMethods
  end

  def parse_time_simple(time)
    if time.to_s =~ /^[0-9]+$/
      TimeHelper.gen_date_time(Time.at(time.to_i))
    else
      TimeHelper.parse_date_time(time).to_i
    end
  end

  def parse_time(data, source)
    if source.start_time.to_s =~ /^[0-9]+$/
      data.start_time = TimeHelper.gen_date_time(Time.at(source.start_time.to_i))
      data.end_time = TimeHelper.gen_date_time(Time.at(source.end_time.to_i))
      if source.close_time
        data.close_time = TimeHelper.gen_date_time(Time.at(source.close_time.to_i))
      end
    else
      data.start_time = TimeHelper.parse_date_time(source.start_time).to_i
      data.end_time = TimeHelper.parse_date_time(source.end_time).to_i
      if source.close_time
        data.close_time = TimeHelper.parse_date_time(source.close_time).to_i
      end
    end
  end

  def parse_basic_time(time)
    if time.to_s =~ /^[0-9]+$/
      time = TimeHelper.gen_date_time(Time.at(time.to_i))
    else
      time = TimeHelper.parse_date_time(time).to_i
    end
    time
  end

  module ClassMethods
    # Used in GameEventsDb
    # Generate event related methods
    def gen_event(name, clazz)
      fail "invalide class #{clazz}" unless clazz < GameEvent::EventBase

      m = %{

        # cache the method thats called the most
        gen_static_cached 60, :get_open_#{name}_event
        gen_static_cached 60, :get_open_#{name}_event_native
        gen_static_invalidate_cache :get_open_#{name}_event
        gen_static_invalidate_cache :get_open_#{name}_event_native

        def self.create_#{name}_event zone, data, user
          create_event(zone, data, user, #{clazz})
        end

        def self.update_#{name}_event(zone, data, user)
          update_event(zone, data, user, #{clazz})
        end

        def self.force_copy_#{name}_events(from_zone, to_zone, user)
          force_copy_events(from_zone, to_zone, user, #{clazz})
        end

        def self.copy_#{name}_events(from_zone, to_zone, user)
          copy_valid_events(from_zone, to_zone, user, #{clazz})
        end

        def self.copy_#{name}_event(from_zone, to_zone, id, user)
          copy_event(from_zone, to_zone, id, user, #{clazz})
        end

        def self.delete_#{name}_event(id, user)
          delete_event(id, user, #{clazz})
        end

        def self.get_open_#{name}_event(zone)
          get_open_event(zone, #{clazz})
        end

        def self.get_open_#{name}_event_native(zone)
          get_open_event_native(zone, #{clazz})
        end

        def self.get_#{name}_events(zone)
          get_events(zone, #{clazz})
        end

        def self.get_#{name}_event_by_id(id)
          get_event(id, #{clazz})
        end

        def self.delete_all_#{name}_events(zone, user)
          delete_all_events(zone, user, #{clazz})
        end

        def self.get_all_open_#{name}_events(zone)
          get_all_open_events(zone, #{clazz})
        end
      }

      class_eval m
    end

    # Used in CosProxy
    # Generate event related methods
    def gen_proxy_event(name)
      m = %{
      def get_#{name}_event(id)
        GameEventsDb.get_#{name}_event_by_id(id)
      end

      def get_#{name}_events(zone)
        GameEventsDb.get_#{name}_events(zone)
      end

      def publish_#{name}_event_invalidate_cache
        Channel.publish_system_invalidate_cache(:GameEventsDb, 'get_open_#{name}_event')
        Channel.publish_system_invalidate_cache(:GameEventsDb, 'get_open_#{name}_event_native')
      end

      def save_#{name}_event(zone, data, user)
        res = GameEventsDb.update_#{name}_event(zone, data, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        res
      end

      def copy_#{name}_event(from_zone, to_zone, id, user)
        res = GameEventsDb.copy_#{name}_event(from_zone, to_zone, id, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        res
      end

      def copy_#{name}_events(from_zone, to_zone, user)
        return {'success' => true} if from_zone.to_i == to_zone.to_i
        res = GameEventsDb.copy_#{name}_events(from_zone, to_zone, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        res
      end

      def delete_#{name}_event(id, user)
        res = GameEventsDb.delete_#{name}_event(id, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        res
      end

      def force_copy_#{name}_events(from_zone, to_zone, user)
        if from_zone.to_i == to_zone.to_i
          return {'success' => true}
        end

        res = GameEventsDb.force_copy_#{name}_events(from_zone, to_zone, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        res
      end

      def create_#{name}_event(zone, data, user)
        res, data = GameEventsDb.create_#{name}_event(zone, data, user)
        if res['success']
          publish_#{name}_event_invalidate_cache
        end
        return res, data
      end

      }

      class_eval m
    end

    def gen_controller_event(name)
      proxy = %(
        def proxy
          self
        end
      )

      get_list = %{
        def get_list
          zone = params[:zone].to_i
          events = {}
          events.events = []
          list = proxy.get_#{name}_events(zone)

          list.each do |data|
            if data
              data.start_time = TimeHelper.gen_date_time(Time.at(data.start_time))
              data.end_time = TimeHelper.gen_date_time(Time.at(data.end_time))
              events.events << data
            end
          end
          render :json => events
        end
      }

      _get = %{
        def _get(id)
          data = proxy.get_#{name}_event(id)
          parse_time(data, data) if data
          data || {}
        end
      }

      get = %{
        def get
          id = params[:id].to_i
          render :json => _get(id)
        end
      }

      delete = %{
        def delete
          user = cur_user
          zone = params[:zone].to_i
          id = params[:id].to_i
          res = proxy.delete_#{name}_event(id, user)
          if res['success']
            current_user.site_user_records.create(
              :action => 'delete_event',
              :success => true,
              :zone => zone,
              :param1 => '#{name}',
              :param2 => id,
            )
          end
          render :json => res
        end

      }

      copy = %{
        def copy
          user = cur_user
          from_zone = params[:zone]
          id = params[:id]
          zones = params[:tozones].split(' ').reject do |z|
            z.nil? or z.blank? or z == from_zone
          end

          res = {}

          zones.each do |zone|
            res = proxy.copy_#{name}_event(from_zone, zone, id, user)
            if res['success']
              current_user.site_user_records.create(
                :action => 'copy_event',
                :success => true,
                :zone => from_zone,
                :param1 => '#{name}',
                :param2 => zone,
              )
            else
             render :json => res
             return
            end
          end
          render :json => { 'success' => true }
        end
      }

      copy_list = %{
        def copy_list
          user = cur_user
          force_copy = params[:force_copy]
          from_zone = params[:zone]
          zones = params[:tozones].split(' ').reject do |z|
            z.nil? or z.blank? or z == from_zone
          end
          res = {}

          if(force_copy == "false" or force_copy == false or force_copy.nil?)
            zones.each do |zone|
              # copy config here
              res = proxy.copy_#{name}_events(from_zone, zone, user)
              if res['success']
                current_user.site_user_records.create(
                  :action => 'copy_events',
                  :success => true,
                  :zone => from_zone,
                  :param1 => '#{name}',
                  :param2 => zone,
                )
              else
                render :json => res
                return
              end
            end
          else
            zones.each do |zone|
              res = proxy.force_copy_#{name}_events(from_zone, zone, user)
              if res['success']
                current_user.site_user_records.create(
                  :action => 'copy_events',
                  :success => true,
                  :zone => from_zone,
                  :param1 => '#{name}',
                  :param2 => zone,
                )
              else
                render :json => res
                return
              end
            end
          end

          render :json => { 'success' => true }
        end
      }

      save = %{
        def save
          user = cur_user
          zone = params[:zone].to_i

          data = {}
          json = JSON.parse(JSON(params))
          data.merge!(json)
          parse_time(data, json)

          res = proxy.save_#{name}_event(zone, data, user)
          render :json => res
        end
      }

      create = %{
        def create
          user = cur_user
          zone = params[:zone].to_i

          data = {}
          json = JSON.parse(JSON(params))
          data.merge!(json)
          parse_time(data, json)
          res, data = proxy.create_#{name}_event(zone, data, user)
          render :json => res
        end
      }

      class_eval [proxy, _get, get, get_list, delete, copy, copy_list, save, create].join("\r\n\t")
    end
  end
end
