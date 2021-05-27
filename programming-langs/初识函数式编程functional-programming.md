[TOC]

# 函数式编程的思想

- 计算机的运算皆**“函数”**

> 函数式编程（英语：functional programming）或称函数程序设计，又称泛函编程，是一种编程范型，它将电脑运算**视为数学上的函数计算**，并且**避免使用程序状态**以及易变对象。
>
> 函数编程语言最重要的基础是λ演算（lambda calculus），λ演算的**函数可以接受函数**当作输入（引数）和输出（传出值）。

​		函数：参数->运算->结果

- 强调程序中的**单个函数单元**及其执行**结果**

> 比起命令式编程，函数式编程更**强调程序执行的结果**而非执行的过程，利用**若干简单的执行单元**让计算结果不断**渐进**，**逐层推导**复杂的运算。

- 没有副作用、不依赖外部环境的“**纯函数**”

## 纯函数

> 纯函数：对于**相同的输入，永远会得到相同的输出**，而且没有任何可观察的副作用，也**不依赖外部环境的状态**。

纯函数的运算是**“自给自足”**的，不依赖外部环境（外部环境不是指传入的参数），实例：

```javascript
//不纯的函数
let min=10;
const compare1 = num => num > min;    //内部的大小对比依赖外部的min变量
compare1(11);    // true

//纯函数
const compare1 = num => num > 10;    //内部的大小对比不依赖外部内容
compare1(11);    //true
```

所谓“副作用”——那些与**函数外部环境**发生的交互

> *副作用*是在计算结果的过程中，系统状态的一种变化，或者与外部世界进行的*可观察的交互*。

实际的项目中，不依赖外部环境”这个条件是根本不可能的。函数式编程中力求让副作用尽可能在可控的范围内发生。

#　函数柯里化curry

> 传递给函数一部分参数来调用它，让它**返回一个函数**去处理剩下的参数。

通俗地说，"柯里化"就是

> 把一个多参数的函数，转化为单参数函数。

因此柯里化后的函数只接受一个参数。函数柯里化用来分隔复杂功能，将其变成**更小**更容易分析的部分。

调用函数时，可以每次传入一个参数分多次调用，也可以一次性的调用。参看下面的示例（接上文示例，对其进行柯里化）：

```javascript
let compare = min => (num => num > min); 
let compare10 = compare(10);    //将参数min=10传入 返回的函数赋值给其他变量
compare10(11);    //true  |  将要num的参数传给返回的函数
//融合以上两行，也可以写成
compare(10)(11);   //true
```

通俗地解释上面的代码：

```javascript
let compare = function (min){
    function temp(num){
        return num > min;
    }
    return temp;
};
let compare10 = compare(10);     //compare10得到的是temp函数
compare10(11);    // true
//融合以上两行，也可以写成
compare(10)(11);   //true
```

# 函数的合成compose

> 如果一个值要经过多个函数，才能变成另外一个值，就可以把所有中间步骤合并成一个函数，这叫做"函数的合成"（compose）。

使用纯函数柯里化之后，很容易写出多层括号嵌套的代码，“优雅性”差，不便阅读，使用函数组合用以解决这种问题——像拼积木一样来组合函数式的代码。

```javascript
const compose = function (a,b){
    return function (num){
        return a(b(num));
    };
};
//或者写成
const compose = (a, b) => (num => a(b(num)));

const mul5 = num => num * 5;
const add1 = num => num + 1;

compose(mul5, add1)(2);    //15
```

执行过程解析：

1. 传入a=mul5，b=add1，得到返回的值`function (num){return mul5(add1(num))}`
2. 传入num=2，得到返回值`mul5(add1(2))`，这是一个函数调用，`add1(2)`即2+1=3，将3作为参数传入，即`mul5(3)`得到3*5=15，结果就是15。

## Tacit programming（point-free风格）

[Tacit programmingpointfree](https://en.wikipedia.org/wiki/Tacit_programming)（或可翻译成“隐性编程”？）又称为point-free style，

> (It)  is a [programming paradigm](https://en.wikipedia.org/wiki/Programming_paradigm) in which function definitions **do not identify the [arguments](https://en.wikipedia.org/wiki/Parameter_%28computer_science%29)** (or "points") on which they operate. 

参看[haskell：point-free](https://wiki.haskell.org/Pointfree)。point-free术语来自拓扑学，它指的是由点组成的空间，以及这些空间之间的功能。

> So a 'points-free' definition of a function is one which does not  explicitly mention the points (values) of the space on which the  function acts.

引申到函数式编程中，point-free风格也就是：**不要显式地定义参数**（参数即point-free中的point）。

>  **never mentioning the actual arguments** they will be applied to.

> **never mentioning the actual arguments** they will be applied to.

> 简单说，Pointfree 就是运算过程抽象化，处**理一个值，但是不提到这个值。**
>
> 不要命名转瞬即逝的中间变量。
>
> 永远不必说出你的数据。

point-free的意义：

> 使用一些**通用的函数**，**组合**出各种复杂运算。**上层运算不要直接操作数据**，而是通过底层函数去处理。这就要求，将一些常用的操作封装成函数。

使代码更加清晰和简练，更符合**语义**，有更好的**通用**性而易于**复用**，也容易进行测试。

```javascript
//这不piont-free
const f = str => str.toUpperCase().split(' ');    //使用了str和' '
//这很point-free
const toUpperCase = word => word.toUpperCase();  //函数1
const split = x => (str => str.split(x));  //函数2
let compose=(p1,p2) => (param=>p1(p2(param)));
let fn=compose(split(''),toUpperCase);
console.log(fn('ok'));    //Array [ "O", "K" ]
```

上面这个ponit-free风格的示例中，函数1和函数2都没有显式地定义参数，两个函数都有着语义化的名称。（示例中这个compose合成方法是自己写的，可以使用[ramda](http://www.ruanyifeng.com/blog/2017/03/ramda.html) 、[lodash](https://github.com/lodash/lodash)等库的方法进行合成）

# 容器

