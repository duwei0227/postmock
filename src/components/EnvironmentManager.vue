<script setup>
import { ref, computed, onMounted } from 'vue';
import { useConfirm } from 'primevue/useconfirm';
import { useEnvironmentsStore } from '@/stores/environments';

const confirm = useConfirm();
const environmentsStore = useEnvironmentsStore();

const showEnvDialog = ref(false);
const envDialogMode = ref('list'); // 'list', 'add', 'edit'
const editingEnv = ref({
  id: '',
  name: '',
  variables: [{ key: '', value: '', enabled: true }]
});
const hoveredVariableIndex = ref(-1);

// 使用 store 中的数据
const currentEnvironment = computed({
  get: () => environmentsStore.activeEnvironmentId,
  set: (value) => environmentsStore.setActiveEnvironment(value)
});

const environments = computed(() => environmentsStore.environments);

const environmentOptions = computed(() => {
  return [
    { label: 'No Environment', value: null },
    ...environments.value.map(env => ({ label: env.name, value: env.id }))
  ];
});

// 加载环境数据
onMounted(async () => {
  await environmentsStore.loadEnvironments();
});

// 环境管理函数
const openEnvDialog = () => {
  envDialogMode.value = 'list';
  showEnvDialog.value = true;
};

const openAddEnv = () => {
  envDialogMode.value = 'add';
  editingEnv.value = {
    id: '',
    name: '',
    variables: [{ key: '', value: '', enabled: true }]
  };
};

// Method to open create dialog directly (for global shortcut)
const openCreateDialog = () => {
  showEnvDialog.value = true;
  openAddEnv();
};

const openEditEnv = (env) => {
  envDialogMode.value = 'edit';
  editingEnv.value = JSON.parse(JSON.stringify(env));
  // 确保至少有一个空行
  if (editingEnv.value.variables.length === 0 || 
      editingEnv.value.variables[editingEnv.value.variables.length - 1].key) {
    editingEnv.value.variables.push({ key: '', value: '', enabled: true });
  }
};

const saveEnvironment = async () => {
  if (!editingEnv.value.name.trim()) {
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Environment name is required',
        life: 3000
      });
    }
    return;
  }

  try {
    // 过滤掉空的变量
    const filteredVariables = editingEnv.value.variables.filter(v => v.key.trim());

    if (envDialogMode.value === 'add') {
      await environmentsStore.createEnvironment(editingEnv.value.name.trim());
      const newEnv = environments.value[environments.value.length - 1];
      if (filteredVariables.length > 0) {
        await environmentsStore.updateEnvironment(newEnv.id, {
          variables: filteredVariables
        });
      }
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment created successfully',
          life: 2000
        });
      }
    } else if (envDialogMode.value === 'edit') {
      await environmentsStore.updateEnvironment(editingEnv.value.id, {
        name: editingEnv.value.name.trim(),
        variables: filteredVariables
      });
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment updated successfully',
          life: 2000
        });
      }
    }

    envDialogMode.value = 'list';
  } catch (error) {
    console.error('Failed to save environment:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to save environment',
        life: 3000
      });
    }
  }
};

const cancelEnvEdit = () => {
  envDialogMode.value = 'list';
};

const deleteEnvironment = (envId) => {
  const env = environments.value.find(e => e.id === envId);
  if (!env) return;
  
  confirm.require({
    message: `确定要删除环境 "${env.name}" 吗？`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '删除',
    rejectLabel: '取消',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await environmentsStore.deleteEnvironment(envId);
        
        if (window.$toast) {
          window.$toast.add({
            severity: 'success',
            summary: 'Success',
            detail: 'Environment deleted successfully',
            life: 2000
          });
        }
      } catch (error) {
        console.error('Failed to delete environment:', error);
        if (window.$toast) {
          window.$toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to delete environment',
            life: 3000
          });
        }
      }
    }
  });
};

const deleteVariable = (index) => {
  if (editingEnv.value.variables.length > 1) {
    editingEnv.value.variables.splice(index, 1);
  }
};

const onVariableChange = () => {
  // 如果最后一行有内容，自动添加新的空行
  const lastVar = editingEnv.value.variables[editingEnv.value.variables.length - 1];
  if (lastVar && (lastVar.key || lastVar.value)) {
    const hasEmptyRow = editingEnv.value.variables.some(v => !v.key && !v.value);
    if (!hasEmptyRow) {
      editingEnv.value.variables.push({ key: '', value: '', enabled: true });
    }
  }
};

const getEnvDialogTitle = () => {
  if (envDialogMode.value === 'list') return 'Manage Environments';
  if (envDialogMode.value === 'add') return 'Add Environment';
  return 'Edit Environment';
};

// 获取当前环境的变量（用于替换请求中的变量）
const getCurrentEnvironmentVariables = () => {
  if (!currentEnvironment.value) return {};
  const env = environments.value.find(e => e.id === currentEnvironment.value);
  if (!env) return {};
  
  const vars = {};
  env.variables.forEach(v => {
    if (v.key && v.enabled !== false) {
      vars[v.key] = v.value;
    }
  });
  return vars;
};

// 格式化日期时间的辅助函数
const formatDateTime = (date, format) => {
  const pad = (num) => String(num).padStart(2, '0');
  
  const year = date.getFullYear();
  const month = pad(date.getMonth() + 1);
  const day = pad(date.getDate());
  const hours = pad(date.getHours());
  const minutes = pad(date.getMinutes());
  const seconds = pad(date.getSeconds());
  
  return format
    .replace(/yyyy/g, year)
    .replace(/MM/g, month)
    .replace(/dd/g, day)
    .replace(/HH/g, hours)
    .replace(/mm/g, minutes)
    .replace(/ss/g, seconds);
};

// 生成随机字符串的辅助函数
const generateRandomString = (length = 10, options = { alpha: true, numeric: true, uppercase: true, lowercase: true }) => {
  let chars = '';
  
  if (options.uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (options.lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
  if (options.numeric) chars += '0123456789';
  
  // 如果没有选择任何字符类型，默认使用全部
  if (chars === '') {
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  }
  
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return result;
};

// 生成随机字母字符串（大小写混合）
const generateRandomAlpha = (length = 10) => {
  return generateRandomString(length, { uppercase: true, lowercase: true, numeric: false });
};

// 生成随机数字字符串
const generateRandomNumeric = (length = 10) => {
  return generateRandomString(length, { uppercase: false, lowercase: false, numeric: true });
};

// 生成随机大写字母字符串
const generateRandomUppercase = (length = 10) => {
  return generateRandomString(length, { uppercase: true, lowercase: false, numeric: false });
};

// 生成随机小写字母字符串
const generateRandomLowercase = (length = 10) => {
  return generateRandomString(length, { uppercase: false, lowercase: true, numeric: false });
};

// 生成随机字母数字混合字符串
const generateRandomAlphanumeric = (length = 10) => {
  return generateRandomString(length, { uppercase: true, lowercase: true, numeric: true });
};

// 生成随机中文字符串的辅助函数
const generateRandomChineseString = (length = 10) => {
  // 常见的中文词组和短语（2-4个字）- 扩充到500+个
  const chinesePhrases = [
    // 技术类
    '测试', '数据', '用户', '系统', '管理', '信息', '服务', '平台', '网络', '技术',
    '开发', '应用', '功能', '操作', '设置', '配置', '文件', '内容', '项目', '任务',
    '程序', '代码', '接口', '模块', '组件', '框架', '架构', '算法', '数据库', '服务器',
    '客户端', '前端', '后端', '全栈', '云计算', '大数据', '人工智能', '机器学习', '深度学习',
    '区块链', '物联网', '移动端', '网页', '软件', '硬件', '固件', '驱动', '协议', '标准',
    '版本', '更新', '升级', '维护', '优化', '性能', '安全', '加密', '解密', '认证',
    '授权', '权限', '角色', '日志', '监控', '告警', '备份', '恢复', '迁移', '部署',
    
    // 业务类
    '客户', '订单', '产品', '价格', '数量', '金额', '支付', '交易', '账户', '余额',
    '充值', '提现', '转账', '退款', '发票', '收据', '合同', '协议', '条款', '政策',
    '营销', '推广', '广告', '促销', '优惠', '折扣', '积分', '会员', '等级', '权益',
    '商品', '库存', '采购', '销售', '供应', '需求', '物流', '配送', '仓储', '运输',
    '品牌', '类目', '分类', '标签', '属性', '规格', '型号', '批次', '序列号', '条码',
    '评价', '评分', '评论', '反馈', '投诉', '建议', '咨询', '客服', '售后', '保修',
    
    // 组织类
    '公司', '企业', '组织', '团队', '部门', '岗位', '职位', '员工', '人员', '成员',
    '领导', '经理', '主管', '专员', '助理', '总监', '总裁', '董事', '股东', '合伙人',
    '分公司', '子公司', '总部', '分部', '办事处', '门店', '网点', '机构', '单位', '集团',
    
    // 操作类
    '添加', '创建', '新建', '保存', '提交', '发布', '上传', '下载', '导入', '导出',
    '删除', '移除', '清空', '修改', '编辑', '更新', '刷新', '同步', '复制', '粘贴',
    '查询', '搜索', '筛选', '排序', '分页', '统计', '汇总', '分析', '计算', '处理',
    '显示', '隐藏', '展开', '折叠', '切换', '选择', '取消', '确认', '返回', '继续',
    '开始', '结束', '暂停', '停止', '启动', '关闭', '打开', '执行', '运行', '调用',
    '发送', '接收', '推送', '拉取', '订阅', '取消订阅', '通知', '提醒', '预览', '打印',
    
    // 状态类
    '成功', '失败', '错误', '异常', '警告', '提示', '完成', '进行中', '待处理', '已处理',
    '启用', '禁用', '激活', '冻结', '锁定', '解锁', '在线', '离线', '忙碌', '空闲',
    '正常', '异常', '超时', '过期', '有效', '无效', '可用', '不可用', '已读', '未读',
    
    // 时间类
    '今天', '昨天', '明天', '本周', '上周', '下周', '本月', '上月', '下月', '今年',
    '去年', '明年', '最近', '最新', '历史', '当前', '实时', '定时', '延时', '即时',
    '早上', '上午', '中午', '下午', '晚上', '凌晨', '白天', '夜间', '工作日', '周末',
    
    // 地点类
    '北京', '上海', '广州', '深圳', '杭州', '成都', '重庆', '武汉', '西安', '南京',
    '天津', '苏州', '郑州', '长沙', '沈阳', '青岛', '大连', '厦门', '宁波', '无锡',
    '东城区', '西城区', '朝阳区', '海淀区', '丰台区', '石景山', '通州区', '顺义区',
    '办公室', '会议室', '接待室', '展厅', '仓库', '车间', '实验室', '机房', '大厅', '前台',
    
    // 文档类
    '文档', '报告', '记录', '日志', '说明', '手册', '指南', '教程', '案例', '模板',
    '表格', '图表', '图片', '视频', '音频', '附件', '压缩包', '文本', '代码', '脚本',
    
    // 通用类
    '名称', '标题', '描述', '备注', '说明', '详情', '摘要', '简介', '概述', '总结',
    '编号', '序号', '代号', '标识', '标记', '标签', '分类', '类型', '种类', '格式',
    '方式', '方法', '模式', '规则', '条件', '参数', '配置', '选项', '属性', '字段',
    '链接', '地址', '路径', '目录', '文件夹', '位置', '坐标', '区域', '范围', '边界',
    '数值', '数字', '字符', '文字', '内容', '信息', '消息', '通知', '提醒', '警告',
    '问题', '答案', '解决方案', '建议', '意见', '想法', '计划', '方案', '策略', '目标',
    '结果', '效果', '影响', '作用', '价值', '意义', '重要性', '优先级', '紧急度', '难度',
    
    // 形容词类
    '重要', '紧急', '普通', '一般', '特殊', '常规', '临时', '永久', '公开', '私密',
    '简单', '复杂', '困难', '容易', '快速', '缓慢', '高级', '初级', '中级', '专业',
    '标准', '自定义', '默认', '推荐', '热门', '最新', '精选', '优质', '免费', '付费',
    
    // 动作类
    '学习', '工作', '生活', '娱乐', '休息', '运动', '旅游', '购物', '阅读', '写作',
    '思考', '讨论', '交流', '沟通', '协作', '合作', '竞争', '比较', '选择', '决定',
    '计划', '安排', '组织', '管理', '控制', '监督', '检查', '审核', '批准', '拒绝'
  ];
  
  // 单字填充词（扩充到1000+个常用字）
  const singleChars = '的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转更单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严龙飞';
  
  let result = '';
  let currentLength = 0;
  
  // 优先使用词组
  while (currentLength < length) {
    const remainingLength = length - currentLength;
    
    // 如果剩余长度较大，使用词组
    if (remainingLength >= 2) {
      // 过滤出长度合适的词组
      const suitablePhrases = chinesePhrases.filter(phrase => phrase.length <= remainingLength);
      
      if (suitablePhrases.length > 0) {
        const randomPhrase = suitablePhrases[Math.floor(Math.random() * suitablePhrases.length)];
        result += randomPhrase;
        currentLength += randomPhrase.length;
      } else {
        // 如果没有合适的词组，使用单字
        const randomIndex = Math.floor(Math.random() * singleChars.length);
        result += singleChars.charAt(randomIndex);
        currentLength++;
      }
    } else {
      // 剩余长度为1，使用单字
      const randomIndex = Math.floor(Math.random() * singleChars.length);
      result += singleChars.charAt(randomIndex);
      currentLength++;
    }
  }
  
  return result;
};

// 获取所有可用变量（环境变量 + 内置变量）
const getAllAvailableVariables = () => {
  const envVars = getCurrentEnvironmentVariables();
  
  const now = new Date();
  
  // 内置变量
  // $randomInt: 默认范围 0-1000，也可以使用 $randomInt(start, end) 指定范围
  // $date: 默认格式 yyyy-MM-dd，也可以使用 $date(format) 自定义格式
  // $time: 默认格式 HH:mm:ss，也可以使用 $time(format) 自定义格式
  // $datetime: 默认格式 yyyy-MM-dd HH:mm:ss，也可以使用 $datetime(format) 自定义格式
  // $randomString: 默认长度 10，包含大小写字母和数字（已废弃，建议使用具体类型的变量）
  // $randomAlpha: 默认长度 10，仅字母（大小写混合），可以使用 $randomAlpha(length) 自定义
  // $randomNumeric: 默认长度 10，仅数字，可以使用 $randomNumeric(length) 自定义
  // $randomUppercase: 默认长度 10，仅大写字母，可以使用 $randomUppercase(length) 自定义
  // $randomLowercase: 默认长度 10，仅小写字母，可以使用 $randomLowercase(length) 自定义
  // $randomAlphanumeric: 默认长度 10，字母数字混合，可以使用 $randomAlphanumeric(length) 自定义
  // $randomChinese: 默认长度 10，生成随机中文字符，可以使用 $randomChinese(length) 自定义
  const builtInVars = {
    '$timestamp': Date.now().toString(),
    '$isoTimestamp': new Date().toISOString(),
    '$randomInt': Math.floor(Math.random() * 1001).toString(), // 0-1000
    '$guid': crypto.randomUUID(),
    '$date': formatDateTime(now, 'yyyy-MM-dd'),
    '$time': formatDateTime(now, 'HH:mm:ss'),
    '$datetime': formatDateTime(now, 'yyyy-MM-dd HH:mm:ss'),
    '$randomString': generateRandomAlphanumeric(10), // 保留兼容性，默认为 alphanumeric
    '$randomAlpha': generateRandomAlpha(10),
    '$randomNumeric': generateRandomNumeric(10),
    '$randomUppercase': generateRandomUppercase(10),
    '$randomLowercase': generateRandomLowercase(10),
    '$randomAlphanumeric': generateRandomAlphanumeric(10),
    '$randomChinese': generateRandomChineseString(10),
  };
  
  return { ...envVars, ...builtInVars };
};

// 替换字符串中的变量
const replaceVariables = (str) => {
  if (!str || typeof str !== 'string') return str;
  
  const allVars = getAllAvailableVariables();
  console.log('[EnvironmentManager] replaceVariables called');
  console.log('[EnvironmentManager] Input string:', str);
  console.log('[EnvironmentManager] Available variables:', allVars);
  
  const result = str.replace(/\{\{([^}]+)\}\}/g, (match, varName) => {
    const trimmedVarName = varName.trim();
    
    // 检查是否是 $randomInt 函数调用
    const randomIntMatch = trimmedVarName.match(/^\$randomInt\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)$/);
    if (randomIntMatch) {
      const start = parseInt(randomIntMatch[1], 10);
      const end = parseInt(randomIntMatch[2], 10);
      const randomValue = Math.floor(Math.random() * (end - start + 1)) + start;
      console.log(`[EnvironmentManager] Replacing ${match} with random int between ${start} and ${end}: ${randomValue}`);
      return randomValue.toString();
    }
    
    // 检查是否是 $randomString 函数调用（保留向后兼容）
    // 支持格式: $randomString(length) 或 $randomString(length, "alpha") 或 $randomString(length, "numeric") 或 $randomString(length, "alphanumeric")
    const randomStringMatch = trimmedVarName.match(/^\$randomString\s*\(\s*(\d+)(?:\s*,\s*['"]([^'"]+)['"])?\s*\)$/);
    if (randomStringMatch) {
      const length = parseInt(randomStringMatch[1], 10);
      const type = randomStringMatch[2] || 'alphanumeric';
      
      let options = { alpha: false, numeric: false, uppercase: false, lowercase: false };
      
      switch (type.toLowerCase()) {
        case 'alpha':
          options.uppercase = true;
          options.lowercase = true;
          break;
        case 'numeric':
          options.numeric = true;
          break;
        case 'alphanumeric':
          options.uppercase = true;
          options.lowercase = true;
          options.numeric = true;
          break;
        case 'uppercase':
          options.uppercase = true;
          break;
        case 'lowercase':
          options.lowercase = true;
          break;
        default:
          // 默认使用 alphanumeric
          options.uppercase = true;
          options.lowercase = true;
          options.numeric = true;
      }
      
      const randomString = generateRandomString(length, options);
      console.log(`[EnvironmentManager] Replacing ${match} with random string (length: ${length}, type: ${type}): ${randomString}`);
      return randomString;
    }
    
    // 检查是否是 $randomAlpha 函数调用
    const randomAlphaMatch = trimmedVarName.match(/^\$randomAlpha\s*\(\s*(\d+)\s*\)$/);
    if (randomAlphaMatch) {
      const length = parseInt(randomAlphaMatch[1], 10);
      const randomAlpha = generateRandomAlpha(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random alpha (length: ${length}): ${randomAlpha}`);
      return randomAlpha;
    }
    
    // 检查是否是 $randomNumeric 函数调用
    const randomNumericMatch = trimmedVarName.match(/^\$randomNumeric\s*\(\s*(\d+)\s*\)$/);
    if (randomNumericMatch) {
      const length = parseInt(randomNumericMatch[1], 10);
      const randomNumeric = generateRandomNumeric(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random numeric (length: ${length}): ${randomNumeric}`);
      return randomNumeric;
    }
    
    // 检查是否是 $randomUppercase 函数调用
    const randomUppercaseMatch = trimmedVarName.match(/^\$randomUppercase\s*\(\s*(\d+)\s*\)$/);
    if (randomUppercaseMatch) {
      const length = parseInt(randomUppercaseMatch[1], 10);
      const randomUppercase = generateRandomUppercase(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random uppercase (length: ${length}): ${randomUppercase}`);
      return randomUppercase;
    }
    
    // 检查是否是 $randomLowercase 函数调用
    const randomLowercaseMatch = trimmedVarName.match(/^\$randomLowercase\s*\(\s*(\d+)\s*\)$/);
    if (randomLowercaseMatch) {
      const length = parseInt(randomLowercaseMatch[1], 10);
      const randomLowercase = generateRandomLowercase(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random lowercase (length: ${length}): ${randomLowercase}`);
      return randomLowercase;
    }
    
    // 检查是否是 $randomAlphanumeric 函数调用
    const randomAlphanumericMatch = trimmedVarName.match(/^\$randomAlphanumeric\s*\(\s*(\d+)\s*\)$/);
    if (randomAlphanumericMatch) {
      const length = parseInt(randomAlphanumericMatch[1], 10);
      const randomAlphanumeric = generateRandomAlphanumeric(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random alphanumeric (length: ${length}): ${randomAlphanumeric}`);
      return randomAlphanumeric;
    }
    
    // 检查是否是 $randomChinese 函数调用
    const randomChineseMatch = trimmedVarName.match(/^\$randomChinese\s*\(\s*(\d+)\s*\)$/);
    if (randomChineseMatch) {
      const length = parseInt(randomChineseMatch[1], 10);
      const randomChinese = generateRandomChineseString(length);
      console.log(`[EnvironmentManager] Replacing ${match} with random Chinese string (length: ${length}): ${randomChinese}`);
      return randomChinese;
    }
    
    // 检查是否是 $date 函数调用
    const dateMatch = trimmedVarName.match(/^\$date\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (dateMatch) {
      const format = dateMatch[1];
      const formattedDate = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted date: ${formattedDate}`);
      return formattedDate;
    }
    
    // 检查是否是 $time 函数调用
    const timeMatch = trimmedVarName.match(/^\$time\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (timeMatch) {
      const format = timeMatch[1];
      const formattedTime = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted time: ${formattedTime}`);
      return formattedTime;
    }
    
    // 检查是否是 $datetime 函数调用
    const datetimeMatch = trimmedVarName.match(/^\$datetime\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (datetimeMatch) {
      const format = datetimeMatch[1];
      const formattedDatetime = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted datetime: ${formattedDatetime}`);
      return formattedDatetime;
    }
    
    // 普通变量替换
    const replacement = allVars[trimmedVarName] !== undefined ? allVars[trimmedVarName] : match;
    console.log(`[EnvironmentManager] Replacing ${match} with ${replacement}`);
    return replacement;
  });
  
  console.log('[EnvironmentManager] Result:', result);
  return result;
};

defineExpose({
  getCurrentEnvironmentVariables,
  getAllAvailableVariables,
  replaceVariables,
  currentEnvironment,
  openCreateDialog
});
</script>

<template>
  <div class="environment-manager flex items-center gap-2">
    <Dropdown 
      v-model="currentEnvironment"
      :options="environmentOptions"
      optionLabel="label"
      optionValue="value"
      placeholder="No Environment"
      class="w-48"
      size="small"
    />
    <Button 
      icon="pi pi-cog"
      text
      rounded
      size="small"
      severity="secondary"
      title="Manage Environments"
      @click="openEnvDialog"
    />
    
    <!-- Environment Management Dialog -->
    <Dialog 
      v-model:visible="showEnvDialog"
      :header="getEnvDialogTitle()"
      :modal="true"
      :style="{ width: '600px' }"
      :closable="envDialogMode === 'list'"
    >
      <!-- List View -->
      <div v-if="envDialogMode === 'list'" class="flex flex-col gap-4">
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-surface-700 dark:text-surface-300">
            Environments
          </span>
          <Button 
            label="Add"
            icon="pi pi-plus"
            size="small"
            @click="openAddEnv"
          />
        </div>
        
        <div v-if="environments.length === 0" class="text-center py-8 text-surface-500 dark:text-surface-400 text-sm">
          No environments configured
        </div>
        
        <div v-else class="space-y-2">
          <div 
            v-for="env in environments"
            :key="env.id"
            class="p-3 border border-surface-200 dark:border-surface-700 rounded hover:bg-surface-50 dark:hover:bg-surface-900 cursor-pointer transition flex justify-between items-center"
            @click="openEditEnv(env)"
          >
            <div>
              <div class="text-sm font-medium text-surface-900 dark:text-surface-50">
                {{ env.name }}
              </div>
              <div class="text-xs text-surface-500 dark:text-surface-400 mt-1">
                {{ env.variables.length }} variable(s)
              </div>
            </div>
            <Button 
              icon="pi pi-trash"
              text
              rounded
              size="small"
              severity="danger"
              @click.stop="deleteEnvironment(env.id)"
            />
          </div>
        </div>
      </div>
      
      <!-- Add/Edit View -->
      <div v-else class="flex flex-col gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">Environment Name</label>
          <InputText 
            v-model="editingEnv.name"
            placeholder="Enter environment name"
            class="w-full"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium mb-3">Variables</label>
          
          <!-- Table Header -->
          <div class="flex gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
            <div class="flex-1">VARIABLE</div>
            <div class="flex-1">VALUE</div>
            <div style="width: 40px;"></div>
          </div>
          
          <!-- Table Rows -->
          <div class="space-y-1 max-h-64 overflow-y-auto">
            <div 
              v-for="(variable, index) in editingEnv.variables"
              :key="index"
              class="flex gap-2 items-center"
              @mouseenter="hoveredVariableIndex = index"
              @mouseleave="hoveredVariableIndex = -1"
            >
              <div class="flex-1">
                <InputText 
                  v-model="variable.key"
                  placeholder="Variable"
                  class="w-full"
                  size="small"
                  @input="onVariableChange"
                />
              </div>
              <div class="flex-1">
                <InputText 
                  v-model="variable.value"
                  placeholder="Value"
                  class="w-full"
                  size="small"
                  @input="onVariableChange"
                />
              </div>
              <div class="flex justify-center" style="width: 40px;">
                <Button 
                  v-if="(hoveredVariableIndex === index || variable.key || variable.value) && editingEnv.variables.length > 1"
                  icon="pi pi-times"
                  text
                  rounded
                  size="small"
                  severity="danger"
                  @click="deleteVariable(index)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <template #footer>
        <div v-if="envDialogMode === 'list'">
          <Button label="Close" @click="showEnvDialog = false" />
        </div>
        <div v-else class="flex gap-2">
          <Button label="Cancel" severity="secondary" @click="cancelEnvEdit" />
          <Button 
            label="Save"
            @click="saveEnvironment"
            :disabled="!editingEnv.name.trim()"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.environment-manager {
  display: flex;
  align-items: center;
}
</style>
