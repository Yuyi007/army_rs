Ext.application({
  name: 'creditsgainreport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '金砖系统获取',
    categories: ['recharge', 'item_drop', 'sign', 'newbeereward', 'cdkey', 'guild_envelop', 'born_quest', 'dialy_activity'],
    catnames: ['充值', '礼包掉落', '签到', '新手奖励', 'cdkey', '社团红包', '开服狂欢', '每日活跃'],
    columns: ['credits', 'players'],
    colnames: ['获得', '人数'],
    type_col: 'reason',
    src_table: 'gain_credits_sys'
  };

  genView(args)
};