import asyncio,json,random,time
from playwright.async_api import async_playwright
BASE="http://127.0.0.1:8765/index.html"
async def bot_until(pg, stop_sel, max_steps=6000, label=""):
    """Plays whatever is on screen until stop_sel appears."""
    for step in range(max_steps):
        if await pg.locator(stop_sel).count(): return step
        for sel in ["#nx","#start","#controls .choice",".slot button",".tile:not([disabled])"]:
            loc=pg.locator(sel)
            n=await loc.count()
            if n:
                try:
                    await loc.nth(random.randrange(n)).click(timeout=600)
                except Exception: pass
                break
        await pg.wait_for_timeout(120)
    print("STUCK SCREEN:", (await pg.inner_text("#view"))[:300]); raise Exception("bot stuck "+label)
async def main():
  async with async_playwright() as p:
    b=await p.chromium.launch(); errs=[]; cons=[]
    ctx=await b.new_context(viewport={"width":390,"height":844},timezone_id="Europe/Paris")
    await ctx.route("**/fonts.*/**",lambda r:r.abort())
    rpc_calls=[]
    async def rpc(route):
        rpc_calls.append(route.request.url.split('/')[-1]); await route.fulfill(status=200,body='null',headers={"content-type":"application/json"})
    await ctx.route("**/rest/v1/rpc/**",rpc)
    pg=await ctx.new_page(); pg.on("pageerror",lambda e:errs.append(str(e))); pg.on("console",lambda m: cons.append(m.text) if m.type=="error" else None)
    await pg.goto(BASE); await pg.evaluate("localStorage.clear()"); await pg.reload(); await pg.wait_for_timeout(300)
    t0=time.time()
    # onboarding -> bilan
    await pg.click("#obnext"); await pg.fill("#ob-name","Test"); await pg.click("#obnext"); await pg.click("#obbil")
    steps=await bot_until(pg,"#h",label="bilan")
    D=await pg.evaluate("JSON.parse(localStorage.getItem('vivace-v1'))")
    print(f"BILAN ok in {steps} steps, {time.time()-t0:.0f}s: history={len(D['history'])} bilans={len(D['bilans'])} practiced={D.get('practiced')} levels={D['levels']}")
    await pg.click("#h")
    # daily session
    t0=time.time(); await pg.click("#go"); steps=await bot_until(pg,"#h",label="session")
    D=await pg.evaluate("JSON.parse(localStorage.getItem('vivace-v1'))")
    print(f"SESSION ok in {steps} steps, {time.time()-t0:.0f}s: history={len(D['history'])} today={D['today']} program={D.get('program')}")
    await pg.click("#h"); await pg.wait_for_timeout(200)
    txt=await pg.inner_text("#view"); print("HOME after session contains 'Séance faite':", "Séance faite" in txt)
    # free play + quit mid-game
    await pg.click(".tile2[data-g=corsi]"); await pg.click("#start"); await pg.wait_for_timeout(400); await pg.click("#quit"); await pg.wait_for_timeout(300)
    print("quit mid-game -> home:", await pg.locator("#go").count()==1)
    # all tabs
    for t in ["progress","famille","science","settings","home"]:
        await pg.click(f"nav.tabs button[data-tab={t}]"); await pg.wait_for_timeout(250)
    # settings toggles
    await pg.click("nav.tabs button[data-tab=settings]")
    for k,v in [("size","tresgrand"),("theme","dark"),("voice","on"),("pace","standard"),("theme","auto"),("size","grand")]:
        await pg.click(f'.seg button[data-k="{k}"][data-v="{v}"]'); await pg.wait_for_timeout(120)
    print("settings:",await pg.evaluate("JSON.parse(localStorage.getItem('vivace-v1')).settings"))
    # reset
    await pg.click("#reset"); await pg.click("#yes"); await pg.wait_for_timeout(200)
    D=await pg.evaluate("JSON.parse(localStorage.getItem('vivace-v1'))"); print("after reset history:",len(D['history']),"onboarded:",D['onboarded'])
    print("RPC calls:",sorted(set(rpc_calls)))
    print("PAGE ERRORS:",errs); print("CONSOLE ERRORS:",[c for c in cons if 'fonts' not in c][:5])
    await b.close()
asyncio.run(main())
