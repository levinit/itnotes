1. 生成CA私钥`ca.key`，用该私钥生成一个CA证书`ca.crt`

2. 生成一个私钥`server.key`，用该私钥创建一个请求文件`server.csr`，再使用CA的私钥和证书签名一个`server.crt`

3. 服务端使用`server.key`和`server.crt`

   例如web服务器需要读取这两个文件。

4. 客户端安装CA证书`ca.crt`即可。

   在windows上安装时，在”证书存储“这一步，选择“将所有的证书都放入下列存储”，点击“浏览”，选择“受信任的证书颁发机构”。

   如果是浏览器访问使用`server.crt`提供web服务的站点，安装完证书后需要重启浏览器。

   

```shell
#!/bin/bash
expire_days=3650
#----1. create CA files (key file and certificate file)
#1.1 create a private key as a CA key
openssl genrsa -des3 -out ca.key 2048   #input an key pharse for ca.key 2 times
#1.1.1 optional remove 
openssl rsa -in ca.key -out ca.key      #input the pharse of ca.key

#input some information, country, province/state, city , organazition ...
openssl req -utf8 -x509 -new -nodes -key ca.key -sha256 -days $expire_days -out ca.crt

#----2. sign a cert by CA key

#2.1 create a private key
openssl genrsa -out server.key 2048
#2.2 create a request file (csr) for generate a certificate
openssl req -new -key server.key -out server.csr

#2.3.0 conf file for generate a certificate
echo "
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = xxx.yy.com   #domain 1 
DNS.2 = aa.bb.cc     #optional, domain 2
IP.1 = 1.2.3.4       #optionally, an IP (if it requires)
" >server.ext

#2.3 sign a certificate (crt)
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days $expire_days -sha256 -extfile server.ext
```



得到的文件中重要的有：

- `ca.key`   CA证书密钥文件，如需再次签署需要使用
- `ca.crt`   CA证书文件，安装到客户端操作系统的**受信任的第三方证书颁发机构**里面
- `server.key`  和  `server.crt`    部署到服务端口的密钥和证书文件

其余文件：

- `server.csr`  证书签发请求的文件
- `server.ext`  生成证书的配置文件