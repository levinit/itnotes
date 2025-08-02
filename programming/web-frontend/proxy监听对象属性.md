> [**Proxy**](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Proxy) 对象用于创建一个对象的代理，从而实现基本操作的拦截和自定义（如属性查找、赋值、枚举、函数调用等）。

监听对象值的变化，实现只需修改值即可根据变化自动触发某些操作的功能。

创建proxy代理：

```javascript
const proxy=new Proxy(target,handler)
```

- target
  用Proxy包装的目标对象

  任何类型的对象（可以是空对象`{}`），包括原生数组，函数，甚至另一个代理）。

- handler
  一个对象，其属性是当执行一个操作时定义代理的行为的函数。

```javascript
var  userInfo= new Proxy({}, {
  get(obj,prop,val) {
    console.log("get val!!!")
  }
  set(obj, prop, val) {
    if (prop === 'username' && val === 'admin') {
      console.log("hello, admin")
      //could do someting here
    } else {
      console.log("hello, dear user.")
    }
    obj[prop] = val
    return true
  }
})

loginInfo.loginState=false
```

