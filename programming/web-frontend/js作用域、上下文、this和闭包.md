# 词法作用域lexical scope

定义在词法阶段的作用域。词法作用域是变量和语句块在**定义时所处的位置**决定的。

- 全局

- 块级

  在`{}`之内是一个块级作用域（ES6之前没有块级作用于只有函数内的局部作用域）

- eval
  - 直接调用时：eval内代码块的作用域绑定到**当前**作用域。
  - 间接调用时：eval内代码块的作用域绑定到**全局**作用域。
  
  

# 执行上下文execution context

当前代码执行时的环境。（执行上下文和执行环境只是两种不同的翻译称呼）

执行环境可分为：全局环境、函数环境和Eval。

解释器初始化时首先默认进入全局环境，后续函数的调用（即便是函数递归调用自身）都创建并进入一个新的函数执行环境。

> 这些执行上下文会构成了一个执行上下文栈（Execution context stack，ECS）。栈底永远都是全局上下文，而栈顶就是当前正在执行的上下文。



代码执行时，当前的作用域会被存储到执行环境中。

# this

## 函数调用的形式

- 函数调用：`fn()`（函数声明）

- 方法调用：`obj.fn()`

  注：方法也是函数，只是将函数以**对象的属性方式来调用**时，一般称其为方法；一般将定义的全局范围的函数称作函数（在浏览器中，自定义的函数其实也是window对象的方法，可以用windows.xx()来调用）

- 构造函数的constractor方法调用

  ```javascript
  function fn(){
      constrctor(){
          this.demo()  //实例化对象时将被调用
      }
      demo(){
          //some codes
      }
  }
  new fn()
  ```

- call/apply调用

  - `fn.call(context,param1,param2...)`（call需要列出所有参数）
  - `fn.apply(context,[arguments|array])`（apply参数是数组形式或arguments时）

  call/apply与bind：

  > bind()会**创建一个新的函数**

  也就是**call()和aplly()方法会直接执行，而bind需要再调用一次**，因此如果调用bind()方法还需加上`()`调用：`fn.bind(context,param)()`

  bind的参数可以逐个列出，也可以使用数组或arguments。

  

各种情况下的this指向
---

（目前）**除箭头函数外，this的指向只有在函数执行的时候才能确定，this指向当前执行上下文中保存的作用域。**

箭头函数中的`this`**总是**指向**词法作用域**（在函数声明就确定了下来），也就是外层调用者，**call/apply/bind也无法对其进行更改**(传入的第一个参数会被忽略)。

参看[MDN-this](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Operators/this)

- 定义时就能确定
  - 箭头函数中的this：函数定义时所处的对象
  - async函数中的this：函数定义时所处的对象
  - 显式地设置this：call/apply/bind方法的第一个参数
  - ajax回调方法中的this : XMLHttpRequest对象


- 执行时才能确定——指向调用它的对象

  注：浏览器全局对象this是window，而node中是global，严格模式下则是undefined。

  - 全局范围内使用 -- 全局对象
  - 函数调用 -- 全局对象
  - 方法调用 -- 方法所属的对象
  - 调用构造函数 -- 新创建的实例对象

  **如果call和apply的第一个参数写的是null，那么this指向的是全局对象。**

  **每个函数其实都包含着apply/call方法**，this的指向即是该方法的第一个参数——调用时的执行环境（context）。

  省略call/apply的写法实际相当于默认将函数前面对象作为ap是ply/call的第一参数传入：

  - `obj.fn()`相当于`obj.fn.call(obj)`，this也就指向obj；
  - `fn()`相当于`fn.call(undefined)`，this也就指向undefined，非严格模式下浏览器就会给出默认的this——window来代替undefined，于是`fn()`中的this也就是window。

  ---

  以全局对象为window的示例：

```javascript
let goo={};
goo.method = function() {
    console.log(this);
    function test() {
        console.log(this);
    }
    test();//函数直接调用
    test.apply(this);//指定test的作用域
}
goo.method();//会依次打印 goo window goo
let temp=goo.method;//goo.method并没有执行，只是赋给temp
temp();//window window window   | 相当于window.temp
temp.call(goo);//goo window goo
```

构造函数中的this与return：如果return值类型和null，那么对构造函数没有影响，实例化对象返回空对象；如果return引用类型（数组，函数，对象——除了null），那么实例化对象就会返回该引用类型。

```javascript
function fn() {
    this.user = "who";
    let obj = new Object;
    return obj;//如果return非对象或null,新实例对象的user依然是who
}
let a = new fn;
console.log(a.user);//undefined
```

×附：bind、call、apply区别

call传给函数的参数（第一个参数之后的参数）需要逐一**列出**：`fn.call(that,arg1,arg2,arg3)`

apply第二个参数是一个**数组**：`fn.apply(that,[arg1,arg2,arg3])`

bind方法**返回**的是一个修改过后的**函数**，call、apply返回的是函数执行的结果。因此使用是以一个变量接受bind返回的“新函数”，然后在调用这个变量；或者添加`()`使其执行

```javascript
fn.bind(that,arg1,arg2);      //并不会执行fn方法 因为返回的是函数
fn.bind(that,arg1,arg2)();    //这样就能执行新函数了
//或者
var test=fn.bind(that,arg1,arg2);    //用新变量接收bind返回的函数
test();   //现在调用就会执行了
```

# 闭包closure

> **闭包**（Closure），又称**词法闭包**（Lexical Closure）或**函数闭包**（function closures），是**引用了自由变量的函数。**

```javascript
 function A(){
    let hello="Hello Closure!"
    function B(){
       console.log(hello);
    }
    return B;
}
var c = A();
c();//Hello Closure!
```

​	函数内部定义了一个函数，然后这个函数调用到了父函数内的相关变量，相关父级变量就会存入闭包作用域里面。

- 闭包特点
  - 函数嵌套函数
  - 函数内部可以引用外部的参数和变量
  - 参数和变量不会被垃圾回收机制回收
- 闭包作用
  - 希望这个变量常驻在内存中
  - 避免“污染”全局的变量
  - 作为私有成员存在

 javascript中的垃圾回收(GC)机制：

> 如果一个对象不再被引用，那么这个对象就会被GC回收。
>
> 如果两个对象互相引用，而不再被第三者所引用，那么这两个互相引用的对象也会被回收。

- 闭包应用
  1. setTimeout/setInterval
  2. 回调函数（callback）
  3. 事件句柄（event handle）
  4. 模块化开发

- 闭包相关问题解决

  - 循环闭包中需要用到计数器

    - 使用let代替var
    - 使用匿名自执行函数（立即执行函数）

    ```javascript
    for(var i=1;i<3;i++){
        (function(i){
            //some codes need use i
        })(i)
    }
    ```