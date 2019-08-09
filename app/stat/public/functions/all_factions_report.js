Ext.application({
  name: 'allfactionreport',
  launch: onLaunch
});

var g_search_name = '';

function onLaunch()
{
 var store_grid =  Ext.create('Ext.data.Store', {
                      fields: ['zone_id', 'date', 'faction', 'players', 'accounts']
                    });
  var columns = [ 
  								{ text: '区',  dataIndex: 'zone_id'},
  								{ text: '日期',  dataIndex: 'date'},
                  { text: '职业',  dataIndex: 'faction'},
                  { text: '角色数',  dataIndex: 'players'},
                  { text: '账号数',  dataIndex: 'accounts'}
                ];

	var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '',
                  store: store_grid,
                  columns: columns,
                  forceFit: true,
                  width: "100%",
                  height: "100%",
              });

  var date_input =  Ext.create('Ext.form.field.Date', {
                      name      : 'query_date',
                      fieldLabel: loc('str_date'),
                      allowBlank: false,
                      editable: false
                    });
  
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

    var date = date_input.getValue();
    if(!date)
    {
      alert(loc('str_plz_select_date')); //请选择日期
      return;
    }

    g_search_name = zone_input.getRawValue()+ "_" + date_input.getRawValue() + "所有职业统计";

    ajaxCall({
        'url'   : '/statshelper/get_all_factions_report',
        'params': { zone_id: zone_id, 
                    sdk: sdk,
                    platform: platform,
                    date: date},
        'onSuccess': function(res){
            updateGrid(res.res)
        }}
      );
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    for(var i=0; i<res.length; i++)
    {
      var rc = res[i];
      store_grid.add( {	zone_id: rc['zone_id'],
      									date: rc['date'],
                        faction: rc['faction'],
                        players: rc['players'],
                        accounts: rc['accounts']});
    }
  }

  var btn_export = { xtype: 'button',
                  icon: '/images/down.png',
                  // width: 200,
                  text: loc('str_export_xls'), //查询
                  handler : onBtnExport};

   function onBtnExport()
   {
      doExportXls(g_search_name, store_grid, columns, null);
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


