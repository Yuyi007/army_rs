Ext.application({
  name: 'guild_level_record',
  launch: onLaunch
});

var g_search_name = '';


function onLaunch()
{
  var fields = ['record_date'
              , 'zone'
              , 'level_1'
              , 'level_1_person'
              , 'level_2'
              , 'level_2_person'
              , 'level_3'
              , 'level_3_person'
              , 'level_4'
              , 'level_4_person'
              , 'level_5'
              , 'level_5_person'
              , 'level_6'
              , 'level_6_person'
              , 'level_7'
              , 'level_7_person'
              , 'level_8'
              , 'level_8_person'
              , 'level_9'
              , 'level_9_person'
              , 'level_10'
              , 'level_10_person'
              , 'level_11_15'
              , 'level_11_15_person'
              , 'level_16_20'
              , 'level_16_20_person'
              , 'level_21_25'
              , 'level_21_25_person'
              , 'level_26_30'
              , 'level_26_30_person'
              , 'level_over_30'
              , 'level_over_30_person'
              ];

  var save_store = Ext.create('Ext.data.Store', { fields: fields});
  var store_grid = Ext.create('Ext.data.Store', { fields: fields});

  var columns = [ { text: '日期',  dataIndex: 'record_date'},
                  { text: '选区',  dataIndex: 'zone'},
                  { text: '1级工会',  dataIndex: 'level_1'},
                  { text: '1级工会人数',  dataIndex: 'level_1_person'},
                  { text: '2级工会',  dataIndex: 'level_2'},
                  { text: '2级工会人数',  dataIndex: 'level_2_person'},
                  { text: '3级工会',  dataIndex: 'level_3'},
                  { text: '3级工会人数',  dataIndex: 'level_3_person'},
                  { text: '4级工会',  dataIndex: 'level_4'},
                  { text: '4级工会人数',  dataIndex: 'level_4_person'},
                  { text: '5级工会',  dataIndex: 'level_5'},
                  { text: '5级工会人数',  dataIndex: 'level_5_person'},
                  { text: '6级工会',  dataIndex: 'level_6'},
                  { text: '6级工会人数',  dataIndex: 'level_6_person'},
                  { text: '7级工会',  dataIndex: 'level_7'},
                  { text: '7级工会人数',  dataIndex: 'level_7_person'},
                  { text: '8级工会',  dataIndex: 'level_8'},
                  { text: '8级工会人数',  dataIndex: 'level_8_person'},
                  { text: '9级工会',  dataIndex: 'level_9'},
                  { text: '9级工会人数',  dataIndex: 'level_9_person'},
                  { text: '10级工会',  dataIndex: 'level_10'},
                  { text: '10级工会',  dataIndex: 'level_10_person'},
                  { text: '11-15级工会',  dataIndex: 'level_11_15'},
                  { text: '11-15级工会人数',  dataIndex: 'level_11_15_person'},
                  { text: '16-20级工会',  dataIndex: 'level_16_20'},
                  { text: '16-20级工会人数',  dataIndex: 'level_16_20_person'},
                  { text: '21-25级工会',  dataIndex: 'level_21_25'},
                  { text: '21-25级工会人数',  dataIndex: 'level_21_25_person'},
                  { text: '26-30级工会',  dataIndex: 'level_26_30'},
                  { text: '26-30级工会人数',  dataIndex: 'level_26_30_person'},
                  { text: '30级以上工会',  dataIndex: 'level_over_30'},
                  { text: '30级以上工会人数',  dataIndex: 'level_over_30_person'},

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

    g_search_name = zone_input.getRawValue() + "_" + date_start.getRawValue() + "_" + date_end.getRawValue()+"工会人数等级分布";
    // alert(g_search_name);
    ajaxCall({
            'url'   : '/statshelper/get_guild_level_record',
            'params': {start_date: start_date, end_date: end_date, zone_id: zone_id},
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