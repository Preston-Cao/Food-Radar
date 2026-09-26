import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Location01Icon, Clock01Icon, FlashIcon, Fire02Icon, UserGroupIcon, Target02Icon,
    SparklesIcon, Tick02Icon, CheckmarkBadge01Icon, Ticket01Icon
}
import from .ui.button { Button }
import from .ui.badge { Badge }
sv import from ..services.biteloop { RewardView }

def:pub time_left(minutes: int) -> str {
    if minutes <= 0 {
        return "Ending now";
    }
    if minutes < 60 {
        return str(minutes) + " min left";
    }
    h = minutes // 60;
    if h < 24 {
        m = minutes % 60;
        return str(h) + "h " + str(m) + "m left";
    }
    return str(h // 24) + " days left";
}

def:pub kind_meta(kind: str) -> dict {
    if kind == "flash" {
        return {"label": "Flash Drop", "icon": FlashIcon, "cls": "bg-yellow-400 text-charcoal"};
    }
    if kind == "hot" {
        return {"label": "Hot right now", "icon": Fire02Icon, "cls": "bg-primary text-primary-foreground"};
    }
    if kind == "friend" {
        return {"label": "Bring a friend", "icon": UserGroupIcon, "cls": "bg-sky-500 text-white"};
    }
    if kind == "mission" {
        return {"label": "Today's mission", "icon": Target02Icon, "cls": "bg-success text-success-foreground"};
    }
    if kind == "mystery" {
        return {"label": "Mystery Bite", "icon": SparklesIcon, "cls": "bg-fuchsia-500 text-white"};
    }
    return {"label": "Local reward", "icon": Ticket01Icon, "cls": "bg-charcoal text-white"};
}

def:pub money(amount: float) -> str {
    return "$" + f"{amount:.2f}";
}

"""Pill showing kind of reward, used on cards and the featured hero."""
def:pub KindPill(kind: str) -> JsxElement {
    meta = kind_meta(kind);
    return <span className={"inline-flex items-center gap-1 rounded-full pt-1 pb-1 pl-2.5 pr-2.5 text-[11px] font-bold uppercase tracking-wide shadow-sm " + meta["cls"]}>
        <HugeiconsIcon icon={meta["icon"]} strokeWidth={2.5} className="size-3.5" />
        {meta["label"]}
    </span>;
}

"""Discovery feed card: photo, restaurant, reward, stock, countdown, action, claim."""
def:pub RewardCard(
    reward: RewardView,
    onClaim: Callable[[str], None],
    claiming: bool = False,
    showRestaurant: bool = True
) -> JsxElement {
    pct = 0;
    if reward.quantity > 0 {
        pct = int(reward.remaining * 100 / reward.quantity);
    }
    sold_out = reward.remaining <= 0;
    return <article className="group flex flex-col overflow-hidden rounded-3xl border bg-card shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:shadow-lg">
        <div className="relative aspect-[16/10] overflow-hidden bg-muted">
            <img src={reward.image} alt={reward.title} loading="lazy" className="size-full object-cover transition-transform duration-500 group-hover:scale-105" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/0 to-black/0" />
            <div className="absolute left-3 top-3 flex flex-wrap gap-1.5">
                <KindPill kind={reward.kind} />
                {reward.sponsored and <span className="rounded-full bg-white/90 pt-1 pb-1 pl-2.5 pr-2.5 text-[11px] font-semibold text-charcoal">{"Sponsored"}</span>}
            </div>
            <span className="absolute right-3 top-3 rounded-full bg-white/95 pt-1 pb-1 pl-2.5 pr-2.5 text-xs font-bold tabular-nums text-charcoal shadow-sm">{money(reward.value) + " value"}</span>
            {showRestaurant and <Link to={"/restaurant/" + reward.restaurant_id} className="absolute bottom-3 left-3 right-3 flex items-center gap-2 text-white">
                <img src={reward.restaurant_logo} alt="" className="size-8 rounded-full border-2 border-white object-cover" />
                <span className="truncate text-sm font-semibold drop-shadow">{reward.restaurant_name}</span>
                {reward.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-4 shrink-0 text-sky-300" />}
            </Link>}
        </div>
        <div className="flex flex-1 flex-col gap-3 pt-4 pb-4 pl-4 pr-4">
            <div className="flex flex-col gap-1">
                <h3 className="text-lg font-bold leading-tight tracking-tight">{reward.title}</h3>
                <p className="line-clamp-2 text-sm text-muted-foreground">{reward.requirements}</p>
            </div>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs font-medium text-muted-foreground">
                <span className="inline-flex items-center gap-1"><HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-3.5" />{str(reward.distance) + " mi"}</span>
                <span className={"inline-flex items-center gap-1 " + ("text-primary" if reward.minutes_left < 60 else "")}><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" />{time_left(reward.minutes_left)}</span>
                {reward.sample and <Badge variant="outline" className="h-5 text-[10px]">{"Sample business"}</Badge>}
            </div>
            <div className="flex flex-col gap-1.5">
                <div className="flex items-center justify-between text-xs">
                    <span className="font-semibold tabular-nums">{str(reward.remaining) + " of " + str(reward.quantity) + " left"}</span>
                    {pct < 35 and not sold_out and <span className="font-semibold text-primary">{"Going fast"}</span>}
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-muted">
                    <div className="h-full rounded-full bg-primary transition-all duration-700" style={{"width": str(pct) + "%"}} />
                </div>
            </div>
            <div className="mt-auto pt-1">
                {<Button variant="secondary" className="h-11 w-full rounded-xl" disabled={True}><HugeiconsIcon icon={Tick02Icon} strokeWidth={2} />{"In your wallet"}</Button> if reward.claimed else <Button className="h-11 w-full rounded-xl font-semibold" disabled={claiming or sold_out} onClick={lambda { onClaim(reward.id); }}>{"All claimed" if sold_out else ("Claiming..." if claiming else "Claim reward")}</Button>}
            </div>
        </div>
    </article>;
}
