[TOC]

# float特性

**float的设计初衷，是为了实现文字环绕图片的图文混排效果** ，图片元素浮动后，文本内容会环绕在其周围。

> 浮动的框可以向左或向右移动，直到它的**外边缘碰到包含框或另一个浮动框的边框**为止。

## 脱离正常流

元素设置浮动后（float不为none），该元素会**脱离正常流（normal flow，或称为普通流/标准流）** ，让出原本在正常流中占据的位置。

### 文本内容环绕效果

即float最初设计需要实现的效果。

浮动元素让出了空间，文本内容向上方浮动元素原有位置方向附近移动，但是[文本内容又不会进入浮动元素原有位置](#某些元素不会进入浮动元素原有位置)，文本就只能移动到浮动元素周围位置（看起来就像浮动元素还“部分存在流中”一样）。

#### 清除inline-block之间的空白

利用浮动元素的文本环绕效果可以消除nline-block之间的空白。

空白产生原因：HTML代码中，**相邻的两个inline-block元素代码之间使用了换行符**后（即在不同的代码行），换行符会被浏览器绘制为空格（不同浏览器效果可能不一致）。示例，以下内容会显示两排按钮，第一排的两个按钮之间会有空白区域，而第二排的两个按钮则是紧连的。：

```html
<button>按钮</button>
<button>按钮</button>
<hr>
 <button>按钮</button><button>按钮</button>
```

将相邻的不同行inline-block元素浮动后，空白内容（换行符）就“环绕”到浮动元素的后面去了，两个元素之间的空白区域也就没有了。

### 未设置高度的父元素“塌陷”

元素浮动脱离正常流 -->  该元素离开父元素内部  --> 该元素原本占据的位置空出 --> 该元素不再撑开父元素  --> 父元素高度塌陷

当然：

- 如父元素中还有其他内容撑开高度，继续保留其他内容撑开的高度，只是由浮动元素撑开的高度不再有效。
- 如父元素设置有高度，则其高度也与该子元素是否浮动无关了。

### 某些元素不会进入浮动元素原有位置

> css元素3定位机制：正常流、浮动和绝对定位

**元素脱离正常流让出原有位置后，其后面的元素也不一定能进入浮动元素的原有位置**，这与postion:absolute/fixed（简称绝对定位）元素脱离正常流让出的原有位置的被占用情况有所不同：

- **绝对定位元素影响所有类型的元素**——绝对元素后面的任何类型的元素都会进入绝对定位元素让出的位置

- 浮动元素后面的元素是否进入浮动元素原有位置分为以下情况：

  - 不进入浮动元素让出位置的元素类型（**即使给以下类型元素设置display:block属性依然如此**）：

    - **inline**
    - **inline-block**
    - 各种table（如**table**、**table-cell**、**table-caption**等）

    当然浮动元素后面的文本内容也不会进入的浮动元素原有位置，绝对定位后面的文本内容会进入绝对定位元素原有位置。

    inline元素和文本内容不会进入浮动元素原有位置应该是为符合float的设计目的——图文环绕效果，而inline-block类和table类元素不能进入float让出区域应该和[BFC特性](#BFC特性)相关。

  - 进入浮动元素让出位置的元素类型（给这些类型元素设置dislplay：inline-block等属性，浮动元素会继续占有位置）：

    - **block**
    - **run-in**
    - **list-item**

## 元素行内-块级化（inline-block）

**浮动元素inline-block化**：

- 原先没有设置宽度的块级（block）元素的宽度会收缩至自适应内部元素的宽度（inline的特性）
- 原先不能设置宽高（当然还有上下margin/padding值）的行内（inline）元素可以设置宽高（block的特性）

注意：行内元素设置上下margin/padding值从显示效果来看是有变化的，但其实设置的是无效的，**并不会对他周围的元素产生任何影响**。

# 清除浮动

为消除float带来的布局问题——主要是**未设置高度的父元素高度塌陷问题**，需要使用一些方法来消除浮动动带来的负面影响。

解决方法主要可分为两类：

- 使用clear属性清除浮动
- 利用[BFC原理](#BFC（flow root）)闭合浮动

---

- ::after 伪元素+clear

  - [How To Clear Floats Without Structural Markup](http://www.positioniseverything.net/easyclearing.html)

    ```css
    .clearfix::after {
        content:".";
        display:block;
        height:0;
        visibility:hidden;
        clear:both;
    }
    .clearfix { *zoom:1; }  /** for IE **/
    ```

    更推荐以下简单容易记方案：

  - 使用“零宽度空格”字符[U+200B ](http://www.fileformat.info/info/unicode/char/200b/index.htm)

    ```css
    .clearfix:after {
        content:"200B";
        display:block;
        height:0;
        clear:both; 
    }
    .clearfix { *zoom:1; }/* For IE 6/7 (trigger hasLayout) */
    ```

  - 空content以及display:table+伪元素清除浮动

    来自Nicolas Gallagher -- [A new micro clearfix hack](http://nicolasgallagher.com/micro-clearfix-hack/) ：

    ```css
    .cf::before,.cf::after {
        content:"";
        display:table;
    }
    .cf::after { 
         clear:both;
    }
    .cf { zoom:1; }/* For IE 6/7 (trigger hasLayout) */
    ```

---

- 父元素定义高度

  父元素拥有自己的高度，也就不存在高度塌陷的问题。只适合固定高度的情况，**非固定高度的情况不要使用**。


- 父元素overflow

  - `overflow：hidden`

    必须定义宽度且不能定义高度，浏览器会自动检查浮动区域高度，不能和position配合使用，因为超出的尺寸会被隐藏，无法显示需要溢出的元素。**谨慎使用**

  - `overflow:auto`

    必须定义宽度且不能定义高度，浏览器自动检查浮动区域的高度，内部宽高超过父元素高度时，会出现**滚动条**。**谨慎使用**

- 父元素也设置浮动

  与父元素相邻的元素的布局会受到影响，产生新的浮动问题。**不要使用**

- 父元素设置`display:table`

  更改了盒模型，可能带来更多麻烦。**不要使用**

- 额外标签+clear属性

  浮动元素末尾添加一个空的标签，如在浮动元素之后添加一个<br>标签或者没有内容的<div></div>标签，为其增加`clear:both`。

  添加了无意义标签，不符合语义化原则，不利于维护。**不要使用**

---

## BFC（flow root）

> Formatting Context：指页面中一个渲染区域，并且拥有一套渲染规则，他决定了其子元素如何定位，以及与其他元素的相互关系和作用。

BFC：Block formatting contexts，块级格式化上下文，规定块级（block）元素的渲染规则。BFC就是页面上的一个隔离的**独立容器**，**容器里面的子元素不会影响到外面的元素**，反之亦然；

### BFC触发条件

- 页面的根元素

- fieldset元素

- float  除了none以外的值——**浮动**

- overflow  除了visible 以外的值（`overflow: hidden |auto | scroll` ）

- `position: absolute |fixed ` ——**绝对定位**

- `display : table-cell | table-caption |inline-block`

  `display:table` 本身并不会创建BFC，但是它会产生匿名框(anonymous boxes)，而匿名框中的`display:table-cell`可以创建新的BFC。

### BFC特性

- 同一BFC中上下相邻子元素上下外边距（margin）值叠加。
- 同一BFC中每一个子元素的外边距和包含块的左边界相接触（对于从右到左的格式化则是右外边距和右边界相接触）——除非这个子元素也创建了一个新的BFC（比如浮动）。
- BFC会完全包含内部的浮动元素（闭合浮动）。
- BFC区域不会与浮动元素区域相重叠。

# 其他

- JavaScript中设置元素对象style的float，不能直接使用float（这是JavaScript保留字），而必须使用cssFloat。

  示例：`element.style.cssFloat="left"` 。