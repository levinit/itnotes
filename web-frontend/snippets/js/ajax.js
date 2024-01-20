
//ajax 传参类似jquery的$.ajax()方法
/* 参数示例
info={
  type:'get',  //请求类型
  url:'xxx',  //地址
  data:'xxx',  //发送的数据
  async:'false',  //是否异步
  sendType:'json', //发送的数据类型
  resType:'json' //返回数据类型
  success:function(){},  // 服务器已成功处理了请求后执行的方法
  fail:function(){}  //服务器未成功处理了请求
}
*/

function ajax(info) {
  //结构传入对象
  let { type, url, data, async, resType, sendType, success, fail } = info;
  //预设值
  type = type || 'GET';
  async = async || true;
  data = data || null;
  sendType = sendType;
  resType = resType;
  success =
    success ||
    function () {
      console.log('没有传输success回调函数');
    };
  // fail = fail

  //1. 实例化xhr对象
  const xhr = new XMLHttpRequest();

  //2. 建立请求
  xhr.open(type, url, async);

  //2.1 请求头
  if (data) {
    let requestContentType = ''
    switch (sendType) {
      case 'json':
        requestContentType = 'application/json; charset=utf-8;'
        data = JSON.stringify(data)
        break;
      case "FormData":
        requestContentType = 'application/x-www-form-urlencoded';
        break;
      default:
        break;
    }
    if (requestContentType) {
      xhr.setRequestHeader('Content-type', requestContentType);
    }
  }

  // xhr.timeout = 3000; //请求超时

  //3. 发送请求
  xhr.send(data);
  //4. 获取回应
  xhr.onreadystatechange = function (res) {
    if (xhr.readyState === 4) {
      const statuscode = xhr.status
      if (statuscode === 200) {
        res = xhr.response
        if (!res) {
          console.log('服务端未返回任何内容');
          return;
        }
        //响应数据的类型 按顺序采用： 约定类型> 实际返回类型 > 默认类型(json)
        resType = resType || xhr.responseType || 'json'
        //根据约定的返回数据类型进行转换
        switch (resType) {
          case 'json':
            res = JSON.parse(xhr.responseText);
            break;
          case 'blob':
            success(xhr)
            return false
          default:
        }
        //转换后的数据调用success回调函数
        success(res)
      }
      else {
        if (fail) {
          fail(statuscode);
        }
          console.log(statuscode)
      }
    }
  }
