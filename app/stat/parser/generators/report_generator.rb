class ReportGenerator  
  include Stats::GeneratorHelper        
  # include Stats::AlterCreditGenerator   
  # include Stats::AlterCoinsGenerator
  # include Stats::AlterMoneyGenerator
  # include Stats::AlterVoucherGenerator
  include Stats::CommonGenerator
  # include Stats::VipPurchaseGenerator
  include Stats::VipLevelGenerator
  include Stats::AllCityEventLevelGenerator
  include Stats::AllPlayerLevelGenerator
  # include Stats::StartCampaignGenerator
  include Stats::MainQuestUserGenerator
  # include Stats::ShopConsumeGenerator
  # include Stats::ShareAwardGenerator 
  # include Stats::MainCampaignGenerator
  include Stats::GuildSkillLevelGenerator
  # include Stats::GuildActiveGenerator 
  include Stats::AllFactionGenerator
  # include Stats::BornQuestGenerator 
  # include Stats::FinishBranchQuestGenerator 
  # include Stats::CreateBranchQuestGenerator 

  def initialize(options={})
    @options = options
    @config = options[:config]
  end

  def run
    gen_basics
    gen_retentions
    gen_activities
    # gen_alter_credits_report
    # gen_alter_coins_report
    # gen_alter_money_report
    # gen_alter_voucher_report
    # gen_vip_purchase_report
    gen_vip_level_report
    gen_all_city_event_level_report
    gen_all_player_level_report
    # gen_start_campaign_report
    gen_main_quest_user_report
    # gen_shop_consume_report
    # gen_share_award_report
    # gen_main_campaign_report
    gen_guild_skill_level_report
    # gen_giuld_active_report
    gen_all_faction_report
    # gen_born_quest_report
    # gen_finish_branch_quest_report
    # gen_create_branch_quest_report
  end

end