Ext.application({
  name: 'retentionreport',
  launch: onLaunch
});

var g_search_name = '';

function onLaunch()
{ 
  var store_grid = Ext.create('Ext.data.Store', {
                storeId:'retention_store',
                fields: ['date', 'total_count', 'd1', 'd2', 'd3', 'd4', 
                         'd5', 'd6', 'w1', 'w2', 'm1', 'm3']
                });

  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '总数',  dataIndex: 'total_count'},
                  { text: '次日留存率',  dataIndex: 'd1'}, 
                  { text: '二日留存率',  dataIndex: 'd2'}, 
                  { text: '三日留存率',  dataIndex: 'd3'}, 
                  { text: '四日留存率',  dataIndex: 'd4'}, 
                  { text: '五日留存率',  dataIndex: 'd5'}, 
                  { text: '六日留存率',  dataIndex: 'd6'}, 
                  { text: '七日留存率',  dataIndex: 'w1'}, 
                  { text: '十四日留存率',  dataIndex: 'w2'}, 
                  { text: '一月留存率',  dataIndex: 'm1'}, 
                  { text: '三月留存率',  dataIndex: 'm3'}];

  var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '',
                  store: store_grid,
                  columns: columns,
                  forceFit: true,
                  width: "100%",
                  height: "100%",
              });

  var store_cat1 = Ext.create('Ext.data.Store', {fields: ['catname', 'category']});   
  var cat_input1= Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_sdk_plat_cat'), //统计活跃类型
                                  editable: false,
                                  store: store_cat1,
                                  valueField: 'category',
                                  displayField: 'catname',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_sdk_plat'),
                                  selectOnFocus:true,
                                  width:235
                            });
  ajaxCall({ 
            'url'   : '/statsorign/get_sdk_plats',
            'onSuccess': function(res){
                      res = res.res;
                      store_cat1.add({catname: '总体', category: 'all#all'});
                      if(res.platforms)
                      {
                        for(var i=0; i<res.platforms.length; i++)
                        {
                          var plat = res.platforms[i];
                          store_cat1.add({catname: plat, category: 'platform#'+plat});
                        }
                      }

                      if(res.sdks){
                        for(var i=0; i<res.sdks.length; i++)
                        {
                          var sdk = res.sdks[i];
                          store_cat1.add({catname: sdk, category: 'sdk#'+sdk});
                        }
                      }

                      if(res.markets){
                        for(var i=0; i<res.markets.length; i++)
                        {
                          var mrk = res.markets[i];
                          store_cat1.add({catname: mrk, category: 'market#'+mrk});
                        }
                      }

                      if(res.zones){
                        for(var i=0; i<res.zones.length; i++)
                        {
                          var zname = res.zones[i];
                          store_cat1.add({catname: zname, category: 'zone_id#'+(i+1)});
                        }
                      }
                    }}

          );

  var store_cat2 = Ext.create('Ext.data.Store', {
                                                fields: ['catname', 'category'],
                                                data : [{catname: loc('str_players'), category: 'user'}, //玩家
                                                        {catname: loc('str_accounts'), category: 'account'}, //账号
                                                        {catname: loc('str_device'), category: 'device'}] //设备
                                            });   

  var cat_input2= Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_active_cat'), //统计活跃类型
                                  editable: false,
                                  store: store_cat2,
                                  valueField: 'category',
                                  displayField: 'catname',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_active_kind'),
                                  selectOnFocus:true,
                                  width:235
                            });

  var btn_query = { xtype: 'button', 
                  icon: '/images/search.png',
                  text: loc('str_query'), 
                  handler : onBtnQuery};

  var btn_export = { xtype: 'button', 
                  icon: '/images/down.png',
                  text: loc('str_export_xls'), 
                  handler : onBtnExport};

  function onBtnQuery()
  { 
    var cat_sp = cat_input1.getValue();
    if(!cat_sp)
    {
      alert(loc('str_plz_select_sdk_plat')); 
      return;
    }

    var cat_act = cat_input2.getValue();
    if(!cat_act)
    {
      alert(loc('str_plz_select_active_kind')); 
      return;
    }

    g_search_name = cat_input1.getRawValue() + "_" + cat_input2.getRawValue()+"留存率";

    ajaxCall({ 
            'url'   : '/statsorign/get_retention_report',
            'params': {cat_sp: cat_sp, cat_act: cat_act},
            'onSuccess': updateGrid});
  };

   function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i]
      store_grid.add( { date: rc['date'],
                        total_count: rc['total_count'],
                        d1: rc['d1'], 
                        d2: rc['d2'], 
                        d3: rc['d3'], 
                        d4: rc['d4'], 
                        d5: rc['d5'], 
                        d6: rc['d6'], 
                        w1: rc['w1'], 
                        w2: rc['w2'], 
                        m1: rc['m1'], 
                        m3: rc['m3']});  
    }
  };  

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
      cat_input1,
      cat_input2,
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