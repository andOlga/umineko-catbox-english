const fs = require('fs')
const startLine = 18472
const lines = fs.readFileSync('script.rb', 'utf-8').split('\n')
for (let i = startLine; i < lines.length; i++) {
  if (
    lines[i].startsWith('s.ins 0x86') &&
    !lines[i].includes('s.layout')
  ) {
    lines[i] = lines[i].replace(/('.+')$/, 's.layout($1)')
  }
}
fs.writeFileSync('script.rb', lines.join('\n'), 'utf-8')
