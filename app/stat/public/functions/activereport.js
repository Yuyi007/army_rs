Ext.application({
  name: 'totalactivereport',
  launch: onLaunch
});

var g_search_name = '';

function onLaunch()
{ 
  var store_grid = Ext.create('Ext.data.Store', {
                storeId:'total_active_store',
                fields: ['date', 'total_count', 'm5', 'm10', 'm15', 'm20', 
                         'm25', 'm30', 'm35', 'm40', 'm45', 'm50',
                         'm55', 'm60', 'm120', 'm180', 'm300', 'm300plus'],
                });
  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '总数',  dataIndex: 'total_count'},
                  { text: '5分钟以内',  dataIndex: 'm5'}, 
                  { text: '10分钟以内',  dataIndex: 'm10'}, 
                  { text: '15分钟以内',  dataIndex: 'm15'}, 
                  { text: '20分钟以内',  dataIndex: 'm20'}, 
                  { text: '25分钟以内',  dataIndex: 'm25'}, 
                  { text: '30分钟以内',  dataIndex: 'm30'}, 
                  { text: '35分钟以内',  dataIndex: 'm35'}, 
                  { text: '40分钟以内',  dataIndex: 'm40'}, 
                  { text: '45分钟以内',  dataIndex: 'm45'}, 
                  { text: '50分钟以内',  dataIndex: 'm50'},   
                  { text: '55分钟以内',  dataIndex: 'm55'}, 
                  { text: '1小时以内',  dataIndex: 'm60'}, 
                  { text: '2小时以内',  dataIndex: 'm120'}, 
                  { text: '3小时以内',  dataIndex: 'm180'}, 
                  { text: '5小时以内',  dataIndex: 'm300'}, 
                  { text: '5小时以上',  dataIndex: 'm300plus'}];

  var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '',
                  store: store_grid,
                  columns: columns,
                  forceFit: true,
                  width: "100%",
                  height: "100%",
              });

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
                                                        {catname: loc('str_device'), category: 'device'}, //设备
                                                        {catname: loc('str_accounts'), category: 'account'}, //账号
                                                        {catname: loc('str_new_player'), category: 'new_user'}, //新玩家
                                                        {catname: loc('str_new_device'), category: 'new_device'}, //新设备
                                                        {catname: loc('str_new_account'), category: 'new_account'}] //新账号
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

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i]
      store_grid.add( { date: rc['date'],
                        total_count: rc['total_count'],
                        m5: rc['m5'], 
                        m10: rc['m10'], 
                        m15: rc['m15'], 
                        m20: rc['m20'], 
                        m25: rc['m25'], 
                        m30: rc['m30'], 
                        m35: rc['m35'], 
                        m40: rc['m40'], 
                        m45: rc['m45'], 
                        m50: rc['m50'],
                        m55: rc['m55'], 
                        m60: rc['m60'], 
                        m120: rc['m120'], 
                        m180: rc['m180'], 
                        m300: rc['m300'], 
                        m300plus: rc['m300plus']});  
    }
  };        

  function onBtnQuery()
  { 
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

    g_search_name = cat_input1.getRawValue() + "_" + cat_input2.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"活跃度";
    // alert(g_search_name);
    ajaxCall({ 
            'url'   : '/statsorign/get_active_report',
            'params': {start_date: start_date, end_date: end_date, cat_sp: cat_sp, cat_act: cat_act},
            'onSuccess': updateGrid});
  };

  
};