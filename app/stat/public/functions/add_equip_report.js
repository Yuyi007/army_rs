Ext.application({
  name: 'levelcampaignreport',
  launch: onLaunch
});

var g_search_name = '';

var map_sys = {
  finish_quest_campaign: '主线任务副本',
  enemy_drop_quest: '主线任务怪掉落',
  mq_drop: '主线任务',
  finish_robber_campaign: '千面银狐副本',
  enemy_drop_robber: '千面银狐怪掉落',
  finish_shadow_cam: '暗影副本',
  enemy_drop_shadow: '暗影怪掉落',
  finish_shadow_advance_cam: '精英暗影副本',
  enemy_drop_shadow_advance: '精英暗影怪掉落',
  finish_boss_cam: '首领副本',
  enemy_drop_leader: '首领怪掉落',
  bq_drop_chapterevent: '章节事件掉落',
  first_recharge: '首冲奖励',
  item_drop: '礼包掉落',
}

function onLaunch()
{
	var fields = ['date', 'zone_id', 'reason', 'grade', 'star', 'suits', 'scarces', 'normals'];
  var columns = [ { text: '日期',  dataIndex: 'date'},
                  { text: '区',  dataIndex: 'zone_id' },
                  { text: '来源',  dataIndex: 'reason' },
                  { text: '品级',  dataIndex: 'grade' },
                  { text: '星级',  dataIndex: 'star' },
                  { text: '套装数量',  dataIndex: 'suits' },
                  { text: '稀有数量',  dataIndex: 'scarces' },
                  { text: '过渡数量',  dataIndex: 'normals' }];

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
  var store_grade = Ext.create('Ext.data.Store', {
                                                  fields: ['gname', 'grade'],
                                                  data : [{gname: '绿', grade: 1},
                                                          {gname: '蓝', grade: 2},
                                                          {gname: '紫', grade: 3},
                                                          {gname: '橙', grade: 4}]
                                              });   



  var grade_input = Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_grade'), //品级
                                  editable: false,
                                  store: store_grade,
                                  valueField: 'grade',
                                  displayField: 'gname',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_grade'),
                                  selectOnFocus:true,
                                  width:235
                            });

   var store_star = Ext.create('Ext.data.Store', {
                                                  fields: ['sname', 'star'],
                                                  data : [{sname: '1', star: 1},
                                                          {sname: '2', star: 2},
                                                          {sname: '3', star: 3},
                                                          {sname: '4', star: 4}]
                                              });   



  var star_input = Ext.create('Ext.form.ComboBox', {
                                  fieldLabel: loc('str_star'), //星级
                                  editable: false,
                                  store: store_star,
                                  valueField: 'star',
                                  displayField: 'sname',
                                  typeAhead: true,
                                  queryMode: 'local',
                                  emptyText:loc('str_plz_select_star'),
                                  selectOnFocus:true,
                                  width:235
                            });

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

    var grade = grade_input.getValue();
    if(!grade) 
    {
      alert(loc('str_plz_select_grade')); 
      return;
    }

    var star = star_input.getValue();
    if(!star) 
    {
      alert(loc('str_plz_select_star')); 
      return;
    }

    g_search_name = zone_input.getRawValue() + "_" + date_input.getRawValue() + "_" + grade_input.getRawValue()+ "_" + star_input.getRawValue()+ "装备掉落打造统计";

    ajaxCall({ 
        'url'   : '/statshelper/get_add_equip_report',
        'params': {zone_id: zone_id, date: date, grade: grade, star: star},
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
      var reason = map_sys[rc['reason']];
      if(!reason){ reason = rc['reason']; };
      store_grid.add( { date: rc['date'],
                        zone_id: rc['zone_id'],
                        reason: reason,
                        grade: rc['grade'],
                        star: rc['star'],
                        suits: rc['suits'],
                        scarces: rc['scarces'],
                        normals: rc['normals']
                      });  
    }
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
      date_input,
      grade_input,
      star_input,
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