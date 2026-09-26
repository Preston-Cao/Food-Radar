import from react { useEffect }
import from "@jac/runtime" { Link }
import from "qrcode.react" { QRCodeSVG }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowLeft01Icon, CheckmarkBadge01Icon, Ticket01Icon, FlashIcon, QrCode01Icon, Wallet01Icon
}
import from .ui.button { Button }
import from .ui.skeleton { Skeleton }
import from .BottomNav { BrandMark }
import from .RewardCard { time_left }
sv import from ..services.biteloop { get_dashboard, DashboardView, RewardView }

glob STEPS: list[dict] = [
    {"n": "1", "title": "Open your camera", "text": "No app download needed to start."},
    {"n": "2", "title": "Scan this code", "text": "You check in instantly and see today's rewards."},
    {"n": "3", "title": "Show your wallet code", "text": "Staff confirm it and your bite is on us."}
];

def:pub DisplayReward(rw: RewardView) -> JsxElement {
    pct = int(rw.remaining * 100 / rw.quantity) if rw.quantity > 0 else 0;
    return <div className="flex items-center gap-3 rounded-2xl bg-white/8 pt-3 pb-3 pl-3 pr-3 ring-1 ring-white/10">
        <img src={rw.image} alt="" className="size-14 shrink-0 rounded-xl object-cover" />
        <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
                {rw.kind == "flash" and <HugeiconsIcon icon={FlashIcon} strokeWidth={2.5} className="size-4 shrink-0 text-yellow-400" />}
                <p className="truncate text-base font-bold">{rw.title}</p>
            </div>
            <p className="text-xs text-white/60 tabular-nums">{str(rw.remaining) + " of " + str(rw.quantity) + " left · " + time_left(rw.minutes_left)}</p>
            <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-white/15"><div className="h-full rounded-full bg-primary" style={{"width": str(pct) + "%"}} /></div>
        </div>
    </div>;
}

def:pub DisplayBody(dash: DashboardView) -> JsxElement {
    url = window.location.origin + "/scan/" + dash.restaurant_id + "/" + dash.checkin_token;
    return <div className="grid min-h-svh bg-background print:min-h-0 lg:grid-cols-[1fr_24rem]">
        <main className="flex flex-col items-center justify-center gap-8 pt-20 pb-12 pl-6 pr-6 text-center print:pt-10">
            <BrandMark />
            <div className="flex flex-col items-center gap-3">
                <div className="flex items-center gap-2">
                    <h1 className="text-balance text-4xl font-bold tracking-tight md:text-5xl">{dash.restaurant_name}</h1>
                    {dash.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-8 text-sky-500" />}
                </div>
                <p className="text-balance text-2xl font-semibold text-primary md:text-3xl">{"Scan to claim a free bite"}</p>
            </div>
            <div className="relative">
                <div className="absolute -inset-6 rounded-[3rem] bg-primary/15 blur-2xl print:hidden" />
                <div className="relative rounded-[2rem] bg-white pt-6 pb-6 pl-6 pr-6 shadow-2xl ring-8 ring-primary print:shadow-none">
                    <QRCodeSVG value={url} size={320} level="M" fgColor="#1f1a17" className="size-64 sm:size-80 lg:size-[22rem]" />
                </div>
            </div>
            <div className="flex flex-col items-center gap-1">
                <span className="text-sm font-bold uppercase tracking-widest text-muted-foreground">{"Or enter store code"}</span>
                <span className="rounded-2xl bg-charcoal pt-2 pb-2 pl-6 pr-6 font-mono text-4xl font-extrabold tracking-[0.35em] text-white md:text-5xl">{dash.store_code}</span>
            </div>
            <div className="grid w-full max-w-3xl gap-3 sm:grid-cols-3">
                {for s in STEPS {
                    <div key={s["n"]} className="flex flex-col items-center gap-2 rounded-2xl bg-card pt-4 pb-4 pl-4 pr-4 shadow-sm ring-1 ring-border">
                        <span className="flex size-9 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground">{s["n"]}</span>
                        <p className="font-bold">{s["title"]}</p>
                        <p className="text-sm text-muted-foreground">{s["text"]}</p>
                    </div>
                }}
            </div>
            <p className="text-sm text-muted-foreground">{"Participating BiteLoop business · rewards are limited and claimed on-site"}</p>
        </main>
        <aside className="flex flex-col gap-4 bg-charcoal pt-8 pb-8 pl-6 pr-6 text-white print:hidden lg:pt-20">
            <div className="flex items-center gap-2">
                <HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} className="size-5 text-primary" />
                <h2 className="text-xl font-bold tracking-tight">{"Rewards today"}</h2>
            </div>
            {if len(dash.rewards) == 0 {
                <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-white/20 pt-10 pb-10 text-center">
                    <HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} className="size-8 text-white/40" />
                    <p className="font-semibold">{"No live rewards right now"}</p>
                    <p className="text-sm text-white/60">{"Scanning still earns Bite Points toward your streak."}</p>
                </div>
                skip;
            }}
            {for rw in dash.rewards { <DisplayReward key={rw.id} rw={rw} /> }}
            <div className="mt-auto flex items-center gap-2 rounded-2xl bg-primary/20 pt-3 pb-3 pl-4 pr-4 text-sm">
                <HugeiconsIcon icon={Wallet01Icon} strokeWidth={2} className="size-5 shrink-0 text-primary" />
                {"+10 Bite Points for every daily check-in"}
            </div>
        </aside>
    </div>;
}

"""Full-screen counter display / printable poster of the in-store check-in QR code."""
def:pub StoreDisplay() -> JsxElement {
    has dash: DashboardView | None = None,
        loading: bool = True,
        error: str = "";

    async def load -> None {
        try {
            dash = await get_dashboard();
            error = "";
        } except Exception as e {
            error = "Could not load the QR code. " + str(e);
        }
        loading = False;
    }

    useEffect(lambda {
        load();
        timer = setInterval(lambda { load(); }, 30000);
        return lambda { clearInterval(timer); };
    }, []);

    def go_fullscreen() {
        el: any = document.documentElement;
        if el.requestFullscreen { el.requestFullscreen(); }
    }

    return <div className="relative">
        <div className="fixed right-4 top-4 z-50 flex flex-wrap gap-2 print:hidden">
            <Link to="/business"><Button variant="outline" size="sm" className="bg-card shadow-sm"><HugeiconsIcon icon={ArrowLeft01Icon} strokeWidth={2} />{"Dashboard"}</Button></Link>
            <Button variant="outline" size="sm" className="bg-card shadow-sm" onClick={go_fullscreen}>{"Full screen"}</Button>
            <Button size="sm" className="shadow-sm" onClick={lambda { window.print(); }}>{"Print poster"}</Button>
        </div>
        {loading and <div className="flex min-h-svh flex-col items-center justify-center gap-6"><Skeleton className="h-10 w-72" /><Skeleton className="size-80 rounded-[2rem]" /></div>}
        {not loading and (dash is None or not dash.checkin_token) and <div className="flex min-h-svh flex-col items-center justify-center gap-3 text-center">
            <HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} className="size-10 text-muted-foreground" />
            <p className="text-lg font-semibold">{"QR code unavailable"}</p>
            <p className="text-sm text-destructive">{error}</p>
            <Button onClick={lambda { loading = True; load(); }}>{"Retry"}</Button>
        </div>}
        {dash and dash.checkin_token and <DisplayBody dash={dash} />}
    </div>;
}
