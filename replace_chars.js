// This script replaces unusual (non-English) characters with their Unicode values.
// Used during translations to other languages.

const fs = require('fs')

const intlCharacters = [ // List all of your language's non-Latin chars here.

]

let script = fs.readFileSync('script.rb', 'utf-8')

for (const character of intlCharacters) {
  const code = character.codePointAt()
  script = script.replaceAll(character, `@u${code}.`)
}

fs.writeFileSync('script.rb', script)
