文档：

- [fetch](https://developer.mozilla.org/zh-CN/docs/Web/API/Fetch_API/Using_Fetch)

  - **仅当网络故障时或请求被阻止时**，Promise状态才会标记为 reject；其余均标记为resolve。
  - 可以接受跨域cookies和建立跨域会话
  - 不会发送cookies（除非你使用了*credentials* 的[初始化选项](https://developer.mozilla.org/zh-CN/docs/Web/API/WindowOrWorkerGlobalScope/fetch#Parameters)。)

  ```javascript
  fetch(uri,initObject)
  ```

  fetch第二个可选参数是一个可以控制不同配置的 `init` 对象，示例：

  ```javascript
  fetch(uri,{
    body:JSON.stringify(data),
    headers:{},
    method:'POST',
    headers: { "Content-Type": "application/json" },
    responseType:blob
  })
  ```

  对于简单的get请求，无需在第二个参数中指定`method:'GET'`。

  

- [async](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Statements/async_function)

  > async函数是[`AsyncFunction`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/AsyncFunction)构造函数的实例， 并且其中允许使用`await`关键字。`async`和`await`关键字让我们可以用一种更简洁的方式写出基于[`Promise`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Promise)的异步行为，而无需刻意地链式调用`promise`。

  

fetch+async以同步的编码习惯，同时避免使用多个`.then()`链式调用的模式。

fetch的`.then()`链式调用示例：

```javascript
const url = 'https://hq.sinajs.cn/list=sh000002'
fetch(url)
  .then(function(res) {
    return res.text();
  })
  .then(function(data) {
    console.log(data);
  });
```



async+fetch模式：

```javascript
const fetchTest= async () => {
  const url = 'https://hq.sinajs.cn/list=sh000002'
  const res = await fetch(url)
  const data = await res.text()
  console.log(data)
}
fetchTest()
```

调用async定义的函数将异步执行，在async函数内部使用await在任何异步的，基于 promise 的函数之前。

fetch也是异步函数，因此使用await以暂停等待promise完成。