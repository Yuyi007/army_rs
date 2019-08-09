Ext.application({
  name: 'levelconsume',
  launch: onLaunch
});


var g_store_consume;
var g_store_players;
var g_chart_consume;
var g_chart_plauers;

var g_const_type;
var g_sys_name;

function generateData (n, floor){
        var data = [],
            p = (Math.random() *  11) + 1,
            i;
            
        floor = (!floor && floor !== 0)? 20 : floor;
        
        for (i = 0; i < (n || 12); i++) {
            data.push({
                name: 'lv'+i,
                data: Math.floor(Math.max((Math.random() * 100), floor))
            });
        }
        return data;
    };

function onLaunch()
{
  var ids = ['v-1','v-2','v-3','v-4','v-5','v-6','v-7','v-8','v-9',
              'v-10','v-11','v-12','v-13','v-14','v-15','v-16','v-17','v-18',];
  var colors = []
  var gradients = []
  for(var i =1; i < ids.length; i++)
  {
    var id = ids[i];
    colors.push('url(#' + id + ')');
    var r1 = Math.floor( Math.random() * 255)
    var g1 = Math.floor( Math.random() * 255)
    var b1 = Math.floor( Math.random() * 255)
    var r2 = Math.floor( Math.random() * 255)
    var g2 = Math.floor( Math.random() * 255)
    var b2 = Math.floor( Math.random() * 255)
    gradients.push({  
                      'id': id,
                      'angle': 0,
                      stops: {  
                                0: {color: 'rgb('+r1+', '+g1+', '+b1+')'},
                                100: {color: 'rgb('+r2+', '+g2+', '+b2+')'}
                              }
                    });
  }
  
  var baseColor = '#000';

  Ext.define('Ext.chart.theme.Fancy', {
        extend: 'Ext.chart.theme.Base',
        
        constructor: function(config) {
            this.callParent([Ext.apply({
                axis: {
                    stroke: baseColor
                },
                axisLabelLeft: {
                    fill: baseColor
                },
                axisLabelBottom: {
                    fill: baseColor
                },
                axisTitleLeft: {
                    fill: baseColor
                },
                axisTitleBottom: {
                    fill: baseColor
                },
                colors: colors
            }, config)]);
        }
    });


  g_store_consume = Ext.create('Ext.data.JsonStore',{
    fields: ['name', 'data'],
    // data: generateData(18, 0)
  })
  g_store_players = Ext.create('Ext.data.JsonStore',{
    fields: ['name', 'data'],
    // data: generateData(18, 0)
  })

  g_chart_consume = Ext.create('Ext.chart.Chart', {
      theme: 'Fancy',
      height: 350,
      width: 1000,
      animate: {
                easing: 'bounceOut',
                duration: 750
            },
      store: g_store_consume,
      // background: { fill: 'rgb(17, 17, 17)'},
      gradients: gradients,
      axes: [{
                type: 'Numeric',
                position: 'left',
                fields: ['data'],
                minimum: 0,
                label: {
                    renderer: Ext.util.Format.numberRenderer('0,0')
                },
                title: '消费',
                grid: {
                    odd: {
                        stroke: '#555'
                    },
                    even: {
                        stroke: '#555'
                    }
                }
            }, {
                type: 'Category',
                position: 'bottom',
                fields: ['name'],
                title: '等级段'
            }],
      series: [{
              type: 'column',
              axis: 'left',
              highlight: true,
              label: {
                display: 'insideEnd',
                'text-anchor': 'middle',
                  field: 'data',
                  orientation: 'horizontal',
                  fill: '#fff',
                  font: '17px Arial'
              },
              renderer: function(sprite, storeItem, barAttr, i, store) {
                  barAttr.fill = colors[i % colors.length];
                  return barAttr;
              },
              style: {
                  opacity: 0.95
              },
              xField: 'name',
              yField: 'data'
          }]
  });

  g_chart_players = Ext.create('Ext.chart.Chart', {
      theme: 'Fancy',
      height: 350,
      width: 1000,
      animate: {
                easing: 'bounceOut',
                duration: 750
            },
      store: g_store_players,
      // background: { fill: 'rgb(17, 17, 17)'},
      gradients: gradients,
      axes: [{
                type: 'Numeric',
                position: 'left',
                fields: ['data'],
                minimum: 0,
                label: {
                    renderer: Ext.util.Format.numberRenderer('0,0')
                },
                title: '人数',
                grid: {
                    odd: {
                        stroke: '#555'
                    },
                    even: {
                        stroke: '#555'
                    }
                }
            }, {
                type: 'Category',
                position: 'bottom',
                fields: ['name'],
                title: '等级段'
            }],
      series: [{
              type: 'column',
              axis: 'left',
              highlight: true,
              label: {
                display: 'insideEnd',
                'text-anchor': 'middle',
                  field: 'data',
                  orientation: 'horizontal',
                  fill: '#fff',
                  font: '17px Arial'
              },
              renderer: function(sprite, storeItem, barAttr, i, store) {
                  barAttr.fill = colors[i % colors.length];
                  return barAttr;
              },
              style: {
                  opacity: 0.95
              },
              xField: 'name',
              yField: 'data'
          }]
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

  var date_input =  Ext.create('Ext.form.field.Date', {
                      name      : 'query_date',
                      fieldLabel: loc('str_date'),
                      allowBlank: false,
                      editable: false
                    });

  var store_cat = Ext.create('Ext.data.Store', {
                                                  fields: ['catname', 'category'],
                                                  data : [{catname: loc('str_credits'), category: 'credits'},
                                                          {catname: loc('str_money'), category: 'money'},
                                                          {catname: loc('str_coins'), category: 'coins'},
                                                          {catname: loc('str_voucher'), category: 'voucher'}]
                                              });   

  var systems = {credits: ['复活', '商城', '打车', '兑换硬币', '兑换纸币'],

                 coins: ['健康饮食', '嘟嘟打车', '地铁','长途','医院',
                          '强身健体', '装备合魂', '装备打造','天赋升级', '装备商店',
                          '礼物商店', '药品商店','食物商店','灵符篆刻',
                          '四象觉醒', '宝石商店','灵符商店', '背包空间','银行空间'],

                 money: ['兑换硬币', '交易行','商城限购'],

                 voucher: ['商城免费']};

  var cat_input = {
        xtype: 'combobox',
        fieldLabel: loc('str_huobi_cat'), //货币类型
        editable: false,
        store: store_cat,
        valueField: 'category',
        displayField: 'catname',
        typeAhead: true,
        queryMode: 'local',
        // triggerAction: 'all',
        emptyText:loc('str_plz_select_category'),
        selectOnFocus:true,
        width:235,
        listeners:{select: onSelectCategory }
  }

  var store_sys = Ext.create('Ext.data.Store', { fields: ['sysname', 'syscat'] });    

  function onSelectCategory(combo, records, eOpts)
  {
    var rc = records[0];
    var cat = rc.data.category;
    g_const_type = cat;

    store_sys.removeAll();
    sys_input.reset();

    var all_sys = systems[cat];
    for (var i = 0; i < all_sys.length; i++)
    {
      var syscat = all_sys[i];
      var sysname = all_sys[i];
      store_sys.add({sysname: sysname, syscat: syscat});
    }
  };

  var sys_input = Ext.create('Ext.form.ComboBox', {
        fieldLabel: loc('str_sys_cat'), //系统类型：
        editable: false,
        store: store_sys,
        displayField: 'sysname',
        valueField: 'syscat',
        typeAhead: true,
        queryMode: 'local',
        triggerAction: 'all',
        emptyText:loc('str_plz_select_syscat'),
        selectOnFocus:true,
        width:235,
        listeners:{select: onSelectSystem }
    });

  function onSelectSystem(combo, records, eOpts)
  {
    var rc = records[0];
    var cat = rc.data.syscat;
    g_sys_name = cat;
  }

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

    if(!g_const_type) 
    {
      alert(loc('str_plz_select_category')); //请选择货币类型
      return;
    }

    if(!g_sys_name)
    {
      alert(loc('str_plz_select_syscat')); //请选择系统类型
      return;
    }

    var date = date_input.getValue();
    if(!date)
    {
      alert(loc('str_plz_select_date')); //请选择日期
      return;
    }

    ajaxCall({ 
        'url'   : '/statshelper/get_lv_consume',
        'params': {zone_id: zone_id, cost_type: g_const_type, sys_name: g_sys_name, date: date},
        'onSuccess': function(res){
            updateChart(res.res)
        }}
      );
  } 

  function updateChart(res)
  {
    g_store_consume.removeAll();
    g_store_players.removeAll();
    var lvs = ['10', '20', '25', '30', '35', '40',
              '45', '50', '55', '60', '65', '70',
              '75', '80', '85', '90', '95', '100'];
    for(var i=0; i<lvs.length; i++)
    {
      var col_name = lvs[i];
      for(var j = 0; j < res.length; j++)
      {
        var rc = res[j];
        var dm = rc.level_rgn / 10;
        if( dm > 2 )
          dm = 2 + (rc.level_rgn - 20) / 5
        if(dm == (i+1))
        {
          g_store_consume.add({name: "lv"+col_name, data: rc.consume});
          g_store_players.add({name: "lv"+col_name, data: rc.players});
        }
      }
    }
  }
                     
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
      sys_input,
      btn_query
     ] 
    }, 
    {
      region: 'center',
      xtype: 'panel',
      weight:20,
      items:[g_chart_consume, g_chart_players]
      
    }]
  });
}