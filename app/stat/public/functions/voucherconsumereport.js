Ext.application({
  name: 'voucherconsumereport',
  launch: onLaunch
});

function onLaunch()
{
  var args = {
    reportname: '代金券各系统消耗',
    categories: ['buy_goods', 'roll_treasure_voucher', 'roll_treasure_exchange'],
    catnames: ['商城免费', '代币夺宝', '代币不够夺宝'],
    columns: ['voucher', 'accounts', 'players'],
    colnames: ['消费', '人数by账', '人数by角'],
    type_col: 'reason',
    src_table: 'alter_voucher_sys'
  };

  genView(args)
};