// Pure planner: receives public board information and the enemy's own hand only.
function enemyPersonValue(a, view) {
  const base = {official:3, leader:2, reporter:3, economist:2, organizer:2, broker:2}[a.id] || 2;
  const level = view.growth[a.id]?.level || 0;
  return base + (level ? (a.id === 'official' ? 4 : 2) : Math.min(1, (view.growth[a.id]?.progress || 0) * .3));
}
function enemyTarget(card, view) {
  const effect = card.effects.find(e => e.op === 'bounce' || e.op === 'suppress');
  if (!effect) return null;
  const candidates = view.allies.filter(a => (!effect.aff || effect.aff === a.aff) &&
    (effect.op !== 'suppress' || a.disabledUntil < view.turn + 1));
  candidates.sort((a,b) => enemyPersonValue(b,view)-enemyPersonValue(a,view));
  return candidates[0]?.id || null;
}
function enemyPlanScore(plan, view) {
  let damage=0, block=0, interference={};
  for (const card of plan) for (const effect of card.effects) {
    if (effect.op === 'damage') damage += effect.n;
    if (effect.op === 'block') block += effect.n;
    if (effect.op === 'bounce' || effect.op === 'suppress') {
      const ally=view.allies.find(a=>a.id===card.target);
      if (!ally || effect.aff && effect.aff !== ally.aff || effect.op==='suppress' && ally.disabledUntil>=view.turn+1) continue;
      const value=enemyPersonValue(ally,view)*(effect.op==='bounce'?.7:1);
      interference[ally.id]=Math.max(interference[ally.id]||0,value);
    }
  }
  const net=Math.max(0,damage-view.playerBlock);
  const attack=Math.min(view.playerHP,net) + (net>=view.playerHP && view.playerHP>0 ? 18 : 0) + damage*.05;
  // Guard is gained after the player's current turn and protects the following turn.
  const expected=Math.min(20,Math.max(6,(view.lastPlayerDamage || 6)+2));
  const defense=Math.min(block,expected)*(view.enemyHP<=12?1.3:.65);
  return attack + defense + Object.values(interference).reduce((n,x)=>n+x,0) - plan.reduce((n,c)=>n+c.cost,0)*.08;
}
function selectEnemyActions(hand, budget, view, reserved=[]) {
  const base=reserved.map(c=>({...c,target:enemyTarget(c,view)}));
  let best=[],score=enemyPlanScore(base,view);
  // At most seven cards: examine every affordable combination, rather than greedy ratios.
  for (let mask=1;mask<2**hand.length;mask++) {
    let cost=0,cards=[];
    for(let i=0;i<hand.length;i++)if(mask & 2**i){cost+=hand[i].cost;cards.push({...hand[i],target:enemyTarget(hand[i],view)});}
    if(cost>budget)continue;
    const value=enemyPlanScore(base.concat(cards),view);
    if(value>score+1e-9){score=value;best=cards;}
  }
  return base.concat(best);
}
