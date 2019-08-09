Ext.application({
  name: 'creditsconsumereport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '金砖各系统消耗',
    categories: ['manual_reborn' , 'buy_goods', 'taxi', 'currency_exchange_coins',
                 'currency_exchange_money', 'resign', 'buy_portrait', 'extend_combat_time',
                 'create_guild', 'guild_change_name', 'guild_banner', 'guild_donate', 'lottery_badges', 'vip_first', 'roll_treasure_credit', 'roll_treasure_exchange'],
    catnames: ['复活', '商城', '打车', '兑换硬币', '兑换纸币', '补签到', '购买头像', '副本延时',
                '创建社团', '社团改名', '社团旗帜', '社团宣传', '纹章抽取', 'vip礼包', '黄金夺宝', '替代币夺宝'],
    columns: ['credits', 'players'],
    colnames: ['消费', '人数'],
    type_col: 'reason',
    src_table: 'alter_credits_sys'
  };

  genView(args)
};