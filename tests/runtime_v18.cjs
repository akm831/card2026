const fs=require('fs');
module.exports=function(version='v18'){
 const loader=fs.readFileSync('tests/hand_rules_v10.cjs','utf8').split('let sims=')[0].replaceAll('prototypes/kasumigaseki_cards_v10.html','prototypes/kasumigaseki_cards_'+version+'.html').replace('(after.hand-before.hand+1)*1.8','(Math.min(after.hand,7)-Math.min(before.hand-1,7))*1.8').replace('score+=(battle.boost-base.boost)*0.9;','score+=(battle.boost-base.boost)*0.9+(battle.nextDraw-base.nextDraw)*0.9;');
 return new Function('require',loader+';return load;')(require)('native');
};
