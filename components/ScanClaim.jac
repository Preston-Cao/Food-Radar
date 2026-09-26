import from "@jac/runtime" { Link, useParams, useNavigate }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { QrCode01Icon, CheckmarkBadge01Icon, Tick02Icon, Ticket01Icon }
import from .ui.button { Button }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from .RewardCard { RewardCard }
sv import from ..services.biteloop { get_checkin, scan_claim, CheckinView, RestaurantView }

def:pub ScanClaim() -> JsxElement {
    has checkin: CheckinView | None = None,
        loading: bool = True,
        claimingId: str = "";

    params = useParams();
    rid: str = params["rid"] or "";
    token: str = params["token"] or "";
    navigate = useNavigate();

    async def load -> None {
        try {
            checkin = await get_checkin(rid, token);
        } except Exception {
            checkin = None;
        }
        loading = False;
    }

    async def claim(rewardId: str) -> None {
        claimingId = rewardId;
        res = await scan_claim(rewardId, rid, token);
        claimingId = "";
        if res.ok {
            toast.success(res.message);
            if navigator.vibrate { navigator.vibrate([40, 30, 40]); }
            navigate("/wallet");
        } else {
            toast.error(res.message);
            await load();
        }
    }

    can with [rid, token] entry {
        load();
    }

    if loading {
        return <div className="flex flex-col gap-4"><Skeleton className="h-40 rounded-3xl" /><Skeleton className="h-80 rounded-3xl" /></div>;
    }
    if checkin is None or not checkin.valid or checkin.restaurant is None {
        return <Empty className="rounded-3xl border border-dashed bg-card pt-14 pb-14">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>{"Invalid check-in code"}</EmptyTitle>
                <EmptyDescription>{(checkin.message if checkin else "") or "This QR code is not valid. Ask staff for the current BiteLoop code."}</EmptyDescription>
            </EmptyHeader>
            <EmptyContent><Link to="/"><Button>{"Browse nearby bites"}</Button></Link></EmptyContent>
        </Empty>;
    }
    return <ScanBody place={checkin.restaurant} checkin={checkin} claimingId={claimingId} onClaim={claim} />;
}

def:pub ScanBody(place: RestaurantView, checkin: CheckinView, claimingId: str, onClaim: Callable[[str], None]) -> JsxElement {
    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <section className="relative overflow-hidden rounded-[2rem] bg-charcoal text-white shadow-xl">
            <img src={place.cover_image} alt={place.name} className="absolute inset-0 size-full object-cover opacity-40" />
            <div className="relative flex flex-col gap-3 pt-7 pb-7 pl-6 pr-6 md:pl-8">
                <span className="inline-flex w-fit items-center gap-1.5 rounded-full bg-success pt-1 pb-1 pl-3 pr-3 text-xs font-bold uppercase tracking-wide text-success-foreground">
                    <HugeiconsIcon icon={Tick02Icon} strokeWidth={2.5} className="size-3.5" />{"You're here"}
                </span>
                <div className="flex items-center gap-2">
                    <h1 className="text-3xl font-bold tracking-tight md:text-4xl">{place.name}</h1>
                    {place.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-6 text-sky-300" />}
                </div>
                <p className="max-w-lg text-sm text-white/80">{"In-store check-in confirmed. Claim a reward below, then show the code from your wallet at the counter."}</p>
            </div>
        </section>
        {if len(checkin.rewards) == 0 {
            <Empty className="rounded-3xl border border-dashed bg-card pt-12 pb-12">
                <EmptyHeader>
                    <EmptyMedia variant="icon"><HugeiconsIcon icon={Ticket01Icon} strokeWidth={2} /></EmptyMedia>
                    <EmptyTitle>{"No live rewards right now"}</EmptyTitle>
                    <EmptyDescription>{"Your check-in still counts toward missions. Check back for the next Flash Drop."}</EmptyDescription>
                </EmptyHeader>
            </Empty>
            skip;
        }}
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
            {for rw in checkin.rewards {
                <RewardCard key={rw.id} reward={rw} onClaim={onClaim} claiming={claimingId == rw.id} showRestaurant={False} />
            }}
        </div>
    </div>;
}
