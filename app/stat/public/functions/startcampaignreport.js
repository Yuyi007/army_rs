Ext.application({
  name: 'creditsconsumereport',
  launch: onLaunch
});

function onLaunch()
{
  var args = {
    reportname: '各类型战斗统计',
    categories: ['boss' , 'practice', 'independent', 'quest', 'review', 'nightmare_review', 'robber', 'ufc', 'wushu', 'freestyle', 'shadow', 'shadow_advance', 'guild_dungeon'],
    catnames: ['首领', '修炼', '机遇', '任务', '回顾', '噩梦回顾', '千面', '无差别格斗', '国术比赛','国术切磋', '暗影', '精英暗影', 'GVE'],
    columns: ['count', 'players', 'accounts'],
    colnames: ['次数', '人数by账', '人数by角'],
    type_col: 'kind',
    src_table: 'start_campaign_sum'
  };

  genView(args)
};