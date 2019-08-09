Ext.application({
  name: 'guild_skill_record',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{
  var fields = ['date'
              , 'guild_id'
              , 'receive_guild_red_envelope'
              , 'receive_prop_red_envelope'
              , 'donate'
              , 'mrjj'
              , 'upgrade_science'
              , 'gve'
              ];

  var save_store = Ext.create('Ext.data.Store', { fields: fields});
  var store_grid = Ext.create('Ext.data.Store', { fields: fields});

  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '工会ID',  dataIndex: 'guild_id'},
                  { text: '工会红包',  dataIndex: 'receive_guild_red_envelope'},
                  { text: '道具红包',  dataIndex: 'receive_prop_red_envelope'},
                  { text: '捐献',  dataIndex: 'donate'},
                  { text: '每日基金',  dataIndex: 'mrjj'},
                  { text: '升级科技',  dataIndex: 'upgrade_science'},
                  { text: '工会战',  dataIndex: 'gve'},
                  ];

  var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '',
                  store: store_grid,
                  columns: columns,
                  forceFit: true,
                  width: "100%",
                  height: "100%",
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
  var date_start =  Ext.create('Ext.form.field.Date', {
                    name      : 'query_date_start',
                    fieldLabel: loc('str_date_start'),
                    allowBlank: false,
                    editable: false
                  });

  var date_end =  Ext.create('Ext.form.field.Date', {
                    name      : 'query_date_end',
                    fieldLabel: loc('str_date_end'),
                    allowBlank: false,
                    editable: false
                  });

  var btn_query = { xtype: 'button',
                  icon: '/images/search.png',
                  // width: 200,
                  text: loc('str_query'), //查询
                  handler : onBtnQuery};

  var btn_export = { xtype: 'button',
                  icon: '/images/down.png',
                  // width: 200,
                  text: loc('str_export_xls'), //查询
                  handler : onBtnExport};
  function onBtnExport()
  {
    doExportXls(g_search_name, save_store, columns, null);
  };

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

    var start_date = date_start.getValue();
    if(!start_date)
    {
      alert(loc('str_plz_select_date_start')); //请选择开始日期
      return;
    }

    var end_date = date_end.getValue();
    if(!end_date)
    {
      alert(loc('str_plz_select_date_end')); //请选择结束日期
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"工会人数等级分布";
    // alert(g_search_name);
    ajaxCall({
            'url'   : '/statshelper/get_guild_active_record',
            'params': {start_date: start_date, end_date: end_date, zone_id: zone_id, sdk: sdk,
                    platform: platform},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    save_store.removeAll();
    res = res.res;
    list_grid = [];

    data_store = {};
    data_save = {};

    pre_guild = ""
    var c = 0
    for(var i=0; i<res.length; i++)
    {
      var rc = res[i];
      // console.log(rc);
      if(i > 0 && rc["guild_id"] != pre_guild)
      {
        save_store.add(data_save);
        if (c<50)
        {
          c += 1;
          // console.log(data_store)
          store_grid.add(data_store);
        }

        data_store = {}
        data_save = {}
      }
      data_store["date"] = rc["date"]
      data_store["guild_id"] = "guild_" + rc["guild_id"];
      data_store[rc["active_type"]] = rc["num"]

      data_save["date"] = rc["date"]
      data_save["guild_id"] = "guild_" + rc["guild_id"];
      data_save[rc["active_type"]] = rc["num"]
      

      pre_guild = rc["guild_id"]
    }

    save_store.add(data_save);
    if (c<50)
    {
      list_grid.push(data_store);
    }

    for(var i=0; i<list_grid; i ++ )
    {
      store_grid.add(list_grid[i]);
    }
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
      date_start,
      date_end,
      btn_query,
      btn_export
     ]
    },{
      region: 'center',
      xtype: 'panel',
      layout: 'fit',
      weight:20,
      items:[data_grid]
    }]
    });
};