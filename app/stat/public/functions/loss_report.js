Ext.application({
  name: 'lossreport',
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

  var store_kind = Ext.create('Ext.data.Store', {
                                                  fields: ['kind_name', 'kind'],
                                                  data : [{kind_name: '等级', kind: 'hero_level' },
                                                          {kind_name: '主线任务', kind: 'main_quest'},
                                                          {kind_name: '主线战斗', kind: 'main_quest_campaign'}]
                                              });   


  var kinds_input = Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_cat'), 
                                  editable: false,
                                  store: store_kind,
                                  valueField: 'kind',
                                  displayField: 'kind_name',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_cat'),
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
    if(zone_id == undefined)
    {
      alert(loc('str_plz_select_zone')); 
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

    var kind = kinds_input.getValue();
    if(!kind)
    {
      alert(loc('str_plz_select_cat'))
      return;
    }

    var days = days_input.getValue();
    if(!days) 
    {
      alert(loc('str_plz_select_days')); 
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + 
                    sdk_input.getRawValue() + "_" + 
                    platform_input.getRawValue() + "_" + 
                    kinds_input.getRawValue() + "_" + 
                    days_input.getRawValue();

    ajaxCall({ 
        'url'   : '/loss/get_loss_report',
        'params': { zone_id: zone_id, 
                    sdk: sdk,
                    platform: platform,
                    kind: kind,
                    days: days},
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

  var columns = [ { text: '类型',  dataIndex: 'kind'},
                  { text: '人数',  dataIndex: 'players'}];
  var fields = ['kind', 'players'];
    

  var store = Ext.create('Ext.data.Store', {
      storeId:'loss_report',
      fields: fields,
  });


 function updateGrid(res)
	{
		store.removeAll();
		for(var goods in res)
		{
			var rc = res[goods];
			store.add({'kind': rc.kind, 'players': rc.players});
		};
	} ;


	var data_grid = Ext.create('Ext.grid.Panel', {
      title: '流失查询',
      store: store,//Ext.data.StoreManager.lookup('recharge_report_store'),
      columns: columns,
      forceFit: true,
  });


  var btn_export = { xtype: 'button', 
                  icon: '/images/down.png',
                  text: loc('str_export_xls'), //查询
                  handler : onBtnExport};
  function onBtnExport()
  {
    var name = "流失"+g_search_name;
    doExportXls(name, store, columns);
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
      kinds_input,
      days_input,
      btn_query,
      btn_export
     ] 
    }, 
    {
      region: 'center',
      xtype: 'panel',
      weight:20,
      items:[data_grid]
    }]
  });
};
