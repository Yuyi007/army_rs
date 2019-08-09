require 'helper'
require 'json'
require 'db/events/event_common'
require 'db/events/config_base'
require 'db/events/event_base'
require 'db/events/events'
require 'db/events/configs'

# GameEvent revamp
#
# event model using ohm
#
# To create a xuezhan related event, start by
# defining a GameEvent::Xuezhan class in db/events/GameEvent.rb
#
# module GameEvent
#   class Xuezhan < EventBase
#     attribute :numSlots, Type::Integer
#     attribute :rewardTid
#   end
# end
#
# in GameEventsDb.rb
# add:
#   include Eventable
#   gen_event :xuezhan, 'GameEvent::Xuezhan'
#
# The following methods are auto-generted for GameEventsDb
#
# def self.create_xuezhan_event(zone, data, user)
# def self.update_xuezhan_event(zone, data, user)
# def self.force_copy_xuezhan_events(from_zone, to_zone, user)
# def self.copy_xuezhan_events(from_zone, to_zone, user)
# def self.copy_xuezhan_event(from_zone, to_zone, id, user)
# def self.delete_xuezhan_event(id, user)
# def self.get_open_xuezhan_event(zone)
# def self.get_xuezhan_events(zone)
# def self.get_xuezhan_event_by_id(id)
# def self.delete_all_xuezhan_events(zone, user)
# def self.get_all_open_xuezhan_events(zone)
#
# in cocs_proxy.rb
# add:
#   include Eventable
#   gen_proxy_event :xuezhan
#
# The following methods are auto-generated for CocsProxy
#
# def get_xuezhan_event(id)
# def get_xuezhan_events(zone)
# def save_xuezhan_event(zone, data, user)
# def copy_xuezhan_event(from_zone, to_zone, id, user)
# def copy_xuezhan_events(from_zone, to_zone, user)
# def delete_xuezhan_event(id, user)
# def force_copy_xuezhan_events(from_zone, to_zone, user)
# def create_xuezhan_event(zone, data, user)
#
#
# After that, write your usual controllers and views etc



