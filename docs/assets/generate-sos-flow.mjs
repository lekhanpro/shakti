import { writeFileSync } from 'node:fs';

const render = function() {
  const W=480,H=148, palette=[[16,18,24],[99,91,255],[192,236,219],[242,240,234],[92,98,116],[183,168,238],[37,41,53],[245,158,11]];
  const font={A:["01110","10001","10001","11111","10001","10001","10001"],B:["11110","10001","10001","11110","10001","10001","11110"],C:["01111","10000","10000","10000","10000","10000","01111"],D:["11110","10001","10001","10001","10001","10001","11110"],E:["11111","10000","10000","11110","10000","10000","11111"],F:["11111","10000","10000","11110","10000","10000","10000"],G:["01111","10000","10000","10111","10001","10001","01111"],H:["10001","10001","10001","11111","10001","10001","10001"],I:["111","010","010","010","010","010","111"],J:["00111","00010","00010","00010","10010","10010","01100"],K:["10001","10010","10100","11000","10100","10010","10001"],L:["10000","10000","10000","10000","10000","10000","11111"],M:["10001","11011","10101","10101","10001","10001","10001"],N:["10001","11001","10101","10011","10001","10001","10001"],O:["01110","10001","10001","10001","10001","10001","01110"],P:["11110","10001","10001","11110","10000","10000","10000"],Q:["01110","10001","10001","10001","10101","10010","01101"],R:["11110","10001","10001","11110","10100","10010","10001"],S:["01111","10000","10000","01110","00001","00001","11110"],T:["11111","00100","00100","00100","00100","00100","00100"],U:["10001","10001","10001","10001","10001","10001","01110"],V:["10001","10001","10001","10001","10001","01010","00100"],W:["10001","10001","10001","10101","10101","10101","01010"],X:["10001","10001","01010","00100","01010","10001","10001"],Y:["10001","10001","01010","00100","00100","00100","00100"],Z:["11111","00001","00010","00100","01000","10000","11111"]};
  const out=[];const byte=(...b)=>out.push(...b);const word=n=>byte(n&255,(n>>8)&255);const ascii=s=>byte(...[...s].map(c=>c.charCodeAt(0)));
  ascii("GIF89a");word(W);word(H);byte(0xf2,0,0);palette.forEach(rgb=>byte(...rgb));
  byte(0x21,0xff,11);ascii("NETSCAPE2.0");byte(3,1,0,0,0);
  for(let frame=0;frame<8;frame++){
    const p=new Uint8Array(W*H);
    const rect=(x,y,w,h,c)=>{for(let j=Math.max(0,y);j<Math.min(H,y+h);j++)for(let i=Math.max(0,x);i<Math.min(W,x+w);i++)p[j*W+i]=c;};
    const text=(s,x,y,c=3,scale=1)=>{for(const ch of s){if(ch===" "){x+=4*scale;continue;}const g=font[ch];if(!g){x+=6*scale;continue;}g.forEach((row,j)=>[...row].forEach((v,i)=>{if(v==="1")rect(x+i*scale,y+j*scale,scale,scale,c);}));x+=(g[0].length+1)*scale;}};
    const line=(x1,y1,x2,y2,c=4)=>{const n=Math.max(Math.abs(x2-x1),Math.abs(y2-y1));for(let i=0;i<=n;i++)rect(Math.round(x1+(x2-x1)*i/n),Math.round(y1+(y2-y1)*i/n),2,2,c);};
    const node=(x,y,w,h,label,color)=>{rect(x,y,w,h,color);rect(x+1,y+1,w-2,h-2,6);text(label,x+10,y+10,3);};
    text("ONE SIGNAL  INDEPENDENT CHANNELS",16,8,5);
    line(112,62,168,62);line(272,62,310,62);line(310,62,310,34);line(310,34,344,34);line(310,62,310,102);line(310,102,344,102);
    node(16,48,96,28,"TRIGGER",1);node(168,48,104,28,"LOCAL SAVE",2);node(344,20,104,28,"SMS",2);node(344,88,104,28,"CLOUD",5);
    text("CELL SERVICE",350,54,4);text("INTERNET",350,122,4);
    text("ILLUSTRATION  NO ALERTS SENT",16,132,4);
    if(frame<3)rect(116+frame*16,59,6,6,2);
    else {const q=(frame-3)/4;rect(275+Math.round(q*57),31,6,6,2);rect(275+Math.round(q*57),99,6,6,5);}
    byte(0x21,0xf9,4,4,45,0,0,0);byte(0x2c);word(0);word(0);word(W);word(H);byte(0,3);
    const packed=[];let bits=0,acc=0;const code=n=>{acc|=n<<bits;bits+=4;while(bits>=8){packed.push(acc&255);acc>>=8;bits-=8;}};
    for(let i=0;i<p.length;){code(8);for(let j=0;j<4&&i<p.length;j++,i++)code(p[i]);}
    code(9);if(bits)packed.push(acc&255);
    for(let i=0;i<packed.length;i+=255){const block=packed.slice(i,i+255);byte(block.length,...block);}byte(0);
  }
  byte(0x3b);return new Uint8Array(out);
};
writeFileSync(new URL('./sos-flow.gif', import.meta.url), render());
