Ext.application({
  name: 'maxonlinereport',
  launch: onLaunch
});

var g_search_name = '';
function onLaunch()
{
  var fields = ['date', 'maxCount', 'time'];
  var columns = [{ text: '日期',  dataIndex: 'date'},
                 { text: '最大在线',  dataIndex: 'maxCount'},
                 { text: '时间',  dataIndex: 'time'}];
  var store_grid = Ext.create('Ext.data.Store', {
                fields: fields,
                });
  var columns = columns;

  var data_grid = Ext.create('Ext.grid.Panel', {
                  title: '最近7天数据',
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

  var btn_query = { xtype: 'button', 
                    icon: '/images/search.png',
                    // width: 200,
                    text: loc('str_query'), //查询
                    handler : onBtnQuery};

  function onBtnQuery()
  { 
    var zone_id = zone_input.getValue();
    if(!zone_id)
    {
      alert(loc('str_plz_select_zone')); //请选择区
      return;
    }

    g_search_name = "" +zone_id+ "区最大在线";
    ajaxCall({ 
        'url'   : '/realtimestats/get_max_online_report',
        'params': {zone_id: zone_id},
        'onSuccess': function(res){
            updateGrid(res.res)
        }}
      );
  } 

  function updateGrid(res)
  {
    if(!res) return;

    store_grid.removeAll();

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i];
      var date = new Date(parseInt(rc['date'])*1000 ).Format("yyyy-MM-dd");    
      var time = new Date(parseInt(rc['time'])*1000 ).Format("hh:mm:ss");    
      store_grid.add({date: date, maxCount: rc['maxCount'], time: time});
    };

  };


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