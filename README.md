RS 
===


==============================================

* Website:

Environment Variables
---------------------
add these environment variables in your ~/.bash_profile:

```bash
export RS_ART=$WORK/art
export RS_DESIGN=$WORK/design
export RC=$WORK/rs/client/scripts
export RS=$WORK/rs

alias rc="cd $RC"
alias rs="cd $RS"
alias ra="cd $ART"
alias rd="cd $DESIGN"

export UNITY="/Applications/Unity/Unity.app/Contents/MacOS/Unity"
```

Modify .git/config
---------------------

```bash
[core]
  autocrlf = false
  precomposeunicode = false
```

Coding Conventions
------------------

- Indentation:
  - c#: 4 spaces
  - ruby, lua: 2 spaces

- Space usage:
  * one space between arithmetics and operators
    + local a = 1 + 2
    + local b = { test = 1 }
  * one space between comment indicator and the actual comment string
    + # This is a comment

- string:
  - ruby and lua, always prefer 'string'; use "string #{var}" only when doing string interpolation


Ruby :
-------------------

- snake_case names for variables, methods and files
- PascalCase names for classes
- 2 spaces for identation

```Ruby
# my_class.rb

class MyClass
  attr_accessor :my_variable

  def sample_method_with_args(arg1, arg2)
    puts 'my_method' + ' called'
  end

  def method_no_args
    puts 'method2 called'
  end

  def call_methods
    # use brackets when argument(s) supplied
    sample_method_with_args(1, 2)

    # do not use brackets
    method_no_args
  end

end
```



C#:
---

- camelCase for member variables
- PascalCase case names for classes, methods, getter/setters, delegates and files
- open curly-bracket on the next line
- 4 spaces for identation
- For monodevelop, set the coding format default to ms visual studio style

```C#
// MyClass.cs

class MyClass
{
    private int x;
    private string name;
    public string Name { get { return name; } }
    public delegate void MyDelelgate;
    public MyDelegate oneDelegate;

    public void SetName(string name)
    {
        this.name = name;
    }
}
```

Lua:
----

- camelCase names for variables, methods,
- PascalCase for classes and files
- 2 spaces for identation

```Lua
-- MyClass.lua

class('MyClass', function(self)
  self.myVariable = 'variable'
end)

function MyClass:myMethod(arg1, arg2)
  print('myMethod' .. ' called')
end
```

Json:
----

The protocol json string used for client-server communication should be
coded with ruby coding conventions


