import from "@jac/runtime" { Link, useLocation }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Home01Icon, Compass01Icon, Target02Icon, Wallet01Icon, UserIcon, Restaurant01Icon
}

glob NAV_TABS: list[dict] = [
    {"label": "Home", "to": "/", "icon": Home01Icon},
    {"label": "Explore", "to": "/explore", "icon": Compass01Icon},
    {"label": "Missions", "to": "/missions", "icon": Target02Icon},
    {"label": "Wallet", "to": "/wallet", "icon": Wallet01Icon},
    {"label": "Profile", "to": "/profile", "icon": UserIcon}
];

def _is_active(path: str, to: str) -> bool {
    if to == "/" {
        return path == "/" or path.startswith("/restaurant");
    }
    return path.startswith(to);
}

"""BiteLoop brand mark: orange tile with a loop-dish icon plus the wordmark."""
def:pub BrandMark(inverted: bool = False) -> JsxElement {
    tile = "bg-white/15 text-white ring-1 ring-white/25" if inverted else "bg-primary text-primary-foreground shadow-sm";
    return <div className="flex items-center gap-2">
        <div className={"flex size-8 items-center justify-center rounded-xl " + tile}>
            <HugeiconsIcon icon={Restaurant01Icon} strokeWidth={2} className="size-4" />
        </div>
        <span className="text-lg font-bold tracking-tight">{"Bite"}<span className={"text-white/80" if inverted else "text-primary"}>{"Loop"}</span></span>
    </div>;
}

"""Fixed bottom tab bar on phones; a left rail on larger screens."""
def:pub BottomNav() -> JsxElement {
    path = useLocation().pathname;
    if path.startswith("/onboarding") {
        return <span />;
    }
    return <>
        <nav className="fixed inset-x-0 bottom-0 z-40 border-t bg-background/90 backdrop-blur-lg md:hidden">
            <div className="mx-auto grid max-w-lg grid-cols-5 pb-[env(safe-area-inset-bottom)]">
                {for t in NAV_TABS {
                    <Link
                        key={t["to"]}
                        to={t["to"]}
                        className={"flex flex-col items-center gap-1 pt-2.5 pb-2.5 text-[11px] font-medium transition-colors " + ("text-primary" if _is_active(path, t["to"]) else "text-muted-foreground hover:text-foreground")}
                    >
                        <span className={"flex h-7 w-12 items-center justify-center rounded-full transition-colors " + ("bg-primary/12" if _is_active(path, t["to"]) else "")}>
                            <HugeiconsIcon icon={t["icon"]} strokeWidth={2} className="size-5" />
                        </span>
                        {t["label"]}
                    </Link>
                }}
            </div>
        </nav>
        <aside className="fixed inset-y-0 left-0 z-40 hidden w-60 flex-col gap-6 border-r bg-card/70 pt-6 pb-6 pl-4 pr-4 backdrop-blur md:flex">
            <Link to="/" className="pl-2"><BrandMark /></Link>
            <div className="flex flex-col gap-1">
                {for t in NAV_TABS {
                    <Link
                        key={t["to"]}
                        to={t["to"]}
                        className={"flex items-center gap-3 rounded-xl pt-2.5 pb-2.5 pl-3 pr-3 text-sm font-medium transition-colors " + ("bg-primary text-primary-foreground shadow-sm" if _is_active(path, t["to"]) else "text-muted-foreground hover:bg-muted hover:text-foreground")}
                    >
                        <HugeiconsIcon icon={t["icon"]} strokeWidth={2} className="size-5" />
                        {t["label"]}
                    </Link>
                }}
            </div>
            <div className="mt-auto flex flex-col gap-2 rounded-2xl bg-charcoal pt-4 pb-4 pl-4 pr-4 text-white">
                <p className="text-sm font-semibold">{"Own a restaurant?"}</p>
                <p className="text-xs text-white/70">{"Drop rewards and bring new regulars through the door."}</p>
                <Link to="/business" className="mt-1 text-xs font-semibold text-primary hover:underline">{"Open Restaurant Mode"}</Link>
            </div>
        </aside>
    </>;
}
