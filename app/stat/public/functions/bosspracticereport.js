Ext.application({
  name: 'bosspractivereport',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{
  var fields = ['date'
              , 'count1_boss'
              , 'count1p_boss'
              , 'count2_boss'
              , 'count2p_boss'
              , 'count3_boss'
              , 'count3p_boss'
              , 'count4_boss'
              , 'count4p_boss'
              , 'count5_boss'
              , 'count5p_boss'
              , 'count6_boss'
              , 'count6p_boss'
              , 'count7_boss'
              , 'count7p_boss'
              , 'count8_boss'
              , 'count8p_boss'
              , 'count_more_boss'
              , 'countp_more_boss'
              , 'count1_practice'
              , 'count1p_practice'
              , 'count2_practice'
              , 'count2p_practice'
              , 'count3_practice'
              , 'count3p_practice'
              , 'count4_practice'
              , 'count4p_practice'
              , 'count5_practice'
              , 'count5p_practice'
              , 'count6_practice'
              , 'count6p_practice'
              , 'count7_practice'
              , 'count7p_practice'
              , 'count8_practice'
              , 'count8p_practice'
              , 'count_more_practice'
              , 'count_morep_practice'];

  var save_store = Ext.create('Ext.data.Store', { fields: fields});
  var store_grid = Ext.create('Ext.data.Store', { fields: fields});

  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '危险1账',  dataIndex: 'count1_boss'},
                  { text: '危险1角',  dataIndex: 'count1p_boss'},
                  { text: '危险2账',  dataIndex: 'count2_boss'},
                  { text: '危险2角',  dataIndex: 'count2p_boss'},
                  { text: '危险3账',  dataIndex: 'count3_boss'},
                  { text: '危险3角',  dataIndex: 'count3p_boss'},
                  { text: '危险4账',  dataIndex: 'count4_boss'},
                  { text: '危险4角',  dataIndex: 'count4p_boss'},
                  { text: '危险5账',  dataIndex: 'count5_boss'},
                  { text: '危险5角',  dataIndex: 'count5p_boss'},
                  { text: '危险6账',  dataIndex: 'count6_boss'},
                  { text: '危险6角',  dataIndex: 'count6p_boss'},
                  { text: '危险7角',  dataIndex: 'count7p_boss'},
                  { text: '危险8角',  dataIndex: 'count8p_boss'},
                  { text: '危险8m账',  dataIndex: 'count_more_boss'},
                  { text: '危险8m角',  dataIndex: 'countp_more_boss'},
                  { text: '不法1账',  dataIndex: 'count1_practice'},
                  { text: '不法1角',  dataIndex: 'count1p_practice'},
                  { text: '不法2账',  dataIndex: 'count2_practice'},
                  { text: '不法2角',  dataIndex: 'count2p_practice'},
                  { text: '不法3账',  dataIndex: 'count3_practice'},
                  { text: '不法3角',  dataIndex: 'count3p_practice'},
                  { text: '不法4账',  dataIndex: 'count4_practice'},
                  { text: '不法4角',  dataIndex: 'count4p_practice'},
                  { text: '不法5账',  dataIndex: 'count5_practice'},
                  { text: '不法5角',  dataIndex: 'count5p_practice'},
                  { text: '不法6账',  dataIndex: 'count6_practice'},
                  { text: '不法6角',  dataIndex: 'count6p_practice'},
                  { text: '不法7角',  dataIndex: 'count7p_practice'},
                  { text: '不法8角',  dataIndex: 'count8p_practice'},
                  { text: '不法8m账',  dataIndex: 'count_more_practice'},
                  { text: '不法8m角',  dataIndex: 'count_morep_practice'},
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

    g_search_name = zone_input.getRawValue() + "_" + sdk_input.getRawValue() + "_" + platform_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"章节任务通过人数";
    // alert(g_search_name);
    ajaxCall({
            'url'   : '/statshelper/get_boss_practice_report',
            'params': { zone_id: zone_id,  
                        sdk: sdk,
                        platform: platform,
                        start_date: start_date,
                        end_date: end_date},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i];
      var data = {};
      for(var j = 0; j<fields.length; j++)
      {
        field = fields[j];
        data[field] = rc[field]
      };

      save_store.add(data);
      if (i<50)
      {
        store_grid.add(data);
      }
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