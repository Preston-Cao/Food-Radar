"""Endpoint bodies for BiteLoop. Seed data mimics a MockPlacesProvider response."""

glob IMG: str = "?w=900&q=80&auto=format&fit=crop";
glob U: str = "https://images.unsplash.com/";

# Approximate area centers for manual location selection (never a user's exact position).
glob LOCATIONS: dict[str, list[float]] = {
    "Downtown": [40.7420, -73.9890],
    "Riverside": [40.7480, -74.0040],
    "Old Mill": [40.7330, -73.9960],
    "Harbor District": [40.7360, -73.9790]
};

glob FRIENDS: list[dict] = [
    {"name": "Alex M.", "initials": "AM", "text": "discovered 3 new cafes this week", "ago": "2h ago"},
    {"name": "Jordan L.", "initials": "JL", "text": "completed Coffee Crawl", "ago": "5h ago"},
    {"name": "Sam K.", "initials": "SK", "text": "unlocked a Mystery Bite", "ago": "Yesterday"},
    {"name": "Priya N.", "initials": "PN", "text": "started a 3-Day Explorer streak", "ago": "Yesterday"}
];

glob MYSTERY: list[str] = [
    "Free drink", "Free dessert", "Free topping", "20% off your order", "Free appetizer", "50 bonus Bite Points"
];

def _now -> float {
    return time.time();
}

def _img(photo: str) -> str {
    return U + photo + IMG;
}

def _code(n: int) -> str {
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    return "".join([random.choice(chars) for _ in range(n)]);
}

def _digits(n: int) -> str {
    return "".join([str(random.randint(0, 9)) for _ in range(n)]);
}

def _center(location: str) -> list[float] {
    if location in LOCATIONS {
        return LOCATIONS[location];
    }
    return LOCATIONS["Downtown"];
}

def _miles(lat1: float, lng1: float, lat2: float, lng2: float) -> float {
    r = 3958.8;
    p1 = math.radians(lat1);
    p2 = math.radians(lat2);
    dp = math.radians(lat2 - lat1);
    dl = math.radians(lng2 - lng1);
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2;
    return round(r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 1);
}

def _profile -> UserProfile {
    found = [root-->[?:UserProfile]];
    if len(found) > 0 {
        return found[0];
    }
    p = UserProfile(created_at=_now(), favorite_categories=["Coffee", "Bakery"]);
    root ++> p;
    return p;
}

def _restaurants -> list[Restaurant] {
    return [root-->[?:Restaurant]];
}

def _rest_by_id(rid: str) -> Restaurant | None {
    for r in _restaurants() {
        if r.rid == rid {
            return r;
        }
    }
    return None;
}

def _add_reward(
    rid: str, title: str, desc: str, rtype: str, kind: str, qty: int, left: int,
    hours: float, req: str, value: float, photo: str, featured: bool = False,
    sponsored: bool = False, started_min_ago: int = 30
) -> None {
    now = _now();
    root ++> Reward(
        restaurant_id=rid, title=title, description=desc, reward_type=rtype, kind=kind,
        quantity=qty, remaining_quantity=left, start_time=now - started_min_ago * 60,
        end_time=now + hours * 3600, duration_hours=hours, requirements=req, value=value,
        image=_img(photo), featured=featured, sponsored=sponsored
    );
}

def _seed -> None {
    if len(_restaurants()) > 0 {
        return;
    }
    now = _now();
    places: list[dict] = [
        {"rid": "ember", "name": "Ember Coffee", "category": "cafe", "cuisine": "Coffee", "hood": "Downtown",
         "lat": 40.7431, "lng": -73.9872, "logo": "photo-1509042239860-f550ce710b93",
         "cover": "photo-1554118811-1e0d58224f24", "tags": ["Coffee", "Bakery", "Open now"], "price": 1,
         "desc": "Small-batch roaster with a sunny corner bar and croissants baked every morning.",
         "menu": ["Iced oat latte", "Cortado", "Chocolate croissant", "Cardamom bun"], "rating": 4.8},
        {"rid": "corner", "name": "The Corner", "category": "restaurant", "cuisine": "Burgers", "hood": "Downtown",
         "lat": 40.7402, "lng": -73.9921, "logo": "photo-1568901346375-23c9450c58cd",
         "cover": "photo-1517248135467-4c7edcad34c4", "tags": ["Burgers", "Late night", "Under $10"], "price": 2,
         "desc": "Smash burgers, hand-cut fries and a neon-lit counter that stays open late.",
         "menu": ["Double smash", "Truffle fries", "Crispy chicken sando", "Black and white shake"], "rating": 4.6},
        {"rid": "verde", "name": "Verde Bowl Co.", "category": "restaurant", "cuisine": "Healthy", "hood": "Riverside",
         "lat": 40.7488, "lng": -74.0021, "logo": "photo-1512621776951-a57141f2eefd",
         "cover": "photo-1512621776951-a57141f2eefd", "tags": ["Healthy", "Vegan options", "Open now"], "price": 2,
         "desc": "Grain bowls, pressed juices and seasonal greens from nearby farms.",
         "menu": ["Green goddess bowl", "Miso salmon bowl", "Cold-pressed citrus", "Matcha chia cup"], "rating": 4.7},
        {"rid": "taqueria", "name": "Luna Taqueria", "category": "restaurant", "cuisine": "Mexican", "hood": "Old Mill",
         "lat": 40.7338, "lng": -73.9978, "logo": "photo-1565299585323-38d6b0865b47",
         "cover": "photo-1565299585323-38d6b0865b47", "tags": ["Mexican", "Under $10", "Late night"], "price": 1,
         "desc": "Handmade tortillas, slow-braised birria and a salsa bar with nine house salsas.",
         "menu": ["Birria tacos", "Al pastor", "Elote", "Horchata"], "rating": 4.9},
        {"rid": "crumb", "name": "Crumb and Co.", "category": "cafe", "cuisine": "Bakery", "hood": "Harbor District",
         "lat": 40.7368, "lng": -73.9801, "logo": "photo-1499636136210-6f4ee915583e",
         "cover": "photo-1555507036-ab1f4038808a", "tags": ["Dessert", "Bakery", "Coffee"], "price": 1,
         "desc": "Brown-butter cookies, laminated pastries and a slow drip coffee bar.",
         "menu": ["Brown-butter cookie", "Almond croissant", "Pour over", "Sea salt brownie"], "rating": 4.7},
        {"rid": "nami", "name": "Nami Ramen Bar", "category": "restaurant", "cuisine": "Japanese", "hood": "Riverside",
         "lat": 40.7462, "lng": -73.9990, "logo": "photo-1569718212165-3a8278d5f624",
         "cover": "photo-1569718212165-3a8278d5f624", "tags": ["Japanese", "Late night"], "price": 2,
         "desc": "Rich tonkotsu, spicy miso and crispy gyoza in a twelve-seat noodle bar.",
         "menu": ["Tonkotsu ramen", "Spicy miso", "Pork gyoza", "Yuzu soda"], "rating": 4.8},
        {"rid": "scoop", "name": "Scoop Theory", "category": "cafe", "cuisine": "Dessert", "hood": "Old Mill",
         "lat": 40.7315, "lng": -73.9935, "logo": "photo-1497034825429-c343d7c6a68f",
         "cover": "photo-1497034825429-c343d7c6a68f", "tags": ["Dessert", "Open now"], "price": 1,
         "desc": "Small-batch ice cream with rotating flavors and waffle cones pressed to order.",
         "menu": ["Honey lavender", "Salted caramel", "Waffle cone", "Affogato"], "rating": 4.6},
        {"rid": "slice", "name": "Harbor Slice", "category": "restaurant", "cuisine": "Pizza", "hood": "Harbor District",
         "lat": 40.7352, "lng": -73.9768, "logo": "photo-1513104890138-7c749659a591",
         "cover": "photo-1513104890138-7c749659a591", "tags": ["Pizza", "Under $10", "Late night"], "price": 1,
         "desc": "Naturally leavened slices, hot honey pies and a chalkboard of daily specials.",
         "menu": ["Hot honey slice", "Margherita", "Garlic knots", "Caesar"], "rating": 4.5}
    ];
    for p in places {
        root ++> Restaurant(
            rid=p["rid"], name=p["name"], category=p["category"], cuisine=p["cuisine"],
            neighborhood=p["hood"], description=p["desc"],
            address=f"{random.randint(12, 480)} {p['hood']} Ave",
            lat=p["lat"], lng=p["lng"], phone="(555) 01" + _digits(2) + "-" + _digits(4),
            website="biteloop.app/sample/" + p["rid"], hours="7:00 AM - 10:00 PM",
            logo=_img(p["logo"]), cover_image=_img(p["cover"]),
            photos=[_img(p["cover"]), _img(p["logo"])], menu=p["menu"], tags=p["tags"],
            price_level=p["price"], rating=p["rating"], verified=True, sample=True,
            owner_id=("owner-demo" if p["rid"] == "ember" else ""), created_at=now
        );
    }
    _add_reward("ember", "Free iced latte", "First 20 people today get an iced latte on us.", "free_drink", "hot", 20, 13, 5.0, "Check in at the counter and show your BiteLoop code.", 5.5, "photo-1461023058943-07fcbe16d735", True);
    _add_reward("ember", "Free pastry before 2 PM", "Visit before 2 PM and pick any pastry from the case.", "free_food", "standard", 30, 22, 3.0, "Visit before 2 PM and check in.", 4.0, "photo-1555507036-ab1f4038808a");
    _add_reward("corner", "Free fries", "Surprise drop: a basket of hand-cut fries.", "free_food", "flash", 20, 17, 0.75, "Show up and check in within 45 minutes.", 4.5, "photo-1573080496219-bb080dd4f877", False, False, 3);
    _add_reward("verde", "Free cold-pressed juice", "Try any new bowl and get a juice on the house.", "free_drink", "mission", 25, 18, 6.0, "Order a bowl you have never tried.", 6.0, "photo-1505252585461-04db1eb84625", False, True);
    _add_reward("taqueria", "Free side of elote", "Try something you have never ordered and get a free side.", "free_food", "mission", 40, 31, 8.0, "Order a new menu item.", 4.0, "photo-1565299585323-38d6b0865b47");
    _add_reward("crumb", "Two free cookies", "Bring a friend and you each get a brown-butter cookie.", "free_food", "friend", 30, 12, 6.0, "Visit together with a friend who has BiteLoop.", 7.0, "photo-1499636136210-6f4ee915583e");
    _add_reward("nami", "Free gyoza", "We are slow right now: first 15 people get free gyoza.", "free_food", "flash", 15, 9, 1.0, "Check in at the bar.", 6.5, "photo-1569718212165-3a8278d5f624", False, False, 8);
    _add_reward("scoop", "Mystery Bite", "Check in for a randomized reward: drink, dessert, topping or bonus points.", "mystery", "mystery", 25, 20, 10.0, "Check in at any time today.", 5.0, "photo-1497034825429-c343d7c6a68f");
    _add_reward("slice", "Free hot honey slice", "Post today's special and unlock a free slice.", "free_food", "standard", 20, 6, 4.0, "Share today's special, then check in.", 4.5, "photo-1513104890138-7c749659a591");
    _add_reward("ember", "Free cold brew", "Claim within 45 minutes for a cold brew.", "free_drink", "hot", 12, 12, 0.75, "Check in at the counter.", 4.5, "photo-1517701550927-30cf4ba1dba5");

    missions: list[dict] = [
        {"key": "first_bite", "title": "First Bite", "desc": "Visit a restaurant you have never visited before.", "reward": "Free appetizer or drink", "points": 40, "target": 1, "progress": 0, "group": "mission", "min": 0},
        {"key": "two_timer", "title": "Two-Timer", "desc": "Visit the same restaurant twice within 14 days.", "reward": "Free menu item", "points": 60, "target": 2, "progress": 1, "group": "mission", "min": 0},
        {"key": "friend_bite", "title": "Friend Bite", "desc": "Invite a friend and complete a visit together.", "reward": "Both of you get a reward", "points": 80, "target": 1, "progress": 0, "group": "mission", "min": 0},
        {"key": "mystery_bite", "title": "Mystery Bite", "desc": "Visit a participating spot and receive a randomized reward.", "reward": "Random surprise reward", "points": 30, "target": 1, "progress": 0, "group": "mission", "min": 0},
        {"key": "local_explorer", "title": "Local Explorer", "desc": "Visit 3 participating businesses in one neighborhood.", "reward": "Unlock a special neighborhood reward", "points": 100, "target": 3, "progress": 1, "group": "mission", "min": 0},
        {"key": "coffee_crawl", "title": "Coffee Crawl", "desc": "Visit 3 different cafes.", "reward": "Free premium drink", "points": 90, "target": 3, "progress": 2, "group": "mission", "min": 0},
        {"key": "chef_table", "title": "Chef's Counter", "desc": "Complete 5 missions to unlock a seat at a partner chef's tasting night.", "reward": "Exclusive experience", "points": 250, "target": 5, "progress": 0, "group": "mission", "min": 500},
        {"key": "explorer3", "title": "3-Day Explorer", "desc": "Visit participating businesses on 3 different days.", "reward": "Streak badge + 50 pts", "points": 50, "target": 3, "progress": 2, "group": "streak", "min": 0},
        {"key": "coffee_week", "title": "Coffee Week", "desc": "Visit 4 cafes within 7 days.", "reward": "Coffee Week badge", "points": 70, "target": 4, "progress": 2, "group": "streak", "min": 0},
        {"key": "local_foodie", "title": "Local Foodie", "desc": "Discover 5 restaurants this month.", "reward": "Local Foodie badge", "points": 120, "target": 5, "progress": 2, "group": "streak", "min": 0}
    ];
    for m in missions {
        root ++> Mission(
            key=m["key"], title=m["title"], description=m["desc"], requirements=m["desc"],
            reward=m["reward"], points=m["points"], target=m["target"], progress=m["progress"],
            group=m["group"], min_points=m["min"], start_time=now, end_time=now + 30 * 86400
        );
    }
    _profile();
}

def _refresh_samples -> None {
    now = _now();
    for rw in [root-->[?:Reward]] {
        if rw.sample and rw.end_time < now and rw.status == "active" {
            rw.start_time = now - 600;
            rw.end_time = now + rw.duration_hours * 3600;
            if rw.remaining_quantity <= 0 {
                rw.remaining_quantity = max(3, rw.quantity // 3);
            }
        }
    }
}

def _ensure -> UserProfile {
    _seed();
    _refresh_samples();
    return _profile();
}

def _claimed_ids -> list[str] {
    return [c.reward_id for c in [root-->[?:Claim]] if c.status != "expired"];
}

def _reward_view(rw: Reward, r: Restaurant, center: list[float], claimed: list[str]) -> RewardView {
    now = _now();
    return RewardView(
        id=jid(rw), restaurant_id=r.rid, restaurant_name=r.name, restaurant_logo=r.logo,
        category=r.category, neighborhood=r.neighborhood, title=rw.title,
        description=rw.description, reward_type=rw.reward_type, kind=rw.kind,
        quantity=rw.quantity, remaining=rw.remaining_quantity,
        minutes_left=max(0, int((rw.end_time - now) / 60)),
        released_minutes_ago=max(0, int((now - rw.start_time) / 60)),
        requirements=rw.requirements, value=rw.value, image=rw.image,
        min_purchase=rw.min_purchase, distance=_miles(center[0], center[1], r.lat, r.lng),
        featured=rw.featured, sponsored=rw.sponsored, sample=rw.sample, verified=r.verified,
        claimed=(jid(rw) in claimed)
    );
}

def _live_rewards(center: list[float]) -> list[RewardView] {
    now = _now();
    rmap: dict[str, Restaurant] = {};
    for r in _restaurants() {
        rmap[r.rid] = r;
    }
    claimed = _claimed_ids();
    out: list[RewardView] = [];
    for rw in [root-->[?:Reward]] {
        if rw.status == "active" and rw.end_time > now and rw.restaurant_id in rmap {
            out.append(_reward_view(rw, rmap[rw.restaurant_id], center, claimed));
        }
    }
    return out;
}

def _rest_view(r: Restaurant, center: list[float], live: list[RewardView]) -> RestaurantView {
    mine = [v for v in live if v.restaurant_id == r.rid];
    span = 0.034;
    x = 50.0 + (r.lng - center[1]) / span * 50.0;
    y = 50.0 - (r.lat - center[0]) / span * 50.0;
    return RestaurantView(
        id=r.rid, name=r.name, category=r.category, cuisine=r.cuisine,
        neighborhood=r.neighborhood, description=r.description, address=r.address,
        logo=r.logo, cover_image=r.cover_image, tags=r.tags, price_level=r.price_level,
        rating=r.rating, distance=_miles(center[0], center[1], r.lat, r.lng),
        map_x=max(6.0, min(94.0, x)), map_y=max(8.0, min(92.0, y)),
        lat=r.lat, lng=r.lng,
        active_rewards=len(mine), has_flash=len([v for v in mine if v.kind == "flash"]) > 0,
        reward_titles=[v.title for v in mine], verified=r.verified, sample=r.sample
    );
}

def _score(v: RewardView, favs: list[str], personalized: bool) -> float {
    s = v.distance;
    if v.kind == "flash" {
        s -= 1.0;
    }
    if personalized {
        low = [f.lower() for f in favs];
        if ("coffee" in low and v.reward_type == "free_drink") or ("dessert" in low and v.category == "cafe") {
            s -= 0.6;
        }
    }
    return s;
}

impl get_feed(location: str = "", radius: float = 0.0) -> FeedView {
    p = _ensure();
    if location {
        p.location = location;
    }
    if radius > 0 {
        p.radius = radius;
    }
    center = _center(p.location);
    live = [v for v in _live_rewards(center) if v.distance <= p.radius];
    favs = p.favorite_categories;
    pers = p.personalized;
    live.sort(key=lambda (v: RewardView) -> float { return _score(v, favs, pers); });
    flash = [v for v in live if v.kind == "flash"];
    featured: RewardView | None = None;
    for v in live {
        if v.featured and v.remaining > 0 {
            featured = v;
            break;
        }
    }
    if featured is None and len(live) > 0 {
        featured = live[0];
    }
    rest = [v for v in live if v.kind != "flash" and (featured is None or v.id != featured.id)];
    return FeedView(
        location=p.location, radius=p.radius, onboarded=p.onboarded, points=p.points,
        featured=featured, flash=flash, rewards=rest
    );
}

impl get_restaurants(location: str = "") -> list[RestaurantView] {
    p = _ensure();
    center = _center(location or p.location);
    live = _live_rewards(center);
    views = [_rest_view(r, center, live) for r in _restaurants()];
    views.sort(key=lambda (v: RestaurantView) -> float { return v.distance; });
    return views;
}

"""Center of the user's chosen area, rounded: an approximate neighborhood, never a precise position."""
impl get_map_center() -> list[float] {
    p = _ensure();
    c = _center(p.location);
    return [round(c[0], 3), round(c[1], 3)];
}

"""Browser Maps key (exposed to clients by design; restrict it by HTTP referrer). GOOGLE_MAPS_API_KEY overrides it."""
glob DEFAULT_MAPS_KEY: str = "AIzaSyBeExHQY6xB0xW96IpBH5cwgW4Mx4RCTtA";

impl get_maps_config() -> dict {
    return {
        "api_key": os.environ.get("GOOGLE_MAPS_API_KEY", "").strip() or DEFAULT_MAPS_KEY,
        "map_id": os.environ.get("GOOGLE_MAPS_MAP_ID", "").strip() or "DEMO_MAP_ID"
    };
}

impl get_restaurant(rid: str) -> RestaurantDetail | None {
    p = _ensure();
    r = _rest_by_id(rid);
    if r is None {
        return None;
    }
    center = _center(p.location);
    live = _live_rewards(center);
    rv = _rest_view(r, center, live);
    rewards = [v for v in live if v.restaurant_id == rid];
    past = [rw.title for rw in [root-->[?:Reward]] if rw.restaurant_id == rid and rw.status != "active"];
    if len(past) == 0 {
        past = ["Free drip coffee (last week)", "Bring-a-friend dessert (last month)"];
    }
    reviews: list[dict] = [
        {"name": "Maya R.", "rating": 5, "text": "Came for the reward, stayed for the food. Already been back twice."},
        {"name": "Devon T.", "rating": 4, "text": "Friendly staff, redemption took ten seconds at the counter."}
    ];
    return RestaurantDetail(
        restaurant=rv, phone=r.phone, website=r.website, hours=r.hours, photos=r.photos,
        menu=r.menu, rewards=rewards, past_rewards=past, reviews=reviews
    );
}

"""Claims are only granted with proof of presence: the store's code or its QR token."""
impl claim_reward(reward_id: str, code: str) -> ActionResult {
    _ensure();
    target = jobj(reward_id);
    if not isinstance(target, Reward) {
        return ActionResult(ok=False, message="This reward no longer exists.");
    }
    r = _rest_by_id((target as Reward).restaurant_id);
    if r is None {
        return ActionResult(ok=False, message="This restaurant is not participating right now.");
    }
    entered = code.strip();
    if "/scan/" in entered {
        entered = entered.rstrip("/").split("/")[-1];
    }
    if not entered {
        return ActionResult(ok=False, message="Scan the store's QR code or enter the code staff give you.");
    }
    if entered.upper() != _store_code(r) and entered != _token(r) {
        return ActionResult(ok=False, message="That code doesn't match " + r.name + ". Ask staff for the current BiteLoop code.");
    }
    res = _do_claim(reward_id);
    if res.ok {
        res.message = "Verified at " + r.name + ". Reward claimed and added to your wallet.";
    }
    return res;
}

def _store_code(r: Restaurant) -> str {
    if not r.store_code {
        r.store_code = _code(6);
    }
    return r.store_code;
}

impl get_reward(reward_id: str) -> RewardView | None {
    p = _ensure();
    target = jobj(reward_id);
    if not isinstance(target, Reward) {
        return None;
    }
    rw = target as Reward;
    r = _rest_by_id(rw.restaurant_id);
    if r is None {
        return None;
    }
    return _reward_view(rw, r, _center(p.location), _claimed_ids());
}

def _do_claim(reward_id: str) -> ActionResult {
    p = _ensure();
    now = _now();
    target = jobj(reward_id);
    if not isinstance(target, Reward) {
        return ActionResult(ok=False, message="This reward no longer exists.");
    }
    rw = target as Reward;
    if rw.status != "active" or rw.end_time < now {
        return ActionResult(ok=False, message="This reward has ended.");
    }
    if rw.remaining_quantity <= 0 {
        return ActionResult(ok=False, message="All rewards have been claimed. Check back for the next drop.");
    }
    r = _rest_by_id(rw.restaurant_id);
    if r is None {
        return ActionResult(ok=False, message="This restaurant is not participating right now.");
    }
    if r.owner_id and r.owner_id == "owner-" + p.username {
        return ActionResult(ok=False, message="Owners cannot claim their own promotions.");
    }
    claims = [root-->[?:Claim]];
    mine = [c for c in claims if c.reward_id == reward_id and c.status != "expired"];
    if len(mine) >= rw.max_per_user {
        return ActionResult(ok=False, message="You already claimed this reward.");
    }
    recent = [c for c in claims if c.claimed_at > now - 3600];
    if len(recent) >= 20 {
        return ActionResult(ok=False, message="Too many claims in the last hour. Try again later.");
    }
    rw.remaining_quantity -= 1;
    minutes = 45.0 if rw.kind == "flash" else 180.0;
    expires = min(rw.end_time + 3600, now + minutes * 60);
    reveal = random.choice(MYSTERY) if rw.kind == "mystery" else "";
    c = Claim(
        reward_id=reward_id, restaurant_id=r.rid, restaurant_name=r.name, title=rw.title,
        image=rw.image, kind=rw.kind, reward_type=rw.reward_type,
        instructions=rw.requirements + " Show this code to staff before ordering.",
        claim_code="BL-" + _code(8), backup_code=_digits(6), claimed_at=now,
        expires_at=expires, reveal=reveal, status="active"
    );
    root ++> c;
    return ActionResult(ok=True, message="Claimed " + rw.title + " at " + r.name + ". It is in your wallet.", claim_id=jid(c));
}

impl get_wallet() -> list[ClaimView] {
    _ensure();
    now = _now();
    out: list[ClaimView] = [];
    for c in [root-->[?:Claim]] {
        if c.status == "active" and c.expires_at < now {
            c.status = "expired";
            for rw in [root-->[?:Reward]] {
                if jid(rw) == c.reward_id and rw.status == "active" {
                    rw.remaining_quantity += 1;
                }
            }
        }
        label = "";
        if c.redeemed_at > 0 {
            mins = int((now - c.redeemed_at) / 60);
            label = ("Redeemed " + str(mins) + " min ago") if mins < 120 else ("Redeemed " + str(mins // 60) + " h ago");
        }
        out.append(ClaimView(
            id=jid(c), restaurant_id=c.restaurant_id, restaurant_name=c.restaurant_name,
            title=c.title, image=c.image, kind=c.kind, instructions=c.instructions,
            claim_code=c.claim_code, backup_code=c.backup_code,
            minutes_left=max(0, int((c.expires_at - now) / 60)), redeemed_label=label,
            reveal=(c.reveal if c.status == "redeemed" else ""), status=c.status
        ));
    }
    out.reverse();
    return out;
}

def _bump(key: str, amount: int, p: UserProfile) -> int {
    earned = 0;
    for m in [root-->[?:Mission]] {
        if m.key == key and not m.completed {
            m.progress = min(m.target, m.progress + amount);
            if m.progress >= m.target {
                m.completed = True;
                m.completed_at = _now();
                p.points += m.points;
                earned += m.points;
            }
        }
    }
    return earned;
}

impl redeem_claim(claim_id: str, code: str) -> ActionResult {
    p = _ensure();
    now = _now();
    target = jobj(claim_id);
    if not isinstance(target, Claim) {
        return ActionResult(ok=False, message="Claim not found.");
    }
    c = target as Claim;
    if c.status == "redeemed" {
        return ActionResult(ok=False, message="This code was already redeemed and cannot be used again.");
    }
    if c.status == "expired" or c.expires_at < now {
        c.status = "expired";
        return ActionResult(ok=False, message="This reward has expired.");
    }
    entered = code.strip().upper();
    if entered != c.claim_code and entered != c.backup_code {
        return ActionResult(ok=False, message="That code does not match. Ask staff to scan again or use the backup code.");
    }
    c.status = "redeemed";
    c.redeemed_at = now;
    earned = 25;
    p.points += 25;
    r = _rest_by_id(c.restaurant_id);
    is_new = c.restaurant_id not in p.visits;
    if is_new {
        p.discovered = p.discovered + [c.restaurant_id];
        p.points += 15;
        earned += 15;
        earned += _bump("first_bite", 1, p);
        earned += _bump("local_foodie", 1, p);
        if r is not None and r.category == "cafe" {
            earned += _bump("coffee_crawl", 1, p);
            earned += _bump("coffee_week", 1, p);
        }
        if r is not None {
            same = [v for v in p.visits if (_rest_by_id(v)?.neighborhood or "") == r.neighborhood];
            if len(same) >= 1 {
                earned += _bump("local_explorer", 1, p);
            }
        }
    } else {
        earned += _bump("two_timer", 1, p);
    }
    if c.kind == "mystery" {
        earned += _bump("mystery_bite", 1, p);
    }
    if c.kind == "friend" {
        earned += _bump("friend_bite", 1, p);
    }
    today = time.strftime("%Y-%m-%d");
    if today not in p.visit_days {
        p.visit_days = p.visit_days + [today];
        p.streak += 1;
        earned += _bump("explorer3", 1, p);
    }
    p.visits = p.visits + [c.restaurant_id];
    msg = "Redeemed at " + c.restaurant_name + ". +" + str(earned) + " Bite Points";
    if c.reveal {
        msg = "Mystery revealed: " + c.reveal + ". +" + str(earned) + " Bite Points";
    }
    return ActionResult(ok=True, message=msg, claim_id=claim_id, points_earned=earned);
}

impl get_missions() -> list[MissionView] {
    p = _ensure();
    return [
        MissionView(
            id=jid(m), key=m.key, title=m.title, description=m.description, reward=m.reward,
            points=m.points, target=m.target, progress=m.progress, group=m.group,
            locked=(p.points < m.min_points), min_points=m.min_points, completed=m.completed
        )
        for m in [root-->[?:Mission]]
    ];
}

impl get_profile() -> ProfileView {
    p = _ensure();
    level = "Taster";
    nxt = 250;
    if p.points >= 1000 {
        level = "Local Legend";
        nxt = 2500;
    } elif p.points >= 500 {
        level = "Explorer";
        nxt = 1000;
    } elif p.points >= 250 {
        level = "Regular";
        nxt = 500;
    }
    hoods: list[str] = [];
    for rid in p.discovered {
        rr = _rest_by_id(rid);
        if rr is not None and rr.neighborhood not in hoods {
            hoods.append(rr.neighborhood);
        }
    }
    missions = [root-->[?:Mission]];
    done = len([m for m in missions if m.completed]);
    redeemed = len([c for c in [root-->[?:Claim]] if c.status == "redeemed"]);
    achievements: list[dict] = [
        {"title": "First Claim", "desc": "Claim your first reward", "earned": len([root-->[?:Claim]]) > 0},
        {"title": "First Bite", "desc": "Redeem at a new spot", "earned": redeemed > 0},
        {"title": "Mission Starter", "desc": "Complete a mission", "earned": done > 0},
        {"title": "Neighborhood Hopper", "desc": "Explore 2 neighborhoods", "earned": len(hoods) >= 2},
        {"title": "Streak Keeper", "desc": "Reach a 3-day streak", "earned": p.streak >= 3},
        {"title": "Regular", "desc": "Earn 250 Bite Points", "earned": p.points >= 250}
    ];
    return ProfileView(
        name=p.name, username=p.username, points=p.points, streak=p.streak, level=level,
        next_level_points=nxt, favorite_categories=p.favorite_categories, radius=p.radius,
        location=p.location, personalized=p.personalized, discovered_count=len(p.discovered),
        neighborhoods=hoods, redeemed_count=redeemed, referral_code=p.referral_code,
        achievements=achievements, friends=FRIENDS
    );
}

impl save_preferences(
    categories: list[str], radius: float, location: str, personalized: bool
) -> ProfileView {
    p = _ensure();
    p.favorite_categories = categories[:8];
    if radius in [0.5, 1.0, 2.0, 5.0, 10.0] {
        p.radius = radius;
    }
    if location in LOCATIONS {
        p.location = location;
    }
    p.personalized = personalized;
    p.onboarded = True;
    return get_profile();
}

impl get_dashboard() -> DashboardView {
    p = _ensure();
    r = _rest_by_id("ember");
    center = _center(p.location);
    live = _live_rewards(center);
    mine = [v for v in live if v.restaurant_id == "ember"];
    reward_ids = [jid(rw) for rw in [root-->[?:Reward]] if rw.restaurant_id == "ember"];
    claims = [c for c in [root-->[?:Claim]] if c.reward_id in reward_ids];
    redeemed = [c for c in claims if c.status == "redeemed"];
    base_claims = sum([rw.quantity - rw.remaining_quantity for rw in [root-->[?:Reward]] if rw.restaurant_id == "ember"]);
    total_redeem = int(base_claims * 0.7) + len(redeemed);
    return DashboardView(
        restaurant_name=(r.name if r else "Ember Coffee"), restaurant_id="ember",
        verified=(r.verified if r else False), plan="Pro",
        impressions=1240 + base_claims * 9, active_rewards=len(mine), claims=base_claims,
        redemptions=total_redeem, new_customers=int(total_redeem * 0.62),
        returning_customers=total_redeem - int(total_redeem * 0.62),
        acquisition_cost=3.1, revenue=round(total_redeem * 11.4, 2),
        checkin_token=(_token(r) if r else ""), store_code=(_store_code(r) if r else ""), rewards=mine
    );
}

"""Secret per-restaurant token printed in the in-store QR poster; scanning it proves presence."""
def _token(r: Restaurant) -> str {
    if not r.checkin_token {
        r.checkin_token = _code(16);
    }
    return r.checkin_token;
}

def _checkin_ok(rid: str, token: str) -> Restaurant | None {
    r = _rest_by_id(rid);
    if r is None or not token or _token(r) != token.strip() {
        return None;
    }
    return r;
}

impl get_checkin(rid: str, token: str) -> CheckinView {
    p = _ensure();
    r = _checkin_ok(rid, token);
    if r is None {
        return CheckinView(valid=False, message="This QR code is not valid. Ask staff for the current BiteLoop code.");
    }
    center = _center(p.location);
    live = _live_rewards(center);
    mine = [v for v in live if v.restaurant_id == rid];
    for v in mine {
        v.distance = 0.0;
    }
    # One check-in bonus per restaurant per day; counts toward the daily streak.
    today = time.strftime("%Y-%m-%d");
    key = rid + "@" + today;
    bonus = 0;
    if key not in p.checkins {
        p.checkins = (p.checkins + [key])[-200:];
        bonus = 10;
        p.points += 10;
        if today not in p.visit_days {
            p.visit_days = p.visit_days + [today];
            p.streak += 1;
            bonus += _bump("explorer3", 1, p);
        }
    }
    return CheckinView(valid=True, message="Checked in at " + r.name, bonus=bonus, restaurant=_rest_view(r, center, live), rewards=mine);
}

impl rotate_checkin(rid: str) -> ActionResult {
    _ensure();
    r = _rest_by_id(rid);
    if r is None {
        return ActionResult(ok=False, message="Restaurant not found.");
    }
    r.checkin_token = _code(16);
    r.store_code = _code(6);
    return ActionResult(ok=True, message="New QR code and store code issued. Old posters no longer work, so print the new one.");
}

impl scan_claim(reward_id: str, rid: str, token: str) -> ActionResult {
    _ensure();
    if _checkin_ok(rid, token) is None {
        return ActionResult(ok=False, message="Scan the QR code at the restaurant to claim this reward.");
    }
    target = jobj(reward_id);
    if not isinstance(target, Reward) or (target as Reward).restaurant_id != rid {
        return ActionResult(ok=False, message="This reward is not available at this location.");
    }
    res = _do_claim(reward_id);
    if res.ok {
        res.message = "Checked in and claimed. Show the code from your wallet at the counter.";
    }
    return res;
}

impl create_reward(
    title: str,
    description: str,
    quantity: int,
    hours: float,
    requirements: str,
    value: float,
    image: str,
    max_per_user: int,
    min_purchase: float,
    reward_type: str
) -> ActionResult {
    _ensure();
    t = title.strip();
    if len(t) < 3 {
        return ActionResult(ok=False, message="Give the reward a name of at least 3 characters.");
    }
    if quantity < 1 or quantity > 500 {
        return ActionResult(ok=False, message="Quantity must be between 1 and 500.");
    }
    if hours <= 0 or hours > 72 {
        return ActionResult(ok=False, message="Availability must be between 1 and 72 hours.");
    }
    now = _now();
    pic: str = image.strip();
    if pic.startswith("data:") and not pic.startswith("data:image/") {
        return ActionResult(ok=False, message="The photo must be an image file.");
    }
    if len(pic) > 3000000 {
        return ActionResult(ok=False, message="That photo is too large. Try a smaller image.");
    }
    if pic and not (pic.startswith("data:image/") or pic.startswith("https://")) {
        return ActionResult(ok=False, message="Upload a photo or use an https image link.");
    }
    pic = pic or _img("photo-1555507036-ab1f4038808a");
    rw = Reward(
        restaurant_id="ember", title=t, description=description.strip(),
        reward_type=reward_type or "free_food", kind="standard", quantity=quantity,
        remaining_quantity=quantity, start_time=now, end_time=now + hours * 3600,
        duration_hours=hours, requirements=requirements.strip() or "Visit and check in.",
        value=max(0.0, value), image=pic, min_purchase=max(0.0, min_purchase),
        max_per_user=max(1, min(5, max_per_user)), sample=False
    );
    root ++> rw;
    return ActionResult(ok=True, message=t + " is live for " + str(quantity) + " customers.", claim_id=jid(rw));
}

impl flash_drop(title: str, quantity: int, minutes: int) -> ActionResult {
    _ensure();
    t = title.strip();
    if len(t) < 3 {
        return ActionResult(ok=False, message="Name the Flash Drop first.");
    }
    if quantity < 1 or quantity > 100 {
        return ActionResult(ok=False, message="Flash Drops can release 1 to 100 rewards.");
    }
    now = _now();
    mins = max(10, min(180, minutes));
    rw = Reward(
        restaurant_id="ember", title=t, description="Flash Drop from Ember Coffee.",
        reward_type="free_drink", kind="flash", quantity=quantity, remaining_quantity=quantity,
        start_time=now, end_time=now + mins * 60, duration_hours=mins / 60.0,
        requirements="Check in at the counter before it runs out.", value=5.0,
        image=_img("photo-1509042239860-f550ce710b93"), sample=False
    );
    root ++> rw;
    return ActionResult(ok=True, message="Flash Drop live. Nearby BiteLoop users are being notified.", claim_id=jid(rw));
}
