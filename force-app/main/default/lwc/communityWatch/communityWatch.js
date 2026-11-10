import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOverview from '@salesforce/apex/CommunityWatchController.getOverview';
import runScan from '@salesforce/apex/CommunityWatchController.runScan';
import updateStatus from '@salesforce/apex/CommunityWatchController.updateStatus';
import getEvidence from '@salesforce/apex/CommunityWatchController.getEvidence';

const SEVERITY_CLASS = { Alert: 'cell alert', Watch: 'cell watch', Normal: 'cell normal' };

export default class CommunityWatch extends NavigationMixin(LightningElement) {
    overview;
    error;
    loading = true;
    openSignalId;
    evidence = [];
    notes = '';

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        try {
            this.overview = await getOverview();
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not load Community Watch.';
        } finally {
            this.loading = false;
        }
    }

    get headers() {
        return (this.overview?.signalLabels || []).map((label, i) => ({ key: `h${i}`, label }));
    }

    get rows() {
        return (this.overview?.rows || []).map((row) => ({
            ...row,
            cellRows: row.cells.map((c, i) => ({
                key: `${row.villageId}-${i}`,
                cls: c.insufficientHistory ? 'cell nohistory' : SEVERITY_CLASS[c.severity] || 'cell normal',
                text: `${c.observed}`,
                sub: c.insufficientHistory ? 'no history yet' : `normal ${Number(c.expected).toFixed(1)}`,
                title: c.explanation
            }))
        }));
    }

    get signals() {
        return (this.overview?.signals || []).map((s) => {
            const weekly = (s.Weekly_Counts__c || '').split(',').filter((x) => x !== '').map((x) => Number(x));
            const max = Math.max(1, ...weekly);
            return {
                ...s,
                village: s.Village__r ? s.Village__r.Name : '',
                badgeClass: s.Severity__c === 'Alert' ? 'badge alert' : 'badge watch',
                statusClass: `status s-${(s.Status__c || '').toLowerCase()}`,
                isOpen: this.openSignalId === s.Id,
                isClosed: s.Status__c === 'Closed' || s.Status__c === 'Dismissed',
                bars: weekly.map((count, i) => ({
                    key: `${s.Id}-b${i}`,
                    style: `height:${Math.round((count / max) * 48) + 4}px`,
                    cls: i === weekly.length - 1 ? 'bar current' : 'bar',
                    label: `${count}`
                }))
            };
        });
    }

    get hasSignals() {
        return this.signals.length > 0;
    }

    get openCount() {
        return this.signals.filter((s) => !s.isClosed).length;
    }

    async handleScan() {
        this.loading = true;
        try {
            const summary = await runScan();
            this.toast('Scan complete',
                `${summary.cellsEvaluated} village-signals checked · ${summary.flagged} flagged · ${summary.created} new · ${summary.updated} updated`,
                'success');
            await this.load();
        } catch (e) {
            this.toast('Scan failed', e?.body?.message || '', 'error');
        } finally {
            this.loading = false;
        }
    }

    async toggleDetails(event) {
        const id = event.currentTarget.dataset.id;
        if (this.openSignalId === id) {
            this.openSignalId = undefined;
            return;
        }
        this.openSignalId = id;
        this.notes = '';
        try {
            this.evidence = (await getEvidence({ signalId: id })).map((e) => ({ ...e, key: e.recordId }));
        } catch (e) {
            this.evidence = [];
        }
    }

    get hasEvidence() {
        return this.evidence.length > 0;
    }

    handleNotes(event) {
        this.notes = event.target.value;
    }

    async setStatus(event) {
        const status = event.currentTarget.dataset.status;
        try {
            await updateStatus({ signalId: this.openSignalId, status, notes: this.notes });
            this.toast('Signal updated', status, 'success');
            this.notes = '';
            await this.load();
        } catch (e) {
            this.toast('Not updated', e?.body?.message || '', 'error');
        }
    }

    openRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
