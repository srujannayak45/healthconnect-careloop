import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPriority from '@salesforce/apex/PatientPriorityController.getPriority';
import saveNow from '@salesforce/apex/PatientPriorityController.saveNow';

export default class PatientPriorityCard extends LightningElement {
    @api recordId;
    view;
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        try {
            this.view = await getPriority({ patientId: this.recordId });
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not calculate the priority.';
        } finally {
            this.loading = false;
        }
    }

    async handleSave() {
        this.loading = true;
        try {
            this.view = await saveNow({ patientId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Priority saved', variant: 'success' }));
        } catch (e) {
            this.error = e?.body?.message || 'Could not save the priority.';
        } finally {
            this.loading = false;
        }
    }

    get live() {
        return this.view?.live;
    }

    get reasons() {
        return (this.live?.reasons || []).map((r, i) => ({ key: `${r.ruleKey}-${i}`, label: `+${r.points}`, text: r.text }));
    }

    get hasReasons() {
        return this.reasons.length > 0;
    }

    get levelClass() {
        const level = (this.live?.level || 'Low').toLowerCase();
        return `level level-${level}`;
    }

    get storedLine() {
        if (!this.view || this.view.storedScore === null || this.view.storedScore === undefined) {
            return 'Not yet saved by the nightly run.';
        }
        return `Saved score ${this.view.storedScore} (${this.view.storedLevel})`;
    }
}
