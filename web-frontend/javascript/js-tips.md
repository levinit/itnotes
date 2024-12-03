# 函数和数据类型判断
- arguments是一个对象

  ```javascript
  (function() {
    return typeof arguments; //argument是一个对象（注意：arguments不是数组）
  })(); //object
  ```
- 不能函数表达式的函数名调用函数
  ```javascript
  let f = function g() { //函数表达式的函数名不能被调用
    return 23;
  };
  typeof g(); //reference error g() is not defined
  ```
- delete只能删除对象的属性
  ```javascript
  (function(x) {
    delete x; //delete只能删除对象的属性
    return x;
  })(1); // 1 
  ```
- 变量赋值
  ```javascript
  var y = 1,
    x = (y = typeof x); //赋值是从右往左赋值 不要这样写
  x; //"undefined"
  ```
- 匿名自执行函数的传参
  ```javascript
  (function f(f) {   //f=1
    return typeof f(); //type of 1
  })(function() {
    return 1;
  }); //"number"
  ```
- 函数的形参
  ```javascript
  var foo = {
    bar: function() {
      return this.baz;
    },
    baz: 1
  };
  (function() { //foo.bar成为一个整体传入 foo.bar是一个函数名
    return typeof arguments[0]();
  })(foo.bar); //"undefined" 传入foo才能得到对象本身 不应该传入函数名.属性
  ```
  ​
  ```javascript
  (function (foo) { //此处的foo是一个形参 foo= {foo:{bar:1}}
    return typeof foo.bar; //该形参下没有bar这个属性 只有一个foo属性
  })({ foo: { bar: 1 } }); //undefined
  ```

- 分组选择符

  ```javascript
  var f = (function f() {
    return "1";
  },
  function g() {
    return 2;
  })(); //分组选择符 示例 var a=(1,2,3); a就为3
  typeof f; //"number"
  ```

- if判断条件的真假
  ```javascript
  var x = 1;
  if (function f() {}) { //if(false/null/undefined/0/"")为假 其他为真
    x += typeof f; //f变量不存在 -> 1+undefined
  }
  x; //'1undefined'
  ```
- typeof返回的值是字符串
  ```javascript
  var x = [typeof x, typeof y][1]; //不管这是什么 总之typeof 返回的是字符串
  typeof typeof x; // typeof x 返回的是字符串（如"Object" "number") 因此最终类型是一个 "String"
  ```
- 函数声明的提升
  ```javascript
  (function f() {
    function f() { return 1; }
    return f();
    function f() { return 2; } //覆盖了上一条 f() 因为函数声明会提升
  })(); //2
  ```
- 构造函数中的return
  ```javascript
  function f() { return f; } //构造函数中返回的函数或对象会覆盖掉构造函数
  new f() instanceof f; //false
  ```

- 函数的长度是函数形参的个数
  ```javascript
  with (function (x, undefined) { }) length; //函数的长度就是函数的形参 2
  //附注：arguments是函数实参
  ```

# 作用域
- 变量未使用关键字声明将成为全局变量
  ```javascript
  function f(){
      var a=b=1; //相当于 var a=1; b=1;(b没有加上var关键字 成为全局变量)
  }
  f(); //调用时f
  a; //undefined
  b; //1
  ```
- 函数作用域

  ```javascript
  var a=10;
  function aaa(){ return a }
  function bbb(){
    var a=1;
    aaa();
  }
  bbb(); //10  bbb()中的a=1不能被aaa()函数获取
  ```
- 预解析

  ```javascript
  var a=10;
  function aaa(){
      alert(a); //变量查找是就近原则 就近的局部未找到就会去外层找
    	var a=20; //js引擎会将所有var function先解析 但赋值等操作还是需按顺序执行
    //相当于
    //var a; //预解析
    //alert(a);
    //a=20
  }
  aaa(); //undefined
  ```
- 函数参数的作用域

  ```javascript
  var a=10;
  function aaa(a){ //参数的作用域也在函数作用域内
      alert(a); //找到了参数a
    	var a=20;
  }
  aaa(); //10 参数和局部变量同名时 优先级一致
  ```
  ```javascript
  var a=[1,2,3]
  function aaa(a){
      a=[1,2,3,4]; //这个来自参数的a 不会影响外部的a 它在内存中新生成一个对象
  }
  aaa(a);
  a; //[1,2,3]
  ```

  ​
# 字符串操作

- 字符串转驼峰 border-color -> borderColor

  ```javascript
  function hump(str) {
    const strArr = str.split("-");
    const fn = function(item, index, arr) {
      arr[index] = item[0].toUpperCase() + item.substring(1).toLowerCase();
    };
    strArr.forEach(fn);
    return strArr.join('');
  }
  ```

  或

  ```javascript
  function camel(str) {
    const reg = /-(\w)/g;
    return str.replace(reg, function(match, offset) {
      return offset.toUpperCase();
    });
  }
  ```

- 查找字符串出现最多次数的字符及其个数

  ```javascript
  function mostOne(str) {
    const obj = {}; //每个字符作为一个属性 属性值是一个数组 数组元素是该字符出现的各个位置
    let num = 0; //出现的次数
    let value = ''; //出现最多的字符
    for (let i = 0; i < str.length; i++){
      if (!obj[str[i]]) { //在obj对象中不存在某属性时
        obj[str[i]] = [];
      }
      obj[str[i]].push(str[i]); //将该字符出现的位置添加到数组中
    }
    for (let attr in obj) {
      if (num < obj[attr].length) {
        num = obj[attr].length;
        value = obj[attr][0];
      }
    }
    return "最多："+value+" 出现了"+num+"次"
  }
  ```

  或

  ```javascript
  function mostOne(str) {
    const arr = str.split("");
    arr.sort();
    str = arr.join("");

    let num = 0;
    let value = "";
    const reg = /(\w)\1+/g;
    str.replace(reg, function($0, $1) {
      if (num < $0.length) {
        num = $0.length;
        value = $1;
      }
    });
    return "最多：" + value + " 出现了" + num + "次";
  }
  ```

- 给数字加上千分符（每三位添加一个逗号）

  ```javascript
  function separator(num) {
    let str = String(num);
    const arr = []; 

    let prevNum = str.length % 3; //每3个字符一组分 剩余几个？

    if (prevNum != 0) { //当有剩余时
      const prevStr = str.substring(0, prevNum);
      arr.push(prevStr);
    }

    str = str.substring(prevNum); //去掉剩余部分
    for (let i = 0; i < str.length; i = i + 3) {
      arr.push(str.substring(i, i + 3)); //substring截取部分是前开后闭区间
    }//三位三位分割 加入数组
    
    return arr.join(",");
  }
  ```

  或

  ```javascript
  function separator(num) {
    let str = String(num);
  //向前匹配3位 但又不包括者三位字符本身 也不包括前面是字符串边界的情况
    const reg = /(?=(?!\b)(\w{3})+$)/g;
    return str.replace(reg,',');
  }
  ```

- 提取字符串中各个相连的数字作为一个数组的元素

  ```javascript
  function selectNum(str) {
    const reg = /\D+/g;
    const arr = str.split(reg);
    if (arr[0] === '') {
      arr.shift();
    }
    if(arr[arr.length - 1] === ''){
      arr.pop();
    }
    return arr;
  }
  ```



- 调换两个变量的值(不使用第三个变量)

  - 只适合数字

    ```javascript
    let a = 1;
    let b = 2;
    a = (a + b); //3
    b = a - b; //3-2=1
    a = a - b; //3-1=2
    ```

  - 适合任何类型

    ```javascript
    let a = 'hi';
    let b = 'hello';
    a = [a, b];
    b = a[0];
    a = a[1];
    ```

  - 变量解构赋值（ES6支持）

    ```javascript
    let a = 1;
    let b = 'hello';
    [a,b]=[b,a]
    ```

- 创建数组

  不用for/while创建一个数组[1,2,3,4,5]

  - Array对象的方法

    ```javascript
    let n = 5;
    const arr1 = Array.apply(null, { length: n }).map((v, i) => i);
    const arr2 = Array.from(new Array(n), (v, i) => { return  i });
    ```

  - 使用递归

    ```javascript
    function newArr(n) {
      const arr = [];
      return (function() {
        arr.unshift(n); //将数字放到数组前面
        n--;
        if (n != 0) {
          arguments.callee(); //调用函数本身
        }
        return arr;
      })();
    }
    ```

    - replace方法

      ```javascript
      function newArr(n) {
        const arr = [];
        arr.length = n+1;
        let str = arr.join('a'); //aaaaa
        const arr2 = [];
        str.replace(/a/g, function () { //匹配5次 会执行五次改函数
          arr2.unshift(n--);
         })
        return arr2;
      }
      ```

- 写一个函数，如果传入的数字小于100，返回该数字，否则返回100，不能使用if、switch...case、while、三目运算符。

  - Math对象的min方法

    ```javascript
    function testNum(n) {
      return Math.min(n,100)
    }
    ```

  - 数组及sort方法

    ```javascript

    function testNum(n) {
      const arr = [n, 100];
      arr.sort(function (a, b) { 
        return a - b;
      })
      return arr[0];
    }
    ```

  - 循环

    ```javascript
    function testNum(n) {
      for (let i = 99; i <Math.floor(n); i++){
        return 100;
      }
      return n;
    }
    ```

  - 字符串长度+循环

    ```javascript
    function testNum(n) {
      let num = n; //先把这个数存起来
      n = Math.floor(n); //将小数尾数去掉
      let m = String(n);
      for (let i = 2; i < m.length && n>0; i++){ //大于0 且位数至少为3位时
        return 100;
      }
      return num;
    }
    ```

  - 逻辑判断

    ```javascript
    function testNum(n) {
      let m = n >= 100 && 100; //n>=100为真-true&&100 则m=100 否则m为false
      return m = m || n; //m为false则m=n 否则m为100
    }
    ```

  - 逻辑判断和for...in

    ```javascript
    function testNum(n) {
      const tf=n < 100 || {name:'hi'};
      for (let attr in tf) {
        return 100
      }
      return n;
    }
    ```