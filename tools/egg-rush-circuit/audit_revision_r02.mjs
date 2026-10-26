const dot=(a,b)=>a[0]*b[0]+a[1]*b[1];
const sub=(a,b)=>[a[0]-b[0],a[1]-b[1]];
const length=a=>Math.hypot(...a);
const top=p=>p.cf[1]+p.size[1]/2;
function polygon(p,shift=[0,0,0]){
 const f=p.cf,x=p.size[0]/2,z=p.size[2]/2;
 return [[-1,-1],[1,-1],[1,1],[-1,1]].map(([a,b])=>[f[0]+shift[0]+f[3]*a*x+f[5]*b*z,f[2]+shift[2]+f[9]*a*x+f[11]*b*z]);
}
function segmentDistance(p,a,b){
 const d=sub(b,a),q=sub(p,a),t=Math.max(0,Math.min(1,dot(q,d)/dot(d,d)));
 return length(sub(p,[a[0]+d[0]*t,a[1]+d[1]*t]));
}
function gap(a,b){
 let separated=false,penetration=Infinity;
 for(const poly of [a,b])for(let i=0;i<4;i++){
  const e=sub(poly[(i+1)%4],poly[i]),n=[-e[1]/length(e),e[0]/length(e)];
  const aa=a.map(p=>dot(p,n)),bb=b.map(p=>dot(p,n));
  const overlap=Math.min(Math.max(...aa),Math.max(...bb))-Math.max(Math.min(...aa),Math.min(...bb));
  if(overlap<0)separated=true;
  penetration=Math.min(penetration,overlap);
 }
 if(!separated)return {distance:0,penetration};
 let distance=Infinity;
 for(const [p,q] of [[a,b],[b,a]])for(const point of p)for(let j=0;j<4;j++)distance=Math.min(distance,segmentDistance(point,q[j],q[(j+1)%4]));
 return {distance,penetration:0};
}
function reach(rise){return rise>7.2?0:16*(Math.sqrt(2*196.2*7.2)+Math.sqrt(2*196.2*(7.2-rise)))/196.2;}
function travel(geometry,p){
 if(!p.moving)return [0,0,0];
 const m=geometry.mechanisms.find(x=>x.name===p.moving),v=m.attributes.Travel;
 if(!v)return [0,0,0];
 const f=m.pivot;return [f[3]*v[0]+f[4]*v[1]+f[5]*v[2],f[6]*v[0]+f[7]*v[1]+f[8]*v[2],f[9]*v[0]+f[10]*v[1]+f[11]*v[2]];
}
export function auditGeometry(geometry){
 const report={candidate:geometry.candidate,staticClashes:[],nearProjectedClashes:[],routes:{},limits:'Analytic surface geometry and ideal jump envelope; excludes human control, collision-body margin, moving phase admission and full play proof'};
 const fixed=geometry.parts.filter(p=>p.collide&&!p.moving&&!p.path.startsWith('StartPen'));
 for(let i=0;i<fixed.length;i++)for(let j=i+1;j<fixed.length;j++){
  const a=fixed[i],b=fixed[j],g=gap(polygon(a),polygon(b));if(g.penetration<=.05)continue;
  const y=Math.min(top(a),top(b))-Math.max(a.cf[1]-a.size[1]/2,b.cf[1]-b.size[1]/2);
  const row={a:a.name,b:b.name,depth:g.penetration,topDifference:Math.abs(top(a)-top(b))};
  if(y>.05)report.staticClashes.push(row);
  else if(row.topDifference<4.5)report.nearProjectedClashes.push(row);
 }
 for(const [name,refs]of Object.entries(geometry.routes)){
  const hops=[],shortcuts=[];
  for(let i=1;i<refs.length;i++){
   const a=geometry.parts[refs[i-1].id-1],b=geometry.parts[refs[i].id-1];
   const shift=refs[i].waitKind==='SideExit'?travel(geometry,a):[0,0,0];
   const g=gap(polygon(a,shift),polygon(b)),rise=top(b)-top(a)-shift[1],maximum=reach(rise);
   hops.push({index:i,from:a.name,to:b.name,gap:g.distance,rise,idealReach:maximum,margin:maximum-g.distance,moving:!!(a.moving||b.moving)});
  }
  for(let i=0;i<refs.length;i++)for(let j=i+2;j<Math.min(refs.length,i+6);j++){
   const a=geometry.parts[refs[i].id-1],b=geometry.parts[refs[j].id-1];
   if(a.moving||b.moving||refs.slice(i+1,j).some(r=>r.waitKind||/CP\d_Pocket/.test(r.name)))continue;
   const g=gap(polygon(a),polygon(b)),rise=top(b)-top(a),maximum=reach(rise);
   if(g.distance<maximum-.7)shortcuts.push({from:a.name,to:b.name,skipped:j-i-1,gap:g.distance,rise,margin:maximum-g.distance});
  }
  report.routes[name]={hops,impossible:hops.filter(h=>h.margin<-.05),tight:hops.filter(h=>h.margin>=-.05&&h.margin<.7),shortcuts};
 }
 return report;
}
