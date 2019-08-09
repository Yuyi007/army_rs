Ext.application({
  name: 'moneygainreport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '纸币各系统获取',
    categories: ['sell_photo' , 'finish_job', 'bq_drop_wanted', 'currency_exchange_credits', 'sign', 'newbeereward', 
                  'guild_envelop', 'bq_drop_chapterevent', 'month_card', 'born_quest', 'cdkey', 'item_drop'],
    catnames: ['都市摄影', '应聘打工', '通讯录委托', '黄金兑换', 
                '签到', '新手奖励', '社团红包', '章节事件', '月卡', '开服狂欢', 'cdkey礼包', '礼包掉落'],
    columns: ['money', 'players'],
    colnames: ['获取', '人数'],
    type_col: 'reason',
    src_table: 'gain_money_sys'
  };

  genView(args)
};