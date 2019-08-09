Ext.application({
  name: 'newplayerrechargereport',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{ 
	var fields = ['goods', 'num', 'accounts'];
  var save_store = Ext.create('Ext.data.Store', { fields: fields});
  var store_grid = Ext.create('Ext.data.Store', { fields: fields});

  var columns = [ { text: '类型',  dataIndex: 'goods'},
                  { text: '数量',  dataIndex: 'num'},
                  { text: '账户',  dataIndex: 'accounts'}];


  var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '',
                  store: store_grid,
                  columns: columns,
                  forceFit: true,
                  width: "100%",
                  height: "100%",
              });
 

  var store_cat1 = Ext.create('Ext.data.Store', {fields: ['catname', 'category']});   
  var cat_input= Ext.create('Ext.form.ComboBox', {
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

                      if(res.sdks){
                        for(var i=0; i<res.sdks.length; i++)
                        {
                          var sdk = res.sdks[i];
                          store_cat1.add({catname: sdk, category: 'sdk#'+sdk});
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

  var store_plat = Ext.create('Ext.data.Store', { fields: ['name', 'platform']});
  store_plat.add({name: 'all', platform: 'all'})
  store_plat.add({name: '安卓', platform: 'android'})
  store_plat.add({name: '苹果', platform: 'ios'})
  store_plat.add({name: 'Unity', platform: 'editor'})
  var platform_input =  Ext.create('Ext.form.ComboBox', {
			  									fieldLabel: loc('str_platform'), //ios android editor
			  									editable: false,
			  									store: store_plat,
			  									valueField: 'platform',
			                    displayField: 'name',
			                    typeAhead: true,
			                    queryMode: 'local',
			                    emptyText:loc('str_plz_select_platform'),
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
    doExportXls(g_search_name, save_store, columns, null);
  };  

  function onBtnQuery()
  { 
    var cat = cat_input.getValue();
    if(!cat)
    {
      alert(loc('str_plz_select_zone')); //请选择区
      return;
    }

    var platform = platform_input.getValue();
    if(!platform)
    {
      alert(loc('str_plz_select_platform')); //请选择平台
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

   g_search_name = cat_input.getRawValue() + "_" + platform_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"新增充值统计";
    // alert(g_search_name);
    ajaxCall({ 
            'url'   : '/recharge/get_new_player_recharge_report',
            'params': {start_date: start_date, end_date: end_date, cat: cat, platform: platform},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i]
      save_store.add( { goods: rc['goods'],
                        num: rc['num'],
                        accounts: rc['accounts']});  
      if (i<50)
      {
        store_grid.add( { goods: rc['goods'],
                        num: rc['num'],
                        accounts: rc['accounts']});  
        
      };
    };
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
      cat_input,
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