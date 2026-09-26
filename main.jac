import from services.biteloop {
    get_feed, get_restaurants, get_restaurant, claim_reward, get_wallet, redeem_claim,
    get_missions, get_profile, save_preferences, get_dashboard, create_reward, flash_drop, get_checkin, scan_claim, rotate_checkin, get_reward, CheckinView,
    Restaurant, Reward, Claim, Mission, UserProfile, RewardView, RestaurantView,
    RestaurantDetail, FeedView, ClaimView, MissionView, ProfileView, DashboardView, ActionResult
}

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, Navigate, AuthGuard }
import from .components.LoginPage { LoginPage }
import from .components.ui.sonner_toast { Toaster }
import from .components.BottomNav { BottomNav }
import from .components.HomeFeed { HomeFeed }
import from .components.OnboardingFlow { OnboardingFlow }
import from .components.ExploreMap { ExploreMap }
import from .components.RestaurantProfile { RestaurantProfile }
import from .components.MissionsBoard { MissionsBoard }
import from .components.WalletScreen { WalletScreen }
import from .components.ProfileScreen { ProfileScreen }
import from .components.BusinessDashboard { BusinessDashboard }
import from .components.ScanClaim { ScanClaim }
import from .components.StoreDisplay { StoreDisplay }
import from .components.ClaimVerify { ClaimVerify }

def:pub AppFrame(children: any = None) -> JsxElement {
    return <div className="min-h-svh bg-background">
        <BottomNav />
        <main className="md:pl-60">
            <div className="mx-auto w-full max-w-6xl pt-5 pb-28 pl-4 pr-4 sm:pl-6 sm:pr-6 md:pt-8 md:pb-12 lg:pl-10 lg:pr-10">
                {children}
            </div>
        </main>
    </div>;
}

def:pub app() -> JsxElement {
    return <Router>
        <Toaster position="top-center" richColors={True} />
        <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<AuthGuard redirect="/login" />}>
                <Route path="/" element={<AppFrame><HomeFeed /></AppFrame>} />
                <Route path="/onboarding" element={<OnboardingFlow />} />
                <Route path="/explore" element={<AppFrame><ExploreMap /></AppFrame>} />
                <Route path="/restaurant/:id" element={<AppFrame><RestaurantProfile /></AppFrame>} />
                <Route path="/missions" element={<AppFrame><MissionsBoard /></AppFrame>} />
                <Route path="/wallet" element={<AppFrame><WalletScreen /></AppFrame>} />
                <Route path="/profile" element={<AppFrame><ProfileScreen /></AppFrame>} />
                <Route path="/business" element={<AppFrame><BusinessDashboard /></AppFrame>} />
                <Route path="/business/display" element={<StoreDisplay />} />
                <Route path="/verify/:rewardId" element={<AppFrame><ClaimVerify /></AppFrame>} />
                <Route path="/scan/:rid/:token" element={<AppFrame><ScanClaim /></AppFrame>} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace={True} />} />
        </Routes>
    </Router>;
}
