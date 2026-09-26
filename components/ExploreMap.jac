import from "@jac/runtime" { Link, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Search01Icon, FlashIcon, Location01Icon, StarIcon, CheckmarkBadge01Icon, Store01Icon, Cancel01Icon
}
import from .ui.input { Input }
import from .ui.button { Button }
import from .ui.badge { Badge }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from .RestaurantMap { RestaurantPinMap }
sv import from ..services.biteloop { get_restaurants, get_map_center, RestaurantView }

glob FILTERS: list[str] = [
    "All", "Free food", "Free drinks", "Under $10", "Flash Drops", "Cafes", "Restaurants",
    "Dessert", "Healthy", "Late night", "Open now"
];

def _matches(r: RestaurantView, f: str, q: str) -> bool {
    if q {
        hay = (r.name + " " + r.cuisine + " " + r.neighborhood + " " + r.category + " " + " ".join(r.tags) + " " + " ".join(r.reward_titles)).lower();
        if q.lower() not in hay {
            return False;
        }
    }
    if f == "All" { return True; }
    if f == "Flash Drops" { return r.has_flash; }
    if f == "Cafes" { return r.category == "cafe"; }
    if f == "Restaurants" { return r.category == "restaurant"; }
    if f == "Under $10" { return r.price_level <= 1; }
    if f == "Free drinks" {
        return len([t for t in r.reward_titles if "juice" in t.lower() or "latte" in t.lower() or "brew" in t.lower() or "coffee" in t.lower()]) > 0;
    }
    if f == "Free food" { return r.active_rewards > 0 and r.category == "restaurant" or "Dessert" in r.tags; }
    return f in r.tags or f == r.cuisine;
}

def:pub PinSheet(place: RestaurantView, onView: Callable[[str], None], onClose: Callable[[], None]) -> JsxElement {
    return <div className="absolute inset-x-3 bottom-3 z-[1000] flex items-center gap-3 rounded-2xl bg-card pt-3 pb-3 pl-3 pr-3 shadow-xl animate-in slide-in-from-bottom-4 duration-300">
        <img src={place.cover_image} alt={place.name} className="size-16 shrink-0 rounded-xl object-cover" />
        <div className="min-w-0 flex-1">
            <p className="truncate font-bold">{place.name}</p>
            <p className="truncate text-xs text-muted-foreground">{str(place.distance) + " mi · " + str(place.active_rewards) + " live rewards"}</p>
            <p className="truncate text-xs font-medium text-primary">{", ".join(place.reward_titles) or "No live rewards right now"}</p>
        </div>
        <div className="flex flex-col gap-1">
            <Button size="sm" onClick={lambda { onView(place.id); }}>{"View"}</Button>
            <button aria-label="Close" onClick={lambda { onClose(); }} className="self-center text-muted-foreground"><HugeiconsIcon icon={Cancel01Icon} strokeWidth={2} className="size-4" /></button>
        </div>
    </div>;
}

def:pub ExploreMap() -> JsxElement {
    has places: list[RestaurantView] = [],
        loading: bool = True,
        error: str = "",
        query: str = "",
        filter: str = "All",
        selected: str = "",
        center: list[float] = [40.742, -73.989];

    navigate = useNavigate();

    async def load -> None {
        error = "";
        try {
            places = await get_restaurants("");
            center = await get_map_center();
        } except Exception as e {
            error = "Could not load the map. " + str(e);
        }
        loading = False;
    }

    can with entry {
        load();
    }

    shown = [r for r in places if _matches(r, filter, query)];
    picked = [r for r in shown if r.id == selected];

    return <div className="flex flex-col gap-5 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <div className="flex flex-col gap-1">
            <h1 className="text-3xl font-bold tracking-tight">{"Explore"}</h1>
            <p className="text-sm text-muted-foreground">{"Participating restaurants and cafes around you. Tap a pin to see live rewards."}</p>
        </div>
        <div className="relative">
            <HugeiconsIcon icon={Search01Icon} strokeWidth={2} className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-muted-foreground" />
            <Input value={query} onChange={lambda (e: ChangeEvent) { query = e.target.value; }} placeholder="Search coffee, tacos, Riverside, free drink..." className="h-12 rounded-2xl bg-card pl-11 text-base shadow-sm" />
        </div>
        <div className="no-scrollbar -ml-4 -mr-4 flex gap-2 overflow-x-auto pl-4 pr-4">
            {for f in FILTERS {
                <button key={f} onClick={lambda { filter = f; }} className={"inline-flex shrink-0 items-center gap-1 rounded-full pt-2 pb-2 pl-3.5 pr-3.5 text-sm font-medium transition-colors " + ("bg-charcoal text-white shadow-sm" if f == filter else "bg-card ring-1 ring-border hover:bg-muted")}>
                    {f == "Flash Drops" and <HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-3.5 text-yellow-500" />}
                    {f}
                </button>
            }}
        </div>

        {loading and <Skeleton className="h-[26rem] w-full rounded-3xl" />}
        {error and <p className="text-sm text-destructive">{error}</p>}

        {not loading and <div className="grid min-w-0 grid-cols-1 gap-5 lg:grid-cols-5">
            <div className="relative isolate h-[26rem] overflow-hidden rounded-3xl border bg-muted shadow-sm lg:col-span-3 lg:h-[34rem]">
                <RestaurantPinMap places={shown} center={center} selected={selected} onSelect={lambda (rid: str) { selected = rid; }} />
                <div className="pointer-events-none absolute right-3 top-3 z-[1000] flex flex-wrap justify-end gap-1.5 text-[11px] font-semibold">
                    <span className="rounded-full bg-card/95 pt-1 pb-1 pl-2.5 pr-2.5 shadow-sm">{str(len(shown)) + " spots"}</span>
                    <span className="rounded-full bg-yellow-400 pt-1 pb-1 pl-2.5 pr-2.5 text-charcoal shadow-sm">{"Flash Drop"}</span>
                    <span className="rounded-full bg-sky-500/90 pt-1 pb-1 pl-2.5 pr-2.5 text-white shadow-sm">{"Your area (approx.)"}</span>
                </div>
                {len(picked) > 0 and <PinSheet place={picked[0]} onView={lambda (rid: str) { navigate("/restaurant/" + rid); }} onClose={lambda { selected = ""; }} />}
            </div>

            <div className="flex flex-col gap-3 lg:col-span-2 lg:max-h-[34rem] lg:overflow-y-auto">
                <p className="text-sm font-medium text-muted-foreground tabular-nums">{str(len(shown)) + (" spot" if len(shown) == 1 else " spots") + " on BiteLoop"}</p>
                {if len(shown) == 0 {
                    <Empty className="rounded-3xl border border-dashed bg-card pt-10 pb-10">
                        <EmptyHeader>
                            <EmptyMedia variant="icon"><HugeiconsIcon icon={Store01Icon} strokeWidth={2} /></EmptyMedia>
                            <EmptyTitle>{"No spots match"}</EmptyTitle>
                            <EmptyDescription>{"Try a different search or clear the filter."}</EmptyDescription>
                        </EmptyHeader>
                        <EmptyContent><Button variant="outline" onClick={lambda { filter = "All"; query = ""; }}>{"Clear filters"}</Button></EmptyContent>
                    </Empty>
                    skip;
                }}
                {for r in shown {
                    <Link key={r.id} to={"/restaurant/" + r.id} className="flex items-center gap-3 rounded-2xl border bg-card pt-3 pb-3 pl-3 pr-3 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md">
                        <img src={r.cover_image} alt={r.name} className="size-16 shrink-0 rounded-xl object-cover" />
                        <div className="min-w-0 flex-1">
                            <div className="flex items-center gap-1">
                                <p className="truncate font-semibold">{r.name}</p>
                                {r.verified and <HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} className="size-4 shrink-0 text-sky-500" />}
                            </div>
                            <p className="flex items-center gap-2 text-xs text-muted-foreground">
                                <span className="inline-flex items-center gap-0.5"><HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-3" />{str(r.distance) + " mi"}</span>
                                <span className="inline-flex items-center gap-0.5"><HugeiconsIcon icon={StarIcon} strokeWidth={2} className="size-3" />{str(r.rating)}</span>
                                <span>{r.cuisine + " · " + r.neighborhood}</span>
                            </p>
                        </div>
                        {<Badge className={"shrink-0 " + ("bg-yellow-400 text-charcoal" if r.has_flash else "")}>{str(r.active_rewards) + " live"}</Badge> if r.active_rewards > 0 else <Badge variant="outline" className="shrink-0">{"Quiet"}</Badge>}
                    </Link>
                }}
            </div>
        </div>}
    </div>;
}
