export interface ParsedCurl {
  method: string;
  url: string;
  headers: { key: string; value: string; enabled: boolean }[];
  body: {
    type: string;
    raw: string;
    formData: { key: string; value: string; type: string; enabled: boolean }[];
    urlencoded: { key: string; value: string; enabled: boolean }[];
  };
}

export function parseCurl(curlCommand: string): ParsedCurl {
  // 清理命令：移除换行符和多余空格
  let cmd = curlCommand.replace(/\\\r?\n/g, ' ').replace(/\s+/g, ' ').trim();
  
  // 移除开头的 curl
  cmd = cmd.replace(/^curl\s+/i, '');
  
  // 提取 method
  let method = 'GET';
  const methodMatch = cmd.match(/-X\s+([A-Z]+)/i);
  if (methodMatch) {
    method = methodMatch[1].toUpperCase();
    cmd = cmd.replace(/-X\s+[A-Z]+/i, '');
  }
  
  // 提取 URL - 支持带引号和不带引号的 URL
  let url = '';
  // 先尝试匹配带双引号的 URL
  const doubleQuotedUrlMatch = cmd.match(/"(https?:\/\/[^"]+)"/);
  if (doubleQuotedUrlMatch) {
    url = doubleQuotedUrlMatch[1];
    cmd = cmd.replace(/"(https?:\/\/[^"]+)"/, '');
  } else {
    // 尝试匹配带单引号的 URL
    const singleQuotedUrlMatch = cmd.match(/'(https?:\/\/[^']+)'/);
    if (singleQuotedUrlMatch) {
      url = singleQuotedUrlMatch[1];
      cmd = cmd.replace(/'(https?:\/\/[^']+)'/, '');
    } else {
      // 尝试匹配不带引号的 URL
      const simpleUrlMatch = cmd.match(/(https?:\/\/[^\s]+)/);
      if (simpleUrlMatch) {
        url = simpleUrlMatch[1];
        cmd = cmd.replace(simpleUrlMatch[0], '');
      }
    }
  }
  
  // 提取 headers - 支持双引号和单引号
  const headers: { key: string; value: string; enabled: boolean }[] = [];
  // 匹配 -H "key: value" 或 -H 'key: value'
  const headerRegex = /-H\s+["']([^"':]+):\s*([^"']+)["']/g;
  let headerMatch;
  while ((headerMatch = headerRegex.exec(cmd)) !== null) {
    headers.push({ 
      key: headerMatch[1].trim(), 
      value: headerMatch[2].trim(), 
      enabled: true 
    });
  }
  
  // 提取 body
  let bodyType = 'none';
  let bodyRaw = '';
  let bodyFormData: { key: string; value: string; type: string; enabled: boolean }[] = [];
  let bodyUrlencoded: { key: string; value: string; enabled: boolean }[] = [];
  
  const dataMatch = cmd.match(/(?:-d|--data|--data-raw|--data-binary)\s+["'](.+?)["']/);
  const formMatch = cmd.match(/-F\s+["'](.+?)["']/g);
  
  if (dataMatch) {
    const bodyContent = dataMatch[1];
    // 检查是否是 JSON
    try {
      JSON.parse(bodyContent);
      bodyType = 'json';
      bodyRaw = bodyContent;
    } catch {
      // 可能是 form-urlencoded
      if (bodyContent.includes('=') && bodyContent.includes('&')) {
        bodyType = 'x-www-form-urlencoded';
        const pairs = bodyContent.split('&');
        bodyUrlencoded = pairs.map(pair => {
          const [key, value] = pair.split('=');
          return {
            key: decodeURIComponent(key || ''),
            value: decodeURIComponent(value || ''),
            enabled: true
          };
        });
        // 添加空行
        bodyUrlencoded.push({ key: '', value: '', enabled: true });
      } else {
        bodyType = 'json';
        bodyRaw = bodyContent;
      }
    }
  } else if (formMatch) {
    bodyType = 'form-data';
    bodyFormData = formMatch.map(f => {
      const match = f.match(/-F\s+["']([^=]+)=(.+?)["']/);
      if (match) {
        return { 
          key: match[1], 
          value: match[2], 
          type: 'text', 
          enabled: true 
        };
      }
      return null;
    }).filter(Boolean) as { key: string; value: string; type: string; enabled: boolean }[];
    // 添加空行
    bodyFormData.push({ key: '', value: '', type: 'text', enabled: true });
  }
  
  // 确保 headers 有空行
  if (headers.length === 0) {
    headers.push({ key: '', value: '', enabled: true });
  } else {
    headers.push({ key: '', value: '', enabled: true });
  }
  
  // 确保 formData 和 urlencoded 有空行
  if (bodyFormData.length === 0) {
    bodyFormData.push({ key: '', value: '', type: 'text', enabled: true });
  }
  if (bodyUrlencoded.length === 0) {
    bodyUrlencoded.push({ key: '', value: '', enabled: true });
  }

  return {
    method,
    url,
    headers,
    body: {
      type: bodyType,
      raw: bodyRaw,
      formData: bodyFormData,
      urlencoded: bodyUrlencoded
    }
  };
}
