[TOC]

# sass/sCSS简介

SASS(Sassy CSS)是一种CSS的开发工具，提供了许多便利的写法，大大节省了设计者的时间，使得CSS的开发，变得简单和可维护。

## sass和sCSS

实质上是同一种语言，只是采用了两种不同风格的写法：

- sass采用ruby/python的**缩进**风格写法；文件后缀名.sass。
- sCSS采用CSS的大括号风格写法；文件后缀名.sCSS。

注意：**同一个文件**中，**不**能混合使用以上两种写法。

以下均以sCSS为例。

## 安装/更新/删除

- 使用gem，gem需要ruby

  - OSX/FreeBSD/Linux：先用包管理器（或其他方法）安装ruby，如后再使用gem命令（推荐全局安装，需要root或sudo）安装sass。

    ```shell
    dnf install ruby  #centos/fedora等安装ruby
    brew install ruby  #OSX安装ruby
    gem install sass  #安装使用该命令安装sass
    sass --version  #或sass -v 查看sass版本
    gem update sass  #更新sass
    gem uninstall sass  #卸载（删除）sass
    ```

  - windows：前往[rubyinstaller.org](https://rubyinstaller.org/)下载ruby，安装后再使用ruby提供的命令行使用gem安装sass（命令同上）。

- 某些Linux发行版如Arch系、Debian系在官方源中提供了`ruby-sass`这个包（可到此搜索查看：[pkgs.org:ruby-sass](https://pkgs.org/download/ruby-sass) )，可以直接安装使用该发行版的包管理器直接安装/更新/删除。

##编译为CSS

Sass 的编译有多种方法：命令编译、GUI工具编译和自动化编译

sass提供四种编译风格：

> expanded：展开的多行CSS代码，输出的CSS后半部分大括号另起一行。
>
> nested：嵌套缩进的CSS代码，输出的CSS后半部分大括号在行尾。
>
> compact：简洁格式的CSS代码，输出的CSS是单行风格。
>
> compressed：压缩后的CSS代码，输出的CSS去掉了所有的注释和空格。

如果希望压缩后保留注释信息，参看后文[注释](#注释) 。

- 命令行

  - 使用sass的命令

    ```shell
    sass file.sCSS  #在命令行显示生成的CSS
    sass file.sCSS file.CSS   #生成CSS
    sass --watch file.sCSS:file.CSS  #watch参数监听文件/目录的变化，自动生成CSS
    sass --style compressed test.sass test.CSS  #使用压缩风格生成CSS
    ```

  - 使用其他工具：如[compass](http://compass-style.org/)，参看尾部[附-compass](#compass)

    > Sass本身只是一个编译器，Compass在它的基础上，封装了一系列有用的模块和模板，补充Sass的功能。

- GUI工具

  - [Koala](http://koala-app.com/)  支持编译sass/sCSS、less、coffee script；处理javascript（如压缩、格式化等等）、CSS（如果添加浏览器厂商前缀、合并文件等等）；配置compass……
  - [codekitapp](https://codekitapp.com/)和[prepros](https://prepros.io/) （注意这两个软件可能需要付费）

- 自动化编译：如Webpack、Gulp和Grunt（具体参看该工具相关说明文档）

# 语法

## 数据类型

- 数字Number: 如，1、 2、 13、 10px；
- 字符串String：有引号字符串或无引号字符串，如，"foo"、 'bar'、 baz；
- 颜色Color：如，blue、 #04a3f9、 rgba(255,0,0,0.5)；
- 布尔型Boolean：如，true、 false；
- 空值Null：空值，位置的数据，null；
- 值列表List：用空格或者逗号分开的一系列值，如，margin:1.5em 1em 0 2em 、 Helvetica, Arial, sans-serif。
- 映射Map：键值对，映射定义值成组，并且可以被动态访问，如，$map: (FirsyKey: frstvalue, SecondKey: secvalue, Thirdkey: thdvalue);

## 变量

变量**声明和使用均要以`$`开头**；如果变量需要镶嵌在字符串之中，就必须需要写在`#{}`之中。
- 普通变量：定义之后可以在**全局范围**内使用
- 默认变量：在变量的值后面加上` !default`
  设置默认值，如果有其他的值则优先替换为其他值，没有其他值则显示默认值。

重新声明变量可覆盖默认值。

```scss
$lightgray:#eee123;
a{
  color:$lightgray;
}
$side : left;
.rounded {
  border-#{$side}-radius: 5px;
}
$baseLineHeight:1.5 !default;
body{
    line-height: $baseLineHeight; 
}
```

### 变量作用域

- 定义在元素外面的变量是全局变量，全局可用。

  在变量值后使用**`!global`可使其成为全局变量**。

- 定义在元素内部的变量是局部变量，只在该范围内生效。

## 运算

- 运算符号中的加号`+`和减号`-`两边需要有空格。
- 运算时数值的单位类型不同会报错。
- 使用加号`+`可对字符串进行拼接。
  - 两个变量连接，两个变量名将会被拼接为字符串。
  - 前一个字符串有引号，则生成带引号字符串，否则生成不带引号字符串。
- 颜色值支持运算。
  - rgba中单个色值运算结果超过255 , 会把结果作为255；
  - rgba运算，alpha值必须相同；
  - 十六进制中，计算的值超过`#ffffff`就视结果为`#ffffff`。

## 注释

SASS共有两种注释风格：

- C语言风格注释：标准的CSS注释 `/* comment */ `，会保留到编译后的文件。在`/*`后面加一个感叹号，表示这是"重要注释"。即使是[压缩模式编译](#编译为CSS)，也会保留这行注释，例如用于版权信息。
- C++语言风格的注释：单行注释 `// comment`，只保留在SASS源文件中，编译后被省略。

```scss
//注释
/*注释
注释
*/
```

## 嵌套

### 媒体查询@media嵌套

和CSS 的使用方法一样，但是：

- SCSS/Sass中可以将@media样式嵌套在其他样式中。（CSS文件中是不能将@media嵌套到其他样式块中的，当然，编译生成的CSS文件中，@media样式会被提取编写到最外层）
- 在**内层**使用的 @media会**作用到外层**的选择器上。

### 样式嵌套

有两种嵌套：**选择器嵌套**和**属性嵌套**

- `&`：代表&所在的嵌套结构。

```scss
//选择器嵌套
nav {
  a {
    color: red;
    header & {    //此处&就代表了nav a
      color:green;
    }
  }  
}
//属性嵌套
.box{
  border{
    top:1px solid white;
    right:1px solid red;
  }
}
//伪元素选择嵌套--清除浮动的例子
.clearfix{
	&::before,
	&::after {
   		content:"";
    	display: table;
    }
	&::after {
    	clear:both;
    	overflow: hidden;
    }
}
```

提示：避免滥用嵌套——如无提升权重的需要，尽量减少嵌套的使用，尤其是对于class和id选择器。

### 跳出嵌套

- @at-root跳出所有上级选择器（@at-root不能跳出`@media`或`@support` ）

```scss
.parent {
    color:#f00;
    @at-root .child {    //.child已经不属于.parent的下一层级
      	width:200px;
    }
}
```

- `@at-root (without: media)`  跳出媒体查询
- `@at-root (without: support)`  跳出support


- `@rule`   跳出常规CSS
- `@all`   跳出所有  

```scss
@media print {
    .parent3{
     color:#f00;
	@at-root (without: all) {
    .child3 {
    	width:200px;
     } 
   }
  }
}
```

## 复用

### 引入@import

引入外部SCSS 和 SCSS 文件，编译时，引入的内容会被合并进当前文件中输出。

- 引入时可以省略后缀名
- 引入多个文件时，可以在一个`@import`后面添加多个引入文件

```scss
@import "example.scss";
@import "example","test";
```

但是，在以下几种情况下，@import会被当成 CSS的`@import`：

- 文件的扩展名是 .css；
- 文件名以 http:// 开头；
- 文件名是 url()；
- @import 包含了任何媒体查询（media queries）。

#### 片段文件

如果需要引入某个 SCSS 或 Sass 文件，但又不希望被引入的文件被单独编译为一个 CSS 文件，可以在文件名前面加一个下划线`_`避免被编译。这种下划线`_`开始的sCSS/sass文件就是片段文件（或叫做本地文件）

- 引用片段文件时可以省略掉文件名前面的下划线

示例：片段文件名为`_mixin.sCSS`，需要在`main.sCSS`中引用片段文件中的内容，可在`main.CSS`写入：

```scss
@import "_mixin";
@import "mixin"; //可以省略下划线
```

编译后只会将`_mixin.sCSS`中的被引用的内容添加到`main.sCSS`编译出来的`main.CSS`中，不会再生成一个`_mixin.sCSS`文件。

### 继承类@extend

`@extend`来继承已存在的**类**样式块。

注意：

- 不能继承嵌套选择器的样式。
- 无论声明的样式块有没有被`@extend`引用，该样式都会出现在编译后的文件中（造成代码冗余），使用[占位符%](#占位符%)来声明样式可以避免这种情况出现。（推荐使用）

```scss
.nounderline {
  text-decoration: none;
}
a {
  @extend .nounderline;
}
```

 编译后：

```scss
.nounderline, a {
  text-decoration: none;
}
```

如果.nounderline没有被引用过，编译后的CSS文件中也有.nonderline这三行样式。

#### 占位符%声明样式块

占位符声明仅用来被继承的样式块，无论该样式块被引用与否，它都**不会出现在编译生成的CSS文件中** （当然，占位符声明的样式被引用后，其中的样式内容会出现在引用的位置）。样式名使用`%`开始：

```scss
%error {
  color: red;
}
.warn {
  @extend %error;
}
```

编译后：

```scss
.warn {
  color: red;
}
```

如果%error没有被引用过，它就不会出现在编译后的CSS文件中。

### 混入类@mixin声明及其调用@include

混合样式有是可以重用的代码块。

使用`@mixin`声明，`@include`调用。mixin中还**可以传入参数**（形参）和参数默认的值（实参）。

```scss
@mixin link($size:1.8rem){//声明 可在mixn中定义参数和默认值
    text-decoration: none;
  	color:#bbc5d3;
  	font-size:$size;
}
body{
  @include link(1.6rem);//调用 并让size为1.6rem，覆盖默认的1.8rem
}
```

注意：

- Sass 在调用相同的混合样式时，并**不能**智能的**将相同的样式代码块合并在一起**。

  例如某选择器中已经有`color:red;`，而include进来的mixin样式中也有`color:red;`，在生成的CSS中就，该选择器内就会有两条`color:red;`

#### 向混合样式中导入内容@content

将一段代码导入到混合类指令中，然后再输出混合类样式，额外导入的部分将出现在 `@content` 标志的地方：

```scss
@mixin apply-to-ie6-only {
  * html {
    @content;
  }
}
@include apply-to-ie6-only {
  #logo {
    background-image: url(/logo.gif);
  }
}
```

## 流程控制

### 条件

- `@if`-`@else`

```scss
$type:monster;
p {
    @if $type==ocean {
        color: blue;
    }
    @else if $type==matador {
        color: red;
    }
    @else {
        color: black;
    }
}
```



- 三目判断：`if($condition,$if_true,$if_false)`

  三个参数：条件，条件为真的值，条件为假的值

  ` if(true, 1px, 2px) => 1px`

### 循环

- @for循环
  - `for $var from <start>though<end>`
  - `for $var from <start> to <end>`
    $i表示变量，start表示起始值，end表示结束值，through表示包括end这个数，而to则不包括end这个数。

  ```scss
  @for $i from 1 through 3 {
      .item-#{$i} { width: 2em * $i; }
  }
  ```

  ​

- @while循环

  ```scss
  $types: 4;
  $type-width: 20px;
  @while $types>0 {
      .item-#{$types} {
          width: $type-width + $types;
      }
      $types: $types - 1;
  }
  ```

  ​

- @each循环

  `@each $var in <list or map>`
  $var表示变量，而list和map表示list类型数据和map类型数据。

  ```scss
  $animal-list: puma,sea-slug,egret,salamander;    //一个列表
  @each $animal in $animal-list {
      .#{$animal}-icon {
          background-image: url('/images/#{$animal}.png');
      }
  }
  ```
## 常用函数

### 字符串函数
- `unquote($string)`：删除字符串中的引号；
- `quote($string)`：给字符串添加引号；
- `To-upper-case()`：将字符串小写字母转换成大写字母；
- `To-lower-case()`：将字符串转换成小写字母。

### 数字函数

- `percentage($value)`：将一个不带单位的数转换成百分比值；
- `round($value)`：将数值四舍五入取整；
- `ceil($value)`：向上取整；
- `floor($value)`：向下取整；
- `abs($value)`：取绝对值；
- `min($numbers…)`：取几个数值之间的最小值；
- `max($numbers…)`：取几个数值之间的最大值；
- `random()`: 取随机数。

### 列表函数

- `length($list)`：返回列表的长度值；
- `nth(list, n)`：返回列表中指定的某个标签值；
- `join(list1, list2, [$separator])`：将两个列表连接成一个列表；
- `append(list1, val, [$separator])`：将某个值放在列表的最后；
- `zip($lists…)`：将几个列表结合成一个多维的列表；
- `index(list, value)`：返回一个值在列表中的位置值。

### 映射函数
- `map-get($map,$key)`：根据给定的 key 值，返回 map 中相关的值。
- `map-merge($map1,$map2)`：将两个 map 合并成一个新的 map。
- `map-remove($map,$key)`：从 map 中删除一个 key，返回一个新 map。
- `map-keys($map)`：返回 map 中所有的 key。
- `map-values($map)`：返回 map 中所有的 value。
- `map-has-key($map,$key)`：根据给定的 key 值判断 map 是否有对应的 value 值，如果有返回 true，否则返回 false。
- `keywords($args)`：返回一个函数的参数，这个参数可以动态的设置 key 和 value。

### Introspection 函数

- `type-of($value)`：返回一个值的类型；
- `unit($number)`：返回一个值的单位；
- `unitless($number)`：判断一个值是否带有单位；
- `comparable($number-1, $number-2)`：判断两个值是否可以做加、减和合并。

### 颜色函数
#### RGB
- `rgb($red,$green,$blue)`：根据红、绿、蓝三个值创建一个颜色；
- `rgba($red,$green,$blue,$alpha)`：根据红、绿、蓝和透明度值创建一个颜色；
- `red($color)`：从一个颜色中获取其中红色值；
- `green($color)`：从一个颜色中获取其中绿色值；
- `blue($color)`：从一个颜色中获取其中蓝色值；
- `mix($color-1,$color-2,[$weight])`：把两种颜色混合在一起。
#### HSL
- `hsl($hue,$saturation,$lightness)`：通过色相（hue）、饱和度(saturation)和亮度（lightness）的值创建一个颜色；
- `hsla($hue,$saturation,$lightness,$alpha)`：通过色相（hue）、饱和度(saturation)、亮度（lightness）和透明（alpha）的值创建一个颜色；
- `hue($color)`：从一个颜色中获取色相（hue）值；
- `saturation($color)`：从一个颜色中获取饱和度（saturation）值；
- `lightness($color)`：从一个颜色中获取亮度（lightness）值；
- adjust-hue($color,$degrees)`：通过改变一个颜色的色相值，创建一个新的颜色；
- `lighten($color,$amount)`：通过改变颜色的亮度值，让颜色变亮，创建一个新的颜色；
- `darken($color,$amount)`：通过改变颜色的亮度值，让颜色变暗，创建一个新的颜色；
- `saturate($color,$amount)`：通过改变颜色的饱和度值，让颜色更饱和，从而创建一个新的颜色
- `desaturate($color,$amount)`：通过改变颜色的饱和度值，让颜色更少的饱和，从而创建出一个新的颜色；
- `grayscale($color)`：将一个颜色变成灰色，相当于desaturate($color,100%);
- `complement($color)`：返回一个补充色，相当于adjust-hue($color,180deg);
- `invert($color)`：反回一个反相色，红、绿、蓝色值倒过来，而透明度不变。

####  Opacity
- `alpha($color) /opacity($color)`：获取颜色透明度值；
- `rgba($color, $alpha)`：改变颜色的透明度值；
- `opacify($color, $amount) / fade-in($color, $amount)`：使颜色更不透明；
- `transparentize($color, $amount) / fade-out($color, $amount)`：使颜色更加透明。
## 调试

- @debug   在Sass 代码在编译出错时，在命令终端会输出错误提示。

- @warn    在@warn后添加要输出的警告信息。

- @error    在@warn后添加要输出的错误信息。

```scss
@debug 54px + 86px;
    @if unitless($y) {
    	@warn "#{$y} 的单位是像素px";
    	$y: 1px * $y;
  	}@else{
         @error "$y不存在";
  	}
```

# compass

compass需要ruby，使用gem安装/更新/删除：`gem install compass` （参看前文[gem安装sass](#安装/更新/删除) ）

[compass文档](http://compass-style.org/help/documentation/)

- 常用命令行

  ```shell
  compass create name  #创建项目（name是项目名）
  compass compile  #编译文件 在项目根目录执行
  compass compile --output-style compressed  #可以定义编译风格
  compass compile --force  #强制编译所有文件（默认只编译未变动文件）
  ```

  - 创建（create）项目后，项目文件夹中会生成stylesheets文件夹、sass文件夹和config.rb文件；
  - 在sass文件夹中的Sass/SCSS文件在编译（compile）后会在stylesheets文件夹中生成CSS文件；
  - 项目文件夹中的config.rb文件中可以定义[相关编译参数](http://compass-style.org/help/documentation/configuration-reference/)（如`_output_style=:expand` ）

## 模块

使用`@import`引用模块

  - 核心模块

    核心模块使用`@import compass`即可引用一下所有模块，当然也可以单独引用：

    - [CSS3](http://compass-style.org/reference/compass/CSS3/)  CSS3相关属性支持

      使用`@include`引用该模块定义的mixin（参看前文[混合@mixin](#混合@mixin) ），如[opacity](http://compass-style.org/reference/compass/CSS3/opacity/) ：

      ```scss
      @import "compass/CSS3";
       
      #opacity-10 {
        @include opacity(0.1);
      }
      ```

      内容较多 更多CSS3模块中的内容 参看链接的官方文档

    - [typograph](http://compass-style.org/reference/compass/typography/)   文本样式

    - [utilities](http://compass-style.org/reference/compass/utilities/)  各种其他功能如清除浮动使用`@include clearfix`即可

    - [Helpers](http://compass-style.org/reference/compass/helpers/)   一些Sass增强函数

  - 非核心模块

    - reset  重置浏览器默认样式
    - [layout](http://compass-style.org/reference/compass/layout/)  布局功能 栅格背景和页脚等

    非核心模块需要单独引用：

    ```scss
    @import "compass/reset";
    @import "compass/layout";
    ```

  - [support](http://compass-style.org/reference/compass/support/)  跨浏览器支持（浏览器兼容）

## 常用扩展

使用`gem install`扩展安装后，使用require引入：

- `require 'compass-normalize'`

  ​

- `require 'compass/import-once/activate'`   只引用一次文件

  使用了该扩展后，在Sass/SCSS中使用`@import`引用一个文件多次，该文件内容也不会在编译时被添加多次。

  如果使用了扩展，但又需要多次引入同一个文件，只需要在引用语句最后加上一个`!`即可。

  ​