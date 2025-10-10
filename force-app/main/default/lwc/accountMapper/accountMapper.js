import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAccounts from '@salesforce/apex/AccountMapperController.getAccounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class AccountMapper extends NavigationMixin(LightningElement) {
    @track accounts;
    @track mapMarkers = [];
    @track center;
    @track zoomLevel;
    @track error;

    @track selectedAccount;
    @track isEditingTeam = false; // Controls team assignment form visibility
    _initialRender = true;

    // Pagination properties
    @track pageNumber = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 0;

    wiredAccountsResult; // Stores the result to refreshApex

    @wire(getAccounts, {pageSize: '$pageSize', pageNumber: '$pageNumber' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result; // Cache the result
        if (result.data) {
            this.accounts = result.data.accounts;
            this.totalRecords = result.data.totalRecords;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

            this.mapMarkers = this.accounts.map(account => {
                return {
                    location: {
                        Latitude: account.BillingLatitude,
                        Longitude: account.BillingLongitude,
                    },
                    value: account.Id,
                };
            });

            if(this.mapMarkers.length > 0) {
                this.center = this.mapMarkers[0].location;
            }
            this.error = undefined;
        } else if (result.error) {
            this.error = error;
            this.accounts = undefined;
        }
    }

    get teamDisplayValue() {
        return this.selectedAccount && this.selectedAccount.Team__c ? this.selectedAccount.Team__c : 'Unassigned';
    }

    handleAccountListSelect(event) {
        const selectedAccountId = event.detail;
        this.selectedAccount = this.accounts.find(acc => acc.Id === selectedAccountId);

        if (this.selectedAccount) {
            this.center = {
                location: { Latitude: this.selectedAccount.BillingLatitude, Longitude: this.selectedAccount.BillingLongitude },
            };
            this.zoomLevel = 14; 
        }
    }

    // Handles the markerselect event from the c-account-map component
    handleMarkerSelect(event) {
        const selectedAccountId = event.detail;
        this.selectedAccount = this.accounts.find(acc => acc.Id === selectedAccountId);
        console.log('SELECTED ACCOUNT FOUND: ' + JSON.stringify(this.selectedAccount));
    }

    // --- Map popup card handlers ---

    // Clears the selected account to hide the overlay
    handleCloseOverlay() {
        this.selectedAccount = null;
    }
    
    // Navigates to the selected account's record page
    handleViewRecord() {
        if (!this.selectedAccount) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedAccount.Id,
                actionName: 'view',
            },
        });
    }

    async handleSuccess (event) {
        const evt = new ShowToastEvent({
            title: "Success",
            message: "Account updated",
            variant: "success"
        });
        this.dispatchEvent(evt);
        this.isEditingTeam = false;

        await refreshApex(this.wiredAccountsResult);

        this.selectedAccount = this.accounts.find(acc => acc.Id === this.selectedAccount.Id);
    }

    handleChangeTeamClick() {
        this.isEditingTeam = true;
    }

    handleCancel() {
        this.isEditingTeam = false;
    }

    // --- Pagination Methods ---
    handlePreviousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.selectedAccount = null; // Clear overlay on page change
            this.isEditingTeam = false;
        }
    }

    handleNextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.selectedAccount = null; // Clear overlay on page change
            this.isEditingTeam = false;
        }
    }

    // --- Scroll into View Logic ---
    // Logic to ensure app is centered into viewport on page load
    renderedCallback() {
        if (this._initialRender) {
            this._initialRender = false;

            const scrollTarget = this.template.querySelector('[data-id="scroll-target"]');
            if (!scrollTarget) return;

            // 1. Find the nearest scrollable ancestor element
            let scrollableParent = scrollTarget.parentElement;
            while (scrollableParent && scrollableParent !== document.body) {
                const style = window.getComputedStyle(scrollableParent);
                if (style.overflowY === 'auto' || style.overflowY === 'scroll') {
                    break; // Found it
                }
                scrollableParent = scrollableParent.parentElement;
            }

            // Fallback to window if no specific parent is found
            if (!scrollableParent || scrollableParent === document.body) {
                scrollableParent = window;
            }

            // 2. Calculate the correct scroll position with an offset
            const targetRect = scrollTarget.getBoundingClientRect();
            const offset = 125; // Desired offset in pixels
            
            let scrollPosition;

            if (scrollableParent === window) {
                scrollPosition = targetRect.top + window.scrollY - offset;
            } else {
                const containerRect = scrollableParent.getBoundingClientRect();
                scrollPosition = targetRect.top - containerRect.top + scrollableParent.scrollTop - offset;
            }

            // 3. Perform the scroll
            scrollableParent.scrollTo({
                top: scrollPosition,
                behavior: 'smooth'
            });
        }
    }
}
