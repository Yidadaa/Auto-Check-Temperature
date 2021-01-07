// 以下代码用于生成各种请求

// 必要的依赖项
api = require('api')
appConfig = require('appConfig')

// mock 掉 mintUI
function fakeMintUI() {
  var fakeProxy = () => new Proxy(function (cb) {
    console.log('[mintUI]: ', ...arguments)
    if (typeof (cb) === 'function') cb()
    return fakeProxy()
  }, {
    get: fakeProxy
  })
  return fakeProxy()
}

// 每日报平安
function fuckDailyReport(debug = true) {
  this.nowDate = dateFormat('YYYY-mm-dd', new Date())

  mintUI = fakeMintUI();
  var initData = () => new Promise((resolve) => {
    var $this = this;
    var tempFormData = {};

    tempFormData.USER_ID = USERID;
    MOB_UTIL.Post(api.getMyTodayReportWid, {
      pageNumber: 1,
      pageSize: 10,
      USER_ID: USERID,
    }).done(function (result) {
      var rows = result.datas.getMyTodayReportWid.rows;
      tempFormData.MEMBER_HEALTH_UNSUAL_CODE = '';
      tempFormData.IS_SEE_DOCTOR = '';
      tempFormData.MEMBER_HEALTH_STATUS_CODE = '';
      var userInfo = USER_INFO;
      tempFormData.USER_NAME = userInfo.USER_NAME;
      tempFormData.DEPT_CODE = userInfo.DEPT_CODE;
      tempFormData.DEPT_NAME = userInfo.DEPT_NAME;
      tempFormData.PHONE_NUMBER = userInfo.PHONE_NUMBER;
      tempFormData.IDCARD_NO = userInfo.IDENTITY_CREDENTIALS_NO;
      if (rows.length !== 0) {
        $.extend(tempFormData, rows[0]);
      } else {
        tempFormData.WID = '';
      }
      tempFormData.CREATED_AT = dateFormat("YYYY-mm-dd HH:MM", new Date());
      tempFormData.NEED_CHECKIN_DATE = appConfig.serverDate;
      MOB_UTIL.Post(api.getLatestDailyReportData, {
        pageNumber: 1,
        pageSize: 10,
        USER_ID: USERID
      }).done(function (rs) {
        var row = rs.datas.getLatestDailyReportData.rows;
        if (row.length !== 0) {
          $.extend(tempFormData, row[0]);
        }
        //计算年龄
        var myDate = new Date();
        var year = myDate.getFullYear();
        if (userInfo.BIRTHDAY) {
          tempFormData.AGE = Number(year) - Number(userInfo.BIRTHDAY.split("-")[0]);
        }
        tempFormData.GENDER_CODE = userInfo.GENDER;
        tempFormData.TUTOR = userInfo.TUTOR;
        tempFormData.LB = userInfo.STU_TYPE;
        $this.dailyReportInfo = tempFormData;
        $this.dataReady = true;
        resolve();
      });
    });
  })

  var save = () => new Promise((resolve) => {
    this.$router = {
      go() {
        console.log('[auto fuck dailyReportInfo] done.')
        resolve()
      }
    };

    var $this = this;
    if (Number($this.dailyReportInfo.TEMPERATURE) > 50) {
      mintUI.MessageBox('提示', "本人温度不能大于50！");
      return;
    }
    mintUI.MessageBox.confirm('确定数据无误并提交数据吗？').then(function () {
      if ($this.dailyReportInfo.HEALTH_STATUS_CODE != "002") {
        $this.dailyReportInfo.HEALTH_UNSUAL_CODE = '';
      }
      if ($this.dailyReportInfo.IS_SEE_DOCTOR != "YES") {
        $this.dailyReportInfo.SAW_DOCTOR_DESC = '';
      }
      if ($this.dailyReportInfo.MEMBER_HEALTH_STATUS_CODE != "002") {
        $this.dailyReportInfo.MEMBER_HEALTH_UNSUAL_CODE = '';
      }
      //电子科大定制-发热状态赋值
      if ($this.dailyReportInfo.HEALTH_UNSUAL_CODE.indexOf("999") != -1) {
        $this.dailyReportInfo.IS_HOT = '1';
      } else {
        $this.dailyReportInfo.IS_HOT = '0';
      }
      if ($this.dailyReportInfo.HEALTH_UNSUAL_CODE.indexOf("999") == -1 && $this.dailyReportInfo.IS_IN_HB != '1') {
        $this.dailyReportInfo.TEMPERATURE = '';
      }
      //电子科大定制-新增字段赋值
      $this.dailyReportInfo.TEMPERATURE = $this.dailyReportInfo.TEMPERATURE ? $this.dailyReportInfo.TEMPERATURE : '';
      $this.dailyReportInfo.REMARK = $this.dailyReportInfo.REMARK ? $this.dailyReportInfo.REMARK : '';
      // open the show loading.
      mintUI.Indicator.open();
      if (debug) return resolve()
      MOB_UTIL.Post(WIS_CONFIG.ROOT_PATH + '/sys/' + APPNAME + '/api/base/getServerDate.do', '').done(function (result) {
        mintUI.Indicator.close();
        if (result == $this.nowDate) {
          MOB_UTIL.Post(api.saveMyDailyReportDetail, $this.dailyReportInfo).done(function (result) {
            // close the show loading.
            mintUI.Indicator.close();
            if (result && result.code == '0') {
              mintUI.Toast('提报成功');
              $this.$router.go(-1);
            } else {
              mintUI.MessageBox('提示', "操作失败，请重试或联系管理员");
              return false;
            }
          });
        } else {
          mintUI.MessageBox.confirm('当日填报时间已截止，是否刷新并重新填报？').then(function () {
            $this.$router.go(-1);
          });
        }
      });
    });
  })

  return new Promise(res => {
    initData().then(save).then(res)
  })
}

/**
 * 申报体温
 * @param {Bool} debug 调试模式不会发送最后的请求
 * @param {Number} time 0 早上; 1 中午; 2 晚上
 */
function fuckTemp(time = 0, debug = true) {
  mintUI = fakeMintUI();

  const initData = () => new Promise(res => {
    var $this = this;
    var tempFormData = {};

    // USER_INFO为内置变量
    tempFormData.USER_ID = USERID;
    var userInfo = appConfig.userInfoFromDB;
    tempFormData.USER_NAME = userInfo.USER_NAME;
    tempFormData.DEPT_CODE = userInfo.DEPT_CODE;
    tempFormData.DEPT_NAME = userInfo.DEPT_NAME;
    var hours = ['09', '12', '18']
    var dateStr = dateFormat("YYYY-mm-dd", new Date())
    var nowDate = new Date(`${dateStr} ${hours[time]}:00:00`)
    var nowTime = dateFormat("YYYY-mm-dd HH:MM", nowDate);
    tempFormData.CREATED_AT = nowTime;
    //根据当前时间封装体温日期，及上下午判断
    tempFormData.NEED_DATE = nowTime.substring(0, 10);
    if (nowTime.substring(11, 13) >= 12) {
      if (nowTime.substring(11, 13) >= 18) {
        tempFormData.DAY_TIME = '3';
        tempFormData.DAY_TIME_DISPLAY = '晚上';
      } else {
        tempFormData.DAY_TIME = '2';
        tempFormData.DAY_TIME_DISPLAY = '中午';
      }
    } else {
      tempFormData.DAY_TIME = '1';
      tempFormData.DAY_TIME_DISPLAY = '早上';
    }
    tempFormData.WID = '';
    tempFormData.TEMPERATURE = 36
    $this.tempReportInfo = tempFormData;
    $this.dataReady = true;

    res(); // 初始化数据结束
  })

  const save = () => new Promise(resolve => {
    this.$router = {
      go() {
        console.log('[auto fuck saveMyTempReportDetail] done.')
        resolve()
      }
    };

    console.log('[温度]: ', this.tempReportInfo.TEMPERATURE)

    var $this = this;
    if (Number($this.tempReportInfo.TEMPERATURE) > 50 || Number($this.tempReportInfo.TEMPERATURE) < 30) {
      mintUI.MessageBox('提示', "体温区间为30℃~50℃！");
      return;
    }
    mintUI.MessageBox.confirm('确定数据无误并提交数据吗？').then(function () {
      if (!$this.tempReportInfo.WID) {
        mintUI.Indicator.open();
        var params = {
          USER_ID: USERID,
          NEED_DATE: $this.tempReportInfo.NEED_DATE,
          DAY_TIME: $this.tempReportInfo.DAY_TIME
        };
        axios({
          method: "POST",
          url: api.getMyTempReport,
          params: params,
        }).then(function (resp) {
          var rows = resp.data.datas.getMyTempReportDatas.rows;
          if (rows.length > 0) {
            mintUI.MessageBox('提示', "当前时间段温度已上报，请勿重复上报！");
            mintUI.Indicator.close();
            return;
          } else {
            if (debug) return resolve($this.tempReportInfo)
            axios({
              method: "POST",
              url: api.saveMyTempReportDetail,
              params: $this.tempReportInfo,
            }).then(function (resp) {
              // close the show loading.
              mintUI.Indicator.close();
              if (resp.data && resp.data.code == '0') {
                mintUI.Toast('提报成功');
                $this.$router.go(-1);
              } else {
                mintUI.MessageBox('提示', "网络开小差了，请稍后再试");
                return false;
              }
            });
          }
        });
      } else {
        if (debug) return resolve($this.tempReportInfo)
        axios({
          method: "POST",
          url: api.saveMyTempReportDetail,
          params: $this.tempReportInfo,
        }).then(function (resp) {
          // close the show loading.
          mintUI.Indicator.close();
          if (resp.data && resp.data.code == '0') {
            mintUI.Toast('提报成功');
            $this.$router.go(-1);
          } else {
            mintUI.MessageBox('提示', "网络开小差了，请稍后再试");
            return false;
          }
        });
      }
    });
  })

  return new Promise(res => {
    initData().then(save).then(res)
  })
}

console.log('[js] 注入成功')