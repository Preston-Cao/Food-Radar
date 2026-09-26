import from react { useEffect }
import from "react-leaflet" { MapContainer, TileLayer, Marker, Circle, useMap }
import from leaflet { divIcon, latLngBounds }
sv import from ..services.biteloop { RestaurantView }

glob TILE_URL: str = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
glob TILE_ATTR: str = "&copy; OpenStreetMap contributors";

"""HTML pin: orange bubble with the live reward count; yellow for Flash Drops, charcoal when selected."""
def _pin(place: RestaurantView, selected: bool) -> any {
    bg = "#f06a1c";
    fg = "#ffffff";
    if place.has_flash {
        bg = "#facc15";
        fg = "#1f1a17";
    }
    if selected {
        bg = "#1f1a17";
        fg = "#ffffff";
    }
    bolt = "<svg width=\"11\" height=\"11\" viewBox=\"0 0 24 24\" fill=\"currentColor\"><path d=\"M13 2 4 14h7l-1 8 9-12h-7z\"/></svg>" if place.has_flash else "";
    count = str(place.active_rewards) if place.active_rewards > 0 else "0";
    scale = "scale(1.15)" if selected else "scale(1)";
    html = "<div style=\"transform:translate(-50%,-100%) " + scale + ";display:flex;flex-direction:column;align-items:center;transition:transform .2s\">"
        + "<div style=\"display:flex;align-items:center;gap:4px;padding:3px 9px 3px 3px;border-radius:999px;background:" + bg + ";color:" + fg + ";font:700 12px/1 sans-serif;box-shadow:0 4px 12px rgba(0,0,0,.25);border:2px solid #fff;white-space:nowrap\">"
        + "<img src=\"" + place.logo + "\" style=\"width:22px;height:22px;border-radius:999px;object-fit:cover\"/>"
        + bolt + count + "</div>"
        + "<div style=\"width:10px;height:10px;background:" + bg + ";transform:rotate(45deg);margin-top:-6px;border-right:2px solid #fff;border-bottom:2px solid #fff\"></div></div>";
    return divIcon({"html": html, "className": "", "iconSize": [0, 0]});
}

"""Re-fits the view to the visible pins whenever the filtered set changes."""
def:pub FitToPlaces(places: list[RestaurantView], center: list[float]) -> JsxElement {
    map_: any = useMap();
    key = ",".join([p.id for p in places]);
    useEffect(lambda {
        if len(places) == 0 {
            map_.setView(center, 14);
        } elif len(places) == 1 {
            map_.setView([places[0].lat, places[0].lng], 15);
        } else {
            map_.fitBounds(latLngBounds([[p.lat, p.lng] for p in places]), {"padding": [40, 40], "maxZoom": 15});
        }
    }, [key]);
    return <span />;
}

"""Interactive Explore map with reward pins and a translucent approximate-area circle."""
def:pub RestaurantPinMap(
    places: list[RestaurantView], center: list[float], selected: str, onSelect: Callable[[str], None]
) -> JsxElement {
    return <MapContainer center={center} zoom={14} scrollWheelZoom={True} zoomControl={True} className="size-full" style={{"zIndex": 0}}>
        <TileLayer url={TILE_URL} attribution={TILE_ATTR} />
        <Circle center={center} radius={450} pathOptions={{"color": "#0ea5e9", "weight": 1, "fillColor": "#0ea5e9", "fillOpacity": 0.12}} />
        {for p in places {
            <Marker key={p.id} position={[p.lat, p.lng]} icon={_pin(p, p.id == selected)} zIndexOffset={1000 if p.id == selected else 0}
                eventHandlers={{"click": lambda { onSelect(p.id); }}} />
        }}
        <FitToPlaces places={places} center={center} />
    </MapContainer>;
}

"""Small static location map for a restaurant profile."""
def:pub LocationPreview(place: RestaurantView) -> JsxElement {
    return <div className="h-40 overflow-hidden rounded-xl ring-1 ring-border">
        <MapContainer center={[place.lat, place.lng]} zoom={15} className="size-full" style={{"zIndex": 0}}
            dragging={False} scrollWheelZoom={False} doubleClickZoom={False} touchZoom={False} zoomControl={False} keyboard={False} attributionControl={False}>
            <TileLayer url={TILE_URL} />
            <Marker position={[place.lat, place.lng]} icon={_pin(place, True)} interactive={False} />
        </MapContainer>
    </div>;
}
