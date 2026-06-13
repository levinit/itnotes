# polkit简介

> polkit 是一个应用程序级别的工具集，通过定义和审核权限规则，实现不同优先级进程间的通讯：控制决策集中在统一的框架之中，决定低优先级进程是否有权访问高优先级进程。

桌面环境中，一些系统操作无需管理权限亦可以进行操作（例如关机，更改网络连接），这是因为polkit提供了一些允许策略。polkit 在系统层级进行权限控制，提供了一个低优先级进程和高优先级进程进行通讯的系统。



# polkit 控制策略

Polkit 定义了两种不同的内容：

- **操作（Actions）**：在 `/usr/share/polkit-1/actions` 中定义，文件是 XML 格式，以 `.policy` 结尾。每个**操作**都有一个默认的权限集合。默认值是可以修改的，但是不应该通过修改操作文件实现。

  action文件例如：

  ```shell
  org.freedesktop.NetworkManager.policy  #nm网络管理
  org.freedesktop.login1.policy          #登录服务（包括关机）
  org.freedesktop.timesync1.policy       #时间同步
  ```

  以`org.freedesktop.NetworkManager.policy`中的部分内容为例：

  ```xml
  <action id="org.freedesktop.login1.power-off">
      <description>Power off the system</description>
      <defaults>
          <allow_any>auth_admin_keep</allow_any>
          <allow_inactive>auth_admin_keep</allow_inactive>
          <allow_active>yes</allow_active>
      </defaults>
  </action>
  ```

  action标签的id属性值列出了操作的唯一名字；defaults标签定义了默认的验证规则，该标签内部的子标签定义了不同策略，标签内部的内容即策略的取值，可使用的取值有：

  - no 验证不通过（不允许）
  - yes 验证通过（无需密码）
  - auth_self  使用任意本地用户验证
  - auth_admin  需要管理员身份验证
  - auth_self_keep  同auth_self ，在一段时间内（如5分钟）保持验证（例如输入过一次密码，一段时间内无需再次输入密码）
  - auth_self_admin  同auth_admin ，在一段时间内（如5分钟）保持验证

  

- **认证规则（Authorization rules）**：用 JavaScript 语法定义，文件以 `.rules` 结尾。有两个目录可放置规则文件：第三方的包将文件放置在 `/usr/share/polkit-1/rules.d`（尽管很少见），本地配置应该放置在 `/etc/polkit-1/rules.d`。

  一个认证规则文件示例：

  ```javascript
  polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("kvm")) {
              return polkit.Result.YES;
      }
  });
  ```

  固定写法是使用`polkit.addRule()`函数，其参数为一个匿名函数，接收action和subject两个参数，action即上文中那些以`.policy`结尾的action文件名去掉`.policy`的部分，action.id是获取action文件中`<action>`标签的id属性的值，subject即触发这个action操作的用户对象。

  函数内部对action和subject（或其中之一）进行判断，返回一个以`polkit.Result.`开头的权限结果值，后面部分为前面action列出的可选值中的任意一个，例如`polkit.Result.YES`中的YES就表示通过。

# polkit配置实例

## 调试

下面的规则会输出关于所请求的访问的详细信息

```javascript
polkit.addRule(function(action, subject) {
    polkit.log("action=" + action);
    polkit.log("subject=" + subject);
});
```



## 允许普通用户管理某个systemd单元

例如允许普通用户控制无线网络：

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units") {
        if (action.lookup("unit") == "wpa_supplicant.service") {
            var verb = action.lookup("verb");
            if (verb == "start" || verb == "stop" || verb == "restart") {
                return polkit.Result.YES;
            }
        }
    }
});
```

## 禁止普通控制电源

例如在多用户使用的场景中，避免普通用户在远程桌面连接（如VNC）中关闭主机。

一般的，如有其他登录会话存在，普通用户无法直接关机的（即不使用管理员密码关机)。

编辑或添加polkit规则文件，文件以`.rules`结尾，示例：

```javascript
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.power-off") &&
        subject.isInGroup("root")) {
            return polkit.Result.YES;
    }
    else {
        return polkit.Result.NO;
    }
});
```

以上规则只允许root用户可以重启和关机。

## 禁止普通用户控制网络连接

`polkit.Result.AUTH_ADMIN`表示需要管理员权限。

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.network-control") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.enable-disable-wifi") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.own") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.wifi.share.open") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.wifi.share.protected") {
        return polkit.Result.AUTH_ADMIN;
    }
});
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.enable-disable-network") {
        return polkit.Result.AUTH_ADMIN;
    }
});
```
