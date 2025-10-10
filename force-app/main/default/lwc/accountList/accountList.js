import { LightningElement, api } from 'lwc';

export default class AccountList extends LightningElement {
    @api accounts;
    @api totalPages;
    @api pageNumber;

    handleSelect(event) {
        // Dispatch a custom event with the selected account's Id
        const selectedEvent = new CustomEvent('select', {
            detail: event.currentTarget.dataset.id
        });
        this.dispatchEvent(selectedEvent);
    }

    handlePrevious() {
        // Dispatch a custom event to signal the parent to go to the previous page
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleNext() {
        // Dispatch a custom event to signal the parent to go to the next page
        this.dispatchEvent(new CustomEvent('next'));
    }

    get disablePrevious() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }
}