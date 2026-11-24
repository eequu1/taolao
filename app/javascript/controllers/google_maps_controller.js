import { Controller } from "@hotwired/stimulus"
import GMaps from 'gmaps';

export default class extends Controller {
  static values = { markers: Array }

  connect() {

    this.requestUserLocation();

    const urlParams = new URLSearchParams(window.location.search);
    const userLat = parseFloat(urlParams.get('user_lat'));
    const userLng = parseFloat(urlParams.get('user_lng'));

    const initialLat = userLat || 0;
    const initialLng = userLng || 0;
    const map = new GMaps({ el: '#map', lat: initialLat, lng: initialLng });

    const markers = this.markersValue;

    if (userLat && userLng) {
      map.setCenter(userLat, userLng);
      map.setZoom(13);

      map.addMarker({
        lat: userLat,
        lng: userLng,
        title: "Your location"
      });
    }

    if (markers && markers.length > 0) {
      map.addMarkers(markers);

      if (userLat && userLng) {
        const bounds = markers.map(m => ({ lat: m.lat, lng: m.lng }));
        bounds.push({ lat: userLat, lng: userLng });
        map.fitLatLngBounds(bounds);
      }
    }
  }

  requestUserLocation() {
    const urlParams = new URLSearchParams(window.location.search);

    if (navigator.geolocation && !urlParams.has('user_lat')) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          urlParams.set('user_lat', position.coords.latitude);
          urlParams.set('user_lng', position.coords.longitude);
          window.location.search = urlParams.toString();
        },
      );
    }
  }
}
