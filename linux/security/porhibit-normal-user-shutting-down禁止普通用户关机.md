

普通用户可以进行重启、关机等操作，是因为获取了相关权限

- sudo提权

- polkit

  桌面环境中，一般会默认配置polkit为普通用户提权，

- 更改reboo、poweroff、halt等可执行文件的操作权限（一般不建议）

  



编辑或添加polkit规则文件，文件以`.rules`结尾，使用javascript语法，存放在`/etc/polkit-1/rules.d`，示例：

```javascript
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.consolekit.system.stop" ||
        action.id == "org.freedesktop.consolekit.system.restart") &&
        subject.isInGroup("root")) {
            return polkit.Result.YES;
    }
    else {
        return polkit.Result.NO;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.login1.power-off") == 0 ||
        action.id.indexOf("org.freedesktop.login1.reboot") == 0) {
        try {
            // user-may-reboot exits with success (exit code 0)
            // only if the passed username is authorized
            polkit.spawn(["/usr/local/bin/user-may-reboot",
                          subject.user]);
            return polkit.Result.YES;
        } catch (error) {
            // Nope, but do allow admin authentication
            return polkit.Result.AUTH_ADMIN;
        }
    }
});
```

以上规则中判断用户的信息允许或阻止用户通过桌面环境的接口的重启或关机行为。