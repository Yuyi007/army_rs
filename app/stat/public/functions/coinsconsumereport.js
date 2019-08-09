Ext.application({
  name: 'coinsconsumereport',
  launch: onLaunch
});

function onLaunch()
{ 
  var args = {
    reportname: '硬币各系统消耗',
    categories: ['buy_foods' , 'taxi', 'take_subway', 'buy_bus_ticket', 'hospital_cure', 'coach', 'absorb_equip', 
                 'make_forge', 'upgrade_new_talent', 'buy_goods_eqp', 'buy_goods_gem','buy_goods_gift', 'buy_goods_wine', 'buy_goods_cooking', 
                 'use_enchant_medica', 'upgrade_therion', 'buy_goods_gem', 'buy_goods_drawing', 'unlock_bag_slot', 'add_inventory',
                 'buy_goods_quest', 'upgrade_skill', 'booth_sell', 'ufc_signup'],
    catnames: ['健康饮食', '嘟嘟打车', '地铁', '长途', '医院疗伤', '强身健体', '装备合魂', 
                '装备打造', '天赋升级', '装备商店', '宝石商店', '礼物商店', '药品商店', '食物商店', 
                '灵符篆刻', '四象觉醒', '宝石商店', '灵符商店', '背包空间', '银行空间', 
                '购买任务道具', '技能升级', '交易行上架', '无差别格斗报名'],
    columns: ['coins', 'players'],
    colnames: ['消费', '人数'],
    type_col: 'reason',
    src_table: 'alter_coins_sys'
  };

  genView(args)
};