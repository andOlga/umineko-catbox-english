const fs = require('fs')
const lines = fs.readFileSync('script.rb', 'utf-8').split('\n')
const nametags = {
  '南條　輝正': 'Nanjo',
  '右代宮　金蔵': 'Kinzo',
  '呂ノ上　源次': 'Genji',
  '右代宮　戦人': 'Battler',
  '右代宮　譲治': 'George'
}
for (let i = 0; i < lines.length; i++) {
  if (!lines[i].startsWith('s.ins 0x86')) continue
  for (const nt of Object.keys(nametags)) {
    lines[i] = lines[i].replace(`, '${nt}@r`, `, '${nametags[nt]}@r`)
  }
}
fs.writeFileSync('script.rb', lines.join('\n'), 'utf-8')
