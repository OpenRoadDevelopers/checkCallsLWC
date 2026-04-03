import { LightningElement, track, api } from 'lwc';
import getPlacePredictions from '@salesforce/apex/AutoCompleteCityState.getPlacePredictions';
import addTrackingUpdate from '@salesforce/apex/trackingUpdateManager.addTrackingUpdate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CheckCall extends LightningElement {
    @api recordId;
    city = '';
    state = '';
    ETA = '';
    status='';
    comment='';
    @track location = '';
    @track locationPredictions = [];
    @track selectedIndex = -1;
    searchTimeout;
    error = '';

    statusOptions = [
        { label: 'On Time', value: 'On Time' },
        { label: 'Delayed', value: 'Delayed' },
        { label: 'Problem', value: 'Problem' },
    ];

    connectedCallback() {
        this.recordId && console.log('Record ID:', this.recordId);
    }
    async handleLocationChange(event) {
        console.log('Location change:', event.target.value);
        this.location = event.target.value;
        if (!this.location.trim()) {
            this.city = '';
            this.state = '';
        }
        
        await this.fetchPredictions(this.location);
        // this.saveState();
    }

    handleETAChange(event) {
        this.ETA = event.target.value;
    }
    handleStatusChange(event) {
        this.status = event.target.value;
    }
    handleCommentChange(event) {
        this.comment = event.target.value;
    }


    //helper functions
    async handleClickLocationInput(){
        console.log('Location input clicked');
        if (!this.location.trim()) {
            this.city = '';
            this.state = '';
        }
        await this.fetchPredictions(this.location);
    }

    handleLocationKeyDown(event) {
        console.log('Key down:', event.key, 'Selected index:', this.selectedIndex, 'Location predictions length:', this.locationPredictions.length);
        if (this.locationPredictions.length === 0) return;

        switch (event.key) {
            case 'ArrowDown':
                console.log('ArrowDown pressed');
                event.preventDefault();
                this.selectedIndex = (this.selectedIndex + 1) % this.locationPredictions.length;
                console.log('New selected index:', this.selectedIndex);
                this.highlight();
                break;
            case 'ArrowUp':
                event.preventDefault();
                this.selectedIndex = (this.selectedIndex - 1 + this.locationPredictions.length) % this.locationPredictions.length;
                this.highlight();
                break;
            case 'Enter':
                console.log('Enter or Tab pressed');
                if (this.selectedIndex >= 0) {
                    console.log('selectedIndex is valid:', this.selectedIndex);
                    event.preventDefault();
                    const p = this.locationPredictions[this.selectedIndex];
                    console.log('whats p:', p);
                    this.location = p.full_text;
                    this.city = p.city;
                    this.state = p.state;
                    this.locationPredictions = [];
                    this.selectedIndex = -1;
                    const originEl = this.template.querySelector('.origin-combined');
                    if (originEl) originEl.blur();
                }
                break;
            case 'Escape':
                this.locationPredictions = [];
                this.selectedIndex = -1;
                break;
        }
    }

    handleBlur() {
        setTimeout(() => {
            this.locationPredictions = [];
            this.selectedIndex = -1;
        }, 200);
    }

    handleSelectLocation(event) {
        const fullText = event.currentTarget.dataset.fullText;
        const parts = fullText.split(',');
        
        this.city = parts[0].trim();
        this.state = parts[1] ? parts[1].trim() : '';
        this.location = fullText;
        this.locationPredictions = [];
        this.selectedIndex = -1;
        
        const destEl = this.template.querySelector('.dest-combined');
        if (destEl) destEl.blur();

        setTimeout(() => {
            const equipEl = this.template.querySelector('lightning-combobox');
            if (equipEl) equipEl.focus();
        }, 80);
    }


    async fetchPredictions(input) {
        window.clearTimeout(this.searchTimeout);
        if (input.length < 3) {
            this.locationPredictions = [];
            return;
        }

        this.searchTimeout = setTimeout(async () => {
            try {
                if (!this.isConnected) return;
                const response = await getPlacePredictions({ input: input });
                const data = JSON.parse(response);
                
                if (data.suggestions && data.suggestions.length > 0) {
                    const formatted = data.suggestions.map(s => {
                        const place = s.placePrediction;
                        const text = place.text.text;
                        const parts = text.split(',');
                        return {
                            place_id: place.placeId,
                            full_text: text,
                            city: parts[0].trim(),
                            state: parts[1] ? parts[1].trim() : ''
                        };
                    });
                    this.locationPredictions = formatted;
                }
            } catch (e) {
                console.error('Autocomplete error:', e);
            }
        }, 200);
    }

    highlight() {
        console.log('Selected index:',  this.selectedIndex);
        const dropdown = this.template.querySelector('.custom-dropdown');
        if (!dropdown) return;
        const items = dropdown.querySelectorAll('li');
        const index =  this.selectedIndex;
        items.forEach((item, i) => {
            item.classList.toggle('slds-is-selected', i === index);
            if (i === index) item.scrollIntoView({ block: 'nearest' });
        });
    }

    get validationMessage() {
        if (!this.city || !this.state) {
            return '⚠ Please search and select a valid location from the dropdown';
        }

        if (!this.ETA) {
            return '⚠ Please fill in the ETA';
        } else {
            if (!this.status) {
                return '⚠ Please select a status';
            }
        }
        return '⚠ Please fill in all required fields';
    }


    handleSave(){
        this.error = '';
        if (!this.city || !this.state || !this.ETA || !this.status) {
            this.error = this.validationMessage;
            return;
        }
        addTrackingUpdate({
            loadId: this.recordId,
            city: this.city,
            stateCode: this.state,
            ETA: this.ETA,
            status: this.status,
            comment: this.comment
        }).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Tracking updated successfully',
                    variant: 'success'
                })
            );
            // Clear form after successful save
            this.city = '';
            this.state = '';
            this.ETA = '';
            this.status = '';
            this.comment = '';
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed to update tracking',
                    message: 'An error occurred while updating tracking. Please try again.',
                    variant: 'error'
                })
            );
        });
        
    }

}


//trackingUpdateManager.addTrackingUpdate('a0jNr00000397dFIAQ', 'Beaverton', 'OR', '3 hours away', 'On Time', 'Takuns test');
//SELECT City__c, State__c, Status__c, ETA__c, Comment__c, Load__c FROM Tracking_Update__c