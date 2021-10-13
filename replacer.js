const fs = require('fs')
let targetScript = fs.readFileSync('script_replace.rb', 'utf-8')
const scriptBase = `script_plain/${process.argv[2]}`
const scriptJp = `${scriptBase}_jp.txt`
const scriptEn = `${scriptBase}.txt`
if (!fs.existsSync(scriptJp) || !fs.existsSync(scriptEn)) process.exit()

const linesJp = fs.readFileSync(scriptJp, 'utf-8').split('\n')
const linesEn = fs.readFileSync(scriptEn, 'utf-8').split('\n')
const replaceDialogue = true
const lineFuns = replaceDialogue ? [x => x + '@', x => x + "'", x => x.trim() + '@', x => x.trim() + "'"] : [x => x, x => x.trim()]
for (let i = 0; i < linesJp.length; i++) {
  if (linesEn[i]) {
    for (const fun of lineFuns) {
      const tmpScript = targetScript.replace(fun(linesJp[i]), fun(linesEn[i]))
      if (tmpScript !== targetScript) {
        targetScript = tmpScript
        break
      }
    }
  }
}
fs.writeFileSync('script_replace.rb', targetScript, 'utf-8')
