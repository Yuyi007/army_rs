
require 'json'
require 'digest'
require 'time'

module Boot

  class User

    attr_accessor :id, :pass, :email, :phone,:type,:reg_time,:last_login_time

    include Loggable
    include Jsonable
    include RedisHelper


    # type 1  self  24 qq  22 wechat  
    # userid is thirdparty user id
    def initialize(id = nil, pass = nil, email = nil, phone = nil,type = nil, userid = nil,reg_time=nil,last_login_time=nil)
      @id = id
      @pass = pass
      @email = email
      @phone = phone
      @type = type
      @reg_time = reg_time
      @last_login_time = last_login_time
    end

    def self.create(id, pass, email)
      if UserValidator.validate(id, pass, email)
        # check account has the same email
        if email and email.length > 0 then
          exist = read_by_email(email)
        end
        if not exist then
          created = redis.setnx(user_key(id), User.new(id, pass, email,nil,1,nil,Time.now.to_i,Time.now.to_i).to_json)
          if created and email then
            redis.set(email_key(email), id)
          end
          created or false
        else
          false
        end
      else
        d{ sprintf("validating of %s %s %s failed!", id, pass, email) }
        false
      end
    end

    def self.create_by_phone(id, pass, email, phone)
      if UserValidator.validate(id, pass, email) and UserValidator.validate_phone(phone)
        # check account has the same email
        if phone and phone.length > 0 then
          exist = read_by_mobile(phone)
        else
          exist = false  
        end
        if not exist then
          created = redis.setnx(user_key(id), User.new(id, pass, email,phone,1,nil,Time.now.to_i,Time.now.to_i).to_json)
          if created and email then
            redis.set(mobile_key(phone), id)
          end
          created or false
        else
          false
        end
      else
        d{ sprintf("validating of %s %s %s  %s failed!", id, pass, email ,phone) }
        false
      end
    end


     def self.create_by_thirdparty(id, pass, email, userid, platform)
      if UserValidator.validate(id, pass, email) and UserValidator.validate_phone(phone)
        # check account has the same email
        if email and email.length > 0 then
          exist = read_by_email(email)
        else
          exist = false  
        end
        if userid and userid.length>0 then
          exist = read_by_thirdparty_id(userid)
        else
          exist = false  
        end

        if not exist then
          created = redis.setnx(user_key(id), User.new(id, pass, email,nil,platform,userid,Time.now.to_i,Time.now.to_i).to_json)
          if created and email then
            redis.set(email_key(email), id)
            redis.set(thirdparyt_id_key(userid), id)
          end
          created or false
        else
          false
        end
      else
        d{ sprintf("validating of %s %s %s  %s %s failed!", id, pass, email ,userid,platform) }
        false
      end
    end

    def self.update(user)
      if UserValidator.validate(user.id, user.pass, user.email)
        if user.id then
          exist = read(user.id)
        end
        if exist and (exist.email == nil or exist.email == user.email) then
          if user.email and user.email.length > 0 then
            # update email and pass
            id = redis.get(email_key(user.email)).to_i
            if not id or id == user.id then
              redis.set(user_key(user.id), user.to_json)
              redis.set(email_key(user.email), user.id)
            else
              # the email has been used for another account
              false
            end
          else
            # update pass
            redis.set(user_key(user.id), user.to_json)
          end
        else
          # cannot change user email
          false
        end
      else
        d{ sprintf("validating of %s %s %s failed!", user.id, user.pass, user.email) }
        false
      end
    end



    def self.read(id)
      raw = redis.get(user_key(id))
      if raw != nil
        User.new.from_json!(raw)
      else
        nil
      end
    end

    def self.read_by_email(email)
      id = redis.get(email_key(email)).to_i
      if id
        self.read(id)
      else
        nil
      end
    end

    def self.read_by_mobile(mobile)
      id = redis.get(mobile_key(mobile)).to_i
      if id
        self.read(id)
      else
        nil
      end
    end

    def self.read_by_thirdparty_id(userid)
      id = redis.get(thirdparty_id_key(userid)).to_i
      if id
        self.read(id)
      else
        nil
      end
    end

    def self.login(id)
      if read(id) != nil
        token = gen_token(id)
        redis.set(user_token_key(id), token)
        redis.pexpire(user_token_key(id), 8 * 60 * 60 * 1000)
        token
      else
        nil
      end
    end

    def self.logout(id)
      redis.del(user_token_key(id))
    end

    def self.auth(id, token)
      redis.get(user_token_key(id)) == token
    end

    def self.delete(id)
      user = self.read(id)
      if user
        redis.del(user_key(id))
        redis.del(email_key(user.email)) if user.email
        user
      end
      nil
    end

  private

    def self.redis
      get_redis :user
    end

    def self.gen_token(id)
      Digest::MD5.hexdigest(id + 'fv13' + Time.now.to_s)
    end

    def self.user_key(id)
      "u:#{id}"
    end

    def self.email_key(email)
      "e:#{email}"
    end

    def self.thirdparty_id_key(userid)
      "t:#{userid}"
    end


    def self.user_token_key(id)
      "u:#{id}:token"
    end

    def self.mobile_key(mobile)
       "m:#{mobile}"
    end


  end

  class UserHelper

    include RedisHelper

    RESERVED_ID_RANGE = 10_000_000 unless defined? RESERVED_ID_RANGE

    def self.generate_id
      (redis.incr guest_id_key) + RESERVED_ID_RANGE
    end

    def self.random_pass
      source = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9 ! @ # $ % ^ & * [ ] )
      (0..8).map{ source[rand(72)] }.join
    end

    def self.hash_pass(pass)
      Digest::SHA256.hexdigest("f1#{pass}3v" + Time.now.to_s)[0, 32]
    end

  private

    def self.redis
      get_redis :user
    end

    def self.guest_id_key
      "user:id"
    end

  end

  module UserValidator

    def self.validate(id, pass, email)
      validate_id(id) and validate_pass(pass) and validate_email(email)
    end

    def self.validate_id(id)
      id.is_a?(Integer) and id > UserHelper::RESERVED_ID_RANGE
    end

    def self.validate_pass(pass)
      pass != nil and /[\w\.!#$\%&'*+-\/=\?^_`{|}~@\[\]\(\);,]+/ =~ pass
    end

    def self.validate_email(email)
      email == nil or /[\w\.!#$\%&'*+-\/=\?^_`{|}~@]+/ =~ email
      # or, you can use this:
      # http://www.ex-parrot.com/~pdw/Mail-RFC822-Address.html
    end

    def self.validate_phone(phone)
      phone == nil or /\d{11}/ =~ phone
    end

  end

end