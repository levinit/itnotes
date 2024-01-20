

根据系统的配色模式（如夜间模式）切换页面的配色：

# CSS querymedia prefers-color-scheme

```css
/* dark mode */
@media (prefers-color-scheme: dark) {
  body {
      background-color: darkgray;
      color: lightsteelblue;
  }
}
```

在css加载时才生效，如果页面没有刷新但是系统切换了配色模式，无法实现自动切换页面配色，



# JS自动侦测配色模式

## js中更新指定的样式

- 监听页面加载`load`事件，加载时判断是否为夜间模式，做出相应样式设置
- 监听`window.matchMedia('(prefers-color-scheme: dark)')`的change事件，如果系统切换了配色模式，做出相应样式设置

```javascript
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
  const isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  if (isDark){
    //chang to dark mode
  }else{
    //change to light mode
  }
})
```

判断是否为夜间模式，根据情况加载不通的css样式。完整示例如下：

css内容

```css
.dark-mode {
  font-size: 0.18rem;
  background-color: lightgray;
}
```

js内容

```shell
//加载时onload | change color scheme follow os
window.addEventListener('load', () => {
  const isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  if (isDark) {
    document.body.classList.add("dark-mode")
  }
})

//监听change事件onchange | auto change 
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
  const isDark = e.matches
  if (isDark) {
    document.body.classList.add("dark-mode")
  }else{
    document.body.classList.remove("dark-mode")
  }
});
```



## css querymedia定义样式+js刷新css文件

该方式较前文中操作body DOM的classList属性的方式而言更灵活方便，对于有大量不同配色模式的css样式而言，classList模式操作麻烦。

- 思路一：在同一css中写好query media相关内容

  侦测到系统配色模式变化时刷新下html中link的href，且不关心具体变化模式，刷新的link的href即可，query media将自动侦测并渲染样式。

  

- 思路二：两个css文件，一个对应light模式light.css，一个对应dark模式dark.css

  html中的link引用一个css文件为默认模式，在页面加载和侦测到系统配色模式变化时，根据需要动态更改link的href

  可无需写css的query media。

  拆分css文件对于css样式文件内容较多的情况下易于管理。

  

- 思路三：综合前两者，使用两个css文件，将query media相关内容拆分为一个单独文件

  html中的link引用两个模式的css文件，加载后自动识别query media，因此无需在加载后处理使用js样式问题

  只需检测系统配色模式的变化时，无需关心具体变为什么模式，js刷新含有query media的css的link的href属性即可。



思路一示例：

html

```html
<link id="stylecss" rel="stylesheet" href="light.css">
```

light.css

```css
body {
  font-size: 0.18rem;
  background-color: #ccccd625;
}
/* other css */
```

dark.css

```css
body {
    background-color: rgba(34, 33, 33, 0.817);
    color: lightsteelblue;
}
/* other css */
```

js

- 监听页面加载`load`事件
- 监听`window.matchMedia('(prefers-color-scheme: dark)')`的change事件

```javascript
//加载时onload | change color scheme follow os
window.addEventListener('load', () => {
  const isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  if (isDark) {
  document.getElementById("indexcss").href="dark.css"
  }
})

//监听change事件onchange | auto change 
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
  const mode = e.matches ? "dark" : "light";
	document.getElementById("indexcss").href=`${mode}.css`
});
```



思路二示例：

html

```html
<link id="stylecss" rel="stylesheet" href="style.css">
```

css

```css
/* light mode */
body {
  font-size: 0.18rem;
  background-color: #ccccd625;
}

/* dark mode */
@media (prefers-color-scheme: dark) {
  body {
      background-color: rgba(34, 33, 33, 0.817);
      color: lightsteelblue;
  }
}
```

js

监听`window.matchMedia('(prefers-color-scheme: dark)')`的change事件，发生变化就进行刷新，不关心具体配色模式是什么

```javascript
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
  const ele=document.getElementById("indexcss")
  const linkhref=ele.href
  ele.href=linkhref
});
```



