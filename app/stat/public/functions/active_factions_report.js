Ext.application({
  name: 'activefactionreport',
  launch: onLaunch
});

function onLaunch()
{
  var args = {
    reportname: '职业人数分布',
    categories: ['tao' , 'dem', 'pol', 'qigong', 'rune', 'shadow', 'fire', 'fighter', 'sanda'],
    catnames: ['道士', '狐妖', '杀马特', '御剑', '灵符', '利刃', '幻术', '街霸', '舞者'],
    columns: ['count_by_account', 'count_by_player'],
    colnames: [ '人数by账', '人数by角'],
    type_col: 'faction',
    src_table: 'active_factions'
  };

  genViewNoSdkPlat(args)
};