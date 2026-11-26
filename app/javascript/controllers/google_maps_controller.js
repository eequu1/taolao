import { Controller } from "@hotwired/stimulus"
import GMaps from 'gmaps';

export default class extends Controller {
  static values = {
    markers: Array,
    center: Object
  }

  connect() {
    if (typeof google === 'undefined') return;

    this.requestUserLocation();

    const markers = this.markersValue;
    const center = this.centerValue;

    // 1. Determine center coordinates
    const initialLat = (center && center.lat) ? center.lat : 35.681;
    const initialLng = (center && center.lng) ? center.lng : 139.767;

    const map = new GMaps({ el: '#map', lat: initialLat, lng: initialLng });

    if (initialLat !== 0 && initialLng !== 0) {
      map.setCenter(initialLat, initialLng);
      map.setZoom(12);
    }
    console.log(markers);

    if (markers && markers.length > 0) {
      map.addMarkers(markers);

      if (markers.length > 1) {
        map.fitLatLngBounds(markers);
      }
    }
  }

  requestUserLocation() {
    const urlParams = new URLSearchParams(window.location.search);

    if (navigator.geolocation && !urlParams.has('user_lat') && !urlParams.has('query')) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          urlParams.set('user_lat', position.coords.latitude);
          urlParams.set('user_lng', position.coords.longitude);
          window.location.search = urlParams.toString();
        }
      );
    }
  }
}
