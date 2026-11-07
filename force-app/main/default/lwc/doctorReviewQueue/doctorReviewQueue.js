import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getPendingReviews from '@salesforce/apex/DoctorReviewController.getPendingReviews';

const CHANNEL = '/event/CareLoop_Alert__e';

export default class DoctorReviewQueue extends NavigationMixin(LightningElement) {
    items = [];
    error;
    loading = true;
    live = false;
    subscription;

    connectedCallback() {
        this.load();
        onError((err) => {
            // Streaming errors only switch off the live indicator; the list still works.
            this.live = false;
            // eslint-disable-next-line no-console
            console.warn('CareLoop live alerts unavailable', JSON.stringify(err));
        });
        subscribe(CHANNEL, -1, (message) => this.handleAlert(message))
            .then((sub) => {
                this.subscription = sub;
                this.live = true;
            })
            .catch(() => {
                this.live = false;
            });
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {});
        }
    }

    async load() {
        this.loading = true;
        try {
            const rows = await getPendingReviews();
            this.items = rows.map((r) => ({
                ...r,
                key: r.visitId,
                cardClass: r.redFlag ? 'item red' : 'item',
                badge: r.redFlag ? 'RED FLAG' : 'REVIEW',
                badgeClass: r.redFlag ? 'badge badge-red' : 'badge badge-amber',
                where: [r.village, r.region].filter((x) => x).join(' · '),
                waiting: r.hoursWaiting < 1 ? 'just now' : `${r.hoursWaiting} h waiting`
            }));
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not load the review queue.';
        } finally {
            this.loading = false;
        }
    }

    handleAlert(message) {
        const data = message?.data?.payload || {};
        if (data.Alert_Type__c !== 'RED_FLAG' && data.Alert_Type__c !== 'REVIEW_REQUESTED') {
            return;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: data.Alert_Type__c === 'RED_FLAG' ? 'New red-flag visit' : 'New visit to review',
                message: data.Message__c || '',
                variant: data.Severity__c === 'High' ? 'error' : 'info',
                mode: 'sticky'
            })
        );
        this.load();
    }

    get hasItems() {
        return this.items.length > 0;
    }

    get showEmpty() {
        return !this.loading && !this.error && this.items.length === 0;
    }

    get countLabel() {
        const red = this.items.filter((i) => i.redFlag).length;
        return `${this.items.length} waiting · ${red} red flag${red === 1 ? '' : 's'}`;
    }

    get liveLabel() {
        return this.live ? 'Live' : 'Refresh manually';
    }

    get liveClass() {
        return this.live ? 'live on' : 'live';
    }

    openVisit(event) {
        this.navigate(event.currentTarget.dataset.id);
    }

    openPatient(event) {
        this.navigate(event.currentTarget.dataset.id);
    }

    navigate(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, actionName: 'view' }
        });
    }

    refresh() {
        this.load();
    }
}
