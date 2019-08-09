# ClientRpc.rb

require 'json'
require 'oj'

module Boot::LoadClientRpc

  def rpc_update(encoding)
    send_client_message(100, {
      'encoding' => encoding,
    })
  end

  def rpc_register(email, pass)
    send_client_message(101, {
      'email' => email,
      'pass' => pass,
    })
  end

  def rpc_login(email, pass, zone)
    send_client_message(102, {
      'email' => email,
      'pass' => pass,
      'zone' => zone,
    })
  end

  def rpc_get_game_data
    send_client_message(151, {
    })
  end

  def rpc_resize_game_data size = 5000
    send_client_message(nil, {
      'size' => size,
    })
  end

  def rpc_chat text
    send_client_message(nil, {
      'message' => text,
      'chid' => ''
    })
  end

  def rpc_combat npcId, enemyId, randomPlayer
    send_client_message(nil, {
      'npcId' => npcId,
      'enemyId' => enemyId,
      'randomPlayer' => randomPlayer,
    })
  end

  def on_message_received(type, msg)
    case type
    when 100
      on_update msg
    when 101
      on_register msg
    when 102
      on_login msg
    when 151
      @test.on_get_game_data msg
    when 57
      @test.on_enter_campaign_combat msg
    when 58
      @test.on_begin_next_combat msg
    when 135
      @test.on_resize_game_data msg
    when 1001
      on_chat_push msg
    else
      puts "invalid message received type=#{type}"
    end
  end

  def on_update msg
    if @test.respond_to?(:on_update)
      @test.on_update msg
    else
      rpc_login @user.email, @user.pass, @user.zone
    end
  end

  def on_login msg
    if @test.respond_to?(:on_login)
      @test.on_login msg
    else
      if msg['success']
        rpc_get_game_data
      else
        rpc_register @user.email, @user.pass
      end
    end
  end

  def on_register msg
    if @test.respond_to?(:on_register)
      @test.on_register msg
    else
      if msg['success']
        rpc_login @user.email, @user.pass, @user.zone
      else
        puts "register failed"
      end
    end
  end

  def on_chat_push msg
    # received chat push
    if @test.respond_to? 'on_chat_push'
      @test.send 'on_chat_push', msg
    end
  end

end