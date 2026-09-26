"""BiteLoop server: participating restaurants, rewards, claims, missions and the user profile.

The app's own graph is the source of truth for participation, rewards, claims,
redemptions, missions and points. Place metadata (name, address, coordinates,
hours) comes through a PlacesProvider; the demo uses MockPlacesProvider data,
and every seeded business is flagged f"sample=True".
"""
import time;
import math;
import random;

# ---------------------------------------------------------------- graph nodes

node Restaurant {
    has rid: str,
        name: str,
        category: str = "restaurant",
        cuisine: str = "",
        neighborhood: str = "",
        description: str = "",
        address: str = "",
        lat: float = 0.0,
        lng: float = 0.0,
        phone: str = "",
        website: str = "",
        hours: str = "",
        logo: str = "",
        cover_image: str = "",
        photos: list[str] = [],
        menu: list[str] = [],
        tags: list[str] = [],
        price_level: int = 1,
        rating: float = 4.5,
        verified: bool = True,
        sample: bool = True,
        owner_id: str = "",
        checkin_token: str = "",
        created_at: float = 0.0;
}

node Reward {
    has restaurant_id: str,
        title: str,
        description: str = "",
        reward_type: str = "free_food",
        kind: str = "standard",
        quantity: int = 20,
        remaining_quantity: int = 20,
        start_time: float = 0.0,
        end_time: float = 0.0,
        duration_hours: float = 4.0,
        requirements: str = "",
        value: float = 5.0,
        image: str = "",
        min_purchase: float = 0.0,
        max_per_user: int = 1,
        featured: bool = False,
        sponsored: bool = False,
        sample: bool = True,
        status: str = "active";
}

node Claim {
    has reward_id: str = "",
        restaurant_id: str = "",
        restaurant_name: str = "",
        title: str = "",
        image: str = "",
        kind: str = "standard",
        reward_type: str = "free_food",
        instructions: str = "",
        claim_code: str = "",
        backup_code: str = "",
        claimed_at: float = 0.0,
        expires_at: float = 0.0,
        redeemed_at: float = 0.0,
        reveal: str = "",
        status: str = "active";
}

node Mission {
    has key: str,
        title: str,
        description: str = "",
        requirements: str = "",
        reward: str = "",
        points: int = 50,
        target: int = 1,
        progress: int = 0,
        group: str = "mission",
        min_points: int = 0,
        completed: bool = False,
        completed_at: float = 0.0,
        start_time: float = 0.0,
        end_time: float = 0.0;
}

node UserProfile {
    has name: str = "Riley Park",
        username: str = "rileybites",
        email: str = "riley@example.com",
        profile_image: str = "",
        points: int = 120,
        streak: int = 2,
        favorite_categories: list[str] = [],
        dietary: list[str] = [],
        radius: float = 2.0,
        location: str = "Downtown",
        personalized: bool = True,
        onboarded: bool = False,
        discovered: list[str] = [],
        visits: list[str] = [],
        visit_days: list[str] = [],
        checkins: list[str] = [],
        referral_code: str = "RILEY-7Q2",
        created_at: float = 0.0;
}

# ---------------------------------------------------------------- view models

obj RewardView {
    has id: str,
        restaurant_id: str,
        restaurant_name: str,
        restaurant_logo: str,
        category: str,
        neighborhood: str,
        title: str,
        description: str,
        reward_type: str,
        kind: str,
        quantity: int,
        remaining: int,
        minutes_left: int,
        released_minutes_ago: int,
        requirements: str,
        value: float,
        image: str,
        min_purchase: float,
        distance: float,
        featured: bool,
        sponsored: bool,
        sample: bool,
        verified: bool,
        claimed: bool;
}

obj RestaurantView {
    has id: str,
        name: str,
        category: str,
        cuisine: str,
        neighborhood: str,
        description: str,
        address: str,
        logo: str,
        cover_image: str,
        tags: list[str],
        price_level: int,
        rating: float,
        distance: float,
        map_x: float,
        map_y: float,
        active_rewards: int,
        has_flash: bool,
        reward_titles: list[str],
        verified: bool,
        sample: bool;
}

obj RestaurantDetail {
    has restaurant: RestaurantView,
        phone: str,
        website: str,
        hours: str,
        photos: list[str],
        menu: list[str],
        rewards: list[RewardView],
        past_rewards: list[str],
        reviews: list[dict];
}

obj FeedView {
    has location: str,
        radius: float,
        onboarded: bool,
        points: int,
        featured: RewardView | None,
        flash: list[RewardView],
        rewards: list[RewardView];
}

obj ClaimView {
    has id: str,
        restaurant_id: str,
        restaurant_name: str,
        title: str,
        image: str,
        kind: str,
        instructions: str,
        claim_code: str,
        backup_code: str,
        minutes_left: int,
        redeemed_label: str,
        reveal: str,
        status: str;
}

obj MissionView {
    has id: str,
        key: str,
        title: str,
        description: str,
        reward: str,
        points: int,
        target: int,
        progress: int,
        group: str,
        locked: bool,
        min_points: int,
        completed: bool;
}

obj ProfileView {
    has name: str,
        username: str,
        points: int,
        streak: int,
        level: str,
        next_level_points: int,
        favorite_categories: list[str],
        radius: float,
        location: str,
        personalized: bool,
        discovered_count: int,
        neighborhoods: list[str],
        redeemed_count: int,
        referral_code: str,
        achievements: list[dict],
        friends: list[dict];
}

obj DashboardView {
    has restaurant_name: str,
        restaurant_id: str,
        verified: bool,
        plan: str,
        impressions: int,
        active_rewards: int,
        claims: int,
        redemptions: int,
        new_customers: int,
        returning_customers: int,
        acquisition_cost: float,
        revenue: float,
        checkin_token: str,
        rewards: list[RewardView];
}

obj CheckinView {
    has valid: bool,
        message: str,
        bonus: int = 0,
        restaurant: RestaurantView | None = None,
        rewards: list[RewardView] = [];
}

obj ActionResult {
    has ok: bool,
        message: str,
        claim_id: str = "",
        points_earned: int = 0;
}

# ---------------------------------------------------------------- endpoints

def:pub get_feed(location: str = "", radius: float = 0.0) -> FeedView;
def:pub get_restaurants(location: str = "") -> list[RestaurantView];
def:pub get_restaurant(rid: str) -> RestaurantDetail | None;
def:pub claim_reward(reward_id: str) -> ActionResult;
def:pub get_wallet() -> list[ClaimView];
def:pub redeem_claim(claim_id: str, code: str) -> ActionResult;
def:pub get_missions() -> list[MissionView];
def:pub get_profile() -> ProfileView;
def:pub save_preferences(
    categories: list[str], radius: float, location: str, personalized: bool
) -> ProfileView;
def:pub get_dashboard() -> DashboardView;
def:pub create_reward(
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
) -> ActionResult;
def:pub flash_drop(title: str, quantity: int, minutes: int) -> ActionResult;
def:pub get_checkin(rid: str, token: str) -> CheckinView;
def:pub scan_claim(reward_id: str, rid: str, token: str) -> ActionResult;
def:pub rotate_checkin(rid: str) -> ActionResult;
