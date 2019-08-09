Ext.application({
  name: 'levelconsumereport',
  launch: onLaunch
});

var g_search_name = "";

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
                                    width:235
                                  });
  ajaxCall({ 
          'url'   : '/statshelper/get_zones',
          'onSuccess': function(res){
              var zones = res.res;
              for(var i=0; i< zones.length; i++)
              {
                var zone = zones[i];
                store_zone.add({zone_name: zone['name'], zone_id: i+1});
              }
          }}
        );

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

  var store_days = Ext.create('Ext.data.Store', {
                                                  fields: ['days_name', 'days'],
                                                  data : [{days_name: '3', days: 3},
                                                          {days_name: '7', days: 7},
                                                          {days_name: '14', days: 14},
                                                          {days_name: '30', days: 30}]
                                              });   


  var days_input = Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_lianxu_days'), //天数
                                  editable: false,
                                  store: store_days,
                                  valueField: 'days',
                                  displayField: 'days_name',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_days'),
                                  selectOnFocus:true,
                                  width:235
                            });

  var btn_query = { xtype: 'button', 
                    icon: '/images/search.png',
                    text: loc('str_query'), //查询
                    handler : onBtnQuery};

  function onBtnQuery()
  { 
  	var zone_id = zone_input.getValue();
    if(!zone_id)
    {
      alert(loc('str_plz_select_zone')); 
      return;
    } 

    var days = days_input.getValue();
    if(!days) 
    {
      alert(loc('str_plz_select_days')); 
      return;
    }

    var cost_type = cat_input.getValue();
    if(!cost_type) 
    {
      alert(loc('str_plz_select_category')); 
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + days_input.getRawValue() + "_" + cat_input.getRawValue();

    ajaxCall({ 
        'url'   : '/loss/get_loss_consume_report',
        'params': {zone_id: zone_id, cost_type: cost_type, days: days},
        'onSuccess': function(res){
            updateGrid(res.res)
        }}
      );
  };


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
      storeId:'players_report_store',
      fields: fields,
  });

 function updateGrid(res)
	{
		store_consume.removeAll();
		store_players.removeAll();
		// var sys_names = Object.keys(res);
    // console.log(res);
		for(var sys_name in res)
		{
			var rc = res[sys_name];
			var data_consume = {};
      var data_players = {};

      enumLevel(function(j){
      	data_consume['sys_name'] = sys_name;
        data_players['sys_name'] = sys_name;

        data_consume['lv'+j] = rc[''+j].num;
        data_players['lv'+j] = rc[''+j].players;
     	});
			store_consume.add(data_consume);
      store_players.add(data_players);
		};
	} ;


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
      days_input,
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



