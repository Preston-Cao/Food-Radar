import from "@jac/runtime" { Link }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Wallet01Icon, QrCode01Icon, Clock01Icon, Tick02Icon, Cancel01Icon }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from .RewardCard { KindPill, time_left }
sv import from ..services.biteloop { get_wallet, redeem_claim, ClaimView }

def _hash(s: str, i: int) -> int {
    h = 7 + i * 31;
    for ch in s {
        h = (h * 33 + ord(ch) + i) % 1000003;
    }
    return h;
}

"""Deterministic QR-style matrix drawn as SVG from the claim code (demo scanner visual)."""
def:pub QrMatrix(code: str) -> JsxElement {
    n = 25;
    cells: list[list[int]] = [];
    for y in range(n) {
        for x in range(n) {
            in_finder = (x < 7 and y < 7) or (x >= n - 7 and y < 7) or (x < 7 and y >= n - 7);
            if in_finder {
                fx = x if x < 7 else x - (n - 7);
                fy = y if y < 7 else y - (n - 7);
                ring = fx == 0 or fx == 6 or fy == 0 or fy == 6;
                core = fx >= 2 and fx <= 4 and fy >= 2 and fy <= 4;
                if ring or core {
                    cells.append([x, y]);
                }
            } elif _hash(code, y * n + x) % 2 == 0 {
                cells.append([x, y]);
            }
        }
    }
    return <svg viewBox="-2 -2 29 29" className="size-full" shapeRendering="crispEdges">
        <rect x="-2" y="-2" width="29" height="29" fill="white" />
        {for c in cells { <rect key={str(c[0]) + "-" + str(c[1])} x={c[0]} y={c[1]} width="1" height="1" fill="#1f1a17" /> }}
    </svg>;
}

def:pub RedeemPanel(claim: ClaimView, busy: bool, onRedeem: Callable[[str, str], None], onClose: Callable[[], None]) -> JsxElement {
    has manual: str = "";
    return <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 backdrop-blur-sm animate-in fade-in sm:items-center" onClick={lambda { onClose(); }}>
        <div className="flex w-full max-w-md flex-col gap-4 rounded-t-[2rem] bg-card pt-6 pb-8 pl-6 pr-6 shadow-2xl animate-in slide-in-from-bottom-8 duration-300 sm:rounded-[2rem]" onClick={lambda (e: MouseEvent) { e.stopPropagation(); }}>
            <div className="mx-auto h-1.5 w-12 rounded-full bg-muted sm:hidden" />
            <div className="flex items-start justify-between gap-3">
                <div>
                    <p className="text-sm text-muted-foreground">{claim.restaurant_name}</p>
                    <h2 className="text-2xl font-bold tracking-tight">{claim.title}</h2>
                </div>
                <button aria-label="Close" onClick={lambda { onClose(); }} className="flex size-9 items-center justify-center rounded-full bg-muted"><HugeiconsIcon icon={Cancel01Icon} strokeWidth={2} className="size-4" /></button>
            </div>
            <div className="mx-auto size-56 rounded-2xl bg-white pt-3 pb-3 pl-3 pr-3 shadow-inner ring-1 ring-border"><QrMatrix code={claim.claim_code} /></div>
            <div className="flex items-center justify-center gap-6 text-center">
                <div><p className="text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">{"Claim code"}</p><p className="font-mono text-lg font-bold">{claim.claim_code}</p></div>
                <div><p className="text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">{"Backup code"}</p><p className="font-mono text-lg font-bold tracking-widest">{claim.backup_code}</p></div>
            </div>
            <p className="rounded-xl bg-muted pt-2.5 pb-2.5 pl-3 pr-3 text-xs text-muted-foreground">{"Staff: scan the code, or type the backup code below to confirm. Each code works once."}</p>
            <div className="flex gap-2">
                <Input value={manual} onChange={lambda (e: ChangeEvent) { manual = e.target.value; }} placeholder="Staff enters backup code" className="h-11 rounded-xl font-mono" />
                <Button variant="outline" className="h-11 rounded-xl" disabled={busy or not manual.strip()} onClick={lambda { onRedeem(claim.id, manual); }}>{"Verify"}</Button>
            </div>
            <Button size="lg" className="h-12 rounded-xl text-base font-bold" disabled={busy} onClick={lambda { onRedeem(claim.id, claim.claim_code); }}>{"Confirming..." if busy else "Simulate staff scan"}</Button>
        </div>
    </div>;
}

def:pub WalletScreen() -> JsxElement {
    has claims: list[ClaimView] = [],
        loading: bool = True,
        error: str = "",
        tab: str = "active",
        openId: str = "",
        busy: bool = False;

    async def load -> None {
        try {
            claims = await get_wallet();
        } except Exception as e {
            error = "Could not load your wallet. " + str(e);
        }
        loading = False;
    }

    async def redeem(cid: str, code: str) -> None {
        busy = True;
        res = await redeem_claim(cid, code);
        if res.ok {
            toast.success(res.message);
            if navigator.vibrate { navigator.vibrate([40, 30, 40]); }
            openId = "";
        } else {
            toast.error(res.message);
        }
        busy = False;
        await load();
    }

    can with entry {
        load();
    }

    active = [c for c in claims if c.status == "active"];
    redeemed = [c for c in claims if c.status == "redeemed"];
    expired = [c for c in claims if c.status == "expired"];
    shown = active if tab == "active" else (redeemed if tab == "redeemed" else expired);
    opened = [c for c in claims if c.id == openId];

    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <div className="flex flex-col gap-1">
            <h1 className="text-3xl font-bold tracking-tight">{"Wallet"}</h1>
            <p className="text-sm text-muted-foreground">{"Rewards you have claimed. Open one at the counter and tap Redeem."}</p>
        </div>
        <div className="flex w-fit gap-1 rounded-full bg-muted pt-1 pb-1 pl-1 pr-1">
            {for t in [["active", "Active", str(len(active))], ["redeemed", "Redeemed", str(len(redeemed))], ["expired", "Expired", str(len(expired))]] {
                <button key={t[0]} onClick={lambda { tab = t[0]; }} className={"rounded-full pt-1.5 pb-1.5 pl-4 pr-4 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if tab == t[0] else "text-muted-foreground")}>{t[1] + " (" + t[2] + ")"}</button>
            }}
        </div>
        {loading and <div className="grid gap-4 md:grid-cols-2"><Skeleton className="h-44 rounded-3xl" /><Skeleton className="h-44 rounded-3xl" /></div>}
        {error and <p className="text-sm text-destructive">{error}</p>}
        {if not loading and len(shown) == 0 {
            <Empty className="rounded-3xl border border-dashed bg-card pt-14 pb-14">
                <EmptyHeader>
                    <EmptyMedia variant="icon"><HugeiconsIcon icon={Wallet01Icon} strokeWidth={2} /></EmptyMedia>
                    <EmptyTitle>{"No rewards in your wallet." if tab == "active" else ("Nothing redeemed yet" if tab == "redeemed" else "No expired rewards")}</EmptyTitle>
                    <EmptyDescription>{"Explore nearby restaurants and claim your first Bite."}</EmptyDescription>
                </EmptyHeader>
                <EmptyContent><Link to="/"><Button>{"Find nearby bites"}</Button></Link></EmptyContent>
            </Empty>
            skip;
        }}
        <div className="grid gap-4 md:grid-cols-2">
            {for c in shown {
                <article key={c.id} className={"flex overflow-hidden rounded-3xl border bg-card shadow-sm transition-all " + ("ring-2 ring-primary/40 hover:shadow-lg" if c.status == "active" else "opacity-80")}>
                    <img src={c.image} alt={c.title} className={"w-28 shrink-0 object-cover sm:w-36 " + ("grayscale" if c.status == "expired" else "")} />
                    <div className="flex min-w-0 flex-1 flex-col gap-2 pt-4 pb-4 pl-4 pr-4">
                        <KindPill kind={c.kind} />
                        <div>
                            <h3 className="truncate text-lg font-bold leading-tight">{c.title}</h3>
                            <p className="truncate text-sm text-muted-foreground">{c.restaurant_name}</p>
                        </div>
                        {c.status == "active" and <p className="inline-flex items-center gap-1 text-xs font-semibold text-primary"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />{"Expires: " + time_left(c.minutes_left)}</p>}
                        {c.status == "redeemed" and <p className="inline-flex items-center gap-1 text-xs font-semibold text-success"><HugeiconsIcon icon={Tick02Icon} strokeWidth={2} className="size-3.5" />{c.redeemed_label + (" · " + c.reveal if c.reveal else "")}</p>}
                        {c.status == "expired" and <p className="text-xs font-semibold text-muted-foreground">{"Expired"}</p>}
                        {c.status == "active" and <p className="line-clamp-2 text-xs text-muted-foreground">{c.instructions}</p>}
                        {c.status == "active" and <Button className="mt-auto h-10 rounded-xl font-semibold" onClick={lambda { openId = c.id; }}><HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} />{"Redeem"}</Button>}
                    </div>
                </article>
            }}
        </div>
        {len(opened) > 0 and <RedeemPanel claim={opened[0]} busy={busy} onRedeem={redeem} onClose={lambda { openId = ""; }} />}
    </div>;
}
