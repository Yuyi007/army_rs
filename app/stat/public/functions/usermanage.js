Ext.application({
  name: 'usermanage',
  launch: onLaunch
});

var g_store;
var g_list;
function onLaunch()
{
  Ext.define("User", {
    extend: 'Ext.data.Model',
    fields: [
              {name: 'id', type: 'int'},
              {name: 'email', type: 'string'}, 
              {name: 'role', type: 'string'},
              {name: 'inuse', type: 'string'}
            ],

  });

  g_store =  Ext.create('Ext.data.Store', 
                        {
                          storeId:'usersStore',
                          autoDestroy: true,
                          model: "User",
                          proxy: {
                              type: 'memory'
                          },
                          sorters: [{
                               property: 'id',
                               direction: 'ASC'
                           }],
                        });

  g_list = Ext.create('Ext.grid.Panel', 
                      { title: loc('str_user_manage'),
                        store: Ext.data.StoreManager.lookup('usersStore'),
                        columns:  [
                                    { text: loc('str_id'),  dataIndex: 'id', width: 50 },
                                    { text: loc('str_email'),  dataIndex: 'email', flex: 1},
                                    { text: loc('str_role'), dataIndex: 'role', width: 150},
                                    { text: loc('str_inuse'), dataIndex: 'inuse', width: 100},
                                    { xtype: 'actioncolumn', sortable: false, menuDisabled: true,
                                      text: loc('str_switch_inuse'),
                                      items: [{
                                          icon: '/images/accept.png',
                                          tooltip: loc('str_switch_inuse'),
                                          scope: this,
                                          handler: onActiveClick
                                      }]},
                                    { xtype: 'actioncolumn', sortable: false, menuDisabled: true,
                                      text: loc('str_modify_user_role'), 
                                      items: [{
                                          icon: '/images/add.gif',
                                          tooltip: loc('str_modify_user_role'),
                                          handler: onModifyClick
                                      }]}
                                  ],
                        height: '100%',
                        width: '100%',
                        renderTo: Ext.getBody()
                    });
  new Ext.Viewport({
    layout: 'fit',
    width: '100%',
    height: '100%',
    items: [g_list]
  });
  rpcGetUserList();
} 

function rpcGetUserList()
{
  ajaxCall({
      'url'   : '/users/user_list',
      'method': 'POST',
      'onSuccess': function(res){
                    res = res.res
                    for (var i = res.length - 1; i >= 0; i--) 
                    {
                      var rc = res[i];
                      var inuse = loc("no");
                      if (rc.inuse) 
                        inuse = loc("yes");

                      g_store.add({id: rc.id, email: rc.email, role: rc.role, inuse: inuse});
                    };
                  },
    }); 
}

function onActiveClick(grid, rowIndex)
{
  var rc = g_store.getAt(rowIndex);
  var inuse = rc.get('inuse');
  var id = rc.get('id');
  if(id == 0) 
    return;

  if (inuse==loc('yes')) 
    inuse = 1
  else
    inuse = 0

  ajaxCall({
      'url'   : '/users/enable_account',
      'method': 'POST',
      'params': {id: id, inuse: inuse},
      'onSuccess': function(res){
                    g_store.removeAll();
                    rpcGetUserList();
                  },
    }); 
}

function onModifyClick(grid, rowIndex)
{
  var rc = g_store.getAt(rowIndex);
  var role = rc.get('role');
  var uid = rc.get('id');
  window.location.href = BASE_URL + "/users/change_role?uid="+uid+"&role="+role;
}