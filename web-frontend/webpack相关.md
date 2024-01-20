常用包

```shell
npm install --dev webpack webpack-cli webpack-serve html-webpack-plugin style-loader css-loader mini-css-extract-plugin postcss-loader postcss-import autoprefixer url-loader file-loader expose-loader
```

- webpack基础套件  webpack webpackf-cli
- 开发服务器辅助工具  webpack-serve
- html相关  html-webpack-plugin
- css相关  style-loader css-loader mini-css-extract-plugin
  - postcss相关  postcss-loader postcss-import autoprefixer
- 文件处理（处理除了html css js之外的文件如图片字体）   url-loader file-loader
- 暴露全局模块（常用于将npm安装安装的库如jq暴露全局使用） expose-loader

---

# 简介

## webpack

安装`webpack`和 `webpck-cli`，要使用webpack需要在`package.json`中的scripts下添加指令，例如：

```json
  "scripts": {
    "start": "webpack-serve --hot --open-app --port 8888",
    "build": "webpack --config webpack.config.js"
  }
```

然后执行`npm build`即是使用webpack安装webpack.config.js文件中的配置进行打包。

## webapck配置文件解读

基本结构：

```javascript
//各种import(require)
import xxx from 'xxxx';

webapcConfig = {
  //模式
  mode: 'production', //或development
    
  //目录别名
  resolve: {
     alias: {
     lib: './src/lib'
     }
  },
    
  //入口文件--打包文件的来源
  entry: {}, 

  //出口文件--打包生成的文件
  output: {},
    
  //模块
  module: {
    rules: []  //各种规则
  }, 
  
   //插件
  plugins: {},
  
   //优化(webpack内置)
  optimization: {},
     
  //开发辅助(webpack内置)
  devtool: 'source-map' //调试时使用source map
    
  //其他常用配置项目
};

export default webpackConfig;
```

### entry  入口

入口文件（js）配置。默认路径为`./src`，默认入口文件是`index.js`（如果不指定entry）。

```javascript
  entry: {
    app: './index.js', // index.js打包后将变成app.js
    util: './common/util.js',
    service: ['./service/info.js','./service/host.js'] //这两个文件将合并为service.js
  },
```

### output 输出

打包的目标位置，所有文件都将默认被打包到指定文件夹下。默认路径为`./dist`。

```javascript
output: {
    // publicPath: '/', // web服务的根目录 绝对路径 注意末尾必须有/
    filename: '[name]/[name].js' //打包后的js文件的命名方式
    chunkFilename: 'js/[name]-[hash].js' //按需加载模块的打包的名称
  },
```

`[name]`表示使用原名称，`[hash]`表示添加生成的hash值（`[hash:3]`使用生成的hash值的前三位）。

### module 模块

#### rules 规则

loader的配置内容放置于webpack配置文件中module对象下的rules对象内。

### plugins 插件

各种插件，plugins的配置内容放置于plugins内。

- plugin需要需要在配置文件前面引用

  例如要使用html-webpack-plugin：

  先引用该插件，例如`const htmlWebpackPlugin=require('html-webpack-plugin')`

  然后再实例化使用`new htmlWebpackPlugin()`

### optimizition 优化

压缩代码。

分割代码块。

```javascript
optimization: {
  //minimize:true //压缩 如果mode为production则自动启用
  //chunk 提取模块
  runtimeChunk: 'single',  //按runtime提取
  
  splitChunks: {  //分割代码块
    chunks: 'all',
 
    cacheGroups: {
      default: {
        enforce: true,
        priority: 1
      },
      vendors: {
        test: /[\\/]node_modules[\\/]/,
        priority: 2,
          name: 'vendors',
          enforce: true,
          chunks: 'all'
      }
    }
  }
}
```

### devtool

内置，开发调试的辅助，例如设置值为`sourcemap`方便迅速定位代码。参看官方文档devtool部分。

# 常用loader和plugins

一些插件需要在rules和plugins内同时配置（如提取css的mini-css-extract-plugin)

loader——模块转换器，它可以将原内容按照需求转换成新内容。

plugins——插件，在Webpack 构建流程中的特定时机注入扩展逻辑来改变构建结果。

## HTML

### html-webpack-plugin

主要作用是将指定的模板文件（默认ejs）生成为html页面，并将入口文件（entry）中符合配置要求（chunk选项）的js模块使用`<script src="xxx">`的方式插入到生成的html中。

html生成在出口（output）配置的路径下——默认为dist/。

该示例中，`/src/index.html`将生成为output指定目录下的`index.html`：

```javascript
new htmlWebpackPlugin({
  template: './src/index.html',  //模板来源
  filename: 'index.html',  //生成位置
  favicon: './src/ico.png',  //在在head标签内插入link指定favicon
  title:'主页',  //在head标签内插入title标签
  // chunks: ['util'], // 本页面自动嵌入的js模块
  //excludechunks:[], //本页面不使用的js模块
  minify: {  //压缩参数
    // collapseWhitespace: true, 
    // removeComments: true
  }
})
```

生成多个页面时多次使用`new htmlWebpackPlugin`即可。

### html-loader

可以加将html文件内容当作字符串处理，实现公共html部分的复用。

配置loader：

```javascript
 {
     test: /\.(html)$/,
         use: {
             loader: 'html-loader'
          }
}
```

示例在一个html中引用另一个公共html代码片段。公共文件head.html内容为：

```html
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta http-equiv="X-UA-Compatible" content="ie=edge" />
<link rel="shortcut icon" href="static/img/logo.png" type="image/png" />
```

在其他页面html的`<head></head>`中引用head.html，该页面打包后，head.html内容会嵌入到`<head></head>`中：

```html
<html>
    <head
		<%= require('.head.html') %>
	</head>
</html>
```

如果使用了html-webpack-plugin，二者可能发生冲突，参看[html-webpack-plugin和html-loader冲突](#html-webpack-plugin和html-loader冲突)。

具体配置使用参见官方文档。

### html-withimg-loader

[html-withimg-loader](https://github.com/wzsxyz/html-withimg-loader)配置rules：

```javascript
{
      test: /\.(htm|html)$/i,
      loader: 'html-withimg-loader'
}
```

- 可直接在html的img标签的src中使用图片路径

  src地址无需使用下面的require()方式：

  ```html
  <img src={require('image.png')} />
  ```

- 还支持引用html子页面（参看[html-loader](#html-loader)中描述的在一个html中引用另一个html代码片段），引用方法：

  ```html
  <div>
      #include("./head.html")
  </div>
  ```

## CSS

### style-loader

将css文件插入html的`<style></style>`标签中 一般配合css-loader使用。

在rules中配置，参照下文中的配置。

### css-loader

解析`@import` 和 `url()`

1. 在rules中配置，参照下文的配置。

2. 在js文件中使用import（或require）css文件。

   ```javascript
   import css1 from '/path/to/css1.css'
   //或
   const css1=require('/path/to/css1.css')
   //然而实际上一般css1这个变量后续也不会使用，因此一般如下进行引用
   import '/path/to/css1.css'
   ```

#### postcss-loader及常用插件

  （sass使用sass-loader和node-sass，less使用less-loader和less）

提示：postcss支持`.postcss`、`.pcss`、`.sss`和`.css`后缀。

postcss常用辅助插件（参看[github:postcss](https://github.com/postcss/postcss/blob/master/README-cn.md)）：

  - autoprefixer  添加不同浏览器前缀（使用[Can I use](https://caniuse.com/)数据）
  - precss  可以使用像sass/less等预处理语言的特性（例如嵌套）
  - postcss-import 监听并编译@import引用的css文件
  - postcss-sorting 给规则的内容以及@规则排序
  - postcss-preset-env 允许使用较新的（甚至是实验性的） CSS 特性（新css的polify）
  - postcss-calc 在编译阶段进行计算以减少不必要的 `calc` （开发时用 `calc` ）
  - postcss-plugin-px2rem  将px转成rem适配各种屏幕

`postcss.config.js`配置文件示例，放置于项目根目录下：

```javascript
  module.exports = {
    plugins: [
      'autoprefixer': {
        browsers: ['last 5 version','Android >= 5.0'],
        cascade: true,//是否美化属性值 默认：true 
        remove: true //是否去掉不必要的前缀 默认：true 
      },
      'precss',
      'postcss-import',
      'precss'
    ]
  }
```

webpack中的配置参看下文。

#### mini-css-extract-plugin

将css内容提取为文件，使用`<link>`标签插入到html。

需要在rules中配置各种css-loder使用，并在plugins中示例化使用。

参看下面的配置：

  ```javascript
const miniCssExtractPlugin=require('min-css-extrac-plugin')
module.exports = {
  entry: {},
  output: {},
  modules: {
    rules: [
      {
        test: /\.css$/,
        use: [
          MiniCssExtractPlugin.loader,
          {
            loader: 'css-loader',
            options: {
              // minimize: true
            }
          },
          {
            loader: 'postcss-loader',
            options: {
              config: {
                path: './postcss.config.js' //postcss的配置文件
              }
            }
          }
        ]
      }
    ]
  },
  plugins:{
    new MiniCssExtractPlugin({
      // Options similar to the same options in webpackOptions.output
      // both options are optional
        filename: "[name].css",
        chunkFilename: "[id].css"
      })
  }
};
  ```

## JavaScript

### 编译ES6的babel-loader相关

安装`babel-loader`、 `babel-core`和 ` babel-preset-env`（如果使用class类需安装`babel-plugin-transform-class-properties`）

```javascript
{
  test: /\.js$/,
  exclude: /(node_modules|browser_components)/,
  use: {
    loader: 'babel-loader',
    options: {
      cacheDirectory:true,
      presets: ['@babel/preset-env'],
      plugins: ['@babel/transform-runtime']
    }
  },
  cacheDirectory: true
}
```

配置内容已经存在项目目录下的babel配置文件中（如.babelrc），则不必要再重复添加preset或plugins等配置。。

注意：编译代码速度慢，建议在开发过程中关闭babel（除非该特性在测试的浏览器上不支持）

### expose-loader暴露全局依赖模块

将模块暴露到全局（成为全局变量），用以调试或者支持依赖其他全局库的库。参看[expose-loader](https://webpack.js.org/loaders/expose-loader/)。

示例jquery

1. 安装`jquery`模块

2. rules中添加：

   ```javascript
       rules: [
         {
           test: require.resolve('jquery'),
           use: [{
             loader: 'expose-loader',
             options: '$'
           }]
         }]
   ```

3. js中引用

   ```javascript
   require("expose-loader?$!jquery");
   //或
   import $ from 'expose-loader?jquery'
   ```

## file-loader和url-loader处理各种文件

file-loader对引用的各种文件资源进行打包处理（例如字体、图片）。

url-loader包含file-loader，url-loader主要用于处理小图片，其可以将小于配置中指定大小的图片base64化，以减少HTTP请求。（如下面的示例，小于8192B的图片将被处理为base64字符串，大于8192B则使用file-loader处理）

```javascript
{
  test: /\.(gif|png|jpg|svg|webp)$/,
  use: [
    {
      loader: 'url-loader',
      options: {
        limit: 8192,  
        name: 'img/[name].[ext]'
      }
    }
  ]
}
```

html或js中引用的图片大于limit的值时，要使用reqiure：

```html
<img src=<%=require( './logo.png') %> />
```

或使用[html-withimg-loader](https://github.com/wzsxyz/html-withimg-loader)

## copy-webpack-plugin复制文件

将指定文件复制到目标（打包文件目录下）路径处。例如希望将src/fonts目录复制到src/dist/fonts，

```javascript
new copyWebpackPlugin([{from:'./src/fonts',to:'img'}])
```

## clean-webpack-plugin自动清空文件

每次使用webpack打包时自动清除指定文件夹中的内容，例如清空dist文件夹：

```javascript
plugins:[
  new cleanWebpackPlugin(['dist'])
]
```

# 其他

## 使用font-awesome

安装`font-awesome``

1. ``modules`中`rules`下添加规则：

   ```javascript
         //fontawesome-woff
         {
           test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,   //直接写成woff*也可以
           loader: 'url-loader?limit=10000&mimetype=application/font-woff'
         },
         //fontawesome-fft&eot
         {
           test: /\.(ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
           loader: 'file-loader'
         },
   ```

   注意，该规则应该放在css相关rules后面。

2. 在js文件中引用css即可，示例：

   ```javascript
   import '../node_modules/font-awesome/css/font-awesome.min.css'
   ```

## 开发服务器webpack-serve

当更改代码后，会进行热更新，同步刷新浏览器。参看[webpack-serve](https://github.com/webpack-contrib/webpack-serve)。

根据是否使用webpack-serve动态设置mode属性的值：

```javascript
//当前模式 当不使用webpack-serve是模式为production
const curMode = process.env.WEBPACK_SERVE ? 'development' : 'production';
//是否为生产模式  （该值可供给其他配置项使用，如html-webpack-plugin中的minify）
const isProduction = curMode === 'production' ? true : false;

module.exports = {
  //mode默认为开发模式 生产模式为production 这里使用上面定义的curMode变量的值
  mode: curMode
    
   serve{
      hot:true,
      port:8888,
      open:true,
   }
}
```

## 经验

### css重复打包问题

如果被导入的模块中导入了css，那么这个css会连带导入，该css的内容会被重复打包

例如page1.js中import了页面共用头部的header.js文件，而header.js中import 'header.css'，那么header.css的内容会被page1.js再导入依次，相当于又将header.css打包了一次。

### html-webpack-plugin和html-loader冲突

如果html-webpack-plugin的模板文件(template)为html文件，则模板html文件中html-loader的相关代码将不能被html-loader解析。

例如在html中使用以下方式导入另一个html

```shell
<%= require('./common.html') %>
```

该语句将原样输出。可选解决方式：

- **删除html-loader相关配置**，在reqiure语句中指定html-loader

  ```javascript
  <%= require('html-loader!./common.html') %>
  ```

- 将模版文件全部替换成ejs文件

### 图片文件打包问题

使用file-loader/url-loader后，图片体积大于url-loader配置中的limit的不会被打包（小于url-loader配置中limit的将被转化为base64）。可选解决方式：

- 使用reqiure引入

  ```html
  <img src=<%=require( '.logo.png') %>/>
  ```

- 改用[html-withimg-loader](https://github.com/wzsxyz/html-withimg-loader)