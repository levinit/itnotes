scrollTop与doctype

---

前端发展日新月异，此文章写于2017年5月，随着浏览器的更新，该文讨论的内容可能不再合适。

遇到的问题
---

在某个scroll事件中使用了`document.documentElement.scrollTop`判断滚动条滚动距离，在firefox和chromium调试时发现值始终是0。

老生常谈的兼容
---
根据以前的经验这是个兼容性问题，可使用`document.documentElement.scrollTop||document.body.scrollTop`解决。不过按照此方法，在chromium下能获取到滚动距离，但firefox下依然为0。

经分别测试发现：

- 在chromium能得到`document.body.scrollTop`的变化的值，而`document.documentElement.scrollTop`始终为0；
- 在firefox下能得到`document.body.scrollTop`的变化的值，而`document.documentElement.scrollTop`始终为0。

**原来是doctype**
---
进行网络搜索查得：
>页面指定了DTD，即指定了DOCTYPE时，使用document.documentElement。
>页面没有DTD，即没指定DOCTYPE时，使用document.body。
>IE和Firefox都是如此。

检查html文件发现确实没写上`<!DOCTYPE html>`，于是乎添加之。调试发现scroll内代码运行正常。
**但是**，在chromium和firefox的控制台分别获取`document.body.scrollTop`和`document.documentElement.scrollTop`，发现firefox的`document.body.scrollTop`依然为0。

于是分别测试带有`<!DOCTYPE html>`和不带有`<!DOCTYPE html>`的两种情况，发现：

- chrome的scrollTop是从来不理会doctype的声明，只取body的scrollTop值；
- firefox在有doctype时能取到documentElement的scrollTop值，但body的scrollTop始终是0；在没有doctype时则情况相反。

**总结**
---
- w3c标准：没有声明doctype时，document.body.scrollTop有效， document.documentElent.scrollTop无效（始终是0）。
- firefox：遵从w3c标准，有doctype时取documentElement的scrollTop，没有doctype时取body的scrollTop。
- chromium只取body的scrollTop，无论是否声明doctype与否。

当然整篇文章下来，还是用开始的`document.body.scrollTop || document.documentElement.scrollTop`解决问题。