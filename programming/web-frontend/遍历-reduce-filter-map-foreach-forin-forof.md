for、for in 、for of 、forEach 、map对比

- for、for in 、for of 是循环语句，**可以break中断遍历** ；for循环可用于对**遍历间隔有要求**的情况。
- forEach和map是数组的方法，适合在**按顺序全部遍历**的时候；map方法返回一个新数组，本质是（将旧数组按函数）映射为新数组，forEach是遍历数组每个元素执行相应运算，返回值是undefined。
- 数组方法every、some和filter都是安装某条件（一个回调函数）对数组元素逐一检验。every和some返回的是true或者false，即数组是否通过了检验；而filter是返回的是数组中符合检验条件的元素所组成的新数组。some和every顾名思义，some即某些元素通过检验就为true，而every需要每个元素都通过检验才为true。
- 以下数组方法中除了reduce之外，均是接受两个参数：第二个参数用以指定this值，可省略；第一个参数是一个函数，该函数又有三个参数：数组元素(item)、数组元素下标(index)、数组(array)。
- 除了**for in只适合遍历（可枚举）对象**，其余都可以用来遍历数组。
- for-in遍历的是键名（key），for-of遍历的是键值（value）。



[TOC]

---

# 数组方法reduce/reduceRight

**数组**的 `reduce()` 接受一个函数（作为**累加器**）将数组中的每个值从左到右累计运算，直到所有值累计为一个值，最终**返回这个累计的值**。

因为该方法会将数组多个值减少为一个值，故而名reduce。reduceRight()方法**从右到左**运算，参考reduce()使用。

参数：
- callback  执行数组中每个值的函数，包含四个参数
    - previousValue  上一次执行回调后的返回值或初始值
    - currentValue  数组中当前处理的元素
    - currentIndex  当前处理的元素的索引，如果提供了 initialValue ，从0开始；**否则从1开始**。可选。
    - array  调用 reduce 的数组。可选。
- initialValue  初始值，用于第一次调用 callback 的第一个参数。**如果没有设置初始值，则将数组中的第1个元素作为初始值**。空数组调用reduce时没有设置初始值将会报错。 可选。

返回值：函数累计处理的结果。
```javascript
const arr=[1,2,3,4,5];
const fn=function (preValue,curValue){
    return accumulator+item;
};
arr.reduce(fn);  //15
```

# 数组方法some

数组的`some()`方法接受一个函数作为条件，以检测数组中的元素是否满足该条件。

参数：

- callback   测试每个元素的函数
- thisArg  可选 执行 callback 时使用的 this值（如不指定，则为undefine）


返回值： true或者false

```javascript
const arr = [1, 2, 3]
const fn = function (item,index,array){
  return item>=3
}
arr.some(fn) //true
```

# 数组方法every

数组的`every()`方法接受一个函数作为条件，以检测数组的所有元素是否都满足了该条件。

参数：

- callback   测试每个元素的函数
- thisArg 可选 执行 callback 时使用的 this值（如不指定，则为undefine）

返回值： true或者false

```javascript
const arr = [1, 2, 3]
const fn = function (item,index,array){
  return item>=3
}
arr.every(fn) //false
```

# 数组方法filter

**数组**的filter方法接受一个函数对数组元素按条件进行检测，并将符合条件的元素作为一个新数组的元素，最终**返回这个新数组**。

filter对空数组无效，不会改变原始数组。

参数：
  - callback 用来检测数组的每个元素的函数，接受三个参数：
    - currentValue  当前处理的元素的值
    - index  当前处理的元素的索引。可选。
    - array  要处理的数组。可选。
  - thisArg  执行 callback 时的用于 this 的值。可选。

返回值： 由通过测试的元素组成的新数组。

```javascript
const arr=[1,2,3,4,5];
const fn=function (curValue){
    return curValue%2===0;
};
console.log(arr.filter(fn));  //[2,4]
```

# 数组方法map
**数组**的map() 方法接受一个函数对数组元素按顺序处理，并将处理得到的值作为一个新数组的元素，最终**返回这个新数组**。

map对**空数组无效**，不会改变原始数组。

参数：

- callback  生成新数组元素的函数，接受三个参数：
  - currentValue  数组中正在处理的当前元素。
  - index  数组中正在处理的当前元素的索引。可选。
  - array  要处理的数组。可选。
- thisArg  可选的。执行 callback 函数时 使用的this 值。

返回值：一个新数组，每个元素都是回调函数的结果。

```javascript
const arr=[1,2,3,4,5];
const fn=function (curValue){
    return item*10;
};
arr.map(fn);  //[10,20,30,40,50]
```
# 数组方法forEach

**数组**的forEach()方法接受一个函数**对数组的每个元素进行遍历**运算。

**但不能使用break或者return**。

参数：
  - callback  为数组中每个元素执行的函数，接受三个参数：
    - currentValue  数组中正在处理的当前元素的值
    - index  数组中正在处理的当前元素的索引。可选。
    - array  要处理的数组。可选。
  - thisArg  执行回调 函数时用作this的值。可选。

返回值：undefined

```javascript
const arr=[1,2,3,4,5];
const fn=function (curValue,index,array){
    array[index]=curValue*10;
};
arr.forEach(fn);
console.log(arr);  //[ 10, 20, 30, 40, 50 ]
```

# for in循环 遍历可枚举对象
> for...in 语句以任意顺序遍历一个对象的可枚举属性。对于每个不同的属性，语句都会被执行。

for-in语句**遍历一个对象的可枚举属性**，只有”enumerable“对象（可枚举对象）的属性能被for-in遍历到。

**最好不要使用for-in遍历数组**，for-in遍历中，**赋值给数组相应索引的值不是数字而是字符串**（也就是数组中的数字元素被转成了字符串）。

参数：
  - variable  在每次迭代时,将不同的属性名分配给变量
  - object  被迭代枚举其属性的对象

```javascript
const obj={"name":"neo","age":"28","gender":"male"};
for(let key in obj){
    console.log(key+":"+obj[key]);
}
```

# for of循环 遍历数组及类数组对象

与数组的forEach方法对比：可以使用break、continue和reutrn；

与for-in语句对比：不会将数组索引对应的值转为字符串。只可以循环可迭代对象的可迭代属性，不可迭代属性在循环中将被忽略。

**for-of循环不仅支持数组，还支持大多数类数组对象**，例如DOM [NodeList对象](https://developer.mozilla.org/en-US/docs/Web/API/NodeList)。支持Map和Set对象遍历。

`for...of`不会遍历对象的key，只会遍历出value，**不能遍历普通的对象**，需要通过和`Object.keys()`搭配使用（这种情况建议使用for...in）。

参数：

- variable  在每次迭代时,将不同的属性名分配给变量
- object  被迭代枚举其属性的对象

```javascript
const arr=[1,2,3];
for(let item of arr){
    console.log(item+":"+item]);
}

//遍历普通对象
const obj={a:1,b:2}
for(const key of Object.keys(obj) ){
    console.log(key+":"+obj[key])
}
```

