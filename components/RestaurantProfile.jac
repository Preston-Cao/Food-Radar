import from "@jac/runtime" { Link, useParams, useNavigate }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowLeft01Icon, CheckmarkBadge01Icon, Location01Icon, Clock01Icon, Globe02Icon,
    Call02Icon, StarIcon, Store01Icon, Ticket01Icon
}
import from .ui.button { Button }
import from .ui.badge { Badge }
import from .ui.skeleton { Skeleton }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription }
import from .RewardCard { RewardCard }
sv import from ..services.biteloop { get_restaurant, RestaurantDetail }

def:pub RestaurantProfile() -> JsxElement {
    has detail: RestaurantDetail | None = None,
        loading: bool = True,
        missing: bool = False,
        claimingId: str = "";

    params = useParams();
    rid: str = params["id"] or "";

    async def load -> None {
        try {
            d = await get_restaurant(rid);
            if d {
                detail = d;
            } else {
                missing = True;
            }
        } except Exception {
            missing = True;
        }
        loading = False;
    }

    navigate = useNavigate();

    def claim(rewardId: str) {
        navigate("/verify/" + rewardId);
    }

    can with [rid] entry {
        load();
    }

    if loading {
        return <div className="flex flex-col gap-4">
            <Skeleton className="h-64 w-full rounded-3xl" />
            <Skeleton className="h-8 w-1/2" />
            <div className="grid gap-4 sm:grid-cols-2"><Skeleton className="h-72 rounded-3xl" /><Skeleton className="h-72 rounded-3xl" /></div>
        </div>;
    }
    if missing or detail is None {
        return <Empty className="rounded-3xl border border-dashed bg-card pt-14 pb-14">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={Store01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>{"Spot not found"}</EmptyTitle>
                <EmptyDescription>{"This business is not participating in BiteLoop right now."}</EmptyDescription>
            </EmptyHeader>
            <Link to="/explore" className="text-sm font-semibold text-primary">{"Back to Explore"}</Link>
        </Empty>;
    }
    return <ProfileBody detail={detail} claimingId={claimingId} onClaim={claim} />;
}

def:pub ProfileBody(detail: RestaurantDetail, claimingId: str, onClaim: Callable[[str], None]) -> JsxElement {
    r = detail.restaurant;
    first_id = detail.rewards[0].id if len(detail.rewards) > 0 else "";
    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <div className="relative -ml-4 -mr-4 -mt-5 overflow-hidden sm:ml-0 sm:mr-0 sm:mt-0 sm:rounded-3xl">
            <img src={r.cover_image} alt={r.name} className="h-64 w-full object-cover md:h-80" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-black/10" />
            <Link to="/" aria-label="Back" className="absolute left-4 top-4 flex size-10 items-center justify-center rounded-full bg-white/90 text-charcoal shadow">
                <HugeiconsIcon icon={ArrowLeft01Icon} strokeWidth={2} className="size-5" />
            </Link>
            <div className="absolute bottom-4 left-4 right-4 flex items-end gap-3 text-white">
                <img src={r.logo} alt="" className="size-16 rounded-2xl border-2 border-white object-cover shadow-lg" />
                <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5">
                        <h1 className="truncate text-2xl font-bold tracking-tight md:text-3xl">{r.name}</h1>
                        {r.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-5 shrink-0 text-sky-300" />}
                    </div>
                    <p className="text-sm text-white/85">{r.cuisine + " · " + r.neighborhood + " · " + str(r.distance) + " mi"}</p>
                </div>
            </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
            {r.verified and <Badge className="bg-sky-500 text-white">{"Verified business"}</Badge>}
            {r.sample and <Badge variant="outline">{"Sample business (demo data)"}</Badge>}
            {for t in r.tags { <Badge key={t} variant="secondary">{t}</Badge> }}
            <span className="inline-flex items-center gap-1 text-sm font-semibold"><HugeiconsIcon icon={StarIcon} strokeWidth={2} className="size-4 text-primary" />{str(r.rating)}</span>
        </div>

        {first_id and <Button size="lg" className="h-12 rounded-xl text-base font-bold shadow-md sm:w-fit sm:pl-8 sm:pr-8" disabled={claimingId == first_id or detail.rewards[0].claimed} onClick={lambda { onClaim(first_id); }}>
            {"Reward in your wallet" if detail.rewards[0].claimed else "Get reward: " + detail.rewards[0].title}
        </Button>}

        <div className="grid gap-6 lg:grid-cols-3">
            <div className="flex flex-col gap-6 lg:col-span-2">
                <section className="flex flex-col gap-3">
                    <h2 className="text-xl font-bold tracking-tight">{"Active rewards"}</h2>
                    {if len(detail.rewards) == 0 {
                        <Empty className="rounded-3xl border border-dashed bg-card pt-10 pb-10">
                            <EmptyHeader>
                                <EmptyMedia variant="icon"><HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} /></EmptyMedia>
                                <EmptyTitle>{"No live rewards right now"}</EmptyTitle>
                                <EmptyDescription>{"Save this spot and check back. Flash Drops can appear at any moment."}</EmptyDescription>
                            </EmptyHeader>
                        </Empty>
                        skip;
                    }}
                    <div className="grid gap-4 sm:grid-cols-2">
                        {for rw in detail.rewards {
                            <RewardCard key={rw.id} reward={rw} onClaim={onClaim} claiming={claimingId == rw.id} showRestaurant={False} />
                        }}
                    </div>
                </section>
                <section className="flex flex-col gap-3">
                    <h2 className="text-xl font-bold tracking-tight">{"Menu preview"}</h2>
                    <div className="grid grid-cols-2 gap-2">
                        {for m in detail.menu { <div key={m} className="rounded-xl bg-card pt-3 pb-3 pl-4 pr-4 text-sm font-medium shadow-sm ring-1 ring-border">{m}</div> }}
                    </div>
                </section>
                <section className="flex flex-col gap-3">
                    <h2 className="text-xl font-bold tracking-tight">{"What people say"}</h2>
                    {for rv in detail.reviews {
                        <Card key={rv["name"]} className="shadow-sm">
                            <CardContent className="flex flex-col gap-1">
                                <div className="flex items-center justify-between"><span className="font-semibold">{rv["name"]}</span><span className="text-sm font-semibold text-primary">{str(rv["rating"]) + " / 5"}</span></div>
                                <p className="text-sm text-muted-foreground">{rv["text"]}</p>
                            </CardContent>
                        </Card>
                    }}
                </section>
            </div>
            <div className="flex flex-col gap-4">
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>{"About"}</CardTitle></CardHeader>
                    <CardContent className="flex flex-col gap-3 text-sm">
                        <p className="text-muted-foreground">{r.description}</p>
                        <InfoRow icon={Location01Icon} text={r.address} />
                        <InfoRow icon={Clock01Icon} text={detail.hours} />
                        <InfoRow icon={Call02Icon} text={detail.phone} />
                        <InfoRow icon={Globe02Icon} text={detail.website} />
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>{"Rewards history"}</CardTitle></CardHeader>
                    <CardContent className="flex flex-col gap-2 text-sm text-muted-foreground">
                        {for p in detail.past_rewards { <p key={p}>{p}</p> }}
                    </CardContent>
                </Card>
                <p className="text-xs text-muted-foreground">{"Businesses on BiteLoop have joined the platform. Place details are provided through our places provider."}</p>
            </div>
        </div>
    </div>;
}

def:pub InfoRow(icon: any, text: str) -> JsxElement {
    return <div className="flex items-center gap-2.5">
        <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={icon} strokeWidth={2} className="size-4" /></span>
        <span className="truncate">{text}</span>
    </div>;
}
