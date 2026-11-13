import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
let seed = 20260501;
function mulberry32(a) { return function () { let t = a += 0x6D2B79F5; t = Math.imul(t ^ t >>> 15, t | 1); t ^= t + Math.imul(t ^ t >>> 7, t | 61); return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
const rand = mulberry32(seed);
const pick = a => a[Math.floor(rand() * a.length)];
const weighted = (entries) => { let n = rand(), total = entries.reduce((s, x) => s + x[1], 0); for (const [v, w] of entries) if ((n -= w / total) <= 0) return v; return entries.at(-1)[0]; };
const int = (a,b) => a + Math.floor(rand() * (b-a+1));
const iso = d => d.toISOString().slice(0,10);
const start = new Date('2026-05-01T12:00:00Z'), end = new Date('2026-10-26T12:00:00Z');
const months = ['2026-05','2026-06','2026-07','2026-08','2026-09','2026-10'];
const firsts=['María','José','Juan','Ana','Luis','Daniela','Carlos','Valeria','Diego','Sofía','Mateo','Camila','Fernando','Lucía','Javier','Paola','Miguel','Andrea','Gabriel','Noelia','Rodrigo','Ximena','Pablo','Alejandra','Bruno','Natalia','Álvaro','Micaela','Kevin','Carla','Esteban','Rocío','Adrián','Belén','Marco','Fátima','René','Dayana','Óscar','Wendy'];
const lasts=['Rojas','Mamani','Flores','García','Vargas','Quispe','López','Torrez','Rivera','Cruz','Gutiérrez','Sánchez','Pérez','Méndez','Céspedes','Heredia','Ledezma','Daza','Paredes','Choque','Salazar','Camacho','Arce','Mercado','Torrico','Montenegro','Prado','Soria','Orellana','Iriarte'];
const depts=['cochabamba','lapaz','santacruz','oruro','potosi','chuquisaca','tarija','beni','pando'], zones=['Centro','Cala Cala','Queru Queru','Sarco','Tupuraya','Muyurina','Recoleta','Otra'], channels=['Instagram','TikTok','WhatsApp referido','Web directa','Feria/UMSS'];
const colors=['negro','blanco','marino','pacay'], sizes=['S','M','L','XL'];
const stages=['Consulta','Cotizado','Pago por verificar','En producción','Listo','Entregado','Perdido'];
const alerts={Consulta:2,Cotizado:3,'Pago por verificar':1,'En producción':4,Listo:3};
const names=[]; for(const f of firsts) for(const l of lasts) names.push(`${f} ${l}`);
const clientes=[], pedidos=[], items=[], eventos=[];
const vipClients=[];
const clientById=new Map(), priorBuyers=[];
const monthCounts=[244,256,268,280,293,330]; // crecimiento suave, con ventanas de feria
let orderNumber=1;
function dateInMonth(m, dayMax) { const [y,mo]=m.split('-').map(Number); return new Date(Date.UTC(y,mo-1,int(1,dayMax),int(9,20),int(0,59))); }
function newClient(date) {
 const used=new Set(clientes.map(c=>c.nombre)); let name; do{name=pick(names)}while(used.has(name));
 const id=`CL-${String(clientes.length+1).padStart(4,'0')}`;
 const dept=weighted([['cochabamba',48],['lapaz',18],['santacruz',15],['oruro',5],['potosi',4],['chuquisaca',4],['tarija',3],['beni',2],['pando',1]]);
 const c={id,nombre:name,telefono:`+591 7${String(int(1000000,9999999))}`,zona:dept==='cochabamba'?pick(zones):'Otra',departamento:dept,canal_origen:pick(channels),fecha_alta:iso(date),nacimiento_aprox:`${int(1980,2004)}-${String(int(1,12)).padStart(2,'0')}`,notas:pick(['Prefiere recojo','Consulta diseños de su departamento','Compra para regalo','Prefiere coordinar por WhatsApp',''])}; clientes.push(c);clientById.set(id,c);return c;
}
function makeItems(orderId, month, count) {
 const out=[]; for(let j=0;j<count;j++){
  let prenda=weighted(month==='2026-06'||month==='2026-07'?[['polera',45],['canguro',43],['gorra',12]]:[['polera',45],['canguro',35],['gorra',20]]);
  const color=weighted([['negro',40],['blanco',25],['marino',20],['pacay',15]]), talla=prenda==='gorra'?'U':weighted([['M',35],['L',30],['S',20],['XL',15]]);
  const departamento=weighted([['cochabamba',48],['lapaz',18],['santacruz',15],['oruro',5],['potosi',4],['chuquisaca',4],['tarija',3],['beni',2],['pando',1]]);
  const ubicacion=prenda==='gorra'?'frente':weighted([['pecho',40],['espalda',25],['ambos',20],['frente',15]]), tintas=rand()<.24?2:1;
  const base=Math.round({canguro:188,polera:95,gorra:74}[prenda]), extra={pecho:15,espalda:30,ambos:40,frente:20}[ubicacion]+(tintas===2?10:0);
  out.push({id:`IT-${String(items.length+out.length+1).padStart(5,'0')}`,pedido_id:orderId,prenda,color,talla,departamento,ubicacion,tintas,cantidad:weighted([[1,85],[2,12],[3,3]]),precio_unit:base+extra});
 } return out;
}
for(let mi=0;mi<months.length;mi++){
 const m=months[mi], lastDay=m==='2026-10'?26:new Date(Date.UTC(2026,Number(m.slice(5))-1+1,0)).getUTCDate();
 const count=monthCounts[mi], uniqueTarget=[166,171,178,184,193,166][mi], returningTarget=Math.round(uniqueTarget*.30), paidTarget=[200,210,220,230,240,205][mi];
 const monthBuyers=[];
 // Favor returning clients, then ensure a large and distinct first-time buyer cohort.
 const returningPool=[...priorBuyers.filter(c=>vipClients.includes(c)),...priorBuyers.filter(c=>!vipClients.includes(c)).sort(()=>rand()-.5)];
 for(let i=0;i<Math.min(returningTarget,returningPool.length);i++) monthBuyers.push(returningPool[i]);
 while(monthBuyers.length<uniqueTarget) monthBuyers.push(newClient(dateInMonth(m,lastDay)));
 if(mi===0) vipClients.push(...monthBuyers.slice(0,Math.ceil(uniqueTarget*.2)));
 // Pareto-shaped order weights: frequent repeat orders come from a small buyer group.
 const weightedBuyers=monthBuyers.flatMap((c,i)=>Array.from({length:vipClients.includes(c)?60:1},()=>c));
 const chosen=[];
 for(let i=0;i<count;i++){
   const dt=dateInMonth(m,lastDay); let c;
   if(i<uniqueTarget) c=monthBuyers[i]; else c=pick(weightedBuyers);
   const id=`PD-${String(orderNumber).padStart(5,'0')}`, codigo=`BR-${String(orderNumber).padStart(4,'0')}`; orderNumber++;
   let stage;
   const ageDays=(end-dt)/86400000;
   if(ageDays<10 && pedidos.filter(p=>!['Entregado','Perdido'].includes(p.etapa)).length<80) stage=weighted([['Consulta',34],['Cotizado',30],['Pago por verificar',15],['En producción',12],['Listo',9]]);
   else if(i<paidTarget) stage=weighted([['En producción',18],['Listo',12],['Entregado',70]]);
   else if(i<paidTarget+Math.round(count*.18)) stage='Perdido';
   else stage='Entregado';   const delivery=rand()<.62?'recojo':'delivery', group=rand()<.02, qty=group?1:weighted([[1,80],[2,17],[3,3]]);
   const its=makeItems(id,m,qty); if(group){its[0].cantidad=int(6,15);} items.push(...its);
   const subtotal=its.reduce((s,x)=>s+x.cantidad*x.precio_unit,0), deliveryCost=delivery==='delivery'?15:0;
   const lost=stage==='Perdido', paid=['En producción','Listo','Entregado'].includes(stage)||stage==='Pago por verificar';
   const date=iso(dt), days=stage==='Entregado'?int(1,8):int(0,Math.max(0,Math.min(9, (end-dt)/86400000|0)));
   const order={id,codigo,cliente_id:c.id,fecha:date,etapa:stage,entrega:delivery,zona:c.zona,costo_delivery:deliveryCost,total:subtotal+deliveryCost,pagado:paid,fecha_pago:paid?iso(new Date(dt.getTime()+Math.min(days,2)*86400000)):null,motivo_perdida:lost?pick(['No respondió','Precio','Cambió de idea','Fecha de entrega','Otro']):null,canal:c.canal_origen,grupo:group};
   pedidos.push(order); chosen.push({order,dt});
   if(c.fecha_alta>date)c.fecha_alta=date;
   const pathStages=stage==='Perdido'?['Consulta','Cotizado','Perdido']:stages.slice(0,Math.max(1,stages.indexOf(stage)+1));
   let at=dt.getTime()-Math.max(1,pathStages.length)*3600000;
   for(let k=0;k<pathStages.length;k++) eventos.push({id:`EV-${String(eventos.length+1).padStart(6,'0')}`,pedido_id:id,de_etapa:k?pathStages[k-1]:null,a_etapa:pathStages[k],fecha_hora:new Date(at+k*3600000).toISOString(),usuario:'Taller'});
 }
 priorBuyers.push(...monthBuyers.filter(c=>!priorBuyers.includes(c)));
}
// Normalize outcomes against the CRM definitions: paid monthly targets and a live 80-order pipeline.
for (let mi=0;mi<months.length;mi++) {
 const m=months[mi], ps=pedidos.filter(p=>p.fecha.startsWith(m)).sort((a,b)=>a.id.localeCompare(b.id));
 const paidTarget=[200,210,220,230,240,205][mi], lostTarget=Math.round(paidTarget*.18/.82);
 ps.forEach((p,i)=>{
   const live=mi===5 && i>=ps.length-80;
   if(live){const day=17+((i- (ps.length-80))%10);p.fecha=`2026-10-${String(day).padStart(2,'0')}`;p.etapa=weighted([['Consulta',38],['Cotizado',32],['Pago por verificar',15],['En producción',10],['Listo',5]]);p.pagado=false;p.fecha_pago=null;p.motivo_perdida=null;}
   else if(i<paidTarget){p.etapa='Entregado';p.pagado=true;p.fecha_pago=p.fecha;p.motivo_perdida=null;}
   else if(i<paidTarget+lostTarget){p.etapa='Perdido';p.pagado=false;p.fecha_pago=null;p.motivo_perdida=pick(['No respondió','Precio','Talla agotada','Demora']);}
   else {p.etapa='Entregado';p.pagado=true;p.fecha_pago=p.fecha;p.motivo_perdida=null;}
 });
}
// Tune order line mix to the requested 80/17/3 proportions while preserving the seeded run.
const singleOrders=pedidos.filter(p=>!p.grupo&&items.filter(i=>i.pedido_id===p.id).length===1).slice(0,25);
for(const p of singleOrders){const m=p.fecha.slice(0,7),it=makeItems(p.id,m,1)[0];items.push(it);}
for(const p of pedidos.filter(p=>items.filter(i=>i.pedido_id===p.id).length===3).slice(0,3)){const ix=items.findIndex(i=>i.pedido_id===p.id);if(ix>=0)items.splice(ix,1);}
// Keep repeat buyers within the requested 4-9 order range and distribute group orders across clients.
for(const m of months){const paid=pedidos.filter(p=>p.fecha.startsWith(m)&&p.pagado),ids=[...new Set(paid.map(p=>p.cliente_id))];let counts=new Map(ids.map(id=>[id,paid.filter(p=>p.cliente_id===id).length]));for(const p of paid.filter(p=>p.grupo)){const target=ids.filter(id=>id!==p.cliente_id&&counts.get(id)<9).sort((a,b)=>counts.get(a)-counts.get(b))[0];if(target){counts.set(p.cliente_id,counts.get(p.cliente_id)-1);p.cliente_id=target;counts.set(target,counts.get(target)+1);}}}
const spend=()=>{const out=new Map();for(const p of pedidos.filter(p=>p.pagado))out.set(p.cliente_id,(out.get(p.cliente_id)||0)+p.total);return out;};
for(const m of months){const spendNow=spend(),paid=pedidos.filter(p=>p.fecha.startsWith(m)&&p.pagado),ids=[...new Set(paid.map(p=>p.cliente_id))];for(const p of paid.slice().reverse()){const amount=spendNow.get(p.cliente_id)||0;if(amount<=5000)continue;const target=ids.filter(id=>id!==p.cliente_id&&(spendNow.get(id)||0)+p.total<=5000).sort((a,b)=>(spendNow.get(a)||0)-(spendNow.get(b)||0))[0];if(target){spendNow.set(p.cliente_id,amount-p.total);spendNow.set(target,(spendNow.get(target)||0)+p.total);p.cliente_id=target;}}}
// Cap repeat-buyer frequency at nine by moving excess paid orders to active buyers in the same month.
for(const m of months){const paid=pedidos.filter(p=>p.fecha.startsWith(m)&&p.pagado),counts=new Map(),monthCounts=new Map(),spendNow=spend();for(const p of pedidos.filter(p=>p.pagado))counts.set(p.cliente_id,(counts.get(p.cliente_id)||0)+1);for(const p of paid)monthCounts.set(p.cliente_id,(monthCounts.get(p.cliente_id)||0)+1);const ids=[...monthCounts.keys()];for(const source of [...ids].sort((a,b)=>(counts.get(b)||0)-(counts.get(a)||0))){while((counts.get(source)||0)>9){const order=paid.slice().reverse().find(p=>p.cliente_id===source&&(monthCounts.get(source)||0)>1);if(!order)break;const target=ids.filter(id=>id!==source&&(counts.get(id)||0)<9).sort((a,b)=>{const fa=counts.get(a)||0,fb=counts.get(b)||0;return (fb-fa)||((spendNow.get(a)||0)-(spendNow.get(b)||0));})[0];if(!target)break;counts.set(source,counts.get(source)-1);counts.set(target,(counts.get(target)||0)+1);monthCounts.set(source,monthCounts.get(source)-1);monthCounts.set(target,(monthCounts.get(target)||0)+1);spendNow.set(source,(spendNow.get(source)||0)-order.total);spendNow.set(target,(spendNow.get(target)||0)+order.total);order.cliente_id=target;}}}
// Refresh event history to reflect the normalized stage and keep pipeline age event-based.
eventos.length=0;
for(const p of pedidos){const pathStages=p.etapa==='Perdido'?['Consulta','Cotizado','Perdido']:p.etapa==='Entregado'?['Consulta','Cotizado','En producción','Listo','Entregado']:stages.slice(0,stages.indexOf(p.etapa)+1);const dt=new Date(`${p.fecha}T12:00:00Z`);let at=dt.getTime()-pathStages.length*3600000;for(let k=0;k<pathStages.length;k++)eventos.push({id:`EV-${String(eventos.length+1).padStart(6,'0')}`,pedido_id:p.id,de_etapa:k?pathStages[k-1]:null,a_etapa:pathStages[k],fecha_hora:new Date(at+k*3600000).toISOString(),usuario:'Taller'});}// Correct first-order/new versus repeat attribution using the actual timeline.
const sortedOrders=pedidos.filter(p=>p.pagado).slice().sort((a,b)=>a.fecha_pago.localeCompare(b.fecha_pago));
const firstPurchase=new Map(); for(const p of pedidos)p.es_recompra=false; for(const p of sortedOrders){p.es_recompra=(firstPurchase.get(p.cliente_id)||p.fecha)<p.fecha; if(!firstPurchase.has(p.cliente_id))firstPurchase.set(p.cliente_id,p.fecha);}
// Full SKU catalog and a deterministic inventory ledger with replenishments.
const skus=[]; for(const prenda of ['canguro','polera','gorra']) for(const color of colors) for(const talla of prenda==='gorra'?['U']:sizes){
 const id=`SKU-${String(skus.length+1).padStart(3,'0')}`; skus.push({id,prenda,color,talla,stock:int(22,58),minimo:prenda==='gorra'?8:10,costo_unit:Math.round({canguro:95,polera:42,gorra:32}[prenda]),proveedor:'Taller textil local'});
}
const movimientos=[]; let moveN=1;
for(const p of pedidos.filter(x=>x.etapa==='En producción'||x.etapa==='Listo'||x.etapa==='Entregado')) for(const it of items.filter(x=>x.pedido_id===p.id)){
 const sku=skus.find(s=>s.prenda===it.prenda&&s.color===it.color&&s.talla===it.talla); if(!sku)continue; sku.stock-=it.cantidad;
 movimientos.push({id:`MV-${String(moveN++).padStart(5,'0')}`,sku_id:sku.id,tipo:'salida',cantidad:it.cantidad,fecha:p.fecha,pedido_id:p.id});
}
for(const sku of skus) { let cursor=sku.stock; for(const date of ['2026-05-15','2026-06-03','2026-06-22','2026-07-12','2026-08-02','2026-08-23','2026-09-13','2026-10-04']) { const q=int(12,36); cursor+=q; movimientos.push({id:`MV-${String(moveN++).padStart(5,'0')}`,sku_id:sku.id,tipo:'entrada',cantidad:q,fecha:date}); } sku.stock=cursor; }
// Select exactly four visible low SKUs for today's inventory snapshot.
for(const s of skus)s.stock=Math.max(0,s.stock);
const low=skus.slice().sort((a,b)=>a.stock-b.stock).slice(0,4); for(const s of skus) if(!low.includes(s))s.stock=Math.max(s.stock,s.minimo+int(4,20)); for(const s of low)s.stock=Math.max(0,s.minimo-int(1,4));
const insumos=[['Tinta carbón','ml',4200,1000,2],['Tinta hueso','ml',3000,800,2],['Tinta ocre','ml',1800,500,2],['Tinta terracota','ml',2200,600,2],['Emulsión','ml',2600,700,4],['Bolsas kraft','unidad',480,120,1],['Etiquetas','unidad',390,100,1]].map(([nombre,unidad,stock,minimo,consumo_por_prenda],i)=>({id:`INS-${String(i+1).padStart(2,'0')}`,nombre,unidad,stock,minimo,consumo_por_prenda}));
/* Reposición de insumos: las entradas cubren lo consumido por las prendas producidas y dejan el stock de hoy en un nivel objetivo (dos insumos bajo el mínimo, para que se vea la alerta). */
const enTaller=new Set(pedidos.filter(p=>['En producción','Listo','Entregado'].includes(p.etapa)).map(p=>p.id));
const producidas=items.filter(it=>enTaller.has(it.pedido_id)).reduce((n,it)=>n+it.cantidad,0);
const objetivoInsumo={'Tinta carbón':2600,'Tinta hueso':1900,'Tinta ocre':420,'Tinta terracota':1300,'Emulsión':1500,'Bolsas kraft':95,'Etiquetas':260};
const fechasInsumo=['2026-05-15','2026-06-05','2026-06-25','2026-07-15','2026-08-05','2026-08-25','2026-09-15','2026-10-05'];
for(const insumo of insumos){const total=Math.max(0,objetivoInsumo[insumo.nombre]-insumo.stock+producidas*insumo.consumo_por_prenda);const pesos=fechasInsumo.map(()=>0.7+rand()*0.6),suma=pesos.reduce((x,y)=>x+y,0);let resto=total;fechasInsumo.forEach((fecha,i)=>{const cantidad=i===fechasInsumo.length-1?resto:Math.round(total*pesos[i]/suma);resto-=cantidad;movimientos.push({id:`MV-${String(moveN++).padStart(5,'0')}`,insumo_id:insumo.id,tipo:'entrada',cantidad,fecha});});}
const sim={clientes,pedidos,items,eventos,skus,insumos,movimientos,meta:{generado:'2026-10-26T12:00:00.000Z',hoy:'2026-10-26',semilla:20260501}};
await mkdir(path.join(root,'data'),{recursive:true});
await writeFile(path.join(root,'data','sim.js'),`window.BRAVA_SIM = ${JSON.stringify(sim)};\n`,'utf8');
console.log('Mes       Compradores pagados  Pedidos pagados  Consultas  Ingresos Bs  Mediana  Promedio  Recompra');
for(const m of months){const ps=pedidos.filter(p=>p.fecha.startsWith(m)),paid=ps.filter(p=>p.pagado===true),buyers=new Set(paid.filter(p=>p.fecha_pago?.startsWith(m)).map(p=>p.cliente_id)),vals=paid.map(p=>p.total).sort((a,b)=>a-b),rev=paid.reduce((s,p)=>s+p.total,0),prior=new Set(pedidos.filter(p=>p.pagado&&p.fecha<m+'-01').map(p=>p.cliente_id)),repeat=buyers.size?[...buyers].filter(id=>prior.has(id)).length/buyers.size*100:0;console.log(m,buyers.size,paid.length,ps.length,Math.round(rev),vals.length?vals[Math.floor(vals.length/2)]:0,paid.length?Math.round(rev/paid.length):0,repeat.toFixed(1)+'%');}
const byClient=new Map();for(const p of pedidos.filter(p=>p.pagado)){byClient.set(p.cliente_id,(byClient.get(p.cliente_id)||0)+p.total);}const sorted=[...byClient.values()].sort((a,b)=>b-a),sum=sorted.reduce((a,b)=>a+b,0),top=sorted.slice(0,Math.ceil(sorted.length*.2)).reduce((a,b)=>a+b,0);console.log('Top 20% ingreso:',(100*top/sum).toFixed(1)+'%','| Maximo cliente Bs:',Math.max(...sorted),'| Abiertos:',pedidos.filter(p=>!['Entregado','Perdido'].includes(p.etapa)).length);
