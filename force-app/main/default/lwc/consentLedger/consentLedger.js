import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLedger from '@salesforce/apex/ConsentLedgerController.getLedger';
import verifyLedger from '@salesforce/apex/ConsentLedgerController.verifyLedger';
import recordConsent from '@salesforce/apex/ConsentLedgerController.recordConsent';

const PURPOSES = ['Reminders and Communication', 'Care Delivery', 'Share With Doctors', 'Programme Analytics'];

export default class ConsentLedger extends LightningElement {
    @api recordId;
    ledger;
    verification;
    error;
    showForm = false;
    purpose = 'Reminders and Communication';
    action = 'grant';
    channel = 'Paper Form';
    reason = '';

    connectedCallback() {
        this.load();
    }

    async load() {
        try {
            this.ledger = await getLedger({ patientId: this.recordId });
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not load consent.';
        }
    }

    get consents() {
        return (this.ledger?.consents || []).map((c) => ({ ...c, cls: c.Status__c === 'Granted' ? 'state on' : 'state off' }));
    }

    get events() {
        return (this.ledger?.events || []).map((e) => ({
            ...e,
            by: e.Performed_By__r ? e.Performed_By__r.Name : '',
            shortHash: e.Event_Hash__c ? e.Event_Hash__c.substring(0, 12) + '…' : '',
            shortPrev: e.Previous_Hash__c ? e.Previous_Hash__c.substring(0, 12) + '…' : ''
        }));
    }

    get hasEvents() {
        return this.events.length > 0;
    }

    get verifyClass() {
        return this.verification?.intact ? 'verify ok' : 'verify bad';
    }

    get purposeOptions() {
        return PURPOSES.map((p) => ({ label: p, value: p }));
    }

    get actionOptions() {
        return [{ label: 'Grant', value: 'grant' }, { label: 'Withdraw', value: 'withdraw' }];
    }

    get channelOptions() {
        return [{ label: 'Paper Form', value: 'Paper Form' }, { label: 'Verbal (Witnessed)', value: 'Verbal (Witnessed)' }];
    }

    async handleVerify() {
        try {
            this.verification = await verifyLedger({ patientId: this.recordId });
        } catch (e) {
            this.error = e?.body?.message || 'Verification failed.';
        }
    }

    toggleForm() {
        this.showForm = !this.showForm;
    }

    handleChange(event) {
        this[event.target.name] = event.detail.value;
    }

    async handleSave() {
        try {
            this.ledger = await recordConsent({
                patientId: this.recordId,
                purpose: this.purpose,
                grant: this.action === 'grant',
                channel: this.channel,
                reason: this.reason
            });
            this.showForm = false;
            this.verification = undefined;
            this.dispatchEvent(new ShowToastEvent({ title: 'Consent recorded in the ledger', variant: 'success' }));
        } catch (e) {
            this.error = e?.body?.message || 'Consent not recorded.';
        }
    }
}
