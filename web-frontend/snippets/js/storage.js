//存储各种信息
const storage = {
  //存入数据
  save(key, val, type) {
    if (type === 'session') {
      sessionStorage.setItem(key, JSON.stringify(val));
    } else {
      localStorage.setItem(key, JSON.stringify(val));
    }
  },
  //取出数据
  get(key) {
    try {
      if (sessionStorage.getItem(key)) {
        return JSON.parse(sessionStorage.getItem(key));
      } else if (localStorage.getItem(key)) {
        return JSON.parse(localStorage.getItem(key));
      }
      return null;
    } catch (err) {
      if (err.name === 'SyntaxError') {
        //eslint-disable-next-line no-console
        console.log('存储内容不是JSON类型');
        return false;
      }
    }
  },
  //删除数据
  remove(key) {
    if (localStorage.getItem(key)) {
      localStorage.removeItem(key);
    } else {
      sessionStorage.removeItem(key);
    }
  }
};
export default storage;
