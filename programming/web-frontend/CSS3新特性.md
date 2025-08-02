CSS3 新特性整理

---

[]括起来的内容表示可选项，|分隔的项目表示所有可使用的项。默认值可省略。

[TOC]

# 尺寸 size

## 用户调整尺寸 resize

`resize: none|both|horizontal|vertical;`

## 响应式尺寸 response size

`max/min-width/height`

注意：应用于图片时，尺寸大小不可能变化到大于其原始大小。

## 盒子尺寸 box-sizing

`box-sizing: content-box|border-box|inherit`

# 边框风格 border style

## 轮廓 outline

`outline:[outline-color] [outline-style] [outline-width] [outline-offset] |inherit`

* 颜色 outline-color：color | invert | inherit
* 风格 outline-style：none | dotted | dashed | solid | double | groove | ridge | inset | outset | inherit
* 宽度 outline-width： thin | medium | thick | length | inherit

## 轮廓偏移 outline-offset

在 border 边缘外的偏移。Outlines 在两个方面不同于边框：Outlines 不占用空间； Outlines 可能非矩形。

## 盒阴影 box-shadow

`box-shadow: h-shadow v-shadow [blur] [spread] [color] [inset]`
h 是水平方向上的阴影，v 是垂直方向上的阴影。盒阴影默认默认在外侧。
h 和 v 设置为 0 并设置 blur 模糊、spread 扩展的值，可以实现盒子边框四周阴影。

## 边框圆角 border-radius

`border-radius:px|em|%|rem`

注意：百分比值以该元素宽度为标准的。

## 边框图像 border-image

`border-image: border-image-source border-image-slice border-image-repeat`
**图片来源、图片偏移值和图片铺排方式是必须的三个值。** border-image 用于设置:

* `border-image-source: url()|none`

* `border-image-slice: number|%|fill`

* `border-image-repeat: stetch|repeat|round|space|initial|inherit`

* `border-image-width:number|%|auto`

* `border-image-outset: length|number` 

  注意：number 是倍数值。

  # 背景 background

## 背景图像 background-image

* 图像来源 `background-image: url()`

* 背景尺寸 `background-size: length|percentage|cover|contain;`

* 背景区域 `background-origin: padding-box|border-box|content-box;`

* 背景绘制 `background-clip: border-box|padding-box|content-box;`

## 渐变 gradient

渐变的颜色值后可跟上（空格隔开）百分比，用以确定颜色的百分比分布值。

* 线性渐变 linear-gradient

  `background: linear-gradient(direction color-stop1 color-stop2, ...);`

  direction 指定渐变的方向（或角度）。

- 重复的线性渐变：

  `background: repeating-linear-gradient(direction color-stop1 color-stop2 ...);`

- 径向渐变 radial-gradient

  `background: radial-gradient(shape size position start-color ... last-color);`

  shape 确定圆的类型: ellipse （默认），椭圆形的径向渐变； circle 圆形的径向渐变。size 定义渐变的大小：farthest-corner (默认) |closest-side |closest-corner|farthest-side；position 定义渐变的位置：center（默认）|top|bottom

* 重复径向渐变如：

  `background: repeatin-gradial-gradient(shape size position start-color ... last-color);`

# 文字和字体 text and font

## 文本效果 text effect

* 文本阴影 `text-shadow: h-shadow v-shadow [blur] [color];`
* 文本溢出 `text-overflow: clip|ellipsis|string;`
* 文本轮廓 `text-outline: thickness [blur] [color];`
* 文本换行 `text-wrap: normal|none|unrestricted|suppress;`
* 长文本换行断词 `word-wrap: normal|break-word;`
* 非中日韩文本断行 `word-break: normal|break-all|keep-all;`
  ……

## 网络字体@font-face

```css
@font-face{
  font-family:font-name;/*规定字体的名称*/
  src:url(xx);/*字体来源地址*/
  font-stretch：/*如何拉伸字体 可选*/
  font-style: /*文字风格 可选*/
  font-weight: /*字体粗细 可选*/
  unicode-range：/*定义字体支持的 UNICODE 字符范围（默认是 "U+0-10FFFF"） 可选*/
}
```

# 变换 transform

## 变换基准点 transform-origin

`transform-origin: x-axis y-axis z-axis;`

用于更改转换元素的位置。x-axis|y-axis|z-axis 设置试图被置于 x|y|z 轴的何处。

* x-axis:left|center|right|length|%

* y-axis:top|bottom|center|length|%

* z-axis:lenght

## 变换元素呈现方式 transform-style

`transform-style: flat|preserve-3d;`

flat 所有子元素在 2D 平面呈现。preserve-3d 所有子元素在 3D 空间中呈现。

## 2D 变换 2d transform

`transform:none|transform-function``

* 位移`translate(x,y)`
* 旋转`rotate(angle)`
* 缩放`scale(x-nmber,[y-number])`
* 倾斜`skew(x-angle,[y-angle])`
* 矩阵`martrix(a,b,c,d,e,f)`

> a db ec f

坐标(x,y)在的算法：

> x=ax+cy+ey=bx+dy+f

tanslate(x,y)--matrix(1,0,0,1,x,y)

scale(x,y)---matrix(x,0,0,y,0,0)

skew(x,y)---matrix(1,tan(θy),tan(θx),1,0,0)

rotate(θ)---matrix(cosθ,sinθ,-sinθ,cosθ,0,0)

## 3D 变换 3d transform

`transform:none|transform-function`

transform-function 变换方法包括：

* 位移 `translate3d(x,y,z)`

* 旋转 `rotate3d(x,y,z,angle)`

* 缩放 `scale3d(x-nmber,y-number,z-number)`

* 矩阵 `martrix(a,b,c,d,e,f,h,i,j,k,l,m,n,o,p,q)`

* 透视 `perspective(n|none)`n 是像素值，书写不带 px 单位。

* 3D 元素透视基准 `perspective-origin: x-axis y-axis;`

  3D 元素所基于的 X 轴和 Y 轴。x-axis 定义该视图在 x 轴上的位置（默认值：50%）： left|center|right|length|%y-axis 定义该视图在 y 轴上的位置（默认值：50%）： top|center|bottom|length|%

- 3D 元素背面可见性 `backface-visibility: visible|hidden;`

**2D 和 3D 变换都可以单独设置一个轴的变换方式，如`translateX(x)`。**

# 过渡 transition

过渡是元素从一种样式逐渐改变为另一种的效果。

* 简写方法：`transiton：property duration [timing-function] [delay];`，默认值分别对应：all 0 ease 0

  简写方法相当于：

  * 应用的属性（可选，不设置则默认为全部[可使用过渡效果的属性](https://developer.mozilla.org/zh-CN/docs/Web/CSS/CSS_animated_properties)）

    `transition-property: none|all|property;`

    property 定义应用过渡效果的 CSS 属性名称列表，all 则会应用到所有 CSS 属性上。

  * 耗时（必须，原因是默认值为 0，没有过渡效果，过渡无意义）

    `transition-duration: time;`

  * 过渡速度变化曲线（可选）

    `transition-timing-function: linear|ease|ease-in|ease-out|ease-in-out|cubic-bezier(n,n,n,n);`

    可参看[贝塞尔曲线 cubiz-bezier](cubic-bezier.com)

  * 过渡延迟时间（可选）

    `transition-delay: time;`

  ​

* 要实现效果，需要：

  1. 给目标元素设置 transition
  2. 给目标元素添加过渡效果的触发方式（如 hover、事件监听）及过渡效果完毕后的最终样式。（**必须**）

  * 使用事件监听：在目标元素对象事件处理函数中设置目标元素对象的最终样式。

```html
<div></div><!--要应用过渡效果的元素-->
<style>
div{
	transition: width 2s;/*该元素需要实现的过渡效果：针对宽度变化，过渡时间持续2秒*/
    width:100px;height:100px;background:red;
}
div:hover{/*当悬停在该元素上触发效果*/
	width:300px;/*过渡效果完毕后的状态*/
}
</style>
```

# 动画@keyframes

一个动画效果包括两部分 CSS 样式：动画规则部分规定动画的具体实现方式，动画属性部分用以绑定动画规则以及设置该绑定的动画。

## 动画规则 animation rule

`@keyframes animationname {keyframes-selector {css-styles;}}`

* animationname 必需的 定义 animation 的名称。
* keyframes-selector 必需的 动画持续时间的百分比：0-100%|from (和 0%相同)|to (和 100%相同)
* css-styles 必需的 一个或多个合法的 CSS 样式属性

## 动画属性 animation properties

`animation: name duration [timing-function] [delay] [iteration-count] [direction] [fill-mode] [play-state];`

* 动画名称`animation-name: *keyframename*|none;`

animation-name 属性为 @keyframes 动画指定名称。

* 动画耗时`animation-duration:time;`

* 动画速度变化曲线：`animation-timing-function: linear|ease|ease-in|ease-out|ease-in-out|cubic-bezier(n,n,n,n);`

* 动画延迟时间`animation-delay: *time*;`

* 动画播放次数`animation-iteration-count: n|infinite;`

  n 是播放的次数（阿拉伯数字），infinite 是无限次播放。

* 动画反向播放`animation-direction: normal|reverse|alternate|alternate-reverse|initial|inherit;`

  * reverse 反向播放
  * alternate 动画在奇数次（1、3、5...）正向播放，在偶数次（2、4、6...）反向播放。
  * alternate-reverse 动画在奇数次（1、3、5...）反向播放，在偶数次（2、4、6...）正向播放。

* 动画运行状态`animation-play-state: paused|running;`

# 媒体查询@media

css 语法：`@media not|only|all mediatype and (expression){css-style}`（注意 and 和小括号之间有一个空格）

也可以 link 样式文件：`<link rel="stylesheet" media="mediatype and|not|only (expressions)" href="cssname.css">`

* mediatype 媒体类型：all|screen|print|speech
* expression 属性：width/height|min/max-width/height|device-width/height|max/min-reslution 等等。

媒体查询可用于检测如：

* viewport(视窗) 的宽度与高度
* 设备的宽度与高度
* 朝向 (智能手机横屏，竖屏) 。
* 分辨率

# 生成内容content

使用伪元素和 content 属性添加内容，content 取值：

* none -- 不生成任何内容
* attr -- 插入标签属性值
* url -- 插入一个外部资源（图像，声频，视频或浏览器支持的其他任何资源）
* string -- 插入字符串

```css
.cf:after {
  content: '';
  display: table;
}
```

# 弹性盒子 flexbox

弹性盒子由弹性容器(Flex container)和弹性子元素(Flex item)组成。弹性容器内包含了一个或多个弹性子元素。

## 弹性容器flex-container的属性

- 使用弹性盒子 `display:flex`或`display: inline-flex`

  使用该属性后，该容器成为弹性盒子。注意：默认弹性盒子内主轴是水平轴，所有子元素排列在一行。

- 子元素排列方式

  `flex-flow: [flex-direction]|[flex-wrap]|initial|inherit;`

  - 子元素排列方向

    `flex-direction: row|row-reverse|column|column-reverse|initial|inherit;`

    每个弹性框布局包含两个轴，弹性项目沿其依次排列的那根轴称为**主轴(main axis)** ，垂直于**主轴**的那根轴称为**侧轴(cross axis)**。因此，flex-direction 的可以确立主轴（默认情况下排列方式是水平排列，因此默认情况下主轴是水平轴或者说横轴）。

  - 子元素换行方式

    `flex-wrap: nowrap|wrap|wrap-reverse|initial|inherit;`

    **默认**情况每个容器只有一行（因为默认的 flex-wrap 值是 nowrap）。

- 子元素在主轴的对齐方式

  `justify-content: flex-start|flex-end|center|space-between|space-around|initial|inherit;`

- 子元素在侧轴的对齐方式

  - `align-items: stretch|center|flex-start|flex-end|baseline|initial|inherit;`
  - `align-content: stretch|center|flex-start|flex-end|space-between|space-around|initial|inherit;`

  使用区别：

  - `align-content`属性只适用于**多行子元素**（超过一行，当然如果主轴是垂直轴，则应该称为多行，下同）的 flex 容器，**如果只有一行子元素，该属性不起作用；**`align-items`适用于任意行子元素的`flex`容器。
  - `align-content`是设置一列子元素在整个侧轴上的对其方式；而`align-items`是设置每个子元素在该行的高度范围内的侧轴上的对齐方式，相当于将侧轴按行平分，设置的是子元素在该行高度范围内的对齐方式。

## 弹性子元素flex-items的属性

- 子元素出现的顺序

  `order: number|initial|inherit;`

- 某个子元素在**交叉轴**上的对齐方式

  `align-self: auto|stretch|center|flex-start|flex-end|baseline|initial|inherit;`

  该属性需写在子元素的样式上。

- 子元素空间分配

  `flex: [flex-grow]|[flex-shrink]|[flex-basis]|auto|initial|none|inherit;`

  其中auto相当于1 1 auto ，none相当于0 0 auto，intial相当于0 1 auto

  - 弹性盒子伸缩基准值`flex-basis: number|auto|initial|inherit;`
  - 弹性盒子的扩展比率`flex-grow: number|initial|inherit;`
  - 弹性盒子的收缩比率`flex-shrink: number|initial|inherit;`

# 网格布局grid

//todo

# 多列 columns

* 列宽和列数`columns: column-width column-count;`

  * 列宽`column-width: auto|length;`
  * 列数`column-count: n|auto;`

* 列间距`column-gap: length|normal;`
  normal 指定一个列之间的普通差距。 W3C 建议 1EM 值。

* 列间样式`column-rule: column-rule-width column-rule-style column-rule-color;`

  * `column-rule-width` 设置列中之间的宽度规则
  * `column-rule-style` 设置列中之间的样式规则
  * `column-rule-color` 设置列中之间的颜色规则

* 跨列数`column-span: 1|all;`

* 列填充`column-fill: balance|auto;`

  balance 列长短平衡。浏览器应尽量减少改变列的长度

# 图片滤镜 image filter

`filter: none | blur() | brightness() | contrast() | drop-shadow() | grayscale() | hue-rotate() | invert() | opacity() | saturate() | sepia() | url();`

* blur(px) 高斯模糊 这个参数可设置 css 长度值(但不接受百分比值） 默认 0
* brightness(%) 亮度 默认 1
* contrast(%) 对比度 默认 1
* drop-shadow(h-shadow v-shadow blur spread color) 阴影效果（接受<shadow>(在 CSS3 背景中定义)类型的值，除了"inset"关键字）该函数与已有的 box-shadow box-shadow 属性很相似；_不同之处在于，通过滤镜，一些浏览器为了更好的性能会提供硬件加速。_
* grayscale(%) 灰度 默认 0
* hue-rotate(deg) 色相旋转 默认 0deg
* invert(%) 反转输入图像 默认是 0
* opacity(%) 透明度 默认 1
  该函数与已有的 opacity 属性很相似，_不同之处在于通过 filter，一些浏览器为了提升性能会提供硬件加速。_
* saturate(%) 饱和度 默认。
  * sepia(%) 转换为深褐色 默认 0
* url() URL 函数接受一个 XML 文件，该文件设置了 一个 SVG 滤镜，且可以包含一个锚点来指定一个具体的滤镜元素。例如：`filter: url(svg-url#element-id)`

# 选择器 selector

CSS3 新增的选择器

* 元素选择器

  * 同级别`~`：`p ~ ul`

* 属性选择器

  * 以某字符串作为开头的属性值--`^=`
    `a[src^="https"]`--src 属性值以 "https" 开头的 a 元素

  * 以某字符串为结尾的属性值--`$=`
    `a[src$=".pdf"]`--src 属性值以".pdf"结尾的 a 元素

  * 包含某字符串的属性值--`*=`
    `a[src*="abc"]`--src 属性包含 abc 的"a"元素

* 伪类选择器

  * 某（些）类子元素
    * `:only-child`
    * `:first-of-type`
    * `:last-of-type`
    * `:nth-of-type(n)`
    * `:nth-last-of-type(n)`
    * `:only-of-type`
  * 某个子元素
    * `:first-child`
    * `:last-child`
    * `:nth-child(n)`
    * `:nth-last-child(n)`
  * 根元素 `:root`
  * 没有子元素的元素 `:empty`
  * 当前活动的元素 `:target`
  * 选中的元素 `:checked`
  * 非某种（个）元素 `:not(selector)`
  * 启用或禁用的元素元素可以设置 disabled 属性（如果为设置默认 enabled）
    * 启用的元素 `:enabled`
    * 禁用的元素 `:disabled`
  * 有校验属性的元素设置了 min 和 max 的 input 元素以及 email 元素等可以校验输入情况
    * 输入值为非法的元素 `:invalid`
    * 输入值为合法的元素 `:valid`
  * 必要和可选属性的元素表单元素可以设置 required 属性（不设置就是 optional）
    * 有可选的输入元素 `:optional`
    * 有 required 属性的元素 `:required`
  * 读写属性的元素
    input、textarea 等元素可以设置 readonly 属性（不设置则是读写）

    * 有 readonly 属性的元素 `:read-only`
    * 有读写属性的元素 `:read-write`

  * input 区间指定元素
    input 元素可以设置 min 和 max 属性规定输入的区间
    * 指定区间内的 input 元素 `:in-range`
    * 指定区间外的 input 元素 `:out-of-range`

* 伪类选择器
  * 选中的元素 `::selection`