const fs=require('fs'),crypto=require('crypto'),r=require('../tests/runtime_v18.cjs')();
const source=fs.readFileSync('prototypes/kasumigaseki_cards_v18.html');
r(`start('admin');state.challenge='intro';state.difficulty='normal';const shuffleForExport=shuffle;shuffle=a=>a.slice();`);
const enemies={};for(const soft of ['none','finance','parliament','press']){r(`state.soft=${soft==='none'?'null':JSON.stringify(soft)}`);enemies[soft]=r("enemyDeck('final')");}
const data={schema:1,sourceSha256:crypto.createHash('sha256').update(source).digest('hex'),cards:r('C'),decks:r('BASEDECKS'),attributes:r('AFF'),labels:r('LABELS'),issues:r('ISSUES'),growth:r('GROW'),enemies};
const text=JSON.stringify(data,null,2)+'\n',path='godot/data/game.json';if(process.argv.includes('--check')){if(fs.readFileSync(path,'utf8')!==text)throw Error('Godot data drift: run npm run export:godot');console.log('PASS: Godot data matches v18 definitions.');}else fs.writeFileSync(path,text);
