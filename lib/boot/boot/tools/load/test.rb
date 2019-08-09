# Test.rb

module Boot

  module LoadTest

    def initialize client
      @client = client
    end

  end

  class LoadTestFactory

    def initialize type
      @type = type
    end

    def make_test client
      test_num = 5

      if (1..test_num).include?(@type) then
        t = @type
      else
        t = rand(test_num) + 1
      end

      if t == 1 then
        TestUpdate.new client
      elsif t == 2 then
        TestLogin.new client
      elsif t == 3 then
        TestGetGameData.new client
      elsif t == 4 then
        TestGetGameData.new client
      elsif t == 5 then
        TestResizeGameData.new client
      end
    end

  end

  class TestUpdate

    include LoadTest

    def on_update msg
      @client.on_finished
    end

  end

  class TestLogin

    include LoadTest

    def on_login msg
      @client.on_finished
    end

  end

  class TestGetGameData

    include LoadTest

    def on_get_game_data msg
      @client.on_finished
    end

  end

  class TestResizeGameData

    include LoadTest

    def on_login msg
      @client.rpc_resize_game_data @client.options[:param].to_i
    end

    def on_resize_game_data msg
      @client.on_finished
    end

  end

  class TestChat

    include LoadTest

    def initialize client
      @client = client
      @i = 0
    end

    def on_login msg
      @client.rpc_chat (0..100).map{ ('A'..'Z').to_a[rand(26)] }.join
    end

    def on_free_chat msg
      @i += 1
      if @i == 2 then
        @client.on_finished
      end
    end

    def on_chat_push msg
      @i += 1
      if @i == 2 then
        @client.on_finished
      end
    end

  end

end
