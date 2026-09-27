import from react { useEffect }
import from "@vis.gl/react-google-maps" { APIProvider, Map, AdvancedMarker, useMap }
import from .RestaurantMap { RestaurantPinMap, LocationPreview }
sv import from ..services.biteloop { get_maps_config, RestaurantView }

glob _cfg_cache: dict = {};

"""Loads the Maps key once per session; empty key means use the OpenStreetMap fallback."""
def:pub useMapsConfig() -> dict {
    has cfg: dict = {},
        ready: bool = False;
    async can with entry {
        if _cfg_cache.get("loaded") {
            cfg = _cfg_cache;
        } else {
            try {
                data = await get_maps_config();
                _cfg_cache["api_key"] = data["api_key"];
                _cfg_cache["map_id"] = data["map_id"];
            } except Exception {
                _cfg_cache["api_key"] = "";
                _cfg_cache["map_id"] = "DEMO_MAP_ID";
            }
            _cfg_cache["loaded"] = True;
            cfg = {**_cfg_cache};
        }
        ready = True;
    }
    return {"ready": ready, "key": cfg.get("api_key") or "", "mapId": cfg.get("map_id") or "DEMO_MAP_ID"};
}

def:pub GPin(place: RestaurantView, selected: bool) -> JsxElement {
    bg = "bg-primary text-primary-foreground";
    if place.has_flash { bg = "bg-yellow-400 text-charcoal"; }
    if selected { bg = "bg-charcoal text-white"; }
    return <div className={"flex flex-col items-center transition-transform " + ("scale-115" if selected else "hover:scale-110")}>
        <div className={"flex items-center gap-1 rounded-full border-2 border-white pt-0.5 pb-0.5 pl-0.5 pr-2.5 text-xs font-bold shadow-lg " + bg}>
            <img src={place.logo} alt="" className="size-6 rounded-full object-cover" />
            {place.has_flash and <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 4 14h7l-1 8 9-12h-7z" /></svg>}
            {str(place.active_rewards)}
        </div>
        <div className={"-mt-1.5 size-2.5 rotate-45 border-b-2 border-r-2 border-white " + bg} />
    </div>;
}

"""Fits the Google map to the visible pins when the filtered set changes."""
def:pub GFit(places: list[RestaurantView], center: list[float]) -> JsxElement {
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
            gmap.setZoom(15);
        } else {
            lats = [p.lat for p in places];
            lngs = [p.lng for p in places];
            gmap.fitBounds({"north": max(lats), "south": min(lats), "east": max(lngs), "west": min(lngs)}, 56);
        }
    }, [gmap, key]);
    return <span />;
}

"""Approximate-area circle drawn with the Maps JS API (neighborhood center, never exact location)."""
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

"""Explore map: Google Maps when a key is configured, OpenStreetMap otherwise."""
def:pub ExploreGoogleMap(
    places: list[RestaurantView], center: list[float], selected: str, onSelect: Callable[[str], None]
) -> JsxElement {
    conf = useMapsConfig();
    if not conf["ready"] {
        return <div className="size-full animate-pulse bg-muted" />;
    }
    if not conf["key"] {
        return <RestaurantPinMap places={places} center={center} selected={selected} onSelect={onSelect} />;
    }
    return <APIProvider apiKey={conf["key"]}>
        <Map mapId={conf["mapId"]} defaultCenter={{"lat": center[0], "lng": center[1]}} defaultZoom={14}
            gestureHandling="greedy" disableDefaultUI={True} zoomControl={True} clickableIcons={False} className="size-full">
            <GAreaCircle center={center} />
            {for p in places {
                <AdvancedMarker key={p.id} position={{"lat": p.lat, "lng": p.lng}} zIndex={1000 if p.id == selected else 1}
                    title={p.name} onClick={lambda { onSelect(p.id); }}>
                    <GPin place={p} selected={p.id == selected} />
                </AdvancedMarker>
            }}
            <GFit places={places} center={center} />
        </Map>
    </APIProvider>;
}

"""Restaurant profile location preview: static Google map, or the OpenStreetMap fallback."""
def:pub GoogleLocationPreview(place: RestaurantView) -> JsxElement {
    conf = useMapsConfig();
    if not conf["ready"] {
        return <div className="h-40 animate-pulse rounded-xl bg-muted" />;
    }
    if not conf["key"] {
        return <LocationPreview place={place} />;
    }
    return <a href={"https://www.google.com/maps/search/?api=1&query=" + str(place.lat) + "," + str(place.lng)} target="_blank" rel="noreferrer"
        className="block h-40 overflow-hidden rounded-xl ring-1 ring-border">
        <APIProvider apiKey={conf["key"]}>
            <Map mapId={conf["mapId"]} defaultCenter={{"lat": place.lat, "lng": place.lng}} defaultZoom={15}
                gestureHandling="none" disableDefaultUI={True} clickableIcons={False} className="pointer-events-none size-full">
                <AdvancedMarker position={{"lat": place.lat, "lng": place.lng}}><GPin place={place} selected={True} /></AdvancedMarker>
            </Map>
        </APIProvider>
    </a>;
}
