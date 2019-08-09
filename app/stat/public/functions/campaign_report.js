Ext.application({
  name: 'campaignreport',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{ 
	var save_store = Ext.create('Ext.data.Store', {
                fields: ['date', 'zone_id', 'cid', 'num', 'players'],
                });
  var store_grid = Ext.create('Ext.data.Store', {
                fields: ['date', 'zone_id', 'cid', 'num', 'players'],
                });
	var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '区',  dataIndex: 'zone_id'},
                  { text: '副本',  dataIndex: 'cid'},
                  { text: '次数',  dataIndex: 'num'},
                  { text: '人数',  dataIndex: 'players'}
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

  var store_cat = Ext.create('Ext.data.Store', { fields: ['cat_name', 'cat']});
  store_cat.add({cat_name: '参与', cat: 'start'});
  store_cat.add({cat_name: '完成', cat: 'finish'});
  var cat_input =  Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_cat'), 
                                  editable: false,
                                  store: store_cat,
                                  valueField: 'cat',
                                  displayField: 'cat_name',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_cat'),
                                  selectOnFocus:true,
                                  width:235
                                });


 	var date_input =  Ext.create('Ext.form.field.Date', {
                    name      : 'query_date',
                    fieldLabel: loc('str_date'),
                    allowBlank: false,
                    editable: false
                  });

 	var cid_input = Ext.create('Ext.form.field.Text', {
                    name      : 'query_cid',
                    fieldLabel: loc('str_campaign_id'),
                    allowBlank: true,
                    editable: true
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
    if(!zone_id)
    {
      alert(loc('str_plz_select_zone')); //请选择区
      return;
    }

    var date = date_input.getValue();
    if(!date)
    {
      alert(loc('str_plz_select_date')); //请选择日期
      return;
    }

    var cat = cat_input.getValue();
    if(!cat)
    {
      alert(loc('str_plz_select_cat')); //请选择类型
      return;
    }

    var cid = cid_input.getValue();

    g_search_name = zone_input.getRawValue() + "_" + date_input.getRawValue() + "_" + cid_input.getRawValue()+ "_"+ cat_input.getRawValue() +"副本报表";
    // alert(g_search_name);
    ajaxCall({ 
            'url'   : '/statshelper/get_campaign_report',
            'params': {date: date, zone_id: zone_id, cat: cat, cid: cid},
            'onSuccess': updateGrid});
  };


  function updateGrid(res)
  {
  	save_store.removeAll();
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i] 

      save_store.add( { date: rc['date'],
                        zone_id: rc['zone_id'],
                        cid: rc['cid'],
                        num: rc['num'],
                        players: rc['players']});  
      if (i<50)
      {
        store_grid.add( { date: rc['date'],
                        zone_id: rc['zone_id'],
                        cid: rc['cid'],
                        num: rc['num'],
                        players: rc['players']});  
        
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
      zone_input,
      date_input,
			cat_input,
			cid_input,
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