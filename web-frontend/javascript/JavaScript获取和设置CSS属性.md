# 获取样式

## 元素对象的宽高位置距离等属性

如offsetWidht、cilentWidht、scrollWidth……

```javascript
let oWidth=obj.offsetWidth;
```

注意：

-   只能获取属性值（**只读**）
-   （这些宽高距离的）值是数字

## style对象的属性

获取所有样式（样式的内容，字符串形式）cssText 和获取单项样式：

```javascript
let oStyle=obj.style.cssText;
let oWidth=obj.style.width;
```

注意：

-   需要用属性名cssFloat代替float（float是JavaScript保留关键字）
-   取得的属性值带有**单位**（如果有单位）
-   只能获取**行内样式**（html标签中的样式）
-   可以获取和设置（**可读可写**）

## window对象的getComputedStyle()  方法

获取当前元素所有**最终**使用的CSS属性值，该方法属于window对象。 ie8-使用 `getCurrentStyle`（**元素对象的方法**）

接收两个参数：元素对象和要匹配的**伪元素**的字符串（普通元素省略或null）

**返回一个对象**，可用使用该返回对象的属性和方法获取样式：

- 通过属性名获取相应属性值

```javascript
let oColor=window.getComputedStyle(obj, null).color;
```

- getPropertyCSSValue()方法获取CSSValue对象的属性

  接收一个参数：属性名（带引号，原带`-`的CSS属性要转换成驼峰法书写）

  返回一个给定属性值的CSSValue对象，该对象有3个属性：primitiveType、cssText和cssValueType，

```javascript
let oStyle=window.getComputedStyle(obj,null).getPropertyCSSValue('color').cssText;
```

- getPropertyValue()方法

  可以获取CSS样式**申明**对象上的属性值（直接属性名称）
  接收一个参数：属性名（带引号，原带`-`的CSS属性要转换成驼峰法书写）

```javascript
let oBgc=window.getComputedStyle(obj, null).getPropertyValue("background-color");
```


注意：

- 全局对象的方法
- 只能获取样式（**只读**）
- 能获取默认、继承的属性
- 返回的值带有单位（如果有）
- **获取最终样式值**


## 元素对象的getClientRects()/getBoundingClientRect()方法

元素对象的方法。

- getClientRects() 获取元素矩形区域样式

  获取元素占据页面的所有矩形区域样式。返回值一个TextRectangle对象集合，包含：top left bottom right width height 六个属性（上下左右宽高）

  注意：

  - 返回的矩形不包括任何可能超出元素范围的子元素的边界
  - 只能获取样式（**只读**）

```javascript
let rectCollection = obj.getClientRects();
```

-   getBoundingClientRect()获取元素位置

    获得页面中某个元素的左，上，右和下分别相对浏览器视窗的位置。

    返回值一个对象，具有6个属性：top,lef,right,bottom,width,height。

    注意：

    - 获取的位置是元素**相对于的视口的位置**

      right是指元素**右边界距窗口最左边的距离**，bottom是指**元素下边界距窗口最上面的距离**。

    - 只能获取样式（**只读**）

```javascript
let eleInfo= obj.getBoundingClientRect();
```

## CSS StyleSheets对象的属性和方法

`document.styleSheets`返回StyleSheetList是一个类数组对象，包含了当前文档的所有css样式表。

- cssRules  返回一个类数组对象cssRuleList，其包含样式表中所有CSS规则。

  cssRules数组对象内元素的常用属性（属性均为**只读**，属性值均是字符串）：
  - cssText  返回css样式
  - style.cssText 返回该条规则的**所有**样式声明
  - style.[attr]   返回具体某个属性的样式
  - selectorText  返回该条规则的选择器
  - parentRule  返回包含规则（如果有）（例如 @media 块中的样式规则）

```javascript
document.styleSheets; //当前文档所有css样式表的类数组对象
document.styleSheets.lenth; //当前文档有多少样式表
document.styleSheets[0]; //当前文档第0个样式表的类数组对象
document.styleSheets[0].cssRules[0]; //当前文档第0个样式表的第0条样式

document.styleSheets[0].cssRules.length; //当前样式表有多少条样式
document.styleSheets[0].cssRules[0].cssText; //第0条样式的内容
document.styleSheets[0].cssRules[0].style.width; //第0条样式中的宽
document.styleSheets[0].cssRules[0].selectorText; //第0条样式选择器
```
# 设置样式

## 直接设置元素的属性

**某些元素**对象如img可以直接设置css样式

```javascript
obj.width='100%';
```
## setAttribute()/removeAttribute()设置元素的style属性
```javascript
obj.setAttribute('style','widht:100px!important');
obj.removeAttribute('style');
obj.setAttribute('width','100%');  //某些元素适用（即“直接设置元素的属性”的情况）
```
##  style对象的属性和方法

### 直接设置某个属性的值

- 根据属性设置单一样式

````javascript
obj.style.height = '100px';
obj.style.borderBottom='2px';
obj.cssFloat='left';
````

注意：

- 需要用属性名cssFloat代替float（float是JavaScript保留关键字）
- **带上单位**（如果需要）
- 带有连字符`-`的CSS属性在JavaScript中，应该转换成驼峰形式或将属性名（带引号）写在中括号[]中

### cssText属性设置样式字符串

可设置多个样式
```javascript
obj.style.cssText="color:gray;font-size:1.25rem;"
```
### setProperty()/removeProperty方法

```javascript
obj.style.setProperty('height', '300px', 'important');
obj.style.removeProperty('color');
```

## 操作class/id改变样式

给元素对象增/改/删className或者idName。相应的class/id设置有相关样式。
### 元素对象的setAttribute()/removeAttribute()设置class/id

```javascript
obj.setAttribute('class',newClassName);
obj.removeAttribute('class',newClassName) ;
```

### 设置元素对象的className/id属性

```javascript
 obj.className=newClassName;
obj.id=newIdName;
```

注意：元素对象没有class（class是JavaScript保留关键字）这个属性，只有className这个属性。

### 属性对象attributes的set/removeNamedItem()设置属性名

```javascript
let attrName=document.createAttribute('class');
let attrName.nodeValue=className;//一个已经存在的class
obj.attributes.setNamedItem(attrName);
obj.attributes.removeNamedItem(attrName);
```
## 操作link标签/节点

- link节点增/删/改

  示例（添加样式表）：

  ```shell
  let linkNew=document.creatElement('link');
  linkNew=setAttribute('rel','stylesheet');
  linkNew=setAttribute('hreft','new.css');
  document.head.appendChild(link);
  ```
- innerHTML
- 更改link的href
  ……
## 操作style标签/节点

- innerHTML或textContent 写入/清空style标签
- style节点增/删/改（参照上文**操作link标签/节点**之**link节点增/删/改**示例）……

### CSS StyleSheets对象的属性和方法

StyleSheets是一个类数组对象，包含了当前文档的所有css样式表。

- disable 属性：打开或关闭一张样式表。

```javascript
document.styleSheets[0].disabled;
```

- delteRule()/insertRule()

  *ie使用addRule()和removeRule()。*

  ```javascript
  document.styleSheets[0].deleteRule(0);
  document.styleSheets[0].insertRule('.test{color:red;font-size:1.5em;}');
  ```

## innerHTML(textContent)

- innerHTML写入样式表
```javascript
document.getElementByTagName('head')[0].innerHTML+= <link rel="stylesheet" href="new.css">
```

- innerHTML或textContent增/删style标签  更改style标签的内容
  参照上面

- innerHTML（新建元素节点）中写入行内样式/id/class

  示例：`obj.innerHTML=<span style="color:red">red</span>`
  ……