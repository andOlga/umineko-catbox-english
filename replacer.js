const fs = require('fs')
const startLine = 18473 - 1
let targetScript = fs.readFileSync('script.rb', 'utf-8').split('\n')
let output = targetScript.slice(0, startLine).join('\n') + '\n'
targetScript = targetScript.slice(startLine).join('\n')
const scriptBase = 'script_plain/umi'
for (let ep = 1; ep <= 8; ep++) {
  console.log(`Processing Episode ${ep}`)
  for (let chapter = 0; chapter <= 100; chapter++) {
    const scriptJp = `${scriptBase}${ep}_${chapter}_jp.txt`
    const scriptEn = `${scriptBase}${ep}_${chapter}.txt`
    if (!fs.existsSync(scriptJp)) break

    const linesJp = fs.readFileSync(scriptJp, 'utf-8').split('\n')
    const linesEn = fs.readFileSync(scriptEn, 'utf-8').split('\n')

    let chapterScript = targetScript.split('\n')
    const lineIdx = chapterScript.findIndex(x => x.startsWith('s.ins 0xa0, byte(1), ')) + 1
    chapterScript = chapterScript.slice(0, lineIdx)
    chapterScript = chapterScript.join('\n')
    for (let i = 0; i < linesJp.length; i++) {
      if (linesEn[i]) {
        for (const fun of [x => x + '@', x => x + "'", x => x.trim() + '@', x => x.trim() + "'"]) {
          const tmpScript = chapterScript.replace(fun(linesJp[i]), fun(linesEn[i]))
          if (tmpScript !== chapterScript) {
            chapterScript = tmpScript
            break
          }
        }
      }
    }

    output += chapterScript + '\n'
    targetScript = targetScript.split('\n').slice(lineIdx).join('\n')
  }
}
fs.writeFileSync('script.rb', output + '\n' + targetScript, 'utf-8')
