[TOC]

# 字符串转数字

- 全局函数`Number()`（注意N大写）和`parseInt()`/`parseFloat`

  - 二者在无法转换成数字时会返回`NaN`，但是，如果字符串以数字开头：
    - `parseInt()`/`parseFloat`会取得字符串前面的连续的数字并返回该数字，连续数字中最后一个数字后面的内容被舍弃
    - `Number()`直接返回`NaN`
  - 二者都能识别字符中的十六进制标识（0x开头）和八进制标识（0开头）。
  - `parseInt()`可以接受两个参数：string（必须，要解析的字符串）和radix（可选，要解析的数字的基数——进制，取值2~36）；`parseFloat()`只接受一个参数，即要解析的字符串。

  ```javascript
  Number('11')  //11
  parseInt('11') //11
  parseInt('11,2')  //3 二进制的11等于十进制的3

  Number('12ab3') //NaN
  parseInt('12ab3') //12
  parseInt('1.2') //1
  parseInt('0x10',16) //16

  Number({}) //NaN
  parseInt([]) //NaN
  ```


- 使用一些算数运算符  注意**`+`任意一侧是字符串则以字符串拼接处理**

  ```javascript
  '2'-0 //2
  '2'*1 //2
  '2'/1 //2
  '2n'-1 //NaN
  Math.pow('2',2) //4
  ```

# 数字转字符串

- 字符串拼接：数字和空字符串拼接


- 全局函数`String()` （注意S大写）和每个对象都拥有的方法`toString()` ：
  - `toString()`不能将null和undefined转换为字符串，`String()`可以。
  - `toString()`括号中可以指定进制，将数字转换成对应的进制**字符串** ，`String()`不可以。
  - 不能使用`123.toString()`这种`数字.toString()`的方法转换

```javascript
123+'' //'123'
String(123) //'123'
123.toString() //SyntaxError: Invalid or unexpected token
var a=123
a.toString() //'123'
a.toString(2) //'11' (二进制数)
```
