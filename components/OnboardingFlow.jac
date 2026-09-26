import from "@jac/runtime" { useNavigate }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Location01Icon, Target02Icon, Store01Icon, Ticket01Icon, Tick02Icon, ArrowRight01Icon
}
import from .ui.button { Button }
import from .ui.progress { Progress }
import from .BottomNav { BrandMark }
sv import from ..services.biteloop { save_preferences }

glob SLIDES: list[dict] = [
    {"title": "Find free bites near you.", "text": "Local cafes and restaurants drop free drinks, samples and surprise rewards every day.", "icon": Location01Icon, "img": "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1200&q=80&auto=format&fit=crop"},
    {"title": "Complete missions.", "text": "Bring a friend, try something new, or crawl three cafes. Missions turn eating out into a game.", "icon": Target02Icon, "img": "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=1200&q=80&auto=format&fit=crop"},
    {"title": "Discover local restaurants.", "text": "Every spot on BiteLoop has joined to meet new neighbors, and verified businesses carry a badge.", "icon": Store01Icon, "img": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=80&auto=format&fit=crop"},
    {"title": "Unlock rewards.", "text": "Claim, visit, show your code. Earn Bite Points that unlock exclusive drops and experiences.", "icon": Ticket01Icon, "img": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=1200&q=80&auto=format&fit=crop"}
];

glob CATEGORIES: list[str] = ["Coffee", "Bakery", "Dessert", "Mexican", "Japanese", "Pizza", "Burgers", "Healthy", "Vegan", "Late night"];
glob AREAS: list[str] = ["Downtown", "Riverside", "Old Mill", "Harbor District"];
glob RADII: list[float] = [0.5, 1.0, 2.0, 5.0, 10.0];

def:pub OnboardingFlow() -> JsxElement {
    has step: int = 0,
        cats: list[str] = ["Coffee"],
        area: str = "Downtown",
        radius: float = 2.0,
        locating: bool = False,
        saving: bool = False;

    navigate = useNavigate();

    def toggle(c: str) {
        if c in cats {
            cats = [x for x in cats if x != c];
        } else {
            cats = cats + [c];
        }
    }

    def use_location() {
        locating = True;
        geo: any = navigator.geolocation;
        if geo {
            geo.getCurrentPosition(
                lambda (pos: any) { locating = False; area = "Downtown"; toast.success("Location found. Showing spots near Downtown."); },
                lambda (err: any) { locating = False; toast("Location unavailable. Pick your area below."); }
            );
        } else {
            locating = False;
            toast("Location unavailable. Pick your area below.");
        }
    }

    async def finish -> None {
        saving = True;
        try {
            await save_preferences(cats, radius, area, True);
            localStorage.setItem("bl_onboarded", "1");
            navigate("/");
        } except Exception as e {
            toast.error("Could not save preferences. " + str(e));
        }
        saving = False;
    }

    total = len(SLIDES) + 1;
    is_setup = step >= len(SLIDES);
    slide = SLIDES[min(step, len(SLIDES) - 1)];

    return <div className="grid min-h-svh bg-background lg:grid-cols-2">
        <div className="relative hidden overflow-hidden bg-charcoal lg:block">
            <img key={slide["img"]} src={slide["img"]} alt="" className="absolute inset-0 size-full object-cover opacity-80 animate-in fade-in duration-700" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-black/10" />
            <div className="relative flex h-full flex-col justify-between pt-10 pb-10 pl-10 pr-10 text-white">
                <BrandMark inverted={True} />
                <div className="flex max-w-md flex-col gap-3">
                    <p className="text-4xl font-bold leading-tight tracking-tight">{"Discover. Do. Get rewarded."}</p>
                    <p className="text-white/80">{"Free bites. Local spots. New discoveries."}</p>
                </div>
            </div>
        </div>
        <div className="flex flex-col pt-6 pb-8 pl-6 pr-6 sm:pl-10 sm:pr-10">
            <div className="flex items-center justify-between">
                <BrandMark />
                {not is_setup and <button onClick={lambda { step = len(SLIDES); }} className="text-sm font-medium text-muted-foreground hover:text-foreground">{"Skip"}</button>}
            </div>
            <Progress value={(step + 1) * 100 / total} className="mt-5 h-1.5" />
            <div className="flex flex-1 items-center justify-center pt-8 pb-8">
                {<div key={"slide" + str(step)} className="flex w-full max-w-md flex-col gap-6 animate-in fade-in slide-in-from-right-4 duration-500">
                    <div className="relative aspect-[4/3] overflow-hidden rounded-[2rem] shadow-xl lg:hidden">
                        <img src={slide["img"]} alt="" className="size-full object-cover" />
                    </div>
                    <div className="flex size-14 items-center justify-center rounded-2xl bg-primary/12 text-primary">
                        <HugeiconsIcon icon={slide["icon"]} strokeWidth={2} className="size-7" />
                    </div>
                    <div className="flex flex-col gap-2">
                        <p className="text-sm font-semibold text-primary">{"Step " + str(step + 1) + " of " + str(total)}</p>
                        <h1 className="text-4xl font-bold leading-tight tracking-tight">{slide["title"]}</h1>
                        <p className="text-lg text-muted-foreground">{slide["text"]}</p>
                    </div>
                    <div className="flex gap-1.5">
                        {for (i, s) in enumerate(SLIDES) {
                            <span key={s["title"]} className={"h-2 rounded-full transition-all " + ("w-8 bg-primary" if i == step else "w-2 bg-border")} />
                        }}
                    </div>
                    <Button size="lg" className="h-12 rounded-xl text-base font-semibold" onClick={lambda { step = step + 1; }}>
                        {"Continue"}<HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} />
                    </Button>
                </div> if not is_setup else <div className="flex w-full max-w-md flex-col gap-7 animate-in fade-in slide-in-from-right-4 duration-500">
                    <div className="flex flex-col gap-2">
                        <h1 className="text-3xl font-bold tracking-tight">{"Make it yours"}</h1>
                        <p className="text-muted-foreground">{"Three quick choices. You can change them anytime in Profile."}</p>
                    </div>
                    <section className="flex flex-col gap-3">
                        <h2 className="font-semibold">{"Where are you?"}</h2>
                        <Button variant="outline" className="h-11 justify-start rounded-xl" onClick={use_location} disabled={locating}>
                            <HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="text-primary" />
                            {"Finding you..." if locating else "Use my approximate location"}
                        </Button>
                        <div className="flex flex-wrap gap-2">
                            {for a in AREAS {
                                <button key={a} onClick={lambda { area = a; }} className={"rounded-full pt-2 pb-2 pl-3.5 pr-3.5 text-sm font-medium transition-colors " + ("bg-charcoal text-white" if a == area else "bg-muted hover:bg-secondary")}>{a}</button>
                            }}
                        </div>
                        <p className="text-xs text-muted-foreground">{"We only use an approximate area and never show your location to anyone."}</p>
                    </section>
                    <section className="flex flex-col gap-3">
                        <h2 className="font-semibold">{"What do you love?"}</h2>
                        <div className="flex flex-wrap gap-2">
                            {for c in CATEGORIES {
                                <button key={c} onClick={lambda { toggle(c); }} className={"inline-flex items-center gap-1.5 rounded-full border pt-2 pb-2 pl-3.5 pr-3.5 text-sm font-medium transition-all " + ("border-primary bg-primary text-primary-foreground shadow-sm" if c in cats else "bg-card hover:border-primary/50")}>
                                    {c in cats and <HugeiconsIcon icon={Tick02Icon} strokeWidth={2.5} className="size-3.5" />}
                                    {c}
                                </button>
                            }}
                        </div>
                    </section>
                    <section className="flex flex-col gap-3">
                        <h2 className="font-semibold">{"How far will you go?"}</h2>
                        <div className="grid grid-cols-5 gap-2">
                            {for r in RADII {
                                <button key={str(r)} onClick={lambda { radius = r; }} className={"rounded-xl pt-2.5 pb-2.5 text-sm font-semibold tabular-nums transition-colors " + ("bg-primary text-primary-foreground" if r == radius else "bg-muted hover:bg-secondary")}>{str(r) + " mi"}</button>
                            }}
                        </div>
                    </section>
                    <Button size="lg" className="h-12 rounded-xl text-base font-semibold" onClick={finish} disabled={saving}>{"Saving..." if saving else "Show me nearby bites"}</Button>
                </div>}
            </div>
        </div>
    </div>;
}
