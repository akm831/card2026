const fs=require('fs'),r=require('../tests/runtime_v18.cjs')();
r(`function stateForPort(){let out=copy(battle);for(let k of ['log','currentCard','currentCost','currentAff'])delete out[k];return {battle:out,seed};}`);
const runs=[];
for(let type of ['admin','regional','noir','economic'])for(let soft of ['none','finance','parliament','press'])for(let value of [123,987654,31337]){
 r(`start('${type}');seed=${value};state.soft=${soft==='none'?'null':JSON.stringify(soft)};begin('final');`);
 const steps=[{op:'start',expected:r('stateForPort()')}];
 for(let turn=0;turn<16&&r("state.phase==='battle'");turn++){
  while(r('battle.hand.length>7&&!battle.outcome')){r('discardOverflow(0)');steps.push({op:'discard',index:0,expected:r('stateForPort()')});}
  for(let k=0;k<25&&r('!battle.outcome');k++){
   const action=r('simpleAction()');if(!action)break;
   r(`commit(${action.i},${JSON.stringify(action.uid)})`);steps.push({op:'play',index:action.i,uid:action.uid,expected:r('stateForPort()')});
   if(k===0&&turn===0){r('undo()');steps.push({op:'undo',expected:r('stateForPort()')});r(`commit(${action.i},${JSON.stringify(action.uid)})`);steps.push({op:'play',index:action.i,uid:action.uid,expected:r('stateForPort()')});}
   while(r('battle.hand.length>7&&!battle.outcome')){r('discardOverflow(0)');steps.push({op:'discard',index:0,expected:r('stateForPort()')});}
  }
  const beforeEndSeed=r('seed');r('end()');const after=r('stateForPort()');if(r("state.phase!=='battle'"))after.seed=beforeEndSeed;steps.push({op:'end',expected:after});
 }
 runs.push({type,soft,seed:value,steps});
}
fs.writeFileSync('godot/tests/parity_fixtures.json',JSON.stringify(runs)+'\n');console.log('Exported',runs.length,'battle traces,',runs.reduce((n,x)=>n+x.steps.length,0),'state comparisons.');
