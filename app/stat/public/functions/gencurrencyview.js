//  args = {
//      reportname: '金砖消耗',
//      categories: ['manual_reborn' , 'buy_goods', 'taxi', 'currency_exchange_coins', 'currency_exchange_money' },
//      catnames: ['复活', '商城', '打车', '兑换硬币', '兑换纸币'],
//      columns: ['credits', 'players'],
//      colnames: ['消费', '人数'],
//      type_col: 'reason',
//      src_table: 'alter_credits_sys'
//    }
function genView(args)
{
  var g_search_name = "";

  var fields = ['date'];
  var columns = [ { text: '日期',  dataIndex: 'date'}]

  for(var i = 0; i<args.categories.length; i++)
  {
    var cat = args.categories[i];
    var cat_name = args.catnames[i];
    for(var j=0; j<args.columns.length; j++)
    {
      var col = args.columns[j]
      var field = cat+"_"+col
      fields.push(field);

      var col_name = args.colnames[j];
      var field_name = cat_name+col_name
      columns.push({text: field_name, dataIndex: field});
    }
  }

  var store_grid = Ext.create('Ext.data.Store', {fields: fields});
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
    doExportXls(g_search_name, store_grid, columns, null);
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

    g_search_name = zone_input.getRawValue() + "_" + sdk_input.getRawValue() + "_" + platform_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+args.reportname;

    var rpcParam = {zone_id: zone_id,  
                    sdk: sdk,
                    platform: platform,
                    categories: args.categories,
                    type_col: args.type_col,
                    src_table: args.src_table, 
                    columns: args.columns,
                    date_start: start_date, 
                    date_end: end_date};

    ajaxCall({ 
            'url'   : '/statshelper/get_currency_records',
            'params': {args: Ext.encode(rpcParam)},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;
    for(var k=0; k<res.length; k++)
    {
      var rc = res[k]
      d = {}
      for(var i = 0; i<args.categories.length; i++)
      {
        var cat = args.categories[i];
        d['date'] = rc['date'];
        for(var j=0; j<args.columns.length; j++)
        {
          var col = args.columns[j]
          var field = cat+"_"+col
          d[field] = rc[field]
        }
      }
      store_grid.add(d);
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
}

function genViewNoSdkPlat(args)
{
  var g_search_name = "";

  var fields = ['date'];
  var columns = [ { text: '日期',  dataIndex: 'date'}]

  for(var i = 0; i<args.categories.length; i++)
  {
    var cat = args.categories[i];
    var cat_name = args.catnames[i];
    for(var j=0; j<args.columns.length; j++)
    {
      var col = args.columns[j]
      var field = cat+"_"+col
      fields.push(field);

      var col_name = args.colnames[j];
      var field_name = cat_name+col_name
      columns.push({text: field_name, dataIndex: field});
    }
  }

  var store_grid = Ext.create('Ext.data.Store', {fields: fields});
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

  ajaxCall({ 
            'url'   : '/statsorign/get_sdk_plats',
            'onSuccess': function(res){
                      res = res.res;
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
    doExportXls(g_search_name, store_grid, columns, null);
  }; 

  function onBtnQuery()
  { 
    var zone_id = zone_input.getValue();
    if(zone_id == undefined)
    {
      alert(loc('str_plz_select_zone')); 
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

    g_search_name = zone_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+args.reportname;

    var rpcParam = {zone_id: zone_id,  
                    categories: args.categories,
                    type_col: args.type_col,
                    src_table: args.src_table, 
                    columns: args.columns,
                    date_start: start_date, 
                    date_end: end_date};

    ajaxCall({ 
            'url'   : '/statshelper/get_currency_records',
            'params': {args: Ext.encode(rpcParam)},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;
    for(var k=0; k<res.length; k++)
    {
      var rc = res[k]
      d = {}
      for(var i = 0; i<args.categories.length; i++)
      {
        var cat = args.categories[i];
        d['date'] = rc['date'];
        for(var j=0; j<args.columns.length; j++)
        {
          var col = args.columns[j]
          var field = cat+"_"+col
          d[field] = rc[field]
        }
      }
      store_grid.add(d);
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
}