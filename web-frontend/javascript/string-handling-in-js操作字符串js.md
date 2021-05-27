# 翻转字符串

Reverse a String

```javascript
function reverseString(str) {
	return str.split("").reverse().join("");
}
```

# 回文检验

Check for Palindromes

```javascript
function palindrome(str) {
     //去掉非字母数字、空白字符和下划线
    str = str.replace( /[\W\s_]/g,"").toLowerCase();
    return str === str.split("").reverse().join("");
}
```
# 寻找句中最长单词

Find the Longest Word in a String

```javascript
function findLongestWord(str) {
	var arr=str.split(/\s/g);
	for(var i=0;i<arr.length-1;i++){
    	if(arr[i].length>arr[i+1].length){
			arr[i+1]=arr[i];
    	}
	}
 	return arr[arr.length-1].length;
}
```


# 句中单词首字母大写

Title Case a Sentense

```javascript
function titleCase(str) {
	var arr=str.toLowerCase().split(" ");
	var narr=[];
	for(var i=0;i<arr.length;i++){
		arr[i]=arr[i][0].toUpperCase()+arr[i].slice(1);
    	}//首字母大写+截取第二到最后一个字母
    return arr.join(" ");
}
```
# 检测一个字符串是否以另一个字符串结尾

Confirm the Ending

```javascript
function confirmEnding(str, target) {
	//substr(start,end); str长度减去target长度=start,target长度=end
	return target===str.substr(str.length-target.length,target.length);
}
```
# 重复字符串

Repeat a string

```javascript
function repeat(str, num) {
	var strn="";
    var i=0;
    while(i<num){
    	strn+=str;
		i++;
	}
	return strn;
}
```
javascript的reapeat方法：

```javascript
'a'.repeate(2); //'aa'\
```

# 一个字符串中是否包含另一个字符串中的所有字符

```javascript
function mutation(arr) {
	for(var i=0;i<arr[1].length;i++){
		if(arr[0].toLowerCase().indexOf(arr[1][i].toLowerCase())===-1){
    		return false;
		}//将字符串2中的每一个字符与字符串一的
	}
  return true;
}
```