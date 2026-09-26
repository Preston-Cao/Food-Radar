import from "@jac/runtime" { jacLogin, jacSignup, jacIsLoggedIn, useNavigate, Navigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Location01Icon, Target02Icon, Ticket01Icon }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.field { Field, FieldLabel, FieldGroup }
import from .BottomNav { BrandMark }

glob PERKS: list[dict] = [
    {"icon": Location01Icon, "title": "Free bites nearby", "text": "Live rewards from local cafes and restaurants."},
    {"icon": Target02Icon, "title": "Missions, not coupons", "text": "Explore new spots and level up as you go."},
    {"icon": Ticket01Icon, "title": "Claim and redeem in seconds", "text": "Scan in store, show your code, enjoy."}
];

def:pub LoginPage() -> JsxElement {
    has mode: str = "signin",
        email: str = "",
        password: str = "",
        confirm: str = "",
        busy: bool = False,
        error: str = "";

    navigate = useNavigate();

    async def submit(e: FormEvent) -> None {
        e.preventDefault();
        error = "";
        mail = email.strip().lower();
        if "@" not in mail or "." not in mail {
            error = "Enter a valid email address.";
            return;
        }
        if len(password) < 8 {
            error = "Password must be at least 8 characters.";
            return;
        }
        if mode == "signup" and password != confirm {
            error = "Passwords do not match.";
            return;
        }
        busy = True;
        signup_result: dict | None = None;
        ok: bool = False;
        try {
            if mode == "signup" {
                signup_result = await jacSignup(mail, password);
                if not signup_result["success"] {
                    error = "Could not create the account. That email may already be registered.";
                    busy = False;
                    return;
                }
                localStorage.removeItem("bl_onboarded");
            }
            ok = await jacLogin(mail, password);
            if not ok {
                error = "Incorrect email or password.";
                busy = False;
                return;
            }
            localStorage.setItem("bl_email", mail);
            busy = False;
            navigate("/onboarding" if mode == "signup" else "/");
        } except Exception as ex {
            error = "Something went wrong. Please try again.";
            busy = False;
        }
    }

    if jacIsLoggedIn() {
        return <Navigate to="/" replace={True} />;
    }

    is_signup = mode == "signup";
    return <div className="grid min-h-svh lg:grid-cols-2">
        <div className="relative hidden overflow-hidden bg-charcoal text-white lg:flex lg:flex-col lg:justify-between pt-10 pb-10 pl-10 pr-10">
            <img src="https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1400&q=80&auto=format&fit=crop" alt="" className="absolute inset-0 size-full object-cover opacity-35" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent" />
            <div className="relative"><BrandMark inverted={True} /></div>
            <div className="relative flex max-w-md flex-col gap-8">
                <h1 className="text-balance text-4xl font-bold leading-tight tracking-tight">{"Discover. Do. Get rewarded."}</h1>
                <div className="flex flex-col gap-4">
                    {for p in PERKS {
                        <div key={p["title"]} className="flex items-start gap-3">
                            <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary"><HugeiconsIcon icon={p["icon"]} strokeWidth={2} className="size-5" /></div>
                            <div><p className="font-semibold">{p["title"]}</p><p className="text-sm text-white/70">{p["text"]}</p></div>
                        </div>
                    }}
                </div>
            </div>
            <p className="relative text-sm text-white/70">{"Free bites. Local spots. New discoveries."}</p>
        </div>
        <div className="flex flex-col bg-background pt-8 pb-8 pl-6 pr-6 sm:pl-10 sm:pr-10">
            <div className="lg:hidden"><BrandMark /></div>
            <div className="flex flex-1 items-center justify-center">
                <form onSubmit={submit} className="flex w-full max-w-sm flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
                    <div className="flex flex-col gap-1.5">
                        <h2 className="text-3xl font-bold tracking-tight">{"Create your account" if is_signup else "Welcome back"}</h2>
                        <p className="text-sm text-muted-foreground">{"Start claiming free bites near you." if is_signup else "Sign in to see what's happening near you."}</p>
                    </div>
                    <div className="grid grid-cols-2 gap-1 rounded-full bg-muted pt-1 pb-1 pl-1 pr-1">
                        <button type="button" onClick={lambda { mode = "signin"; error = ""; }} className={"rounded-full pt-2 pb-2 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if not is_signup else "text-muted-foreground")}>{"Sign in"}</button>
                        <button type="button" onClick={lambda { mode = "signup"; error = ""; }} className={"rounded-full pt-2 pb-2 text-sm font-semibold transition-colors " + ("bg-card shadow-sm" if is_signup else "text-muted-foreground")}>{"Create account"}</button>
                    </div>
                    <FieldGroup>
                        <Field>
                            <FieldLabel htmlFor="email">{"Email"}</FieldLabel>
                            <Input id="email" type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={lambda (e: ChangeEvent) { email = e.target.value; }} className="h-11" />
                        </Field>
                        <Field>
                            <FieldLabel htmlFor="password">{"Password"}</FieldLabel>
                            <Input id="password" type="password" autoComplete={"new-password" if is_signup else "current-password"} placeholder="At least 8 characters" value={password} onChange={lambda (e: ChangeEvent) { password = e.target.value; }} className="h-11" />
                        </Field>
                        {is_signup and <Field>
                            <FieldLabel htmlFor="confirm">{"Confirm password"}</FieldLabel>
                            <Input id="confirm" type="password" autoComplete="new-password" placeholder="Repeat your password" value={confirm} onChange={lambda (e: ChangeEvent) { confirm = e.target.value; }} className="h-11" />
                        </Field>}
                    </FieldGroup>
                    {error and <p className="rounded-xl bg-destructive/10 pt-2.5 pb-2.5 pl-3 pr-3 text-sm text-destructive">{error}</p>}
                    <Button type="submit" className="h-11 w-full rounded-xl text-base font-semibold" disabled={busy}>
                        {("Creating account..." if is_signup else "Signing in...") if busy else ("Create account" if is_signup else "Sign in")}
                    </Button>
                    <p className="text-center text-xs text-muted-foreground">{"Restaurant owners use the same account to open Restaurant Mode."}</p>
                </form>
            </div>
        </div>
    </div>;
}
