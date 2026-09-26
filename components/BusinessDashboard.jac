import from "@jac/runtime" { Link }
import from "sonner" { toast }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowLeft01Icon, CheckmarkBadge01Icon, Ticket01Icon, Analytics01Icon, QrCode01Icon,
    UserGroupIcon, UserIcon, DollarCircleIcon, FlashIcon, ChartHistogramIcon, PlusSignIcon, Upload01Icon
}
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.badge { Badge }
import from .ui.skeleton { Skeleton }
import from .ui.field { Field, FieldLabel, FieldGroup }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .RewardCard { time_left, money }
import from "qrcode.react" { QRCodeSVG }

"""Photo picker: drag-and-drop or tap to choose; resizes in the browser to a compact JPEG data URL."""
def:pub PhotoUpload(image: str, onChange: Callable[[str], None]) -> JsxElement {
    has dragging: bool = False,
        busy: bool = False;

    def read_file(file: any) {
        if not file {
            return;
        }
        if not str(file.type).startswith("image/") {
            toast.error("Choose an image file (JPG, PNG or WebP).");
            return;
        }
        if file.size > 10 * 1024 * 1024 {
            toast.error("That photo is over 10 MB. Pick a smaller one.");
            return;
        }
        busy = True;
        reader: any = new(FileReader);
        reader.onload = lambda (ev: any) {
            img: any = new(Image);
            img.onload = lambda {
                maxw = 1200;
                scale = min(1.0, maxw / img.width);
                canvas: any = document.createElement("canvas");
                canvas.width = int(img.width * scale);
                canvas.height = int(img.height * scale);
                canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
                onChange(canvas.toDataURL("image/jpeg", 0.8));
                busy = False;
            };
            img.onerror = lambda { busy = False; toast.error("Could not read that image."); };
            img.src = ev.target.result;
        };
        reader.readAsDataURL(file);
    }

    def on_pick(e: ChangeEvent) {
        target: any = e.target;
        read_file(target.files[0]);
        target.value = "";
    }

    def on_drop(e: any) {
        e.preventDefault();
        dragging = False;
        read_file(e.dataTransfer.files[0]);
    }

    return <Field>
        <FieldLabel htmlFor="reward-photo">{"Food or drink photo"}</FieldLabel>
        {<div className="relative overflow-hidden rounded-2xl border bg-muted">
            <img src={image} alt="Reward photo preview" className="aspect-[16/10] w-full object-cover" />
            <div className="absolute bottom-2 right-2 flex gap-2">
                <label htmlFor="reward-photo" className="cursor-pointer rounded-lg bg-white/95 pt-1.5 pb-1.5 pl-3 pr-3 text-xs font-semibold text-charcoal shadow">{"Replace"}</label>
                <button type="button" onClick={lambda { onChange(""); }} className="rounded-lg bg-white/95 pt-1.5 pb-1.5 pl-3 pr-3 text-xs font-semibold text-destructive shadow">{"Remove"}</button>
            </div>
        </div> if image else <label
            htmlFor="reward-photo"
            onDragOver={lambda (e: any) { e.preventDefault(); dragging = True; }}
            onDragLeave={lambda { dragging = False; }}
            onDrop={on_drop}
            className={"flex cursor-pointer flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed pt-8 pb-8 pl-4 pr-4 text-center transition-colors " + ("border-primary bg-primary/5" if dragging else "border-border bg-muted/40 hover:border-primary/50")}
        >
            <span className="flex size-11 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Upload01Icon} strokeWidth={2} className="size-5" /></span>
            <span className="text-sm font-semibold">{"Processing photo..." if busy else "Upload a photo"}</span>
            <span className="text-xs text-muted-foreground">{"Drag and drop or tap to choose · JPG, PNG, WebP up to 10 MB"}</span>
        </label>}
        <input id="reward-photo" type="file" accept="image/*" className="hidden" onChange={on_pick} />
    </Field>;
}

"""Printable in-store QR poster. Scanning it opens /scan/<rid>/<token>, which proves presence."""
def:pub StoreQrCard(rid: str, name: str, token: str, storeCode: str, onRotate: Callable[[], None], rotating: bool = False) -> JsxElement {
    url = window.location.origin + "/scan/" + rid + "/" + token;
    return <Card className="shadow-sm print:shadow-none">
        <CardHeader>
            <CardTitle className="flex items-center gap-2"><HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} className="size-5 text-primary" />{"In-store QR code"}</CardTitle>
            <CardDescription>{"Print this and place it at the counter. Customers scan it with their phone camera to check in and claim rewards, so rewards can only be claimed on-site."}</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center gap-4">
            <div id="store-qr-poster" className="flex w-full flex-col items-center gap-3 rounded-3xl bg-primary pt-6 pb-6 pl-6 pr-6 text-center text-primary-foreground">
                <p className="text-xs font-bold uppercase tracking-widest">{"BiteLoop"}</p>
                <p className="text-xl font-bold leading-tight">{"Scan for a free bite at " + name}</p>
                <div className="rounded-2xl bg-white pt-3 pb-3 pl-3 pr-3 shadow-lg">
                    <QRCodeSVG value={url} size={180} level="M" fgColor="#1f1a17" />
                </div>
                <p className="text-xs text-primary-foreground/85">{"Open your camera and point it at the code"}</p>
                <div className="flex flex-col items-center gap-1 rounded-2xl bg-white/15 pt-2 pb-2 pl-5 pr-5">
                    <span className="text-[10px] font-bold uppercase tracking-widest">{"Or enter store code"}</span>
                    <span className="font-mono text-3xl font-extrabold tracking-[0.3em]">{storeCode}</span>
                </div>
            </div>
            <div className="flex w-full flex-wrap gap-2">
                <Button className="flex-1" onClick={lambda { window.print(); }}>{"Print poster"}</Button>
                <a href={url} target="_blank" rel="noreferrer" className="flex-1"><Button variant="outline" className="w-full">{"Test scan link"}</Button></a>
            </div>
            <Link to="/business/display" className="w-full"><Button variant="secondary" className="w-full"><HugeiconsIcon icon={QrCode01Icon} strokeWidth={2} />{"Open display mode"}</Button></Link>
            <Button variant="ghost" size="sm" className="text-muted-foreground" disabled={rotating} onClick={lambda { onRotate(); }}>{"Issuing new code..." if rotating else "Refresh code (cancels old posters)"}</Button>
        </CardContent>
    </Card>;
}
sv import from ..services.biteloop { get_dashboard, create_reward, flash_drop, rotate_checkin, DashboardView }

def:pub Metric(label: str, value: str, icon: any) -> JsxElement {
    return <Card className="shadow-sm transition-shadow hover:shadow-md">
        <CardContent className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">{label}</span>
                <span className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={icon} strokeWidth={2} className="size-4" /></span>
            </div>
            <span className="text-3xl font-semibold tracking-tight tabular-nums">{value}</span>
        </CardContent>
    </Card>;
}

def:pub BusinessDashboard() -> JsxElement {
    has dash: DashboardView | None = None,
        loading: bool = True,
        title: str = "",
        desc: str = "",
        qty: str = "30",
        hours: str = "3",
        req: str = "Visit the cafe and check in.",
        value: str = "4.50",
        image: str = "",
        maxPer: str = "1",
        minPurchase: str = "0",
        rtype: str = "free_food",
        saving: bool = False,
        flashTitle: str = "Free drip coffee",
        flashQty: str = "20",
        flashMin: str = "45",
        dropping: bool = False,
        rotating: bool = False;

    async def rotate -> None {
        rotating = True;
        res = await rotate_checkin(dash.restaurant_id if dash else "ember");
        if res.ok { toast.success(res.message); } else { toast.error(res.message); }
        rotating = False;
        await load();
    }

    async def load -> None {
        try {
            dash = await get_dashboard();
        } except Exception as e {
            toast.error("Could not load dashboard. " + str(e));
        }
        loading = False;
    }

    async def submit_reward -> None {
        saving = True;
        res = await create_reward(title, desc, int(qty or "0"), float(hours or "0"), req, float(value or "0"), image, int(maxPer or "1"), float(minPurchase or "0"), rtype);
        if res.ok {
            toast.success(res.message);
            title = "";
            desc = "";
            image = "";
        } else {
            toast.error(res.message);
        }
        saving = False;
        await load();
    }

    async def trigger_flash -> None {
        dropping = True;
        res = await flash_drop(flashTitle, int(flashQty or "0"), int(flashMin or "0"));
        if res.ok { toast.success(res.message); } else { toast.error(res.message); }
        dropping = False;
        await load();
    }

    can with entry {
        load();
    }

    return <div className="flex flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
        <Link to="/profile" className="inline-flex w-fit items-center gap-1 text-sm font-medium text-muted-foreground hover:text-foreground"><HugeiconsIcon icon={ArrowLeft01Icon} strokeWidth={2} className="size-4" />{"Back to customer app"}</Link>
        <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                    <h1 className="text-3xl font-bold tracking-tight">{(dash.restaurant_name if dash else "Ember Coffee")}</h1>
                    {dash and dash.verified and <Badge className="bg-sky-500 text-white"><HugeiconsIcon icon={CheckmarkBadge01Icon} strokeWidth={2} />{"Verified"}</Badge>}
                    <Badge variant="outline">{"Pro plan"}</Badge>
                </div>
                <p className="text-sm text-muted-foreground">{"Restaurant Mode · today's performance on BiteLoop (sample business)"}</p>
            </div>
        </div>

        {loading and <div className="grid grid-cols-2 gap-4 lg:grid-cols-4"><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /><Skeleton className="h-28 rounded-2xl" /></div>}

        {dash and <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <Metric label="Active rewards" value={str(dash.active_rewards)} icon={Ticket01Icon} />
            <Metric label="Claims" value={str(dash.claims)} icon={Analytics01Icon} />
            <Metric label="Redemptions" value={str(dash.redemptions)} icon={QrCode01Icon} />
            <Metric label="Impressions" value={str(dash.impressions)} icon={ChartHistogramIcon} />
            <Metric label="New customers" value={str(dash.new_customers)} icon={UserIcon} />
            <Metric label="Returning customers" value={str(dash.returning_customers)} icon={UserGroupIcon} />
            <Metric label="Cost per new customer" value={money(dash.acquisition_cost)} icon={DollarCircleIcon} />
            <Metric label="Revenue attributed" value={money(dash.revenue)} icon={DollarCircleIcon} />
        </div>}

        <div className="grid gap-6 lg:grid-cols-5">
            <Card className="shadow-sm lg:col-span-3">
                <CardHeader>
                    <CardTitle>{"Create reward"}</CardTitle>
                    <CardDescription>{"Limited-time incentive shown to nearby BiteLoop users."}</CardDescription>
                </CardHeader>
                <CardContent>
                    <FieldGroup>
                        <Field><FieldLabel htmlFor="rt">{"Reward name"}</FieldLabel><Input id="rt" value={title} placeholder="Free chocolate croissant" onChange={lambda (e: ChangeEvent) { title = e.target.value; }} /></Field>
                        <Field><FieldLabel htmlFor="rd">{"Description"}</FieldLabel><Textarea id="rd" value={desc} placeholder="Fresh out of the oven for early visitors." onChange={lambda (e: ChangeEvent) { desc = e.target.value; }} /></Field>
                        <div className="grid grid-cols-2 gap-4">
                            <Field><FieldLabel htmlFor="rq">{"Quantity available"}</FieldLabel><Input id="rq" type="number" value={qty} onChange={lambda (e: ChangeEvent) { qty = e.target.value; }} /></Field>
                            <Field><FieldLabel htmlFor="rh">{"Available for (hours)"}</FieldLabel><Input id="rh" type="number" value={hours} onChange={lambda (e: ChangeEvent) { hours = e.target.value; }} /></Field>
                            <Field><FieldLabel htmlFor="rv">{"Reward value ($)"}</FieldLabel><Input id="rv" type="number" value={value} onChange={lambda (e: ChangeEvent) { value = e.target.value; }} /></Field>
                            <Field><FieldLabel htmlFor="rm">{"Max per customer"}</FieldLabel><Input id="rm" type="number" value={maxPer} onChange={lambda (e: ChangeEvent) { maxPer = e.target.value; }} /></Field>
                            <Field><FieldLabel htmlFor="rp">{"Minimum purchase ($, optional)"}</FieldLabel><Input id="rp" type="number" value={minPurchase} onChange={lambda (e: ChangeEvent) { minPurchase = e.target.value; }} /></Field>
                            <Field>
                                <FieldLabel htmlFor="ty">{"Reward type"}</FieldLabel>
                                <select id="ty" value={rtype} onChange={lambda (e: ChangeEvent) { rtype = e.target.value; }} className="h-9 rounded-md border bg-background pl-3 pr-3 text-sm">
                                    <option value="free_food">{"Free food"}</option>
                                    <option value="free_drink">{"Free drink"}</option>
                                    <option value="upgrade">{"Upgrade"}</option>
                                    <option value="discount">{"Discount"}</option>
                                </select>
                            </Field>
                        </div>
                        <Field><FieldLabel htmlFor="rr">{"Required action"}</FieldLabel><Input id="rr" value={req} onChange={lambda (e: ChangeEvent) { req = e.target.value; }} /></Field>
                        <PhotoUpload image={image} onChange={lambda (v: str) { image = v; }} />
                        <Button className="h-11 w-full sm:w-fit sm:pl-6 sm:pr-6" disabled={saving} onClick={submit_reward}><HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />{"Publishing..." if saving else "Publish reward"}</Button>
                    </FieldGroup>
                </CardContent>
            </Card>

            <div className="flex flex-col gap-6 lg:col-span-2">
                {dash and dash.checkin_token and <StoreQrCard rid={dash.restaurant_id} name={dash.restaurant_name} token={dash.checkin_token} storeCode={dash.store_code} onRotate={rotate} rotating={rotating} />}
                <Card className="border-2 border-yellow-400/70 shadow-sm">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2"><HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-5 text-yellow-500" />{"Flash Drop"}</CardTitle>
                        <CardDescription>{"Slow moment? Release a surprise reward and notify nearby users right now."}</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <FieldGroup>
                            <Field><FieldLabel htmlFor="ft">{"What are you dropping?"}</FieldLabel><Input id="ft" value={flashTitle} onChange={lambda (e: ChangeEvent) { flashTitle = e.target.value; }} /></Field>
                            <div className="grid grid-cols-2 gap-4">
                                <Field><FieldLabel htmlFor="fq">{"How many"}</FieldLabel><Input id="fq" type="number" value={flashQty} onChange={lambda (e: ChangeEvent) { flashQty = e.target.value; }} /></Field>
                                <Field><FieldLabel htmlFor="fm">{"Minutes"}</FieldLabel><Input id="fm" type="number" value={flashMin} onChange={lambda (e: ChangeEvent) { flashMin = e.target.value; }} /></Field>
                            </div>
                            <Button className="h-11 w-full bg-yellow-400 font-bold text-charcoal hover:bg-yellow-300" disabled={dropping} onClick={trigger_flash}><HugeiconsIcon icon={FlashIcon} strokeWidth={2} />{"Releasing..." if dropping else "Release Flash Drop"}</Button>
                        </FieldGroup>
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>{"Live rewards"}</CardTitle></CardHeader>
                    <CardContent className="flex flex-col gap-3">
                        {if dash is None or len(dash.rewards) == 0 {
                            <p className="text-sm text-muted-foreground">{"No live rewards. Publish one to start attracting customers."}</p>
                            skip;
                        }}
                        {for rw in (dash.rewards if dash else []) {
                            <div key={rw.id} className="flex items-center gap-3">
                                <img src={rw.image} alt="" className="size-11 rounded-lg object-cover" />
                                <div className="min-w-0 flex-1">
                                    <p className="truncate text-sm font-semibold">{rw.title}</p>
                                    <p className="text-xs text-muted-foreground tabular-nums">{str(rw.remaining) + " of " + str(rw.quantity) + " left · " + time_left(rw.minutes_left)}</p>
                                </div>
                                {rw.kind == "flash" and <Badge className="bg-yellow-400 text-charcoal">{"Flash"}</Badge>}
                            </div>
                        }}
                    </CardContent>
                </Card>
            </div>
        </div>
    </div>;
}
