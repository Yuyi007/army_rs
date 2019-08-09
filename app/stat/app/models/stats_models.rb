require 'active_record'

module ActiveRecord
  class Base
    def save_sql
      marshaled_data = self.class.marshal(data)
      connect        = connection

      if @new_record
        %Q{
          INSERT INTO #{table_name} (
            #{connect.quote_column_name(session_id_column)},
            #{connect.quote_column_name(data_column)} )
          VALUES (
            #{connect.quote(session_id)},
            #{connect.quote(marshaled_data)} )
          }
      else
        return %Q{
          UPDATE #{table_name}
          SET #{connect.quote_column_name(data_column)}=#{connect.quote(marshaled_data)}
          WHERE #{connect.quote_column_name(session_id_column)}=#{connect.quote(session_id)}
        }
      end
    end
  end
end

module StatsModels
  def self.create_class(class_name, superclass, &block)
    if not self.const_defined? class_name
      klass = Class.new superclass, &block
      self.const_set class_name, klass
    end
  end

  class PlayerBaseInfo < ActiveRecord::Base
    self.table_name = :player_base_info
  end

  class GameDevice < ActiveRecord::Base
  end

  class GameUser < ActiveRecord::Base
  end

  class GameAccount < ActiveRecord::Base
  end

  class MarketReport < ActiveRecord::Base
    self.table_name = :market_reports
  end

  class OnlineUserNumber < ActiveRecord::Base
  end

  class PackageMarketReport < ActiveRecord::Base
    self.table_name = :package_market_reports
  end

  class ConfigName < ActiveRecord::Base
  end

  class Bill < ActiveRecord::Base
  end

  class UserLevelReport < ActiveRecord::Base
  end

  class NewUserLevelReport < ActiveRecord::Base
  end

  class Sdk < ActiveRecord::Base
  end

  class Platform < ActiveRecord::Base
  end

  class Market < ActiveRecord::Base
  end

  class Zone < ActiveRecord::Base
  end

  class ZoneUser < ActiveRecord::Base
  end

  class ZoneAccount < ActiveRecord::Base
  end

  class ZoneDevice < ActiveRecord::Base
  end

  class ChiefLevelReport < ActiveRecord::Base
    self.table_name = :chief_level_report
  end

  [:user, :account, :device].each do |type|
    [:zone_id, :sdk, :market, :platform].each do |key|
      table_name = "#{type}_#{key}_retention_reports"
      class_name = "#{type}".split('_').map{|x| x.capitalize}.join('') <<  "#{key}".split('_').map{|x| x.capitalize}.join('') <<  "RetentionReport"

      create_class(class_name, ActiveRecord::Base) do
        self.table_name = table_name
      end
    end
  end

  [:user, :account, :device].each do |type|
    table_name = "#{type}_retention_reports"
    class_name = "#{type}".split('_').map{|x| x.capitalize}.join('') <<  "RetentionReport"

    create_class(class_name, ActiveRecord::Base) do
      self.table_name = table_name
    end
  end

  [:user, :account, :device, :new_user, :new_account, :new_device, :paid_user].each do |type|
    [:zone_id, :sdk, :market, :platform].each do |key|
      table_name = "#{type}_#{key}_activity_reports"
      class_name = "#{type}".split('_').map{|x| x.capitalize}.join('') <<  "#{key}".split('_').map{|x| x.capitalize}.join('') << "ActivityReport"

      create_class(class_name, ActiveRecord::Base) do
        self.table_name = table_name
      end
    end
  end

  [:user, :account, :device, :new_user, :new_account, :new_device].each do |type|
    table_name = "#{type}_activity_reports"
    class_name = "#{type}".split('_').map{|x| x.capitalize}.join('') << "ActivityReport"

    create_class(class_name, ActiveRecord::Base) do
      self.table_name = table_name
    end
  end

  class SysFlags < ActiveRecord::Base
    attr_accessible  :flag
    attr_accessible  :value
    self.table_name = :sys_flags
  end

  class UserConsume < ActiveRecord::Base
    self.table_name = :user_consume
  end

  class StatsServer < ActiveRecord::Base
    self.table_name = :stats_server
  end

  kinds = [{:table => 'user_consume', :clz => 'UserConsume'},
           {:table => 'alter_credits', :clz => 'AlterCredits'},
           {:table => 'alter_credits_total', :clz => 'AlterCreditsTotalReport'},
           {:table => 'alter_credits_sum', :clz => 'AlterCreditsSum'},
           {:table => 'alter_credits_sys', :clz => 'AlterCreditsSys'},
           {:table => 'gain_credits_sys', :clz => 'GainCreditsSys'},
           {:table => 'alter_coins', :clz => 'AlterCoins'},
           {:table => 'alter_coins_sys', :clz => 'AlterCoinsSys'},
           {:table => 'gain_coins_sys', :clz => 'GainCoinsSys'},
           {:table => 'alter_money', :clz => 'AlterMoney'},
           {:table => 'alter_money_sys', :clz => 'AlterMoneySys'},
           {:table => 'gain_money_sys', :clz => 'GainMoneySys'},
           {:table => 'remove_item', :clz => 'RemoveItem'},
           {:table => 'add_item', :clz => 'AddItem'},
           {:table => 'alter_voucher_sys', :clz => 'AlterVoucherSys'},
           {:table => 'gain_voucher_sys', :clz => 'GainVoucherSys'},
           {:table => 'shop_consume', :clz => 'ShopConsume'},
           {:table => 'shop_consume_sum', :clz => 'ShopConsumeSum'},
           {:table => 'start_campaign', :clz => 'StartCampaign'},
           {:table => 'start_campaign_sum', :clz => 'StartCampaignSumReport'},
           {:table => 'city_event_level_report', :clz => 'CityEventLevelReport'},
           {:table => 'active_factions', :clz => 'ActiveFactionReport'},
           {:table => 'all_factions', :clz => 'AllFaction'},
           {:table => 'all_factions_report', :clz => 'AllFactionReport'},
           {:table => 'finish_campaign', :clz => 'FinishCampaign'},
           {:table => 'finish_campaign_sum', :clz => 'FinishCampaignSum'},
           {:table => 'consume_levels', :clz => 'ConsumeLevels'},
           {:table => 'booth_trade', :clz => 'BoothTrades'},
           {:table => 'branch_quest_finish', :clz => 'BranchQuestFinish'},
           {:table => 'branch_quest_finish_report', :clz => 'BranchQuestFinishReport'},
           {:table => 'create_branch_quest', :clz => 'BranchQuestCreate'},
           {:table => 'create_branch_quest_report', :clz => 'BranchQuestCreateReport'},
           {:table => 'boss_practice_report', :clz => 'BossPracticeReport'},
           {:table => 'recharge_report', :clz => 'RechargeReport'},
           {:table => 'recharge_record', :clz => 'RechargeRecord'},
           {:table => 'guilds', :clz => 'Guild'},
           {:table => 'guild_level_record', :clz => 'GuildLevelRecord'},
           {:table => 'guild_skill', :clz => 'GuildSkill'},
           {:table => 'guild_skill_report', :clz => 'GuildSkillReport'},
           {:table => 'guild_active', :clz => 'GuildActive'},
           {:table => 'guild_active_report', :clz => 'GuildActiveReport'},
           {:table => 'level_campaign_report', :clz => 'LevelCampaignReport'},
           {:table => 'city_campaign', :clz => 'CityCampaign'},
           {:table => 'city_campaign_report', :clz => 'CityCampaignReport'},
           {:table => 'all_player_level_and_city_event_level', :clz => 'AllPlayerLevelAndCityEventLevelReport'},
           {:table => 'all_player_level', :clz => 'AllPlayerLevelReport'},
           {:table => 'all_city_event_level', :clz => 'AllCityEventLevelReport'},
           {:table => 'add_equip_report', :clz => 'AddEquipReport'},
           {:table => 'campaign_report', :clz => 'CampaignReport'},
           {:table => 'main_quest_report', :clz => 'MainQuestReport'},
           {:table => 'main_quest_users', :clz => 'MainQuestUsers'},
           {:table => 'main_quest_users_report', :clz => 'MainQuestUsersReport'},
           {:table => 'vip_level_report', :clz => 'VipLevelReport'},
           {:table => 'vip_purchase', :clz => 'VipPurchase'},
           {:table => 'vip_purchase_report', :clz => 'VipPurchaseReport'},
           {:table => 'share_award', :clz => 'ShareAward'},
           {:table => 'share_award_report', :clz => 'ShareAwardReport'},
           {:table => 'born_quest', :clz => 'BornQuest'},
           {:table => 'born_quest_report', :clz => 'BornQuestReport'},
           {:table => 'player_record', :clz => 'PlayerRecord'},
         ]

  kinds.each do |kind|
    table_name = "#{kind[:table]}"
    class_name = kind[:clz]
    # puts ">>>class_name:#{class_name}"
    create_class(class_name, ActiveRecord::Base) do
      self.table_name = table_name
    end
  end

end

