Ext.application({
  name: 'regist',
  launch: onLaunch
});

var form;
function onLaunch()
{
  Ext.tip.QuickTipManager.init();
  verifyNamePwd();

  form = Ext.create('Ext.form.Panel', {
    renderTo: Ext.getBody(),
    title: loc('str_regist'),
    layout: 'absolute',
    height: 280,
    width: 350,
    bodyPadding: 10,
    defaultType: 'textfield',
    items: [
        {
          xtype: 'label',
          style: 'color: #000; font-weight: bold; font-size: 11px',
          text: loc('str_email'),
          x: 30,
          y: 35,
        },
        {
          name: 'email',
          x: 150,
          y: 30,
          width: 170,
          style: 'font-size: 20px',
          autoHeight: true,
          allowBlank: false,
          vtype: 'email',
        },
        {
          xtype: 'label',
          style: 'color: #000; font-weight: bold; font-size: 11px',
          text: loc('str_password'),
          x: 30,
          y: 80,
        },
        {
          name: 'pass',
          x: 150,
          y: 75,
          width: 170,
          style: 'font-size: 20px',
          autoHeight: true,
          inputType: 'password',
          allowBlank: false,
          vtype: 'password'
        },
        {
          xtype: 'label',
          style: 'color: #000; font-weight: bold; font-size: 11px',
          text: loc('str_confirm_password'),
          x: 30,
          y:125,
        },
        {
          name: 'passconfirm',
          x: 150,
          y: 120,
          width: 170,
          style: 'font-size: 20px',
          autoHeight: true,
          allowBlank: false,
          inputType: 'password',
          vtype: 'passwordconfirm',
        },
        {
          xtype: 'button',
          name: 'regist',
          text: loc('str_regist'),
          width: 80,
          x: 150,
          y: 205,
          formBind: true,
          handler: onBtnRegist
        }
    ]
});
form.center();
}

function isEmail(str){
       var reg = /^([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+((\.[a-zA-Z0-9_-]{2,3}){1,2})$/;
       return reg.test(str);
}

function verifyNamePwd()
{
   Ext.apply(Ext.form.field.VTypes, {
    email: function(val, field)
    {
      return isEmail(val)
    },
    emailText: loc('err_email_format'),
    password: function(val, field)
    {
      return val.length >= 6
    },
    passwordText: 'Password length must grater than 6!',
    passwordconfirm: function(val, field)
    {
      var values = form.getValues()
      var pass = values['pass']
      if(val != pass)
        return false
      return true;
    },
    passwordconfirmText: 'Confirm password must same with orign password!',
   });
}

function onBtnRegist()
{
  if(!form.isValid()) return;

  var values = form.getValues();
  ajaxCall({
    'url'   : '/users/do_regist',
    'method': 'POST',
    'params': {email: values['email'],
              password: values['pass']},
    'onSuccess': function(res){
                alert('Regist success, now you can login.')
                window.location.href = BASE_URL + "/users/login";
              },
  })
}

