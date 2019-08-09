
Ext.application({
  name: 'rolemanage',
  launch: onLaunch
});

var g_list_store;
var g_list;
var g_row_editing;
function onLaunch()
{
  Ext.define("Role", {
    extend: 'Ext.data.Model',
    fields: [
              {name: 'id', type: 'int'},
              {name: 'name', type: 'string'}, 
              {name: 'desc', type: 'string'}
            ],
    validations: [
              {type: 'length', field: 'name', max: 64},
              {type: 'length', field: 'desc', max: 255},
            ]
  })

  g_list_store = Ext.create('Ext.data.Store', {
                            storeId:'rolesStore',
                            autoDestroy: true,
                            model: "Role",
                            proxy: {
                                type: 'memory'
                            },
                            sorters: [{
                                 property: 'id',
                                 direction: 'ASC'
                             }],
                        });
  g_row_editing = Ext.create('Ext.grid.plugin.RowEditing', {
        clicksToMoveEditor: 1
    });

  g_list = Ext.create('Ext.grid.Panel', {
                      title: loc('str_role_manage'),
                      store: Ext.data.StoreManager.lookup('rolesStore'),
                      columns:  [
                                  { text: loc('str_id'),  dataIndex: 'id', width: 50 },
                                  { text: loc('str_name'),  dataIndex: 'name', width: 150, editor: { allowBlank: false} },
                                  { text: loc('str_description'), dataIndex: 'desc', flex: 1, editor: { allowBlank: false}},
                                  { xtype: 'actioncolumn', width: 64, sortable: false, menuDisabled: true,
                                            text: loc('delete'),
                                            items: [{
                                                icon: '/images/delete.gif',
                                                tooltip: loc('str_remove_role'),
                                                scope: this,
                                                handler: onRemoveClick
                                            }]},
                                  { xtype: 'actioncolumn', width: 64, sortable: false, menuDisabled: true,
                                            text: loc('modify'),
                                            items: [{
                                                text: 'Modify',
                                                icon: '/images/edit.png',
                                                tooltip: loc('str_tip_modify_role'),
                                                handler: onModifyClick
                                            }]}
                                ],
                      width: '100%',
                      height: '100%',
                      margins: '2 2 2 2',
                      // renderTo: Ext.getBody(),
                      dockedItems: [{
                                        xtype: 'toolbar',
                                        dock: 'top',
                                        items: [{ xtype: 'button', 
                                                icon: '/images/add.png',
                                                text: loc('str_add_new_role'),
                                                handler : onBtnAddRow}]
                                    }],
                      plugins: [g_row_editing]
                  });
  
  g_list.on('edit', onUpdateClick);
  
  new Ext.Viewport({
    layout: 'fit',
    width: '100%',
    height: '100%',
    items: [g_list]
  });


  rpcGetRoles();
}

function onModifyClick(grid, rowIndex)
{
  var rc = g_list_store.getAt(rowIndex);
  var id = rc.get('id');
  if(id == 0) 
    return;

  window.location.href = BASE_URL + "/users/right_manage?id="+id;
}

function onUpdateClick(editor, e)
{
  var rc = e.record;
  var id = rc.get("id");
  var name = rc.get("name");
  var desc = rc.get("desc");

  ajaxCall({
      'url'   : '/users/save_role',
      'params' : {id: id, name: name, desc: desc},
      'onSuccess': function(res){
                    _list_store.removeAll();
                    rpcGetRoles();
                    Ext.Msg.alert(loc('alert'), loc('str_save_success'));
                  },
    });
}

function onRemoveClick(grid, rowIndex)
{
  Ext.Msg.show({ title: loc('alert'),
                 msg: loc('str_remove_alert'),
                 buttons: Ext.Msg.OKCANCEL,
                 icon: Ext.Msg.QUESTION,
                 fn: function(btn, text){
                  if (btn == 'ok')
                  {
                      var rc = g_list_store.getAt(rowIndex);
                      var id = rc.get('id');

                       ajaxCall({
                                  'url'   : '/users/remove_role',
                                  'params' : {id: id},
                                  'onSuccess': function(res){
                                                g_list_store.removeAll();
                                                rpcGetRoles();
                                              },
                                }); 

                  }
                }
              });
}


function onBtnAddRow()
{
  g_row_editing.cancelEdit();
  var r = Ext.create('Role', { id: 0, name: "name", desc: "desc"});
  g_list_store.insert(0, r);
  g_row_editing.startEdit(0, 0);
}

function rpcGetRoles()
{
  ajaxCall({
      'url'   : '/users/role_list',
      'method': 'POST',
      'onSuccess': function(res){
                  res = res.res
                  for (var i = res.length - 1; i >= 0; i--) 
                  {
                    var rc = res[i];
                    g_list_store.add({id: rc.id, name: rc.name, desc: rc.desc});

                  };
                },
    });

}

