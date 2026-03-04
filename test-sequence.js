// 测试 $sequence 变量替换逻辑

function testSequenceRegex() {
  const testCases = [
    '$sequence',
    '$sequence()',
    '$sequence(myseq)',
    '$sequence("myseq")',
    '$sequence(myseq, 5)',
    '$sequence(myseq, 5, 100)',
    '$sequence(myseq, 5, 100, 10)',
    '$sequen',  // 不完整的变量名
    '$sequence(',  // 不完整的语法
  ];

  testCases.forEach(testCase => {
    console.log(`\nTesting: "${testCase}"`);
    
    const trimmedVarName = testCase.trim();
    
    if (trimmedVarName === '$sequence' || trimmedVarName.startsWith('$sequence(')) {
      console.log('  ✓ Passed initial check');
      
      const sequenceMatch = trimmedVarName.match(/^\$sequence(?:\s*\(\s*([^,)]+)(?:\s*,\s*(\d+))?(?:\s*,\s*(\d+))?(?:\s*,\s*(\d+))?\s*\))?$/);
      
      if (sequenceMatch) {
        console.log('  ✓ Regex matched');
        console.log('  Groups:', sequenceMatch);
        
        const name = sequenceMatch[1] ? sequenceMatch[1].trim().replace(/^['"]|['"]$/g, '') : 'default';
        const padding = sequenceMatch[2] ? parseInt(sequenceMatch[2], 10) : 0;
        const startValue = sequenceMatch[3] ? parseInt(sequenceMatch[3], 10) : 1;
        const step = sequenceMatch[4] ? parseInt(sequenceMatch[4], 10) : 1;
        
        console.log(`  name: ${name}, padding: ${padding}, start: ${startValue}, step: ${step}`);
      } else {
        console.log('  ✗ Regex did not match');
      }
    } else {
      console.log('  ✗ Failed initial check');
    }
  });
}

testSequenceRegex();
