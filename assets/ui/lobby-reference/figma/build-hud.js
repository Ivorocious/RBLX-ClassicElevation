const page=await figma.getNodeByIdAsync('0:1');
await figma.setCurrentPageAsync(page);
await Promise.all([{family:'Fredoka One',style:'Regular'},{family:'Fredoka',style:'Bold'},{family:'Fredoka',style:'SemiBold'}].map(f=>figma.loadFontAsync(f)));
const createdNodeIds=[],mutatedNodeIds=[],styleIds=[];
const own=n=>(createdNodeIds.push(n.id),n);
const rgb=h=>({r:parseInt(h.slice(0,2),16)/255,g:parseInt(h.slice(2,4),16)/255,b:parseInt(h.slice(4,6),16)/255});
const colors={Navy:'062557',Cream:'FFFAEC',White:'FFFFFF',Muted:'748AA8',Red:'FF4D43',Blue:'657AFF',Mint:'5DFFC9',Lavender:'E3D9FF',Green:'009E6D'};
const collection=figma.variables.createVariableCollection('Lobby HUD / Reference colors');
const tokens={};
for(const [name,color] of Object.entries(colors)){const v=figma.variables.createVariable(name,collection,'COLOR');v.scopes=['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR'];v.setValueForMode(collection.defaultModeId,{...rgb(color),a:1});tokens[name]=v;}
const paint=(name,opacity=1)=>figma.variables.setBoundVariableForPaint({type:'SOLID',color:rgb(colors[name]||name),opacity},'color',tokens[name]);
const solid=h=>({type:'SOLID',color:rgb(h)});
const gradient=(a,b)=>({type:'GRADIENT_LINEAR',gradientTransform:[[0,1,0],[-1,0,1]],gradientStops:[{position:0,color:{...rgb(a),a:1}},{position:1,color:{...rgb(b),a:1}}]});
const shadow=figma.createEffectStyle();shadow.name='Lobby HUD / Raised toy edge';shadow.effects=[{type:'DROP_SHADOW',visible:true,blendMode:'NORMAL',color:{...rgb(colors.Navy),a:.38},offset:{x:0,y:6},radius:2,spread:0}];styleIds.push(shadow.id);
const textStyles={};
for(const [size,family,style] of [[20,'Fredoka','Bold'],[20,'Fredoka','SemiBold'],[20,'Fredoka One','Regular'],[22,'Fredoka One','Regular'],[24,'Fredoka One','Regular'],[28,'Fredoka One','Regular'],[30,'Fredoka One','Regular'],[32,'Fredoka One','Regular'],[18,'Fredoka','SemiBold']]){const s=figma.createTextStyle();s.name='Lobby HUD / '+family+' '+size+' '+style;s.fontName={family,style};s.fontSize=size;s.lineHeight={unit:'PERCENT',value:110};textStyles[`${family}/${style}/${size}`]=s;styleIds.push(s.id);}
function text(label,size=24,color='Navy',width=0,family='Fredoka One',style='Regular'){
  const n=own(figma.createText());n.fontName={family,style};n.characters=label;n.fontSize=size;n.lineHeight={unit:'PERCENT',value:110};n.fills=[paint(color)];n.textStyleId=textStyles[`${family}/${style}/${size}`].id;n.name=label;
  if(width){n.textAutoResize='HEIGHT';n.resize(width,size*1.1);}else n.textAutoResize='WIDTH_AND_HEIGHT';
  return n;
}
function auto(name,dir,w,h){const n=own(figma.createAutoLayout(dir));n.name=name;n.resize(w,h);n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';n.fills=[];n.clipsContent=false;return n;}
function box(parent,name,w,h,x,y,fill,stroke=0,r=0){const n=own(figma.createRectangle());n.name=name;parent.appendChild(n);if(parent.layoutMode!=='NONE')n.layoutPositioning='ABSOLUTE';n.resize(w,h);n.x=x;n.y=y;n.cornerRadius=r;n.fills=fill?[fill]:[];if(stroke){n.strokes=[paint('Navy')];n.strokeWeight=stroke;n.strokeAlign='INSIDE';}return n;}
function inset(n,w,h,r,opacity=.55){const b=box(n,'Glossy inset rim',w-15,h-14,7,6,null,0,r-6);b.strokes=[paint('White',opacity)];b.strokeWeight=2.5;b.strokeAlign='INSIDE';return b;}
function surface(n,a,b,r=18,stroke=3){n.fills=[gradient(a,b)];n.cornerRadius=r;n.strokes=[paint('Navy')];n.strokeWeight=stroke;n.strokeAlign='INSIDE';n.effectStyleId=shadow.id;inset(n,n.width,n.height,r);}
function component(n,description){const c=figma.createComponentFromNode(n);createdNodeIds.push(c.id);c.description=description;return c;}
function property(c,n,name){const key=c.addComponentProperty(name,'TEXT',n.characters);n.componentPropertyReferences={characters:key};}
function svg(parent,name,markup,w,h){const n=own(figma.createNodeFromSvg(markup));n.name=name;n.resize(w,h);parent.appendChild(n);for(const child of n.findAll())createdNodeIds.push(child.id);return n;}
const library=auto('Editable components and original artwork','VERTICAL',1500,825);page.appendChild(library);library.x=200;library.y=1280;library.itemSpacing=32;library.paddingTop=25;library.paddingLeft=25;library.paddingRight=25;library.paddingBottom=25;library.fills=[solid('F0F6FC')];library.cornerRadius=20;
library.appendChild(text('Lobby HUD components · sample values are design data',24));
const iconRow=auto('Original icon components','HORIZONTAL',1400,96);library.appendChild(iconRow);iconRow.itemSpacing=35;
const sources={coin:'2:5',racer:'2:2',trophy:'2:6','shop-bag':'2:7',key:'2:4','settings-gear':'2:3'};
const icons={};
for(const [name,id] of Object.entries(sources)){const source=await figma.getNodeByIdAsync(id);mutatedNodeIds.push(source.id);source.name='Icon / '+name;source.resize(96,96);const c=component(source,'Original Blender artwork; transparent raster fill, editable separate .blend source in the repository.');iconRow.appendChild(c);icons[name]=c;}
function icon(parent,name,size){const n=own(icons[name].createInstance());parent.appendChild(n);n.resize(size,size);return n;}
const controls=auto('HUD component family','HORIZONTAL',1400,250);library.appendChild(controls);controls.itemSpacing=22;controls.counterAxisAlignItems='MIN';
function nav(name,label,a,b,art,w,h){const n=auto(name,'VERTICAL',w,h);n.counterAxisAlignItems='CENTER';n.paddingTop=4;n.paddingBottom=6;n.itemSpacing=-16;surface(n,a,b,30,4);icon(n,art,h-39);const t=text(label,label==='Shop'?24:22,label==='Shop'||label==='My racer'?'White':'Navy',w-12);t.textAlignHorizontal='CENTER';n.appendChild(t);const c=component(n,'Reference navigation tile; editable label and imported original icon.');property(c,t,'Label');controls.appendChild(c);return c;}
const shop=nav('Navigation / Shop','Shop','FF6958','FF4037','shop-bag',121,123);
const racer=nav('Navigation / My racer','My racer','8593FF','5268FF','racer',121,121);
const records=nav('Navigation / Records','Records','FFFDF1','FFF5DD','trophy',119,113);
const settings=nav('Navigation / Settings','Settings','92FFE0','41F8B7','settings-gear',118,108);
function currency(name,value,label,art,w){const n=auto('Currency / '+name,'HORIZONTAL',w,70);n.paddingLeft=79;n.paddingRight=8;n.counterAxisAlignItems='CENTER';surface(n,'FFFDF5','FFF7E6',22,4);const content=auto('Value and label','VERTICAL',w-87,53);n.appendChild(content);const val=text(value,28);content.appendChild(val);content.appendChild(text(label,20,'Muted',0,'Fredoka','SemiBold'));const img=icon(n,art,96);img.layoutPositioning='ABSOLUTE';img.x=-14;img.y=-13;const c=component(n,'Reference sample currency display; sample values do not claim gameplay implementation.');property(c,val,'Value');return c;}
const coins=currency('Coins','12,450','Coins','coin',207);
const keys=currency('Keys','8','Keys','key',153);
const row2=auto('Currency and panel components','HORIZONTAL',1400,210);library.appendChild(row2);row2.itemSpacing=24;row2.appendChild(coins);row2.appendChild(keys);
function action(name,label,a,b,width,art){const n=auto(name,'HORIZONTAL',width,59);n.paddingLeft=10;n.paddingRight=10;n.itemSpacing=6;n.counterAxisAlignItems='CENTER';surface(n,a,b,17,3);if(art==='check'){
    svg(n,'Joined checkmark','<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36"><circle cx="18" cy="18" r="17" fill="#009E6D"/><path d="M10 18l6 6 12-13" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>',36,36);
  }else icon(n,art,36);
  n.appendChild(text(label,22));return n;}
const race=auto('Panel / Next race','VERTICAL',426,191);race.paddingLeft=31;race.paddingRight=12;race.paddingTop=15;race.paddingBottom=18;race.itemSpacing=7;surface(race,'FFFDFA','FFF8E8',24,4);
const raceTop=auto('Course, divider and countdown','HORIZONTAL',383,92);raceTop.counterAxisAlignItems='CENTER';raceTop.itemSpacing=12;race.appendChild(raceTop);
const titleGroup=auto('Course details','VERTICAL',217,92);titleGroup.itemSpacing=2;raceTop.appendChild(titleGroup);
titleGroup.appendChild(text('NEXT RACE',20,'Muted',0,'Fredoka','Bold'));
const course=text('Classic Ascent',30);titleGroup.appendChild(course);
const mode=text('Point-to-point',22,'Muted');titleGroup.appendChild(mode);
const divider=own(figma.createRectangle());divider.name='Vertical divider';divider.resize(2,83);divider.fills=[solid('B9BDC6')];raceTop.appendChild(divider);
const timer=auto('Inline clock and timer','HORIZONTAL',140,57);timer.paddingLeft=10;timer.paddingRight=6;timer.itemSpacing=5;timer.counterAxisAlignItems='CENTER';timer.fills=[gradient('FF6A59','FF3B34')];timer.cornerRadius=16;timer.strokes=[solid('AA251E')];timer.strokeWeight=3;timer.strokeAlign='INSIDE';timer.effectStyleId=shadow.id;inset(timer,140,57,16,.65);raceTop.appendChild(timer);
svg(timer,'Clock','<svg xmlns="http://www.w3.org/2000/svg" width="29" height="29" viewBox="0 0 29 29"><circle cx="14.5" cy="14.5" r="12.5" fill="none" stroke="#fff" stroke-width="3"/><path d="M14.5 6v9h7" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',29,29);
const countdown=text('00:24',30,'White');timer.appendChild(countdown);
const actions=auto('Race actions','HORIZONTAL',383,59);actions.itemSpacing=13;race.appendChild(actions);
actions.appendChild(action('Joined state',"You're in",'98FFE0','54FFD0',176,'check'));
const options=action('Race options','Race options','E1DBFF','B5A7FF',193,'settings-gear');const opText=options.children.find(n=>n.type==='TEXT');opText.fontSize=20;opText.textStyleId=textStyles['Fredoka One/Regular/20'].id;actions.appendChild(options);
const raceComponent=component(race,'Reference visual model with sample course, countdown, and joined state. Runtime values come from server state.');property(raceComponent,course,'Course');property(raceComponent,mode,'Mode');property(raceComponent,countdown,'Countdown');row2.appendChild(raceComponent);
const quests=auto('Panel / Quests','VERTICAL',426,121);quests.paddingLeft=32;quests.paddingRight=24;quests.paddingTop=13;quests.paddingBottom=12;quests.itemSpacing=5;quests.effectStyleId=shadow.id;
const qShape=own(figma.createVector());qShape.name='Editable ticket silhouette with side notches';quests.appendChild(qShape);qShape.layoutPositioning='ABSOLUTE';qShape.vectorPaths=[{windingRule:'NONZERO',data:'M 20 0 L 406 0 Q 426 0 426 20 L 426 44 C 406 49 406 68 426 73 L 426 101 Q 426 121 406 121 L 20 121 Q 0 121 0 101 L 0 73 C 20 68 20 49 0 44 L 0 20 Q 0 0 20 0 Z'}];qShape.fills=[gradient('F0E9FF','D5C8FF')];qShape.strokes=[paint('Navy')];qShape.strokeWeight=4;qShape.strokeAlign='INSIDE';qShape.x=0;qShape.y=0;
const qRim=own(figma.createVector());qRim.name='Ticket glossy inset outline';quests.appendChild(qRim);qRim.layoutPositioning='ABSOLUTE';qRim.vectorPaths=qShape.vectorPaths;qRim.resize(412,107);qRim.x=7;qRim.y=7;qRim.fills=[];qRim.strokes=[paint('White',.6)];qRim.strokeWeight=2;
quests.appendChild(text('QUESTS',20,'Muted',0,'Fredoka','Bold'));
const questBody=auto('Quest detail and view action','HORIZONTAL',370,67);questBody.itemSpacing=11;questBody.counterAxisAlignItems='MAX';quests.appendChild(questBody);
const questLeft=auto('Quest text and progress','VERTICAL',236,67);questLeft.itemSpacing=5;questBody.appendChild(questLeft);
const questLine=auto('Quest label and count','HORIZONTAL',236,28);questLine.itemSpacing=14;questLeft.appendChild(questLine);
const questLabel=text('Finish 3 races',22,'Navy',164);questLine.appendChild(questLabel);const questCount=text('1 / 3',22,'Navy',58);questLine.appendChild(questCount);
const progress=auto('Three node progress','HORIZONTAL',186,34);progress.itemSpacing=45;progress.counterAxisAlignItems='CENTER';questLeft.appendChild(progress);
box(progress,'Progress connector',155,5,16,14,solid('8DA2C1'));
for(let i=0;i<3;i++){const dot=own(figma.createEllipse());dot.name=i===0?'Completed step':'Unfinished step '+(i+1);dot.resize(32,32);dot.fills=[gradient(i===0?'A6FFE3':'F4F8FF',i===0?'45FFCB':'C5D6EA')];dot.strokes=[paint(i===0?'Navy':'Muted')];dot.strokeWeight=3;progress.appendChild(dot);}
const view=auto('View all action','HORIZONTAL',123,49);view.paddingLeft=13;view.paddingRight=8;view.itemSpacing=8;view.counterAxisAlignItems='CENTER';surface(view,'FFFDF6','FFF7E6',15,3);questBody.appendChild(view);view.appendChild(text('View all',22));svg(view,'Chevron','<svg xmlns="http://www.w3.org/2000/svg" width="12" height="18" viewBox="0 0 12 18"><path d="m3 3 6 6-6 6" fill="none" stroke="#062557" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',12,18);
const questComponent=component(quests,'Reference visual model only: 1/3 progress is sample design data, not a gameplay claim.');property(questComponent,questLabel,'Quest');property(questComponent,questCount,'Progress');row2.appendChild(questComponent);
const screen=own(figma.createFrame());screen.name='Lobby HUD / Owner reference · design sample';screen.resize(1672,941);screen.x=200;screen.y=160;screen.fills=[gradient('42C5F6','BCE6FA')];screen.clipsContent=false;page.appendChild(screen);
function place(c,x,y){const n=own(c.createInstance());screen.appendChild(n);n.x=x;n.y=y;return n;}
place(shop,28,136);place(racer,28,271);place(records,28,403);place(settings,28,527);place(coins,1275,47);place(keys,1492,47);place(raceComponent,1222,136);place(questComponent,1222,346);
const note=text('DESIGN SAMPLE · Values shown follow the owner reference. Keys and quests are visual examples.',18,'Navy',1200,'Fredoka','SemiBold');screen.appendChild(note);note.x=28;note.y=884;
const allText=screen.findAllWithCriteria({types:['TEXT']});
return {createdNodeIds,mutatedNodeIds,screenId:screen.id,libraryId:library.id,iconComponentIds:Object.fromEntries(Object.entries(icons).map(([k,n])=>[k,n.id])),componentIds:{shop:shop.id,racer:racer.id,records:records.id,settings:settings.id,coins:coins.id,keys:keys.id,race:raceComponent.id,quests:questComponent.id},variableCollectionId:collection.id,variableIds:Object.values(tokens).map(v=>v.id),styleIds,textCount:allText.length,fontFamilies:[...new Set(allText.map(t=>t.fontName.family))],instanceCount:screen.findAllWithCriteria({types:['INSTANCE']}).length,bounds:{x:screen.x,y:screen.y,width:screen.width,height:screen.height}};
