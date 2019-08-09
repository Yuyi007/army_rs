Ext.application({
  name: 'moneyconsumereport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '纸币各系统消耗',
    categories: ['currency_exchange_coins' , 'booth_buy', 'buy_goods', 'post_tweet'],
    catnames: ['兑换硬币', '交易行', '商城限购', '朋友圈设置礼物'],
    columns: ['money', 'players'],
    colnames: ['消费', '人数'],
    type_col: 'reason',
    src_table: 'alter_money_sys'
  };

  genView(args)
};