为了加强系统的安全性, 有必要建立一个管理员的组, 只允许这个组的用户执行”su -” 命令登录为root, 而让其他组的用户即使执行”su -” 输入了正确的密码, 也无法登录为root用户. 在Unix 和Linux 下, 这个组的名称通常为”wheel”.

1 添加一个用户, 把这个用户加入wheel组
2 修改/etc/pam.d/su
#auth required pam_wheel.so use_uid
这行注释打开
3 修改/etc/login.defs
在文件末添加一行
SU_WHEEL_ONLY yes

