Ext.application({
  name: 'login',
  launch: onLaunch
});

var form;
function onLaunch()
{
  Ext.tip.QuickTipManager.init();

  verifyNamePwd();

  form = Ext.create('Ext.form.Panel', {
    renderTo: Ext.getBody(),
    title: loc('str_login'),
    layout: 'absolute',
    height: 210,
    width: 300,
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
          x: 100,
          y: 30,
          width: 150,
          style: 'font-size: 20px',
          autoHeight: true,
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
          x: 100,
          y: 75,
          width: 150,
          style: 'font-size: 20px',
          autoHeight: true,
          inputType: 'password',
          vtype: 'password',
        },
        {
          xtype: 'button',
          name: 'login',
          text: loc('str_login'),
          width: 80,
          x: 180,
          y: 130,
          formBind: true,
          handler: onBtnLogin
        },
        {
          xtype: 'button',
          name: 'regist',
          text: loc('str_regist'),
          width: 80,
          x: 25,
          y: 130,
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
    passwordText: loc('str_passwore_length_err')
   });
}

function onLoginSuccess(res)
{ 
  Ext.util.Cookies.set('sessionid', res.sid); 
  Ext.util.Cookies.set('userid', res.uid); 
  
  window.location.href = BASE_URL + "/main/dashboard";
}

function onBtnLogin()
{
  if(form.isValid())
  {
    var values = form.getValues();
    ajaxCall({
      'url'   : '/users/do_login',
      'method': 'POST',
      'params': {email: values['email'],
                password: values['pass']},
      'onSuccess': onLoginSuccess,
    })
  }
}

function onBtnRegist()
{
  window.location.href = BASE_URL + "/users/regist"
}