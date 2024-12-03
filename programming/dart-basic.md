# dart简介
一种采用类别基础编程的面向对象语言

Dart有两种方式执行：原生虚拟机；转换成JavaScript直接在Javascript引擎上执行。
示例：
```dart
main(){
  print('Hello, Dart!');
}
```
dart必须要有一个**main()**函数作为顶级执行函数。

# 变量常量

dart语言本质是动态类型语言，**类型是可选的**。

- var声明变量

- const或final声明常量

  const定义的是**编译时**常量，只能用编译时常量来初始化

  final定义的常量可以用变量初始化

# 数据类型

- 内置数据类型

  - 数字Numbers
  - 字符串Strings
  - 布尔指Booleans
  - 列表List（也就是数组）
  - 映射Maps

- 数字

  - int
  - double

  ```dart
  void main(){
  var i=1;
  const m=2;
  final n=3;
  int x=4;
  const double y=5.5555555555;
  final int z=6;
  }
  ```


- 字符串

  可使用单引号或双引号创建字符串；

  使用**三个**单**引号**或者双引号**可以给多行字符串赋值** ；

  使用`\`对引号中的同种引号（如单引号中的单引号）进行转义，在字符串上加上@可以创建纯字符串（不会转义）。

  ​

  使用`$变量`或`${表达式}`可以在字符串中嵌入变量或表达式；

  使用+拼接字符串，或者两个字符串相邻即可拼接（允许跨行）。

```dart
void main(){
  var str='dart';
  var str1="excited";
  String str2="用String也可以建立字符串 it's dart";
  var str3=@'there\'s  有我@在 别想发生转义';
  var str4='''图样的dart
  可以三个引号跨行建立字符串''';
  var str0='$str字符串居然'
    "可以跨行"+"拼接 简直${str1.toUpperCase()";
}
```

- 布尔

  dart的布尔类型名为bool，它两种类型：true和false。dart中，**如果一个值不是true，那么它是什么数据类型，它是就是false。**

```dart
void main(){
  var name='dart';
  if(name){    //name是字符串，只要不是true，统统成false
    print('我是$name');    //对不起你没有显示之日了……
  }else{
    print('你是谁不重要');    //这句话会被打印出来
  }
}
```

- 列表（数组）

```dart
void main(){
  var list = [1, 2, 3];
  print(list.length);
  print(list[1]);    //2
}
```
- 映射

  映射是包含键值对应关系的**对象**。

```dart
void main(){
    var flowers = {'a': 'rose', 'b': 'lily', 'c': 'sunflower'};
    print(flowers['a']);    //rose
}
```

# 函数

函数也是对象，当没有指定返回值的时候，函数返回null。dart可以使用箭头函数。

```dart
void main(){
  String hello(String lang){
    return 'hello $lang';
  }

  say(name)=>'hello $name';    //箭头函数写法
  (name)=>'hello $name';    //匿名函数写法
}
```

- 可选参数


  将函数参数放在`[]`内即被标记为可选参数。

```dart
void main(){
  String say(String from, String msg, [String device]) {
  var result = "$from 说“$msg”";
  if (device != null) {    //判断可选参数是否存在
     result = "$result(通过 $device 发送)";
  }
  return result;
}
  print(say("dart","hello","excited"));
  print(sya("dart","heelo",device:"excited"));//命名参数写法
}
```
如果没有提供默认值，其值为null。
可选参数同时是命名参数，使用`变量:"值"`这种方式调用。

- 第一类函数
  将函数作为参数传递给其他函数。
```dart
void main(){
  List ages = [1,4,5,7,10,14,21];
  List oddAges = ages.filter((i) => i % 2 == 1);
}
```
