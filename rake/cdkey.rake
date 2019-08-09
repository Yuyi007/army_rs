
namespace :cdkey do

  desc 'Generate normal cdkey'
  task :gen_normal, :sdk, :tid, :num, :end_time, :bonus_id do |t, args|
    puts "check args: #{args}"
    tid = args[:tid]
    num = args[:num]
    end_time = args[:end_time]
    bonus_id = args[:bonus_id]
    sdk = args[:sdk]
    if tid and num and end_time and bonus_id
      Dir.chdir('cdkeys/') do
        ruby "cdkey_gen.rb 1 #{sdk} #{tid} #{num} #{end_time} #{bonus_id}"
      end
    else
      puts "example usage: rake cdkey[qh360,this_is_a_special_id,100,2017/09/25,ite1000001]"
    end
  end

  desc "Generate repeatable redeemed cdkeys"
  task :gen_repeatable_normal, :sdk, :tid, :num, :end_time, :bonus_id do |t, args|
    tid = args[:tid]
    num = args[:num]
    end_time = args[:end_time]
    bonus_id = args[:bonus_id]
    sdk = args[:sdk]
    if tid and num and end_time and bonus_id
      Dir.chdir('cdkeys/') do
        ruby "cdkey_gen.rb 2 #{sdk} #{tid} #{num} #{end_time} #{bonus_id}"
      end
    else
      puts "example usage: rake unlimit_cdkey[qh360,this_is_a_special_id,100,2017/09/25,ite1000001]"
    end
  end


  desc "Generate speical cdkeys"
  task :gen_special, :sdk, :tid, :num, :end_time, :bonus_id do |t, args|
    tid = args[:tid]
    num = args[:num]
    sdk = args[:sdk]
    end_time = args[:end_time]
    bonus_id = args[:bonus_id]

    if tid and num and end_time and bonus_id
      Dir.chdir('cdkeys/') do
        ruby "cdkey_gen.rb 3 #{sdk} #{tid} #{num} #{end_time} #{bonus_id}"
      end
    else
      puts "example usage: rake special_cdkey[qh360,this_is_a_special_id,100,2017/09/25,ite1000001]"
    end
  end



end