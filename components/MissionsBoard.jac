import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Target02Icon, Fire02Icon, LockIcon, Tick02Icon, Award01Icon, Coffee02Icon, UserGroupIcon, SparklesIcon, Route01Icon, Store01Icon
}
import from .ui.skeleton { Skeleton }
import from .ui.button { Button }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription }
sv import from ..services.biteloop { get_missions, MissionView }

def _icon(key: str) -> any {
    if "coffee" in key { return Coffee02Icon; }
    if "friend" in key { return UserGroupIcon; }
    if "mystery" in key { return SparklesIcon; }
    if "explorer" in key { return Route01Icon; }
    if "first" in key or "foodie" in key { return Store01Icon; }
    if "chef" in key { return Award01Icon; }
    return Target02Icon;
}

def:pub MissionCard(m: MissionView) -> JsxElement {
    pct = int(m.progress * 100 / m.target) if m.target > 0 else 0;
    tone = "bg-primary/12 text-primary";
    if m.completed { tone = "bg-success/15 text-success"; }
    if m.locked { tone = "bg-muted text-muted-foreground"; }
    return <article className={"flex flex-col gap-4 rounded-3xl border bg-card pt-5 pb-5 pl-5 pr-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md " + ("opacity-75" if m.locked else "")}>
        <div className="flex items-start gap-3">
            <div className={"flex size-12 shrink-0 items-center justify-center rounded-2xl " + tone}>
                <HugeiconsIcon icon={LockIcon if m.locked else (Tick02Icon if m.completed else _icon(m.key))} strokeWidth={2} className="size-6" />
            </div>
            <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-2">
                    <h3 className="text-lg font-bold tracking-tight">{m.title}</h3>
                    <span className="shrink-0 rounded-full bg-charcoal pt-0.5 pb-0.5 pl-2.5 pr-2.5 text-xs font-bold text-white tabular-nums">{"+" + str(m.points) + " pts"}</span>
                </div>
                <p className="text-sm text-muted-foreground">{m.description}</p>
            </div>
        </div>
        <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-between text-xs font-semibold">
                <span className="tabular-nums">{("Unlocks at " + str(m.min_points) + " Bite Points") if m.locked else (str(m.progress) + " of " + str(m.target))}</span>
                <span className={"text-success" if m.completed else "text-muted-foreground"}>{"Completed" if m.completed else m.reward}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-muted">
                <div className={"h-full rounded-full transition-all duration-700 " + ("bg-success" if m.completed else "bg-primary")} style={{"width": ("0" if m.locked else str(pct)) + "%"}} />
            </div>
            {not m.completed and not m.locked and m.target - m.progress == 1 and <p className="text-xs font-semibold text-primary">{"One visit away from completing"}</p>}
        </div>
    </article>;
}

def:pub MissionsBoard() -> JsxElement {
    has missions: list[MissionView] = [],
        loading: bool = True,
        error: str = "",
        tab: str = "active";

    async def load -> None {
        try {
            missions = await get_missions();
        } except Exception as e {
            error = "Could not load missions. " + str(e);
        }
        loading = False;
    }

    can with entry {
        load();
    }

    core = [m for m in missions if m.group == "mission"];
    streaks = [m for m in missions if m.group == "streak"];
    active = [m for m in core if not m.completed];
    done = [m for m in core if m.completed];
    shown = active if tab == "active" else done;

    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <section className="relative overflow-hidden rounded-[2rem] bg-charcoal pt-7 pb-7 pl-6 pr-6 text-white shadow-xl md:pl-8">
            <div className="pointer-events-none absolute -right-16 -top-16 size-64 rounded-full bg-primary/40 blur-3xl" />
            <div className="relative flex flex-col gap-2">
                <span className="inline-flex w-fit items-center gap-1 rounded-full bg-primary pt-1 pb-1 pl-2.5 pr-2.5 text-[11px] font-bold uppercase tracking-wide">{"Bite Missions"}</span>
                <h1 className="text-3xl font-bold tracking-tight md:text-4xl">{"Explore more. Unlock more."}</h1>
                <p className="max-w-lg text-sm text-white/75">{"Missions reward discovery and coming back, not spending. Complete them to earn Bite Points and unlock exclusive drops."}</p>
                <p className="text-sm font-semibold tabular-nums">{str(len(done)) + " of " + str(len(core)) + " missions completed"}</p>
            </div>
        </section>

        {loading and <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3"><Skeleton className="h-40 rounded-3xl" /><Skeleton className="h-40 rounded-3xl" /><Skeleton className="h-40 rounded-3xl" /></div>}
        {error and <p className="text-sm text-destructive">{error}</p>}

        {not loading and <div className="flex flex-col gap-8">
            <section className="flex flex-col gap-4">
                <div className="flex w-fit gap-1 rounded-full bg-muted pt-1 pb-1 pl-1 pr-1">
                    <button onClick={lambda { tab = "active"; }} className={"rounded-full pt-1.5 pb-1.5 pl-4 pr-4 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if tab == "active" else "text-muted-foreground")}>{"Active (" + str(len(active)) + ")"}</button>
                    <button onClick={lambda { tab = "done"; }} className={"rounded-full pt-1.5 pb-1.5 pl-4 pr-4 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if tab == "done" else "text-muted-foreground")}>{"Completed (" + str(len(done)) + ")"}</button>
                </div>
                {if len(shown) == 0 {
                    <Empty className="rounded-3xl border border-dashed bg-card pt-10 pb-10">
                        <EmptyHeader>
                            <EmptyMedia variant="icon"><HugeiconsIcon icon={Target02Icon} strokeWidth={2} /></EmptyMedia>
                            <EmptyTitle>{"No completed missions yet" if tab == "done" else "All missions complete"}</EmptyTitle>
                            <EmptyDescription>{"Claim and redeem a reward at a new spot to finish your first mission."}</EmptyDescription>
                        </EmptyHeader>
                        <Link to="/"><Button>{"Find a reward"}</Button></Link>
                    </Empty>
                    skip;
                }}
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                    {for m in shown { <MissionCard key={m.id} m={m} /> }}
                </div>
            </section>
            <section className="flex flex-col gap-4">
                <div className="flex items-center gap-2">
                    <HugeiconsIcon icon={Fire02Icon} strokeWidth={2} className="size-5 text-primary" />
                    <h2 className="text-xl font-bold tracking-tight">{"Streaks"}</h2>
                    <span className="text-sm text-muted-foreground">{"Optional, built for exploring"}</span>
                </div>
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                    {for m in streaks { <MissionCard key={m.id} m={m} /> }}
                </div>
            </section>
        </div>}
    </div>;
}
