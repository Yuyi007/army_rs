# model.rb

require 'forwardable'

class ModelDelegate
  include Loggable

  attr_reader :model

  def initialize(model)
    @model = model
  end

  def refresh
    model.chief ||= Chief.new
    model.instances ||= {}
    # model.send_mail_infos = []
    # model.send_mail_infos ||= []
  end

  def cur_instance_exist?
    (model.chief && model.chief.cur_inst_id)
  end

  def to_using_hash
    cur_inst_id = model.chief.cur_inst_id
    hash = model.to_hash
    hash.instances = {}
    if model.instances[cur_inst_id]
      model.instances.each do |id, instance|
        if id == cur_inst_id
          hash.instances[id] = instance.to_hash
        else
          hash.instances[id] = instance.to_simple
        end
      end
    else
      hash.instances = {}
    end
    hash
  end


  def ng(reason, *ng_args)
    res = {}
    res.success = false
    res.reason = reason
    res.ng_args = ng_args
    res
  end

  def g(res = {})
    res.success = true
    res
  end

  def valid_chongzhi?(pid, goods_id, opts = {})
    zone, cid, iid = Helper.decode_player_id(pid)
    return ng('str_pay_invalid_zone') if zone != model.chief.zone
    return ng('str_pay_invalid_cid') if cid != model.chief.id
    return ng('str_pay_invalid_pid') if model.instances[iid].nil?
    inst = model.instances[iid]

    inst.valid_chongzhi?(goods_id)
  end

  def chongzhi(pid, goods_id, opts = {})
    zone, cid, iid = Helper.decode_player_id(pid)

    bonuses = []

    if cid.to_i == model.chief.id && zone.to_i == model.chief.zone && model.instances[iid] then
      bonuses = model.instances[iid].chongzhi(goods_id, opts)
      model.instances[iid].global_effects.refresh()
    end


    [bonuses, model.instances[iid]]
  end

  def instance
    cur_instance
  end

  def add_instance
    id = Helper.gen_instance_id(model.instances)
    inst = Instance.spawn(id)
    inst.set_owner(model)
    model.instances[id] = inst
    model.chief.cur_inst_id = id
    inst
  end

  def set_cur_instance(id)
    model.chief.cur_inst_id = id if model.instances[id]
  end

  def cur_instance
    model.instances[model.chief.cur_inst_id] if model.chief
  end
  

  # @param [String] inst_id
  def get_instance_by_id(inst_id)
    if inst_id && inst_id.length > 0
      model.instances[inst_id]
    else
      cur_instance
    end
  end

  # def model
  #   @model
  # end

end

class Model
  attr_accessor :chief # ,  :record
  attr_accessor :instances
  # attr_accessor :send_mail_infos

  include Jsonable
  include Loggable

  json_object :chief, :Chief
  json_hash :instances, :Instance

  # json_array :send_mail_infos, :SendMailInfo

  gen_from_hash
  gen_to_hash

  # 为了避免model的成员变量被直接访问，使用delegate的方法
  # 由于引入HashStorable，要求model的成员变量不可直接访问，必须使用accessors

  extend Forwardable
  attr_reader :delegate

  ModelDelegate.instance_methods(false).each do |sym|
    def_delegator :@delegate, sym
  end

  def initialize
    @delegate = ModelDelegate.new self
  end

  def init_new_created(session)
    self
  end

  def marshal_dump
    dump
  end

  def marshal_load(raw)
    load! raw
    @delegate = ModelDelegate.new self
  end
end
