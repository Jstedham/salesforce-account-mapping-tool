import { LightningElement, api } from 'lwc';

export default class AccountMap extends LightningElement {
    @api mapMarkers;
    @api center;
    @api zoomLevel;

    handleMarkerSelect(event) {
        const markerValue = event.detail.selectedMarkerValue;
        
        const markerSelectEvent = new CustomEvent('accountselect', {
            detail: markerValue
        });
        this.dispatchEvent(markerSelectEvent);
        console.log('MARKER VALUE: ' + markerValue);
    }
}