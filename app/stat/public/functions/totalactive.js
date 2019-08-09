Ext.application({
  name: 'totalactivereport',
  launch: onLaunch
});

function onLaunch()
{
  var store = Ext.create('Ext.data.Store', {
    storeId:'total_active_store',
    fields: ['counts_user', 'counts_account'],
  });

  var data_grid = Ext.create('Ext.grid.Panel', {
      title: '',
      store: store,
      columns: [{ text: '当周活跃用户数量',  dataIndex: 'counts_user'},
                { text: '当周活跃账户数量',  dataIndex: 'counts_account'}
                ],
      forceFit: true,
      width: 200,
      height: "100%",
  });

  var date_input =  Ext.create('Ext.form.field.Date', {
                    name      : 'query_date',
                    fieldLabel: loc('str_date'),
                    allowBlank: false,
                    editable: false
                  });

  var btn_query = { xtype: 'button', 
                  icon: '/images/search.png',
                  // width: 200,
                  text: loc('str_query'), //查询
                  handler : onBtnQuery};


  new Ext.Viewport({
                      layout: 'border',
                      width: '100%',
                      height: '100%',
                      items: [{
     region: "north",
     xtype: "toolbar",
     height: 30,
     items: [
      date_input,
      btn_query
     ] 
    },{
      region: 'center',
      xtype: 'panel',
      weight:20,
      items:[data_grid]
    }]
    }); 


  function onBtnQuery()
  { 
    var date = date_input.getValue();
    if(!date)
    {
      alert(loc('str_plz_select_date')); //请选择日期
      return;
    }

    ajaxCall({ 
            'url'   : '/statsorign/get_total_active',
            'params': {date: date},
            'onSuccess': function(res){
                        store.removeAll();
                        var counts_user = res.counts_user;
                        var counts_account = res.counts_account;
                        store.add({counts_user: counts_user, counts_account: counts_account});
                    }}

          );
  }

}