const fs = require('fs')
const startLine = 18468
const startEpisode = 1
const stopEpisode = 1
const startChapter = 0
let targetScript = fs.readFileSync('script.rb', 'utf-8').split('\n')
const header = targetScript.slice(0, startLine - 1).join('\n') + '\n'
targetScript = targetScript.slice(startLine - 1).join('\n')
fs.writeFileSync('script_target.rb', header, 'utf-8')
const scriptBase = 'script_plain/umi'
for (let ep = startEpisode; ep <= stopEpisode; ep++) {
  for (let chapter = startChapter; chapter <= 100; chapter++) {
    const scriptJp = `${scriptBase}${ep}_${chapter}_jp.txt`
    const scriptEn = `${scriptBase}${ep}_${chapter}.txt`
    if (!fs.existsSync(scriptJp)) break
    console.log(`Processing Episode ${ep}, chapter ${chapter}`)
    const linesJp = fs.readFileSync(scriptJp, 'utf-8').split('\n')
    const linesEn = fs.readFileSync(scriptEn, 'utf-8').split('\n')
    for (let i = 0; i < linesJp.length; i++) {
      if (linesEn[i]) targetScript = targetScript.replace(linesJp[i], linesEn[i])
    }
  }
}
fs.writeFileSync('script_target.rb', targetScript, { encoding: 'utf-8', flag: 'a' })
fs.renameSync('script_target.rb', 'script.rb')
