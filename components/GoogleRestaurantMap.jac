import from react { useEffect }
import from "@vis.gl/react-google-maps" { APIProvider, Map, AdvancedMarker, useMap, useApiLoadingStatus }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Location01Icon, Route01Icon, MapsIcon }
import from .RestaurantMap { RestaurantPinMap, LocationPreview }
sv import from ..services.biteloop { RestaurantView }

"""Google Maps browser key (hardcoded by request; restrict it by HTTP referrer in Google Cloud)."""
glob MAPS_KEY: str = "AIzaSyBeExHQY6xB0xW96IpBH5cwgW4Mx4RCTtA";
glob MAP_ID: str = "DEMO_MAP_ID";

"""Links that open Google Maps on the device (app on phones, web on desktop)."""
def:pub directions_url(lat: float, lng: float) -> str {
    return "https://www.google.com/maps/dir/?api=1&destination=" + str(lat) + "," + str(lng);
}

def:pub place_url(name: str, lat: float, lng: float) -> str {
    _ = name;
    return "https://www.google.com/maps/search/?api=1&query=" + str(lat) + "," + str(lng);
}

def:pub GPin(place: RestaurantView, selected: bool) -> JsxElement {
    bg = "bg-primary text-primary-foreground";
    if place.has_flash { bg = "bg-yellow-400 text-charcoal"; }
    if selected { bg = "bg-charcoal text-white"; }
    return <div className={"flex cursor-pointer flex-col items-center transition-transform duration-200 " + ("scale-125" if selected else "hover:scale-110")}>
        <div className={"flex items-center gap-1 rounded-full border-2 border-white pt-0.5 pb-0.5 pl-0.5 pr-2.5 text-xs font-bold shadow-lg " + bg}>
            <img src={place.logo} alt="" className="size-6 rounded-full object-cover" />
            {place.has_flash and <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 4 14h7l-1 8 9-12h-7z" /></svg>}
            {str(place.active_rewards)}
        </div>
        <div className={"-mt-1.5 size-2.5 rotate-45 border-b-2 border-r-2 border-white " + bg} />
    </div>;
}

"""Fits the map to the visible pins when the filtered set changes; pans to the selected pin."""
def:pub GFit(places: list[RestaurantView], center: list[float], selected: str, recenterTick: int) -> JsxElement {
    gmap: any = useMap();
    key = ",".join([p.id for p in places]);
    useEffect(lambda {
        if not gmap {
            return;
        }
        if len(places) == 0 {
            gmap.setCenter({"lat": center[0], "lng": center[1]});
            gmap.setZoom(14);
        } elif len(places) == 1 {
            gmap.setCenter({"lat": places[0].lat, "lng": places[0].lng});
            gmap.setZoom(16);
        } else {
            w: any = window;
            bounds: any = new(w.google.maps.LatLngBounds);
            for p in places {
                bounds.extend({"lat": p.lat, "lng": p.lng});
            }
            gmap.fitBounds(bounds, {"top": 56, "bottom": 120, "left": 40, "right": 40});
        }
    }, [gmap, key, recenterTick]);
    useEffect(lambda {
        if not gmap or not selected {
            return;
        }
        for p in places {
            if p.id == selected {
                gmap.panTo({"lat": p.lat, "lng": p.lng});
            }
        }
    }, [gmap, selected]);
    return <span />;
}

"""Approximate-area circle (neighborhood center, never an exact location)."""
def:pub GAreaCircle(center: list[float]) -> JsxElement {
    gmap: any = useMap();
    useEffect(lambda {
        if not gmap {
            return lambda {};
        }
        w: any = window;
        g: any = w.google;
        circle: any = new(g.maps.Circle, {
            "map": gmap, "center": {"lat": center[0], "lng": center[1]}, "radius": 450,
            "strokeColor": "#0ea5e9", "strokeWeight": 1, "fillColor": "#0ea5e9", "fillOpacity": 0.12, "clickable": False
        });
        return lambda { circle.setMap(None); };
    }, [gmap, center[0], center[1]]);
    return <span />;
}

"""Overlay shown while Google loads, or if the key is rejected / the script fails."""
def:pub MapStatus(fallback: any = None) -> JsxElement {
    status = useApiLoadingStatus();
    if status == "FAILED" or status == "AUTH_FAILURE" {
        return <div className="absolute inset-0 z-10">
            {fallback}
            <div className="pointer-events-none absolute inset-x-3 top-3 rounded-xl bg-card/95 pt-2 pb-2 pl-3 pr-3 text-xs font-medium text-muted-foreground shadow">
                {"Google Maps couldn't load (check the API key's allowed websites). Showing a basic map instead."}
            </div>
        </div>;
    }
    if status != "LOADED" {
        return <div className="absolute inset-0 z-10 flex items-center justify-center bg-muted">
            <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <HugeiconsIcon icon={MapsIcon} strokeWidth={2} className="size-5 animate-pulse text-primary" />{"Loading Google Maps..."}
            </div>
        </div>;
    }
    return <span />;
}

"""Explore map on Google Maps: reward pins, area circle, fit-to-results, recenter."""
def:pub ExploreGoogleMap(
    places: list[RestaurantView], center: list[float], selected: str, onSelect: Callable[[str], None]
) -> JsxElement {
    has recenterTick: int = 0;
    return <APIProvider apiKey={MAPS_KEY}>
        <div className="relative size-full">
            <Map mapId={MAP_ID} defaultCenter={{"lat": center[0], "lng": center[1]}} defaultZoom={14}
                gestureHandling="greedy" disableDefaultUI={True} zoomControl={True} fullscreenControl={True}
                clickableIcons={False} className="size-full">
                <GAreaCircle center={center} />
                {for p in places {
                    <AdvancedMarker key={p.id} position={{"lat": p.lat, "lng": p.lng}} zIndex={1000 if p.id == selected else 1}
                        title={p.name + " · " + str(p.active_rewards) + " live rewards"} onClick={lambda { onSelect(p.id); }}>
                        <GPin place={p} selected={p.id == selected} />
                    </AdvancedMarker>
                }}
                <GFit places={places} center={center} selected={selected} recenterTick={recenterTick} />
            </Map>
            <button type="button" onClick={lambda { recenterTick = recenterTick + 1; }}
                className="absolute bottom-24 left-3 z-20 flex items-center gap-1.5 rounded-full bg-card pt-2 pb-2 pl-3 pr-3.5 text-xs font-semibold shadow-md ring-1 ring-border transition-colors hover:bg-muted">
                <HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-4 text-primary" />{"Recenter"}
            </button>
            <MapStatus fallback={<RestaurantPinMap places={places} center={center} selected={selected} onSelect={onSelect} />} />
        </div>
    </APIProvider>;
}

"""Restaurant location card: small Google map plus Directions / Open in Maps actions."""
def:pub GoogleLocationPreview(place: RestaurantView) -> JsxElement {
    actions = <div className="grid grid-cols-2 gap-2">
        <a href={directions_url(place.lat, place.lng)} target="_blank" rel="noreferrer"
            className="flex items-center justify-center gap-1.5 rounded-lg bg-primary pt-2 pb-2 text-xs font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90">
            <HugeiconsIcon icon={Route01Icon} strokeWidth={2} className="size-4" />{"Directions"}
        </a>
        <a href={place_url(place.name, place.lat, place.lng)} target="_blank" rel="noreferrer"
            className="flex items-center justify-center gap-1.5 rounded-lg bg-muted pt-2 pb-2 text-xs font-semibold transition-colors hover:bg-secondary">
            <HugeiconsIcon icon={MapsIcon} strokeWidth={2} className="size-4" />{"Open in Google Maps"}
        </a>
    </div>;
    return <div className="flex flex-col gap-2">
        <div className="relative h-44 overflow-hidden rounded-xl ring-1 ring-border">
            <APIProvider apiKey={MAPS_KEY}>
                <Map mapId={MAP_ID} defaultCenter={{"lat": place.lat, "lng": place.lng}} defaultZoom={16}
                    gestureHandling="cooperative" disableDefaultUI={True} zoomControl={True} clickableIcons={False} className="size-full">
                    <AdvancedMarker position={{"lat": place.lat, "lng": place.lng}} title={place.name}><GPin place={place} selected={True} /></AdvancedMarker>
                </Map>
                <MapStatus fallback={<LocationPreview place={place} />} />
            </APIProvider>
        </div>
        {actions}
    </div>;
}
