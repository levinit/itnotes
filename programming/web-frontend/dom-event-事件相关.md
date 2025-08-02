[TOC]

# 事件流

> 页面中接收事件的**顺序**。

## 事件模型：冒泡 与 捕获

假如目标元素是div，二者的接收顺序分别如下：

- 冒泡：div>body>html>Document
- 捕获：Document>html>body>div

## DOM事件流

W3C标准采用了捕获+冒泡的模型，即DOM事件流。

DOM标准规定（DOM2级）事件流包括三个阶段，按顺序为：

1. 事件**捕获**阶段——**事件从Document开始传播**

   注：

   - 实际上浏览器是从window对象开始捕获的。
   - “DOM2级事件标准规范”规定，事件捕获阶段不会涉及事件目标对象，但在浏览器中捕获阶段也会触发目标对象上的事件。（也就是有两次机会在目标对象上面操作事件）


2. 处于**目标**阶段——**事件在目标上发生并处理**（执行事件处理程序）

   注：事件处理会被看成是冒泡阶段的一部分。

3. 事件**冒泡**阶段——**事件传播回Document**

---
有些事件是可以取消的，在整个事件流的任何位置通过调用事件的stopPropagation方法可以停止事件的传播过程。参看后文[事件对象的属性和方法](#事件对象的属性和方法)

此外：

   > 所有的事件都要经过捕获阶段和处于目标阶段，但是有些事件会跳过冒泡阶段。

   例如：focus事件（获取焦点）和的blur事件（失去焦点）会跳过冒泡阶段。

# 事件处理程序

## HTML事件处理程序

在HTML标签中添加事件属性，该属性的值为要执行的脚本代码或者要调用的函数。

```html
<!-- 直接写上代码 -->
<input type="button" value="click me" onclick="alert('hi')" />
<!-- 或 -->
<input type="button" value="click me" onclick="show()" />
<script type="text/javascript">
function show(){
	alert('hi');
}
</script>
```

## DOM0级事件处理程序

将函数赋值给一个事件处理程序的属性：

1. 取得要操作的对象

2. 将一个函数赋值给该对象的事件处理程序属性。(事件名前面要用on，如click事件写成`onclick`)

   删除事件处理程序方法：将事件处理程序属性设置为`null`;

```javascript
var ele=document.getElementById("btn");//取得一个id名为btn的元素对象
btn.onclick=function(){  //添加事件处理程序 
	alert('hi');
}
btn.onclick=function(){
  	alert('yes')  //会覆盖前面的事件处理程序
}
btn.onclick=null; // 删除事件处理程序
```

实际上没有DOM0官方标准，1998 年 10 月 才有W3C的DOM1级推荐规范，DOM1级推出时并没有添加增加事件功能，而此前的事件功能的实现被习惯称为DOM0级。（IE4和Netscape 4.0这些浏览器最初支持的DHTML）。

## DOM2级事件处理程序

1. 取得要操作的对象
2. 向该对象添加`addEventListene() `方法，该方法有三个参数：
   - type事件类型
   - listener事件处理程序：该事件的处理函数（或实现了EventListener 接口的对象）
   - options参数对象（可选）：包含三个属性（属性值均为布尔值，默认false）
     - capture  事件处理程序是否在事件**捕获阶段**传播到该 EventTarget 时触发
     - once       事件处理程序是否调用（一次）之后被**自动移除**
     - passive  事件处理程序是否调用 `preventDefault()`
   - useCapture使用捕获（可选） 布尔值 默认false

```javascript
var btn=document.getElementById("btn");
var fn=function(){  //事件处理的方法
	alert(this.id);
};
btn.addEventListener('click', fn, {
      capture: false,
      once: false,
      passive: false
    },false) ;  //添加

btn.removeEventListener("click",fn,false);  //删除
```

注意：DOM2级事件，同一节点的**相同事件的多个事件处理程序中，后面的事件处理程序并不会覆盖前面的事件处理程序，而是会按先后顺序叠加执行**，故而：对于某节点可能出现反复绑定同一事件处理程序的情况，一定记得在下一次绑定该事件处理程序前**适时地解除事件绑定**！**或改为DOM0级事件进行前后覆盖。**

删除事件处理程序用 `removeEventListener()`

IE8-使用`attachEvent()`和`deattatchEvent()`（事件名前面要用on，如click事件写成`onclick`）

## DOM3级事件处理程序

在DOM2基础上添加一些新的事件（如input、textInput、Location），对不同类型事件进行了重新定义和分类（如UI、焦点、鼠标、滚轮等等类）。


# 事件对象

> 在触发DOM上的某个事件时，会在事件处理程序函数中会产生一个事件对象event，这个对象中包含着所有与事件有关的信息。

- 事件对象——W3C标准规定，事件对象通过事件函数的第一个参数（参数名随意）传入，但是一些浏览器中自带event对象，兼容性写法示例：

```javascript
ele.onclick=function(ev){
    var e=ev||event;  //或window.event
  //some codes need Event object
}
```

## 事件对象的属性和方法

以下是常用的属性和方法：

- DOM事件对象的属性
  - target    触发此事件的节点
  - currentTarget   事件监听器触发该事件的节点

  target在事件流的目标阶段；currentTarget可在事件流任何阶段。currentTarget是事件处理程序当前正在处理事件的那个元素，只有当事件流处在目标阶段的时候，两个的指向才是一样的。

  - timeStamp    事件生成的日期和时间
  - type    当前 Event 对象表示的事件的名称
  - bubbles    事件是否是起泡事件类型
  - cancelable   事件是否可拥可取消的默认动作的属性（如果有—值为true，则能使用preventDefault()阻止事件的默认动作）
  - eventPhase   事件传播的当前阶段

- DOM事件对象方法

  - preventDefault() 	阻止事件的默认动作
  - stopPropagation()    中止事件传播
  - initEvent()    初始化新创建的 Event 对象的属性

# 事件委托

将事件“委托”给父节点，事件触发时，根据一定的条件进行筛选，对实际触发该事件的元素对象添加处理程序。

例如对某ul下的多个li添加点击事件处理程序：

```javascript
const list = document.getElementById('lists') //获取id为lists的ul对象
list.addEventListener('click', fn)

//给list对象绑定事件处理程序
function fn(ev) {
  const e = ev || event
  const target = e.target //获取真正触发点击的元素

  switch (target.id) { //针对每个元素添加不同的事件处理程序
    case 'a': //id为a的li元素
      location.href = 'http://www.w3.org'
      break
    case 'b': //id为b的li元素
      alert('Me')解除事件绑定
      break
    // ...
    default:
      break
  }
}
```
