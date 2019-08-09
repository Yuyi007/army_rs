Ext.application({
  name: 'boothtradereport',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{ 
  var save_store = Ext.create('Ext.data.Store', {
                fields: ['date', 'seller', 'buyer', 'tid', 'name', 'count', 'price', 'time', 'level', 'grade', 'star'],
                });
  var store_grid = Ext.create('Ext.data.Store', {
                fields: ['date', 'seller', 'buyer', 'tid', 'name', 'count', 'price', 'time', 'level', 'grade', 'star' ],
                });

  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '卖家ID',  dataIndex: 'seller'},
                  { text: '买家ID',  dataIndex: 'buyer'},
                  { text: 'tid',  dataIndex: 'tid'},
                  { text: '商品',  dataIndex: 'name'},
                  { text: '数量',  dataIndex: 'count'},
                  { text: '价格',  dataIndex: 'price'},
                  { text: '等级',  dataIndex: 'level'},
                  { text: '品级',  dataIndex: 'grade'},
                  { text: '星级',  dataIndex: 'star'},
                  { text: '交易时间',  dataIndex: 'time'}];

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
    if(!zone_id)
    {
      alert(loc('str_plz_select_zone')); //请选择区
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

    g_search_name = zone_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"交易行流水";
    // alert(g_search_name);
    ajaxCall({ 
            'url'   : '/statshelper/get_booth_trade',
            'params': {start_date: start_date, end_date: end_date, zone_id: zone_id},
            'onSuccess': updateGrid});
  };

  function updateGrid(res)
  {
    store_grid.removeAll();
    res = res.res;

    for(var i=0; i<res.length; i++)
    {
      var rc = res[i] 
      save_store.add( { date: rc['date'],
                        seller: rc['seller'],
                        buyer: rc['buyer'],
                        tid: rc['tid'],
                        name: rc['name'],
                        count: rc['count'],
                        price: rc['price'],
                        time: rc['time'],
                        level: rc['level'],
                        grade: rc['grade'],
                        grade: rc['star']
                      });  
      if (i<50)
      {
        store_grid.add( { date: rc['date'],
                        seller: rc['seller'],
                        buyer: rc['buyer'],
                        tid: rc['tid'],
                        name: rc['name'],
                        count: rc['count'],
                        price: rc['price'],
                        time: rc['time'],
                        level: rc['level'],
                        grade: rc['grade'],
                        grade: rc['star']});  
        
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