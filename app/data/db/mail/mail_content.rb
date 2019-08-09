class MailMessage
  MAX_ATTACHMENT = 5 unless const_defined? :MAX_ATTACHMENT

  attr_accessor :id
  attr_accessor :toId
  attr_accessor :type, :sub_type, :send_type
  attr_accessor :content, :time
  attr_accessor :from_name
  attr_accessor :zone
  attr_accessor :reason

  include Loggable
  include Jsonable

  #json_array :attachments, :MailAttachment

  gen_from_hash
  gen_to_hash

  def initialize(hash = nil)
    @sub_type = 'normal'
    if hash
      @id = hash.id
      @toId = hash.toId
      @type = hash.type
      @sub_type = hash.sub_type
      @send_type = hash.send_type
      @content = hash.content
      @time = hash.time
      @from_name = hash.from_name
      @zone = hash.zone
      @reason = hash.reason
    else
      @content = { 'text' => 'TestDeliverMail', 'things' => [], 'title_one' => 'test_test' }
      @sub_type = 'normal'
    end
  end

  def redeem_attachments(model)
    res = []
    if @effect and @need_process
      if self.respond_to?("process_#{@effect}")
        res = self.send("process_#{@effect}", model)
      else
        d{"a effect unrecognizable:#{a.effect}"}
      end
      @need_process = false
    end
    res
  end

  def can_redeem_attachments?(model)
    if @effect and @effect == 'bonus' and @need_process
      @attachments.each do|a|
        tid = a.params1
        num = a.params2.to_i or 1
        if num != 0
          res = BonusHelper.could_give_item?(model, tid, num)
          if not res.success
            return false
          end
        end
      end
    end
    return true
  end

  def add_attachment(params1, params2)
    if @content.things.length >= MAX_ATTACHMENT then
      return false
    else
      @content.things << {'type' => 'give_item', 'params1' => params1, 'params2' => params2}
      return true
    end
  end

  def process_bonus(model)
    res = []
    @attachments.each do|a|
      r = {}
      tid = a.params1
      num = a.params2.to_i or 1
      next if tid.nil?
      next if num <= 0
      r = BonusHelper.give_bonus_with_reason(model, tid, num, "mail_bonus_#{@sub_type}")
      res << r
    end
    return res
  end

end

class SendMailInfo
  attr_accessor :mail
  attr_accessor :to_id, :to_zone
  # attr_accessor :notify
  # attr_accessor :deliver_self

  include Loggable
  include Jsonable

  json_object :mail, :MailMessage

  gen_from_hash
  gen_to_hash

  def initialize(hash = nil)
    if hash
      @mail = hash.mail
      @to_id = hash.to_id
      @to_zone = hash.to_zone
      # @notify = hash.notify
      # @deliver_self = hash.deliver_self
    end
  end
end

#为model中的mail设置
class MailArray
  attr_accessor :mails

  include Loggable
  include Jsonable

  json_array :mails, :MailMessage

  gen_from_hash
  gen_to_hash

  def initialize()
    @mails ||= []
  end

  def add_mail(mail, model)
    MailBox.init_read(model.chief.id, model.chief.zone, mail.id, mail.type, mail.send_type)
    MailBox.init_redeem(model.chief.id, model.chief.zone, mail.id, mail.type, mail.send_type)
    @mails << mail
    if @mails.length > MailBox::LIMIT
      m = @mails[0]
      @mails.shift
      MailBox.remove_read(model.chief.id, model.chief.zone, m.id, m.type, m.send_type)
      MailBox.remove_redeem(model.chief.id, model.chief.zone, m.id, m.type, m.send_type)
    end
  end

  def get_mails()
    ms = []
    @mails.each do|mail|
      ms << mail.to_hash
    end
    ms
  end

  def remove(id)
    @mails.delete_if{|x| x.id == id}
    return 1
  end
end