import from "@jac/runtime" { Link, useNavigate }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Location01Icon, Search01Icon, Notification01Icon, FlashIcon, Clock01Icon,
    Ticket01Icon, CheckmarkBadge01Icon, Store01Icon
}
import from .ui.button { Button }
import from .ui.skeleton { Skeleton }
import from .ui.avatar { Avatar, AvatarFallback }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from .RewardCard { RewardCard, KindPill, time_left, money }
import from .BottomNav { BrandMark }
sv import from ..services.biteloop { get_feed, FeedView, RewardView }

glob RADII: list[float] = [0.5, 1.0, 2.0, 5.0, 10.0];
glob AREAS: list[str] = ["Downtown", "Riverside", "Old Mill", "Harbor District"];

def:pub HomeFeed() -> JsxElement {
    has feed: FeedView | None = None,
        loading: bool = True,
        error: str = "",
        claimingId: str = "",
        showLocation: bool = False;

    navigate = useNavigate();

    async def load(location: str, radius: float) -> None {
        error = "";
        try {
            data = await get_feed(location, radius);
            if not data.onboarded and localStorage.getItem("bl_onboarded") != "1" {
                navigate("/onboarding");
                return;
            }
            feed = data;
        } except Exception as e {
            error = "We could not load nearby rewards. " + str(e);
        }
        loading = False;
    }

    def claim(rid: str) {
        navigate("/verify/" + rid);
    }

    can with entry {
        load("", 0.0);
    }

    location = feed.location if feed else "Downtown";
    radius = feed.radius if feed else 2.0;

    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <header className="flex flex-col gap-4">
            <div className="flex items-center justify-between gap-3">
                <div className="md:hidden"><BrandMark /></div>
                <div className="hidden md:block" />
                <div className="flex items-center gap-2">
                    <Link to="/explore" aria-label="Search" className="flex size-10 items-center justify-center rounded-full border bg-card shadow-sm transition-colors hover:bg-muted">
                        <HugeiconsIcon icon={Search01Icon} strokeWidth={2} className="size-5" />
                    </Link>
                    <button aria-label="Notifications" onClick={lambda { toast("Flash Drop alert: free fries just dropped 0.4 mi away at The Corner."); }} className="relative flex size-10 items-center justify-center rounded-full border bg-card shadow-sm transition-colors hover:bg-muted">
                        <HugeiconsIcon icon={Notification01Icon} strokeWidth={2} className="size-5" />
                        <span className="absolute right-2 top-2 size-2 rounded-full bg-primary ring-2 ring-card" />
                    </button>
                    <Link to="/profile" aria-label="Profile">
                        <Avatar className="size-10 ring-2 ring-primary/30"><AvatarFallback className="bg-charcoal font-semibold text-white">{"RP"}</AvatarFallback></Avatar>
                    </Link>
                </div>
            </div>
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight md:text-4xl">{"What's happening near you?"}</h1>
                <button onClick={lambda { showLocation = not showLocation; }} className="inline-flex w-fit items-center gap-1.5 rounded-full bg-card pt-1.5 pb-1.5 pl-3 pr-3 text-sm font-medium shadow-sm ring-1 ring-border transition-colors hover:bg-muted">
                    <HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-4 text-primary" />
                    {"Near " + location + " · within " + str(radius) + " mi"}
                </button>
            </div>
            {showLocation and <div className="flex flex-col gap-3 rounded-2xl border bg-card pt-4 pb-4 pl-4 pr-4 shadow-sm animate-in fade-in slide-in-from-top-1">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{"Area (approximate, never shared)"}</p>
                <div className="flex flex-wrap gap-2">
                    {for a in AREAS {
                        <button key={a} onClick={lambda { load(a, 0.0); }} className={"rounded-full pt-1.5 pb-1.5 pl-3 pr-3 text-sm font-medium transition-colors " + ("bg-charcoal text-white" if a == location else "bg-muted hover:bg-secondary")}>{a}</button>
                    }}
                </div>
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{"Radius"}</p>
                <div className="flex flex-wrap gap-2">
                    {for r in RADII {
                        <button key={str(r)} onClick={lambda { load("", r); }} className={"rounded-full pt-1.5 pb-1.5 pl-3 pr-3 text-sm font-medium tabular-nums transition-colors " + ("bg-primary text-primary-foreground" if r == radius else "bg-muted hover:bg-secondary")}>{str(r) + " mi"}</button>
                    }}
                </div>
            </div>}
        </header>

        {loading and <div className="flex flex-col gap-4">
            <Skeleton className="h-72 w-full rounded-3xl" />
            <div className="flex gap-3"><Skeleton className="h-28 w-64 rounded-2xl" /><Skeleton className="h-28 w-64 rounded-2xl" /></div>
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3"><Skeleton className="h-80 rounded-3xl" /><Skeleton className="h-80 rounded-3xl" /><Skeleton className="h-80 rounded-3xl" /></div>
        </div>}

        {error and <div className="flex items-center justify-between gap-3 rounded-2xl border border-destructive/30 bg-destructive/5 pt-3 pb-3 pl-4 pr-4 text-sm text-destructive">
            <span>{error}</span>
            <Button size="sm" variant="outline" onClick={lambda { loading = True; load("", 0.0); }}>{"Retry"}</Button>
        </div>}

        {feed and <FeedBody feed={feed} claimingId={claimingId} onClaim={claim} onWiden={lambda { load("", 10.0); }} />}
    </div>;
}

def:pub FeaturedReward(reward: RewardView, claimingId: str, onClaim: Callable[[str], None]) -> JsxElement {
    return <section className="relative overflow-hidden rounded-[2rem] bg-charcoal text-white shadow-xl">
        <img src={reward.image} alt={reward.title} className="absolute inset-0 size-full object-cover opacity-70" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/45 to-black/10 md:bg-gradient-to-r md:from-black/85 md:via-black/50 md:to-transparent" />
        <div className="relative flex min-h-[22rem] flex-col justify-end gap-4 pt-6 pb-6 pl-6 pr-6 md:min-h-[24rem] md:max-w-xl md:pl-10 md:pb-10">
            <div className="flex flex-wrap items-center gap-2">
                <KindPill kind={reward.kind} />
                <span className="rounded-full bg-white/15 pt-1 pb-1 pl-2.5 pr-2.5 text-[11px] font-semibold uppercase tracking-wide backdrop-blur">{"Featured near you"}</span>
            </div>
            <div className="flex flex-col gap-1">
                <h2 className="text-4xl font-extrabold uppercase leading-none tracking-tight md:text-5xl">{reward.title}</h2>
                <Link to={"/restaurant/" + reward.restaurant_id} className="inline-flex items-center gap-1.5 text-lg font-medium text-white/90 hover:underline">
                    {"At " + reward.restaurant_name}
                    {reward.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-4 text-sky-300" />}
                </Link>
                <p className="text-sm text-white/75">{reward.description}</p>
            </div>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                <HeroStat label="Distance" value={str(reward.distance) + " mi"} />
                <HeroStat label="Time left" value={time_left(reward.minutes_left)} />
                <HeroStat label="Remaining" value={str(reward.remaining) + " of " + str(reward.quantity)} />
                <HeroStat label="Value" value={money(reward.value)} />
            </div>
            <p className="text-xs text-white/70">{"To unlock: " + reward.requirements}</p>
            <Button size="lg" className="h-12 w-full rounded-xl text-base font-bold shadow-lg sm:w-fit sm:pl-8 sm:pr-8" disabled={reward.claimed or claimingId == reward.id or reward.remaining <= 0} onClick={lambda { onClaim(reward.id); }}>
                {"In your wallet" if reward.claimed else ("Claiming..." if claimingId == reward.id else "Claim reward")}
            </Button>
        </div>
    </section>;
}

def:pub HeroStat(label: str, value: str) -> JsxElement {
    return <div className="rounded-xl bg-white/12 pt-2 pb-2 pl-3 pr-3 backdrop-blur">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-white/60">{label}</p>
        <p className="text-sm font-bold tabular-nums">{value}</p>
    </div>;
}

def:pub FlashStrip(items: list[RewardView], claimingId: str, onClaim: Callable[[str], None]) -> JsxElement {
    return <section className="flex flex-col gap-3">
        <div className="flex items-center gap-2">
            <span className="relative flex size-2.5"><span className="absolute inline-flex size-full animate-ping rounded-full bg-yellow-400 opacity-75" /><span className="relative inline-flex size-2.5 rounded-full bg-yellow-400" /></span>
            <h2 className="text-xl font-bold tracking-tight">{"Flash Drops"}</h2>
            <span className="text-sm text-muted-foreground">{"Released just now, gone soon"}</span>
        </div>
        <div className="no-scrollbar -ml-4 -mr-4 flex snap-x gap-3 overflow-x-auto pl-4 pr-4 pb-1">
            {for f in items {
                <div key={f.id} className="flex w-72 shrink-0 snap-start items-center gap-3 rounded-2xl border-2 border-yellow-400/70 bg-card pt-3 pb-3 pl-3 pr-3 shadow-sm">
                    <img src={f.image} alt={f.title} className="size-20 shrink-0 rounded-xl object-cover" />
                    <div className="flex min-w-0 flex-1 flex-col gap-1">
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold uppercase tracking-wide text-yellow-600"><HugeiconsIcon icon={FlashIcon} strokeWidth={2.5} className="size-3.5" />{"Released " + str(f.released_minutes_ago) + " min ago"}</span>
                        <p className="truncate font-bold leading-tight">{f.title + " at " + f.restaurant_name}</p>
                        <p className="text-xs text-muted-foreground tabular-nums">{str(f.distance) + " mi · " + str(f.remaining) + " of " + str(f.quantity) + " left"}</p>
                        <Button size="sm" className="mt-0.5 h-8 rounded-lg" variant={"secondary" if f.claimed else "default"} disabled={f.claimed or claimingId == f.id or f.remaining <= 0} onClick={lambda { onClaim(f.id); }}>{"Claimed" if f.claimed else "Grab it"}</Button>
                    </div>
                </div>
            }}
        </div>
    </section>;
}

def:pub FeedBody(feed: FeedView, claimingId: str, onClaim: Callable[[str], None], onWiden: Callable[[], None]) -> JsxElement {
    if feed.featured is None and len(feed.rewards) == 0 and len(feed.flash) == 0 {
        return <Empty className="rounded-3xl border border-dashed bg-card pt-14 pb-14">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={Store01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>{"No bites nearby yet."}</EmptyTitle>
                <EmptyDescription>{"Try expanding your radius or check back when local restaurants drop new rewards."}</EmptyDescription>
            </EmptyHeader>
            <EmptyContent><Button onClick={onWiden}>{"Expand to 10 miles"}</Button></EmptyContent>
        </Empty>;
    }
    return <div className="flex flex-col gap-8">
        {feed.featured and <FeaturedReward reward={feed.featured} claimingId={claimingId} onClaim={onClaim} />}
        {len(feed.flash) > 0 and <FlashStrip items={feed.flash} claimingId={claimingId} onClaim={onClaim} />}
        <section className="flex flex-col gap-4">
            <div className="flex items-end justify-between gap-3">
                <div>
                    <h2 className="text-xl font-bold tracking-tight">{"Discover nearby"}</h2>
                    <p className="text-sm text-muted-foreground">{"Participating spots with live rewards, closest and most relevant first."}</p>
                </div>
                <span className="inline-flex items-center gap-1 text-sm font-medium text-muted-foreground tabular-nums"><HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} className="size-4" />{str(len(feed.rewards)) + " live"}</span>
            </div>
            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                {for r in feed.rewards {
                    <RewardCard key={r.id} reward={r} onClaim={onClaim} claiming={claimingId == r.id} />
                }}
            </div>
            <p className="inline-flex items-center gap-1.5 text-xs text-muted-foreground"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />{"Sample businesses are fictional demo data used to preview BiteLoop."}</p>
        </section>
    </div>;
}
