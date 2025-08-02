[TOC]

# 基本流程

基本绘制流程（[图像绘制](#图像绘制)和[合成](#合成)不需要第3-5布，直接使用相关方法即可）。

1. 创建画布——html的canvas标签

   ```javascript
   <canvas id="canvas"  width="300" height="300" ></canvas>
   ```

   注：

   - canvas标签是一个内联元素。
   - canvas画布默认是透明的。
   - canvas的宽高也可以在JavaScript中使用canvas的context对象的`.width`方法和`.height`方法进行设定。

2. 获取画布——javascript的获取canvas对象

   获取canvas元素对象后，再使用`getContext(contextID)`方法获取context对象：

   ```javascript
   const canvas=document.getElementById("canvas");
   const context=canvas.getContext("2d");
   ```

3. 确定坐标系——可选 画布坐标系默认是**左上角**为坐标轴的原点(0,0)

   可使用`context.translate(x,y)`重新确定坐标系原点(重新映射(0,0)位置)。

4. 设置[路径](#路径)和画笔[样式](样式)

5. 进行绘制

   - `context.fill();`  填充绘制
   - `context.stroke();`  描边绘制

---

# 画笔样式

## 线条风格

```javascript
context.lineCap="butt|round|square";  //端点风格
context.lineJoin="miter|bevel|round";  //拐点风格
context.lineWidth=number;  //线条粗细
context.miterLimit=number;  //最大斜接长度
```

- 端点风格：定义线条端点的样式（lineCap线条的帽子）。
  - butt：默认值，端点是垂直于线段边缘的平直边缘。
  - round：端点是在线段边缘处以线宽为直径的半圆。
  - square：端点是在选段边缘处以线宽为长、以一半线宽为宽的矩形。


- 拐点风格：定义两条线条相交产生的拐角（连接）处的样式。

  - miter：默认值，在连接处边缘延长相接。miterLimit：角长和线	宽所允许的最大比例(默认是10)。
  - bevel：连接处是一个对角线斜角。
  - round：连接处是一个圆。

- 线条粗细：定义线条粗细，值为一个数字，默认值为1.0。

- 最大斜接长度：设置或返回最大斜接长度，值是正数。

  规定最大斜接长度。如果斜接长度超过 miterLimit 的值，边角会以 lineJoin 的 "bevel" 类型来显示。

## 颜色

```javascript
 //颜色
context.fillStyle="color";
context.strokeStyle＝

//颜色渐变
//1. 添加渐变
var grd = context.createLinearGradient(x1,y1,x2,y2);  //线性渐变：起始坐标x1,y1　结束坐标x2,y2
var grd = context.createRadialGradient(x0,y0,r0,x1,y1,r1);  //径向渐变。x0,y0为圆心坐标，r为半径
//2. 为渐变线添加关键色
grd.addColorStop(stop,color);  //stop是0-1间的浮点数 指颜色断点到(xstart,ystart)的距离占整个渐变色长度是比例

//3. 应用渐变：
context.fillStyle = grd;
context.strokeStyle = grd;

//填充纹理
var img=new Image();  //1.创建Image对象
img.src="path.jpg"  //2.指定Image对象实例img的图片来源
var  pattern = context.createPattern(img,"repeat");  //3.应用图片进行纹理填充
context.fillStyle = pattern;  //进行填充
```

- 颜色
- 颜色渐变：分为线性渐变（LinearGradient）和径向渐变（RadialGradient）。
- 纹理：纹理就是图案的重复，填充图案通过`createPattern(img,repeat-style)`方法实现。img是一个Image对象实例，repeat-style是重复类型：
  - 平面上重复：repeat;
  - x轴上重复：repeat-x;
  - y轴上重复：repeat-y;
  - 不使用重复：no-repeat;
## 阴影

```javascript
context.shadowColor = "red";//阴影颜色
context.shadowBlur= 2;//阴影模糊半径
context.shadowOffsetX = 5;//阴影x轴位移
context.shadowOffsetY = 5;//阴影y轴位移
```

# 路径

## 移动画笔

移动画笔的点来

```javascript
context.moveTo(x,y);
```

## 直线

创建当前坐标点到指定坐标点的线条

```javascript
context.lineTo(x,y)；
```

## 曲线

### 圆弧/圆

```javascript
context.arc(x,y,radius,startAngle,endAngle,anticlockwise);  //标准圆弧
context.arcTo(x1,y1,x2,y2,r);  //使用切点绘制圆弧
```
- 标准圆弧：arc()方法

  x,y是圆心坐标，radius是半径。

  startAngle、endAngle使用的是**弧度值**。

  anticlockwise表示绘制的方法，包括顺时针（false）和逆时针（true）绘制，默认是顺时针（false）。


- 使用切点绘制圆弧：arcTo()方法

  x1,y1和x2,y2分别是两个切点的坐标，radius是圆弧半径。

  圆弧的起点与当前路径的位置到(x1, y1)点的直线相切，圆弧的终点与(x1, y1)点到(x2, y2)的直线相切。

### 贝塞尔曲线

[贝塞尔曲线](cubic-bezier.com/)是一条由起始点、终止点和控制点所确定的曲线。n阶贝塞尔曲线就有n-1个控制点。

```javascript
context.quadraticCurveTo(cpx,cpy,x,y);  //二次贝塞尔曲线（quadraticCurve）
context.bezierCurveTo(cp1x,cp1y,cp2x,cp2y,x,y);  //三次贝塞尔曲线（bezierCurve）
```

cpx,cpy等是控制点（control point）坐标，x,y是起始点和终止点点坐标。

## 矩形

```javascript
rect(x,y,width,height);  //矩形路径
context.fillRect(x,y,width,height);  //或者直接确定路径并绘制--填充
context.stroke(x,y,width,height);  //或者直接确定路径并绘制--描边
context.clearRect();  //擦除
```
x,y为起始坐标点，widht和height是矩形的宽高。

- 擦除：在给定的矩形内清除指定的矩形区域。

## 裁剪

```javascript
context.clip();
```

按前面定义的路径进行裁剪。

注意：裁剪是对画布进行的，裁切后的画布不能恢复到原来的大小。要保证最后仍然能在canvas最初定义的大小下绘图需要注意save()和restore()。

## 路径间隔

```javascript
context.beginPath();//开始新的绘制路径或重置当前路径
//一些绘制代码　路径绘制参看后文的路径　
context.closePath();//结束此次绘制返回起始点路径](#路径)
```

不同的绘制路径代码最好用以上方法**前后**包裹。分隔不同绘制路径，可避免后方路径的状态设置覆盖前面路径的状态设置。

如果**绘制闭合图形，不使用`closePath();`会导致闭合缺口**（笔画越粗越明显）。

# 图形变换

```javascript
context.translate(x,y);  //平移
context.rotate(angle);  //旋转
context.scale(sx,sy);  //缩放
context.transform(a,b,c,d,e,f) ;  //矩阵
```

每次变换完毕后继续变换，新的变换是基于新坐标系进行的，为了避免使用混乱，在每次变换后最好
**将坐标系平移回原点，即调用translate(-x,-y)**，
或者

存储[画布状态](#画布状态)：**在每次变换之前使用context.save()，在每次绘制后使用context.restore()**。

- 平移：x,y是要平移到的目标坐标点。

- 旋转：angle必须是**弧度**(可用`角度值*Math.PI/180`换算)，旋转是以坐标系的原点(0,0)为圆心进行的顺时针旋转。

- 缩放：sx和sy分别是水平方向和垂直方向上对象的缩放倍数。
  缩放并非缩放的是图像，而是整个坐标系、整个画布。
  缩放时，图像左上角坐标的位置也会对应缩放（左上角坐标为0,0除外）；图像线条的粗细也会对应缩放。

- 矩阵:

  > a c e
  >
  > b d f
  >
  > 0 0 1
  - 缩放 ad（1和4）
  - 倾斜 bc（2和3）
  - 位移 ef（5和6）

# 文本

```javascript
//显示
context.font = "50px serif";  //设置字体
context.fillStyle = "#00AAAA";  //设置字体颜色
context.fillText(text,x,y,maxWidth);   //显示字体。

//对齐
context.textAlign="center|end|left|right|start";  //水平
context.textBaseline="alphabetic|top|hanging|middle|ideographic|bottom";  //垂直

//度量
context.measureText(text).width;

//渲染文字
context.fillText(String,x,y,[maxlen]);  //描边方式
context.strokeText(String,x,y,[maxlen]);  //填充方式
```

- 显示

  - font属性：字体（同CSS font写法）

  - fillStyle属性：颜色（同CSS color写法）

  - fillText()方法：要显示的内容

    text是要显示的文本，(x,y)是绘制文本的坐标位置，maxWidth可选，是允许的最大文本宽度（以像素计）。

- 对齐

- 度量：度量文本的长度，可用于如判断字符长度超出一定值的时候使用换行显示（配合fillText/strokeText使用）。

- 渲染

  String是要显示的文字（字符串，使用引号），x,y是开始显示的坐标点，maxlen是最大长度（可以不写）
  fillText和strokeText这两个方法也可以使用fillStyle与strokeStyle代替。

# 图像绘制

可以引入**图像、画布、视频**，并对其进行缩放或裁剪。有三种参数形式：

- ３参数：在画布上定位图像：

  ```javascript
  context.drawImage(img,x,y);
  ```


- ５参数：在画布上定位图像，并规定图像的宽度和高度：

  ```javascript
  context.drawImage(img,x,y,width,height);
  ```


- ９参数：剪切图像，并在画布上定位被剪切的部分：

  ```javascript
  context.drawImage(img,sx,sy,swidth,sheight,x,y,width,height);
  ```
  - img  图像、画布或视频来源
  - x和y  在画布上放置图像的坐标
  - sx和sy　可选　开始放置的坐标点
  - swidth和sheight　可选　被剪切图像的高度
  - width和height　可选　要使用的图像的高度

# 合成

```javascript
context.globalAlpha=number;
context.globalCompositeOperation
```

- 透明：取值在0-1之间的浮点数。

- 重合：将一个图象放置到当前画布上已经存在的图象上。

  - source-over 

    默认。在目标图像上显示源图像。

  - source-atop

    在目标图像顶部显示源图像。源图像位于目标图像之外的部分是不可见。

  - source-in

    在目标图像中显示源图像。只有目标图像内的源图像部分会显示，目标图像透明。

  - source-out

    在目标图像之外显示源图像。只会显示目标图像之外源图像部分，目标图像透明。

  - destination-over

    在源图像上方显示目标图像。

  - destination-atop

    在源图像顶部显示目标图像。源图像之外的目标图像部分不会被显示。

  - destination-in

    在源图像中显示目标图像。只有源图像内的目标图像部分会被显示，源图像透明。

  - destination-out

    在源图像外显示目标图像。只有源图像外的目标图像部分会被显示，源图像透明。

  - lighter

    显示源图像和目标图像。

  - copy

    显示源图像。忽略目标图像。

  - xor

    使用异或操作对源图像与目标图像进行组合。

# 非零环绕
笔画复杂交错的循环路径图形存在着多个相交的子路径，需要对其填充（fill）时必须要判断，可以使用非零环绕原则来辅助判断哪块区域是里面，哪块区域是外面。

>非零环绕规则（Nonzero Winding Number Rule） ：使多边形的边变为矢量。 将环绕数初始化为零。

canvas填充使用非零环绕方法：
给图形确定一条路径，“一笔画”且“不走重复路线”。
>非零环绕规则计数器：
>将计数器初始化为0，每当这个线段与路径上的直线或曲线相交时，就改变计数器的值：
>如果是与路径顺时针相交时，那么计数器就加1， 如果是与路径逆时针相交时，那么计数器就减1。
>如果计数器始终不为0，那么此区域就在路径范围里面，在调用fill()方法时，浏览器就会对其进行填充。如果最终值是0，那么此区域就不在路径范围内，浏览器就不会对其进行填充。

# 画布状态

```javascript
context.save();//保存画布状态到堆栈
context.restore();//恢复存储的画布状态
```