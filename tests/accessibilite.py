import asyncio,json
from playwright.async_api import async_playwright
AXE=open(__import__("os").path.join(__import__("os").path.dirname(__file__),"node_modules/axe-core/axe.min.js")).read()
SEED="""()=>{const D={settings:{size:'grand',pace:'calme',theme:'THEME',voice:'off'},levels:{ufov:310,corsi:5,list:8,switch:3,swVis:1600},history:[],days:{},family:null,pending:[],bilans:[{d:'2026-10-20',idx:{ufov:60,corsi:40,switch:30,list:30}}],onboarded:true,name:'Pascal',practiced:{ufov:true,corsi:true,switch:true,list:true}};
 const t=new Date();for(let i=0;i<10;i++){const d=new Date(t-i*864e5).toLocaleDateString('sv-SE');['ufov','corsi','switch','list'].forEach((g,j)=>D.history.push({d,g,s:[400-i*5,5,40,7][j],v:2}));D.days[d]=true}
 D.today={d:t.toLocaleDateString('sv-SE'),order:['ufov','list','corsi','switch'],done:['ufov']};localStorage.setItem('vivace-v1',JSON.stringify(D))}"""
async def scan(pg,name,out):
    await pg.add_script_tag(content=AXE)
    r=await pg.evaluate("""async()=>{const r=await axe.run(document,{runOnly:['wcag2a','wcag2aa','wcag21aa','best-practice']});return r.violations.map(v=>({id:v.id,impact:v.impact,n:v.nodes.length,help:v.help,ex:v.nodes.slice(0,3).map(n=>n.target.join(' ')+' :: '+(n.failureSummary||'').slice(0,160))}))}""")
    small=await pg.evaluate("""()=>[...document.querySelectorAll('button,a,input,[role=button]')].filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0&&(r.width<44||r.height<44)&&getComputedStyle(e).visibility!=='hidden'}).map(e=>(e.id||e.className||e.tagName)+' '+Math.round(e.getBoundingClientRect().width)+'x'+Math.round(e.getBoundingClientRect().height)+' '+(e.innerText||e.getAttribute('aria-label')||'').trim().slice(0,25))""")
    out[name]={"axe":r,"small_targets":small}
async def main():
  async with async_playwright() as p:
    b=await p.chromium.launch(); out={}
    for theme in ["light","dark"]:
      ctx=await b.new_context(viewport={"width":390,"height":844},timezone_id="Europe/Paris")
      await ctx.route("**/fonts.*/**",lambda r:r.abort())
      await ctx.route("**/rest/v1/rpc/**",lambda r:r.fulfill(status=200,body='[]',headers={"content-type":"application/json"}))
      pg=await ctx.new_page(); await pg.goto("http://127.0.0.1:8765/index.html"); await pg.evaluate(SEED.replace("THEME",theme)); await pg.reload(); await pg.wait_for_timeout(500)
      await scan(pg,theme+":home",out)
      for t in ["progress","famille","science","settings"]:
        await pg.click(f"nav.tabs button[data-tab={t}]"); await pg.wait_for_timeout(1000 if t=="progress" else 300); await scan(pg,f"{theme}:{t}",out)
      await pg.click("nav.tabs button[data-tab=home]"); await pg.click(".tile2[data-g=switch]"); await pg.wait_for_timeout(300); await scan(pg,f"{theme}:intro",out)
      await pg.click("#start"); await pg.wait_for_timeout(500); await scan(pg,f"{theme}:game-switch",out)
      await pg.click("#quit"); await pg.click(".tile2[data-g=ufov]"); await pg.click("#start"); await pg.wait_for_timeout(2500); await scan(pg,f"{theme}:game-ufov",out)
      await ctx.close()
    # summarize
    agg={}
    for scr,v in out.items():
        for x in v["axe"]:
            k=(x["id"],x["impact"],x["help"]); agg.setdefault(k,[]).append((scr,x["n"],x["ex"]))
    for (i,imp,h),lst in sorted(agg.items(),key=lambda z:z[0][1] or ""):
        print(f"\n[{imp}] {i}: {h}")
        for scr,n,ex in lst[:4]: print("   ",scr,n,"|",ex[0][:200] if ex else "")
    print("\nSMALL TARGETS (<44px):")
    seen=set()
    for scr,v in out.items():
        for s in v["small_targets"]:
            key=s.split(' ')[0]
            if key in seen: continue
            seen.add(key); print("  ",scr,"::",s)
    await b.close()
asyncio.run(main())
