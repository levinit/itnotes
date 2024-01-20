[TOC]

---

# 说明

- `.center`表示要被居中的元素，`.wrap` 表示要居中的元素的父元素（包含`.center`元素的元素）。

  为了便于理解和叙述同一：

  - 对于文本内容居中的情况，`.wrap`就是指包含文字的元素（例如`<i>文字</i>` ，i标签就是`.wrap` ）。

    文本内容会在外部创建一个行框（line-box），可以将文本看作是一个（外框隐形）的**行内元素** ，line-box内部可以包含普通文本框、inline-block元素、inline元素。

  - 将文本内容包含在一个容器中（‘父亲’），然后再将该容器在另一个容器（‘祖父’）内居中不看作是文本内容居中，而是该文本内容外部容器的居中（‘父亲’在’祖父‘内居中）。

- **须知某些情况不设置元素宽高、边框色/背景，无法看出居中效果，也就无所谓居中与否**。

  例如父容器不设置背景或边框，无法看出子元素是否居中，**示例代码只是写出了该居中方法所需要的那部分样式** 。

- **inline元素**，准确来说，是不可替换（non-replace）的inline元素，**不能设置竖直方向上的margin和padding**，下不赘述。（margin同理）

  参看[margin规定](http://www.w3.org/TR/CSS2/box.html#margin-properties)和[padding规定](http://www.w3.org/TR/CSS2/box.html#padding-propertie) ，之所以不能设置margin/padding，是因为

  > padding的值是根据目标元素的width计算出来的，而inline中的non-replace元素的width是不确定的。



- CSS兼容性情况未作说明，具体自行查阅[caniuse](http://caniuse.com/)。
- 推荐使用那些不必使用到精确数值（如50px，20rem这种情况，百分比值50%除外）的方法。

---

# 行内内容的居中

如何让一个容器的行内内容（文本和行内元素--inline/inlineblock）居中。（当然inline-block比较特殊，即有行内属性，又有块级属性）

## text-align:center水平居中

在**块级元素**上设置`text-align:center`，其内部的**inline或inline-block**的子元素以及**文本内容**会在父元素内居中。

## line-height垂直居中

line-height设置了行间的距离（行高），将要居中的元素的line-heigth值设置为和其**块级父元素**的height值一样时，其内部内容会垂直居中。

用于**单行的行内元素**的垂直居中

```css
.wrap{
  height:100px;
  line-height: 100px;
}
```

注意：

- line-height不能使用负值


- 在块级元素使用line-height是定义该元素基线之间的最小距离而不是最大距离。

## vertical-align:middle垂直居中

vertical-align的使用效果要分为以下不同情况：

- 行内元素inline/linline-block/inline-table

  - 块级元素（block/inline-block）高度完全由子行内元素撑开

    为其中**确定父元素基线的子行内元素**设置垂直居中即可。

    例如某div中有img和span，高度由img撑开，根据父元素基线确定规则，该情况下div的基线由img的margin-box下边界确定，因此对img设置垂直居中：

    ```css
    .wrap img{
        vertical-align: middle;
    }
    ```

  - 块级元素（block/inline-block）不由子行内元素撑开

    可为使用为该块级元素添加伪元素（子元素），令该**伪元素高度为100%**，这样该**块级元素的基线便由添加的伪元素确定**，对该**伪元素设置垂直居中即可**。

    接上条示例，div高度高于img的高度，div高度不由img撑开，为div添加一个伪元素，伪元素高度为100%就相当于div高度由伪元素撑开，div基线由伪元素margin-box下边界确定，因此对该伪元素设置垂直居中：

    ```css
    .wrap::before{ //或者::after
      content: '';
      display: inline-block;
      height: 100%;
      vertical-align: middle;
    }
    ```

---

**基线**

直接对一个inline-block元素（或block、list-item）设置`vertical-align:middle`往往不能让其内部的达到预期的垂直居中效果，因为：

> vertical-align取值是**相对于父元素**来说的

例如`vertical-align:baseline`（vertical-align的默认值）是相对于父元素的**基线**对齐，`vertical-align:middle`是相对与父元素的中线对齐（**中线位置受到基线的影响**）。

父元素的基线确定规则：

- 子元素是inline类：父元素的基线就是inline元素的文本的基线——基线的位置以（当前元素默认字体的）**小写字母x的底端**确定，font-size和line-height都会对其产生影响。

  注意：**设置为middle也不一定是真正的对齐**，**不同风格的字体**常有**不同的排版标准**，因此**有不同的基线/中线/顶线**等，某些字体的中线位置不一定顶部和底部的正中间，多种字体混合排版会让基线发生变化。

- 子元素是inline-block类

  - > 正常流内容的情况下，`inline-block`元素的baseline就是最后一个作为内容存在的元素的baseline

  - > 在overflow属性不为visible的情况下，baseline就是margin-box的下边界

  - > 在没有内容但是内容区还有高度的情况下，baseline还是margin-box的下边界。

- 子元素是可替换元素（如img）

  无论display设置为inline还是inline-block，父元素基线都为该子元素的margin-box的下边界。

- 存在有多个基线时（如不同的字体），以最低者为准。

---

- 表格单元格（table-cell）元素

  在单元格上设置`vertical-align:middle`，其内部内容将垂直居中。

- [`::first-letter`](https://developer.mozilla.org/zh-CN/docs/Web/CSS/::first-letter) 和 [`::first-line`](https://developer.mozilla.org/zh-CN/docs/Web/CSS/::first-line) 伪元素  （同第一条行内元素）



# 块级元素居中

block、list-item、inline-block等元素如何在其父元素中居中。

## margin/padding值设置居中

最基础的方法是设置**精确的**padding（父元素上）或margin（子元素上）**值**使得子元素居中，这里不再示例。

### clac计算数值

margin值为 父容器宽/高的50% 减去 自身宽/高的50%：

```css
.center{
  width: 20rem;height: 20rem;
  margin-left:calc(50% - 10rem);
  margin-top:calc(50% - 10rem);
}
```

注意：inline水平的元素margin/padding设置**仅在左右方向上有效**。

### margin:0 auto左右居中

要居中的**块级元素（block）**元素设置`margin:0 auto` 。

注意：**对浮动元素、绝对定位和固定定位的元素无效** 。（注意：使用绝对定位+[偏移量0+margin:auto](偏移量0+margin:auto)方法中使用了四个方向的值为0偏移量例外）

---

附：

注意margin/pading

> 百分比值参照其**包含块的宽度**进行计算

因此使用`margin:auto`并不能实现垂直方向上的居中，垂直居中最好不要使用`margin/pading`来实现。（当然如果确切知道父容器的高度，使用精确的margin/pading数值来实现不再此讨论之列）

## position:absolute居中

在父元素上设置定位，再在要居中的子元素上使用绝对定位进行居中。

最基础的方法：计算出要居中的元素宽高与父容器宽高的差值，然后将差值除以2得到精确的值，再用以设置精确的水平和垂直偏移量；

其次是设置水平和垂直偏移量鸽50%，然会设置水平和垂直的负margin值——取值分别为要居中的子元素宽高的半。

以上方法均需要使用容器宽高的确切值，灵活性较差，以下方法更为灵活：

### 偏移量50%+负margin值

设置50%的水平和垂直偏移，然后设置的margin-top和margin-left值是要居中元素自身宽/高的一半的负数 ：

```css
.wrap {
  position: relative;
}
.center {
  position: absolute;
  height: 100px;width:100px;
  top: 50%;left:50%;
  margin-top:-50px;
  margin-left:-50px;
}
```
### 偏移量50%+负50%translate值

使用位移transform:translate，将设置了50%偏移的子元素”往回”移动自身宽高的一半：

```css
.wrap {
  position: relative;
}
.center {
  position: absolute;
  top: 50%;
  left:50%;
  transform: translate(-50%,-50%);
}
```

### 偏移量0+margin:auto

父元素设置相对或绝对定位；要居中的子元素设置绝对定位，所有偏移量为0，外边距为auto：

```css
.wrap{
  positon:relative;
}
.center{
  position:absolute;
  top:0;bottom:0;left:0;right:0;
  margin:auto;
}
```
## flex弹性布局居中

父元素设置为弹性盒子（容器），子元素就成为了弹性元素，利用flex相关属性进行居中。

更多flex相关信息>>[MDN-弹性盒子](https://developer.mozilla.org/zh-CN/docs/Web/CSS/CSS_Flexible_Box_Layout/Using_CSS_flexible_boxes)

- 父元素设置为弹性容器`display:flex`，并设置弹性容器内主轴/侧轴`justify-content/align-content`值为`center`：

  ```css
  .wrap{
    display:flex; /*使用flex盒子*/
    justify-content:center;/*主轴上居中*/
    align-items:center;/*侧轴上居中*/
  }
  ```

  主轴默认时水平方向，侧轴时垂直方向

- 父元素设置为弹性容器`display:flex`，子元素设置`magrin:auto` ：

  ```css
  .wrap{
    display:flex;
  }
  .child{
    margin: auto;
  }
  ```

  

---

注意：

- 如果有多个弹性子元素，默认情况下弹性子元素会成一横排分布在父元素容器中，因为
  1. flex默认将子元素水平排列到一行（`flex-direction:row`），使用`flex-direction:column`可以使子元素垂直排成一列。
  2. flex默认子元素不折行显示（`flex-wrap: nowrap` ），使用`flex-wrap: wrap`可使子元素自动折行显示（当一行宽/高度不足容下多个子元素时折行为多行/列）。
- 弹性盒子的主轴不是固定的，它由弹性子元素的排列方式（flex-direction）决定。


- `align-items`和`align-content`区别：

  - `align-content`属性只适用于**多行子元素**（超过一行，当然如果主轴是垂直轴，则应该称为多列，下同）的 flex 容器，**如果只有一行子元素，该属性不起作用；**`align-items`适用于任意行子元素的`flex`容器。
  - `align-content`是设置一列子元素在整个侧轴上的对其方式；而`align-items`是设置每个子元素在该行的高度范围内的侧轴上的对齐方式，相当于将侧轴按行平分，设置的是子元素在该行高度范围内的对齐方式。


## object-fit和object-postion居中

**object-fit 只能用于[可替换元素](https://developer.mozilla.org/zh-CN/docs/Web/CSS/Replaced_element)(replaced element) **，用以

> 指定替换元素的内容应该如何适应到其使用的高度和宽度确定的框。

一般用做图片的样式。它有着类似background-image的用法：

```css
.center{
	object-fit:fill|cover|contain|none|scale-down;
/*其属性值，分别是填充（默认）、包含、覆盖（可能被裁剪）、无变化（保持原状）和等比例缩放*/
}
```
而object-positon属性默认值是`50% 50%`，也就是居中(也就是要求居中的情况不用写这个属性了……），对元素定位控制，类似background-postion。

## grid网格布局居中

根据需要布局网格，将要居中的元素“摆放”在网格中间即可。

示例制作3x3的表格内元素居中：

```css
.wrap{
  display:grid;
  grid-template-rows: repeat(3, 1fr);
  grid-template-columns: repeat(3, 1fr);
}
.center{
  grid-row: 2;
  grid-column: 2;
}
```



# 表格内容居中

- 表格式布局：根据语义化原则，使用表格布局非表格的内容已不再合适，而且表格的`<td>` `<th>`标签的align和valign属性已经是HTML的废除标签属性，**建议不要使用**。
- 非表格元素模拟表格：可以使用`display:table-cell` 模拟其为一个表格，由于不建议使用废除的align和valign标签属性，故而也就`vertical-align:middle` 垂直居中具有实用性，将元素模拟成表格进行垂直居中意义也不大了，因此**建议不要使用**。
- 真正的表格，**表格内容的居中**：
  - 水平：`text-align:center` 
  - 垂直：`vertical-align:middle`
  - 也可以使用margin/pading等其他方法来控制表格内容的居中

