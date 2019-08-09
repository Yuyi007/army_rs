Ext.application({
  name: 'coinsgainreport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '硬币各系统获取',
    categories: ['mq_drop' , 'bq_drop_chapterevent', 'sell_slot', 'drop_chance', 'drop_review', 'drop_boss', 'drop_shadow', 'drop_shadow_advance',
                 'dialy_activity', 'decompose_equip', 'city_event', 'apply_drive', 'currency_exchange_money',
                  'currency_exchange_credits', 'sign', 'newbeereward', 'level_reward', 'city_level_reward', 'fightval_reward', 'guild_envelop', 'guild_dialy', 'born_quest'],
    catnames: ['主线任务', '章节事件', '卖道具', '机遇副本', '回顾副本', '危险人物', '城市暗影', '精英暗影', '每日活跃', '装备分解', 
                '市井事件', '试驾', '纸币兑换', '黄金兑换', '签到', '新手奖励', '升级奖励', '阅历奖励', '战力奖励', '公会红包', '公会翻牌', '开服狂欢'],
    columns: ['coins', 'players'],
    colnames: ['获取', '人数'],
    type_col: 'reason',
    src_table: 'gain_coins_sys'
  };

  genView(args)
};