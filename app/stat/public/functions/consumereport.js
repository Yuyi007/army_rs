Ext.application({
  name: 'levelconsumereport',
  launch: onLaunch
});

var g_search_name = "";
var g_cost_type = '';

function onLaunch()
{

  var store_zone = Ext.create('Ext.data.Store', { fields: ['zone_name', 'zone_id']});
  var zone_input =  Ext.create('Ext.form.ComboBox', {
                                    fieldLabel: loc('str_zone'), //区
                                    editable: false,
                                    store: store_zone,
                                    valueField: 'zone_id',
                                    displayField: 'zone_name',
                                    typeAhead: true,
                                    queryMode: 'local',
                                    emptyText:loc('str_plz_select_zone'),
                                    selectOnFocus:true,
                                    width:200
                                  });

  var store_sdk = Ext.create('Ext.data.Store', { fields: ['sdk_name', 'sdk']});
  var sdk_input =  Ext.create('Ext.form.ComboBox', {
                                    fieldLabel: loc('str_sdk'), 
                                    editable: false,
                                    store: store_sdk,
                                    valueField: 'sdk',
                                    displayField: 'sdk_name',
                                    typeAhead: true,
                                    queryMode: 'local',
                                    emptyText:loc('str_plz_select_sdk'),
                                    selectOnFocus:true,
                                    width:200
                                  });

  var store_platform = Ext.create('Ext.data.Store', { fields: ['platform_name', 'platform']});
  var platform_input =  Ext.create('Ext.form.ComboBox', {
                                    fieldLabel: loc('str_platform'), 
                                    editable: false,
                                    store: store_platform,
                                    valueField: 'platform',
                                    displayField: 'platform_name',
                                    typeAhead: true,
                                    queryMode: 'local',
                                    emptyText:loc('str_plz_select_platform'),
                                    selectOnFocus:true,
                                    width:200
                                  });

  ajaxCall({ 
            'url'   : '/statsorign/get_sdk_plats',
            'onSuccess': function(res){
                      res = res.res;

                      store_sdk.add({sdk_name: '总体', sdk: 'all'});
                      if(res.sdks){
                        for(var i=0; i<res.sdks.length; i++)
                        {
                          var sdk = res.sdks[i];
                          store_sdk.add({sdk_name: sdk, sdk: sdk});
                        }
                      }

                      store_platform.add({platform_name: '总体', platform: 'all'});
                      if(res.platforms)
                      {
                        for(var i=0; i<res.platforms.length; i++)
                        {
                          var plat = res.platforms[i];
                          store_platform.add({platform_name: plat, platform: plat});
                        }
                      }

                      store_zone.add({zone_name: '总体', zone_id: 0})
                      if(res.zones){
                        for(var i=0; i<res.zones.length; i++)
                        {
                          var zname = res.zones[i];
                          store_zone.add({zone_name: zname, zone_id: (i+1)});
                        }
                      }
                    }}

          );


  var date_input =  Ext.create('Ext.form.field.Date', {
                      name      : 'query_date',
                      fieldLabel: loc('str_date'),
                      allowBlank: false,
                      editable: false
                    });

  var store_cat = Ext.create('Ext.data.Store', {
                                                  fields: ['catname', 'category'],
                                                  data : [{catname: loc('str_credits'), category: 'credits'},
                                                          {catname: loc('str_money'), category: 'money'},
                                                          {catname: loc('str_coins'), category: 'coins'},
                                                          {catname: loc('str_voucher'), category: 'voucher'}]
                                              });   


  var cat_input = Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_huobi_cat'), //货币类型
                                  editable: false,
                                  store: store_cat,
                                  valueField: 'category',
                                  displayField: 'catname',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  // triggerAction: 'all',
                                  emptyText:loc('str_plz_select_category'),
                                  selectOnFocus:true,
                                  width:235
                            });

  var btn_query = { xtype: 'button', 
                    icon: '/images/search.png',
                    // width: 200,
                    text: loc('str_query'), //查询
                    handler : onBtnQuery};

  function onBtnQuery()
  { 
    var zone_id = zone_input.getValue();
    if(zone_id == undefined)
    {
      alert(loc('str_plz_select_zone')); //请选择区
      return;
    } 

    var sdk = sdk_input.getValue();
    if(!sdk)
    {
      alert(loc('str_plz_select_sdk')); 
      return;
    } 

    var platform = platform_input.getValue();
    if(!platform)
    {
      alert(loc('str_plz_select_platform')); 
      return;
    }

    var cost_type = cat_input.getValue();
    g_cost_type = cost_type;
    if(!cost_type) 
    {
      alert(loc('str_plz_select_category')); //请选择货币类型
      return;
    }

    var date = date_input.getValue();
    if(!date)
    {
      alert(loc('str_plz_select_date')); //请选择日期
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + sdk_input.getRawValue() + "_" + platform_input.getRawValue() + "_" + cat_input.getRawValue() + "_" + date_input.getRawValue();

    ajaxCall({ 
        'url'   : '/statshelper/get_consume_report',
        'params': {zone_id: zone_id, 
                    sdk: sdk,
                    platform: platform,
                    cost_type: cost_type, 
                    date: date},
        'onSuccess': function(res){
            updateGrid(res.res)
        }}
      );
  } 


  function enumLevel(func)
  {
    var i = 0;
    while(i < 100){
      if(i < 20)
        i += 10;
      else
        i += 5;
      func(i);
    }
  }

  var columns_consume = [{ text: '系统分类',  dataIndex: 'sys_name'}];
  var columns_players = [{ text: '系统分类',  dataIndex: 'sys_name'}];
  var fields = ['sys_name'];
  enumLevel(function(i){
      columns_consume.push({ text: '消费_'+i,  dataIndex: 'lv'+i });
      columns_players.push({ text: '人数_'+i,  dataIndex: 'lv'+i });
      fields.push('lv'+i );
    });

  var store_consume = Ext.create('Ext.data.Store', {
      storeId:'consume_report_store',
      fields: fields,
  });

  var store_players = Ext.create('Ext.data.Store', {
      storeId:'consume_report_store',
      fields: fields,
  });

  var map_sys_credits = {
                 manual_reborn: '复活', 
                 buy_goods: '商城',
                 taxi: '打车',
                 currency_exchange_coins: '兑换硬币',
                 currency_exchange_money: '兑换纸币',
                 resign: '补签到',
                 buy_portrait: '购买头像',
                 extend_combat_time: '副本延时',
                 create_guild: '创建社团',
                 guild_change_name: '社团改名',
                 guild_banner: '社团旗帜',
                 guild_donate: '社团宣传',
                 lottery_badges: '纹章抽取',
                 vip_first: 'vip礼包', 
                 roll_treasure_credit: '黄金夺宝',
                 roll_treasure_exchange: '替代币夺宝'
               };
               
  var map_sys_coins = {
               buy_foods: '健康饮食',
               taxi: '嘟嘟打车',
               take_subway: '地铁',
               buy_bus_ticket: '长途',
               hospital_cure: '医院',
               coach: '强身健体',
               absorb_equip: '装备合魂',
               make_forge: '装备打造',
               upgrade_new_talent: '天赋升级',
               buy_goods_eqp: '装备商店',
               buy_goods_gift: '礼物商店',
               buy_goods_wine: '药品商店',
               buy_goods_cooking: '食物商店',
               use_enchant_medica: '灵符篆刻',
               refresh_therion: '四象觉醒',
               buy_goods_gem: '宝石商店',
               buy_goods_drawing: '灵符商店',
               unlock_bag_slot: '背包空间',
               add_inventory: '银行空间',
               upgrade_skill: '技能升级',
               booth_sell: '交易行上架',
               ufc_signup: '无差别格斗报名'
            };

  var map_sys_voucher = {
    buy_goods: '商城免费',
    roll_treasure_voucher: '代币夺宝',
    roll_treasure_exchange: '代币不够夺宝',
  };

  var map_sys_money = {
        currency_exchange_coins: '兑换硬币',
        booth_buy: '交易行',
        buy_goods: '商城限购',
        post_tweet: '朋友圈设置礼物'
  };

  function updateGrid(res)
  {
    store_consume.removeAll();
    store_players.removeAll();

    var tmpData = {};
    var syses = [];
    var map_sys = {};
    if( g_cost_type == 'credits' ){
      map_sys = map_sys_credits;
    }else if(g_cost_type == 'coins'){
      map_sys = map_sys_coins;
    }else if(g_cost_type == 'monty'){
      map_sys = map_sys_money;
    }else{
      map_sys = map_sys_voucher;
    }
    for(var i=0; i<res.length; i++){
      var rc = res[i];
      sn = map_sys[rc.sys_name]
      if(sn != undefined){
        rc.sys_name = sn
      }

      if(!tmpData[rc.sys_name])
      {
        tmpData[rc.sys_name] = {};
        syses.push(rc.sys_name);
      }  
      tmpData[rc.sys_name][''+rc.level_rgn] = {consume: rc.consume, players: rc.players};
    }

    for(var i =0; i<syses.length; i++)
    {
      var sys_name = syses[i];
      var data_consume = {};
      var data_players = {};
      
      enumLevel(function(j){
        data_consume['sys_name'] = sys_name;
        data_players['sys_name'] = sys_name;
        if(!tmpData[sys_name][''+j])  
        {
          data_consume['lv'+j] = 0;
          data_players['lv'+j] = 0;
        }
        else
        {
          data_consume['lv'+j] = tmpData[sys_name][''+j].consume;
          data_players['lv'+j] = tmpData[sys_name][''+j].players;
        }
      });
      store_consume.add(data_consume);
      store_players.add(data_players);
    }
  }

  var data_grid_consume = Ext.create('Ext.grid.Panel', {
      title: '消费等级表',
      store: store_consume,//Ext.data.StoreManager.lookup('consume_report_store'),
      columns: columns_consume,
      forceFit: true,
  });

  var data_grid_players = Ext.create('Ext.grid.Panel', {
      title: '人数等级表',
      store: store_players,//Ext.data.StoreManager.lookup('players_report_store'),
      columns: columns_players,
      forceFit: true,
  });

  var btn_export = { xtype: 'button', 
                  icon: '/images/down.png',
                  // width: 200,
                  text: loc('str_export_xls'), //查询
                  handler : onBtnExport};


  function onBtnExport()
  {
    var name = "消费"+g_search_name;
    doExportXls(name, store_consume, columns_consume, function()
      {
        var name = "人数"+g_search_name;
        doExportXls(name, store_players, columns_players);    
      });
  }; 

  new Ext.Viewport({
    layout: 'border',
    width: '100%',
    height: '100%',
    items: [{
     region: "north",
     xtype: "toolbar",
     height: 30,
     items: [
      zone_input,
      sdk_input,
      platform_input,
      date_input,
      cat_input,
      btn_query,
      btn_export
     ] 
    }, 
    {
      region: 'center',
      xtype: 'panel',
      weight:20,
      items:[data_grid_consume, data_grid_players]
    }]
  });
};
