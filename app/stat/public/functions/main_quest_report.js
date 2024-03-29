Ext.application({
  name: 'levelcampaignreport',
  launch: onLaunch
});

var g_search_name = '';

function onLaunch()
{
	var fields = ['date', 'zone_id', 'tid', 'num'];
  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '区',  dataIndex: 'zone_id' },
                  { text: '任务Tid',  dataIndex: 'tid' },
                  { text: '数量',  dataIndex: 'num' }];

 	var store_grid =  Ext.create('Ext.data.Store', { fields: fields });		

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

    var date = date_input.getValue();
    if(!date) 
    {
      alert(loc('str_plz_select_date')); 
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + date_input.getRawValue() + "主线任务统计";

    ajaxCall({ 
        'url'   : '/statshelper/get_main_quest_report',
        'params': {zone_id: zone_id, date: date},
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
      var rc = res[i]
      store_grid.add( { date: rc['date'],
                        zone_id: rc['zone_id'],
                        tid: rc['tid'],
                        num: rc['num']
                      });  
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
      date_input,
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