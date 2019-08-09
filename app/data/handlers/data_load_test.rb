
# for load test purpose, not used in game

class DataLoadTest < Handler

  def self.process(session, msg, model)
    return ng('no_game_data') unless model.cur_instance_exist?

    if msg['throw_ruby_error']
      raise "throw_ruby_error: #{msg['throw_ruby_error']}"
    end

    if msg['sleep_time']
      Boot::Helper.sleep(msg['sleep_time'])
    end

    random_text = msg['random_text']

    instance = model.cur_instance

    instance.hero.level = instance.hero.level + (Random.rand * 3).to_i - 2
    instance.hero.level = (Random.rand * 15).to_i if instance.hero.level <= 0

    instance.update_player

    person = instance.person
    min = instance.hero.level - 1
    max = instance.hero.level + 1
    pids = SearchPlayer.search_by_level_range(min, max, instance, session, [])
    pids.each do |pid|
      option = {
        'recent' => true,
        'time' => Time.now.to_i,
        'content' => {
          'ignore_check' => true,
        }
      }
      person.send_message(pid, random_text, option)
      break
    end

    {
      'success' => true,
      'random_text' => SecureRandom.hex(32768),
    }
  end

end
