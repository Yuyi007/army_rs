Ext.application({
  name: 'changerole',
  launch: onLaunch
});


function onLaunch()
{
  getAllRoles();
}

var g_comb;
var urlparam = getUrlParam();
var cur_uid = urlparam.uid;
var cur_role = urlparam.role;

function createViews(data, curid)
{
  var store = Ext.create('Ext.data.Store', {
      fields: ['id', 'name'],
      data : data
  });

  g_comb = Ext.create('Ext.form.ComboBox', {
            fieldLabel: loc('str_select_role'),
            store: store,
            width: 300,
            queryMode: 'local',
            displayField: 'name',
            valueField: 'id'
        });
  var form = Ext.create('Ext.form.Panel', {
        title: loc('str_role_manage'),
        frame: true,
        defaults: {bodyStyle: "background-color: #FFFFFF;", frame: false},
        bodyPadding: 10,
        renderTo: Ext.getBody(),
        width: 400,
        height: 150,
        items: [ g_comb,
                {
                  xtype: 'button',
                  name: 'save',
                  text: loc('str_save'),
                  width: 80,
                  y: 50,
                  x: 60,
                  formBind: true,
                  handler: onBtnSave
                },
                {
                  xtype: 'button',
                  name: 'cancel',
                  text: loc('str_cancel'),
                  x: 150,
                  y: 50,
                  width: 80,
                  formBind: true,
                  handler: onBtnCancel
                }]
        });

  g_comb.select(curid);
}

function getAllRoles()
{
  ajaxCall({
      'url'   : '/users/role_list',
      'onSuccess': function(res){
                  res = res.res
                  var curid = 0;
                  var data = new Array();
                  for (var i = res.length - 1; i >= 0; i--) 
                  {
                    var rc = res[i];
                    data.push({"id": rc.id, "name": rc.name});
                    if (rc.name == cur_role) 
                      curid = rc.id;
                  };

                  createViews(data, curid);
                },
    });
}

function onBtnSave()
{
  var roleid = g_comb.getValue();
  ajaxCall({
      'url'   : '/users/do_change_role',
      'params': {uid: cur_uid, roleid: roleid},
      'onSuccess': function(res){
                  Ext.Msg.alert(loc('alert'), loc('str_save_success'));
                  window.location.href = BASE_URL + "/users/user_manage";
                },
    });
}

function onBtnCancel()
{
  window.location.href = BASE_URL+"/views/user_manage.html";
}
