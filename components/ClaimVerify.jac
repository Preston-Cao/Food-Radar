import from "@jac/runtime" { Link, useParams, useNavigate }
import from "sonner" { toast }
import from "@yudiel/react-qr-scanner" { Scanner }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowLeft01Icon, QrCode01Icon, Ticket01Icon, CheckmarkBadge01Icon, LockIcon, Location01Icon, Clock01Icon
}
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from .RewardCard { KindPill, time_left, money }
sv import from ..services.biteloop { get_reward, claim_reward, RewardView }

"""Live camera scanner; hands the first decoded value up and pauses while a claim is in flight."""
def:pub StoreScanner(busy: bool, onCode: Callable[[str], None]) -> JsxElement {
    has camError: str = "";

    def handle_scan(codes: any) {
        if busy or not codes or len(codes) == 0 {
            return;
        }
        onCode(str(codes[0].rawValue));
    }

    if camError {
        return <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed bg-muted/40 pt-10 pb-10 pl-6 pr-6 text-center">
            <HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} className="size-8 text-muted-foreground" />
            <p className="font-semibold">{"Camera unavailable"}</p>
            <p className="text-sm text-muted-foreground">{camError}</p>
        </div>;
    }
    return <div className="relative overflow-hidden rounded-2xl bg-charcoal">
        <div className="aspect-square w-full">
            <Scanner
                onScan={handle_scan}
                onError={lambda (err: any) { camError = "Allow camera access, or switch to Enter store code."; }}
                paused={busy}
                constraints={{"facingMode": "environment"}}
                styles={{"container": {"width": "100%", "height": "100%"}, "video": {"objectFit": "cover"}}}
            />
        </div>
        <p className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent pt-6 pb-3 text-center text-sm font-medium text-white">
            {"Verifying..." if busy else "Point your camera at the BiteLoop QR code at the counter"}
        </p>
    </div>;
}

def:pub ClaimVerify() -> JsxElement {
    has reward: RewardView | None = None,
        loading: bool = True,
        method: str = "code",
        code: str = "",
        busy: bool = False,
        error: str = "";

    params = useParams();
    rid: str = params["rewardId"] or "";
    navigate = useNavigate();

    async def load -> None {
        try {
            reward = await get_reward(rid);
        } except Exception {
            reward = None;
        }
        loading = False;
    }

    async def verify(value: str) -> None {
        if busy {
            return;
        }
        entered = value.strip();
        if not entered {
            error = "Enter the code from the store.";
            return;
        }
        busy = True;
        error = "";
        res = await claim_reward(rid, entered);
        busy = False;
        if res.ok {
            toast.success(res.message);
            if navigator.vibrate { navigator.vibrate([40, 30, 40]); }
            navigate("/wallet");
        } else {
            error = res.message;
            if navigator.vibrate { navigator.vibrate(120); }
        }
    }

    can with [rid] entry {
        load();
    }

    if loading {
        return <div className="mx-auto flex w-full max-w-2xl flex-col gap-4"><Skeleton className="h-44 rounded-3xl" /><Skeleton className="h-72 rounded-3xl" /></div>;
    }
    if reward is None {
        return <Empty className="rounded-3xl border border-dashed bg-card pt-14 pb-14">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>{"Reward not found"}</EmptyTitle>
                <EmptyDescription>{"It may have ended or been fully claimed."}</EmptyDescription>
            </EmptyHeader>
            <EmptyContent><Link to="/"><Button>{"Back to nearby bites"}</Button></Link></EmptyContent>
        </Empty>;
    }
    return <VerifyBody reward={reward} method={method} code={code} busy={busy} error={error}
        onMethod={lambda (m: str) { method = m; error = ""; }}
        onCode={lambda (v: str) { code = v.upper(); }}
        onVerify={verify} />;
}

def:pub VerifyBody(
    reward: RewardView, method: str, code: str, busy: bool, error: str,
    onMethod: Callable[[str], None], onCode: Callable[[str], None], onVerify: Callable[[str], None]
) -> JsxElement {
    unavailable = reward.remaining <= 0 or reward.minutes_left <= 0;
    return <div className="mx-auto flex w-full max-w-2xl flex-col gap-5 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <Link to={"/restaurant/" + reward.restaurant_id} className="inline-flex w-fit items-center gap-1 text-sm font-medium text-muted-foreground hover:text-foreground">
            <HugeiconsIcon icon={ArrowLeft01Icon} strokeWidth={2} className="size-4" />{reward.restaurant_name}
        </Link>

        <section className="flex gap-4 overflow-hidden rounded-3xl border bg-card pt-3 pb-3 pl-3 pr-3 shadow-sm">
            <img src={reward.image} alt={reward.title} className="size-28 shrink-0 rounded-2xl object-cover sm:size-32" />
            <div className="flex min-w-0 flex-1 flex-col justify-center gap-1.5 pr-2">
                <KindPill kind={reward.kind} />
                <h1 className="text-xl font-bold leading-tight tracking-tight sm:text-2xl">{reward.title}</h1>
                <p className="flex items-center gap-1 truncate text-sm text-muted-foreground">
                    {reward.restaurant_name}
                    {reward.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-4 shrink-0 text-sky-500" />}
                </p>
                <p className="flex flex-wrap gap-x-3 text-xs font-medium text-muted-foreground tabular-nums">
                    <span className="inline-flex items-center gap-1"><HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-3.5" />{str(reward.distance) + " mi"}</span>
                    <span className="inline-flex items-center gap-1"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />{time_left(reward.minutes_left)}</span>
                    <span>{str(reward.remaining) + " left · " + money(reward.value) + " value"}</span>
                </p>
            </div>
        </section>

        <section className="flex flex-col gap-5 rounded-3xl border bg-card pt-6 pb-6 pl-5 pr-5 shadow-sm sm:pl-7 sm:pr-7">
            <div className="flex items-start gap-3">
                <span className="flex size-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-primary"><HugeiconsIcon icon={LockIcon} strokeWidth={2} className="size-5" /></span>
                <div>
                    <h2 className="text-xl font-bold tracking-tight">{"Verify you're at the store"}</h2>
                    <p className="text-sm text-muted-foreground">{"Rewards unlock in person. Scan the BiteLoop QR at the counter or enter the code staff give you."}</p>
                </div>
            </div>

            {reward.claimed and <p className="rounded-xl bg-success/10 pt-3 pb-3 pl-4 pr-4 text-sm font-medium text-success">{"You already claimed this reward. Find it in your wallet."}</p>}
            {unavailable and not reward.claimed and <p className="rounded-xl bg-muted pt-3 pb-3 pl-4 pr-4 text-sm font-medium text-muted-foreground">{"This reward is no longer available."}</p>}

            {not reward.claimed and not unavailable and <div className="flex flex-col gap-5">
                <div className="grid grid-cols-2 gap-1 rounded-full bg-muted pt-1 pb-1 pl-1 pr-1">
                    <button type="button" onClick={lambda { onMethod("code"); }} className={"rounded-full pt-2 pb-2 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if method == "code" else "text-muted-foreground")}>{"Enter store code"}</button>
                    <button type="button" onClick={lambda { onMethod("scan"); }} className={"rounded-full pt-2 pb-2 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if method == "scan" else "text-muted-foreground")}>{"Scan store QR"}</button>
                </div>

                {<StoreScanner busy={busy} onCode={onVerify} /> if method == "scan" else <form className="flex flex-col gap-3" onSubmit={lambda (e: FormEvent) { e.preventDefault(); onVerify(code); }}>
                    <label htmlFor="store-code" className="text-sm font-semibold">{"Store code"}</label>
                    <Input id="store-code" value={code} maxLength={6} autoComplete="off" autoCapitalize="characters" placeholder="e.g. K7Q2MX"
                        onChange={lambda (e: ChangeEvent) { onCode(e.target.value); }}
                        className="h-14 rounded-2xl text-center font-mono text-2xl font-bold uppercase tracking-[0.4em]" />
                    <p className="text-xs text-muted-foreground">{"Shown on the BiteLoop sign at the counter, or ask a staff member."}</p>
                    <Button type="submit" size="lg" className="h-12 rounded-xl text-base font-bold" disabled={busy or len(code.strip()) < 6}>{"Verifying..." if busy else "Verify and claim"}</Button>
                </form>}

                {error and <p role="alert" className="rounded-xl bg-destructive/10 pt-3 pb-3 pl-4 pr-4 text-sm font-medium text-destructive">{error}</p>}
            </div>}

            {reward.claimed and <Link to="/wallet"><Button className="h-11 w-full rounded-xl">{"Open wallet"}</Button></Link>}
        </section>
        <p className="text-center text-xs text-muted-foreground">{"To unlock: " + reward.requirements}</p>
    </div>;
}
