import from "@jac/runtime" { Link }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Fire02Icon, Award01Icon, Store01Icon, Location01Icon, Share01Icon, LockIcon, Tick02Icon, Restaurant01Icon, ArrowRight01Icon
}
import from .ui.button { Button }
import from .ui.skeleton { Skeleton }
import from .ui.avatar { Avatar, AvatarFallback }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
sv import from ..services.biteloop { get_profile, save_preferences, ProfileView }

def:pub StatTile(label: str, value: str, icon: any) -> JsxElement {
    return <div className="flex flex-col gap-2 rounded-2xl border bg-card pt-4 pb-4 pl-4 pr-4 shadow-sm">
        <span className="flex size-9 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={icon} strokeWidth={2} className="size-4" /></span>
        <span className="text-2xl font-bold tracking-tight tabular-nums">{value}</span>
        <span className="text-xs text-muted-foreground">{label}</span>
    </div>;
}

def:pub ProfileScreen() -> JsxElement {
    has profile: ProfileView | None = None,
        loading: bool = True,
        error: str = "";

    async def load -> None {
        try {
            profile = await get_profile();
        } except Exception as e {
            error = "Could not load your profile. " + str(e);
        }
        loading = False;
    }

    async def toggle_personal(p: ProfileView) -> None {
        profile = await save_preferences(p.favorite_categories, p.radius, p.location, not p.personalized);
        toast.success("Personalization " + ("on" if not p.personalized else "off"));
    }

    can with entry {
        load();
    }

    if loading {
        return <div className="flex flex-col gap-4"><Skeleton className="h-44 rounded-3xl" /><div className="grid grid-cols-2 gap-3 md:grid-cols-4"><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /></div></div>;
    }
    if profile is None {
        return <div className="flex items-center gap-3 text-sm text-destructive">{error or "Profile unavailable."}<Button size="sm" variant="outline" onClick={lambda { loading = True; load(); }}>{"Retry"}</Button></div>;
    }
    return <ProfileBody p={profile} onTogglePersonal={toggle_personal} />;
}

def:pub ProfileBody(p: ProfileView, onTogglePersonal: Callable[[ProfileView], None]) -> JsxElement {
    pct = min(100, int(p.points * 100 / p.next_level_points));
    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <section className="relative overflow-hidden rounded-[2rem] bg-primary pt-6 pb-6 pl-6 pr-6 text-primary-foreground shadow-xl md:pl-8 md:pr-8">
            <div className="pointer-events-none absolute -right-20 -top-20 size-72 rounded-full bg-white/15 blur-3xl" />
            <div className="relative flex flex-col gap-5 sm:flex-row sm:items-center">
                <Avatar className="size-20 ring-4 ring-white/30"><AvatarFallback className="bg-charcoal text-2xl font-bold text-white">{"RP"}</AvatarFallback></Avatar>
                <div className="flex flex-1 flex-col gap-1">
                    <h1 className="text-2xl font-bold tracking-tight">{p.name}</h1>
                    <p className="text-sm text-primary-foreground/80">{"@" + p.username + " · " + p.level}</p>
                    <div className="mt-2 flex flex-col gap-1.5">
                        <div className="flex justify-between text-xs font-semibold tabular-nums"><span>{str(p.points) + " Bite Points"}</span><span>{"Next level at " + str(p.next_level_points)}</span></div>
                        <div className="h-2 overflow-hidden rounded-full bg-white/25"><div className="h-full rounded-full bg-white transition-all duration-700" style={{"width": str(pct) + "%"}} /></div>
                    </div>
                </div>
            </div>
        </section>

        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <StatTile label="Day streak" value={str(p.streak)} icon={Fire02Icon} />
            <StatTile label="Spots discovered" value={str(p.discovered_count)} icon={Store01Icon} />
            <StatTile label="Neighborhoods explored" value={str(len(p.neighborhoods))} icon={Location01Icon} />
            <StatTile label="Rewards redeemed" value={str(p.redeemed_count)} icon={Award01Icon} />
        </div>

        <div className="grid gap-6 lg:grid-cols-5">
            <Card className="shadow-sm lg:col-span-3">
                <CardHeader>
                    <CardTitle>{"Achievements"}</CardTitle>
                    <CardDescription>{"Points unlock higher-level missions, exclusive drops and experiences, not unlimited free food."}</CardDescription>
                </CardHeader>
                <CardContent className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                    {for a in p.achievements {
                        <div key={a["title"]} className={"flex flex-col items-center gap-2 rounded-2xl pt-4 pb-4 pl-3 pr-3 text-center " + ("bg-primary/10" if a["earned"] else "bg-muted/60")}>
                            <span className={"flex size-11 items-center justify-center rounded-full " + ("bg-primary text-primary-foreground" if a["earned"] else "bg-muted text-muted-foreground")}>
                                <HugeiconsIcon icon={Tick02Icon if a["earned"] else LockIcon} strokeWidth={2} className="size-5" />
                            </span>
                            <span className="text-sm font-semibold leading-tight">{a["title"]}</span>
                            <span className="text-xs text-muted-foreground">{a["desc"]}</span>
                        </div>
                    }}
                </CardContent>
            </Card>
            <Card className="shadow-sm lg:col-span-2">
                <CardHeader>
                    <CardTitle>{"Friends"}</CardTitle>
                    <CardDescription>{"Activity only. Locations are never shared."}</CardDescription>
                </CardHeader>
                <CardContent className="flex flex-col gap-4">
                    {for f in p.friends {
                        <div key={f["name"]} className="flex items-center gap-3">
                            <Avatar className="size-9"><AvatarFallback className="bg-secondary text-xs font-semibold">{f["initials"]}</AvatarFallback></Avatar>
                            <div className="min-w-0 flex-1">
                                <p className="text-sm"><span className="font-semibold">{f["name"]}</span>{" " + f["text"]}</p>
                                <p className="text-xs text-muted-foreground">{f["ago"]}</p>
                            </div>
                        </div>
                    }}
                </CardContent>
            </Card>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
            <Card className="shadow-sm">
                <CardHeader>
                    <CardTitle>{"Invite friends"}</CardTitle>
                    <CardDescription>{"You both get an intro reward after your friend's first redemption. One reward per verified new friend."}</CardDescription>
                </CardHeader>
                <CardContent className="flex items-center gap-3">
                    <span className="flex-1 rounded-xl bg-muted pt-2.5 pb-2.5 pl-4 pr-4 font-mono font-bold tracking-wider">{p.referral_code}</span>
                    <Button variant="outline" onClick={lambda { navigator.clipboard.writeText(p.referral_code); toast.success("Invite code copied"); }}><HugeiconsIcon icon={Share01Icon} strokeWidth={2} />{"Copy code"}</Button>
                </CardContent>
            </Card>
            <Card className="shadow-sm">
                <CardHeader>
                    <CardTitle>{"Preferences"}</CardTitle>
                    <CardDescription>{"Favorites: " + (", ".join(p.favorite_categories) or "none yet") + " · " + p.location + " · " + str(p.radius) + " mi"}</CardDescription>
                </CardHeader>
                <CardContent className="flex flex-wrap gap-2">
                    <Button variant={"default" if p.personalized else "outline"} onClick={lambda { onTogglePersonal(p); }}>{"Personalized feed: " + ("On" if p.personalized else "Off")}</Button>
                    <Link to="/onboarding"><Button variant="outline">{"Edit favorites"}</Button></Link>
                </CardContent>
            </Card>
        </div>

        <Link to="/business" className="group flex items-center gap-4 rounded-3xl bg-charcoal pt-5 pb-5 pl-5 pr-5 text-white shadow-lg transition-transform hover:-translate-y-0.5">
            <span className="flex size-12 items-center justify-center rounded-2xl bg-primary"><HugeiconsIcon icon={Restaurant01Icon} strokeWidth={2} className="size-6" /></span>
            <div className="flex-1">
                <p className="font-bold">{"Switch to Restaurant Mode"}</p>
                <p className="text-sm text-white/70">{"Create rewards, trigger Flash Drops and see today's performance."}</p>
            </div>
            <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-5 transition-transform group-hover:translate-x-1" />
        </Link>
    </div>;
}
