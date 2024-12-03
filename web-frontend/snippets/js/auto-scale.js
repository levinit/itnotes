//a. 加载页面时根据视口大小设置基准字体大小
setBaseFontSize()

//b. 更改视口大小（浏览器窗口大小）时动态调整基准字体大小
window.addEventListener('resize', setBaseFontSize, false)

//c. 缩放浏览器时调整

// 提示：浏览器缩放后，页面的documentElement元素的尺寸会随之反比例变化
//可获取window.devicePixelRatio缩放比例 用以调整缩放大小

// 没有单独对浏览器缩放的监测事件
// 但是可以监测crtl+鼠标滚轮（缩放）事件和键盘事件(快捷键ctrl +/-/0缩放)来实现监听

//c1 Ctrl+鼠标滚轮缩放
document.addEventListener('DOMMouseScroll', function (e) {
  e = e || window.event;
  //监测滚轮事件中是否按下了Ctrl键
  if (e.ctrlKey) {
    setBaseFontSize()
  }
})

//c2 键盘快捷键缩放
document.addEventListener('keydown', function (e) {
  e = e || window.event;
  //按下Ctrl 以及以下任意一键：+ - 或 0
  if (e.ctrlKey && (e.code === 'Equal' || e.code === 'Minus' || e.code === 'Digit0')) {
    setBaseFontSize()
  }
})

//===

//设置html标签的基准字体
function setBaseFontSize() {
  const viewportWidth = window.innerWidth || document.documentElement.scrollWidth ||
    document.body.scrollWidth || document.documentElement.getBoundingClientRect().width;
  //浏览器缩放值(1表示未缩放)
  const ratio = window.devicePixelRatio

  //自定义默认缩放基础比例
  const defaultScale = 100
  //原始设计稿宽度（px）
  const originDesignDraftWidth = 1440

  const fontSize = viewportWidth * defaultScale / originDesignDraftWidth * ratio + 'px';

  document.querySelector('html').style.fontSize = fontSize;
}
