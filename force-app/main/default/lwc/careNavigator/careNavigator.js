import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getPlan from '@salesforce/apex/NavigatorController.getPlan';
import planMyDay from '@salesforce/apex/NavigatorController.planMyDay';
import updateStop from '@salesforce/apex/NavigatorController.updateStop';
import getTeamPlans from '@salesforce/apex/NavigatorController.getTeamPlans';

const STATUS_CLASS = { Planned: 'status planned', Visited: 'status visited', 'Not Home': 'status nothome', Skipped: 'status skipped' };

export default class CareNavigator extends NavigationMixin(LightningElement) {
    plan;
    team = [];
    selectedWorker;
    loading = true;
    error;
    skipFor;
    skipReason = '';

    connectedCallback() {
        this.load(null);
    }

    async load(workerId) {
        this.loading = true;
        try {
            const [plan, team] = await Promise.all([getPlan({ workerId }), getTeamPlans()]);
            this.plan = plan;
            this.team = team || [];
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not load the plan.';
        } finally {
            this.loading = false;
        }
    }

    async handlePlan() {
        this.loading = true;
        try {
            this.plan = await planMyDay();
            this.team = (await getTeamPlans()) || [];
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not plan the day.';
        } finally {
            this.loading = false;
        }
    }

    get hasPlan() {
        return !!this.plan;
    }

    get hasStops() {
        return this.plan && this.plan.stops && this.plan.stops.length > 0;
    }

    get noStops() {
        return this.plan && (!this.plan.stops || this.plan.stops.length === 0);
    }

    get showPlanButton() {
        return !this.plan || this.plan.isMine;
    }

    get planButtonLabel() {
        return this.plan ? 'Re-plan my day' : 'Plan my day';
    }

    get gain() {
        if (!this.plan || !this.plan.baselineGaps) {
            return null;
        }
        return Math.round(((this.plan.gapsTargeted - this.plan.baselineGaps) / this.plan.baselineGaps) * 100);
    }

    get gainText() {
        const g = this.gain;
        if (g === null) {
            return '';
        }
        return g >= 0 ? `+${g}% more care gaps reached` : `${g}% vs due-date list`;
    }

    get distanceText() {
        if (!this.plan) {
            return '';
        }
        const saved = (this.plan.baselineDistance || 0) - (this.plan.distance || 0);
        return saved > 0.5 ? `${saved.toFixed(1)} km less walking` : 'similar distance';
    }

    get stopCount() {
        return this.plan && this.plan.stops ? this.plan.stops.length : 0;
    }

    get progressPercent() {
        if (!this.plan || !this.plan.stops.length) {
            return 0;
        }
        return Math.round((this.plan.visited / this.plan.stops.length) * 100);
    }

    get stops() {
        if (!this.plan) {
            return [];
        }
        return this.plan.stops.map((s) => ({
            ...s,
            statusClass: STATUS_CLASS[s.status] || 'status',
            reasonRows: (s.reasons || []).map((text, i) => ({ key: `${s.id}-r${i}`, text })),
            memberRows: (s.members || []).map((m) => ({
                ...m,
                itemRows: (m.items || []).map((text, i) => ({ key: `${m.contactId}-i${i}`, text }))
            })),
            distanceText: s.sequence === 1 ? 'Start here' : s.distance > 0 ? `${s.distance} km from previous` : 'Same village',
            closedText: `${s.gapsClosed}/${s.gaps} gaps closed`,
            isPlanned: s.status === 'Planned',
            showSkip: this.skipFor === s.id,
            canEdit: this.plan.isMine
        }));
    }

    get markers() {
        if (!this.plan) {
            return [];
        }
        const seen = new Map();
        this.plan.stops.forEach((s) => {
            if (s.latitude === null || s.latitude === undefined) {
                return;
            }
            const key = `${s.latitude},${s.longitude}`;
            const label = `${s.sequence}. ${s.household}`;
            if (seen.has(key)) {
                seen.get(key).description += `; ${label} (${s.gaps} gaps)`;
            } else {
                seen.set(key, {
                    location: { Latitude: s.latitude, Longitude: s.longitude },
                    title: s.village,
                    description: `${label} (${s.gaps} gaps)`
                });
            }
        });
        return Array.from(seen.values());
    }

    get hasMarkers() {
        return this.markers.length > 0;
    }

    get teamOptions() {
        return this.team.map((t) => ({ label: `${t.workerName} (${t.visited}/${t.planned} visits)`, value: t.workerId }));
    }

    get showTeam() {
        return this.team.length > 1;
    }

    handleWorkerChange(event) {
        this.selectedWorker = event.detail.value;
        this.load(this.selectedWorker);
    }

    openRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }

    recordVisit(event) {
        const patientId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Health_Visit__c', actionName: 'new' },
            state: { defaultFieldValues: encodeDefaultFieldValues({ Patient__c: patientId, Visit_Type__c: 'Home Visit' }) }
        });
    }

    async markNotHome(event) {
        await this.changeStop(event.currentTarget.dataset.id, 'Not Home', null);
    }

    showSkip(event) {
        this.skipFor = event.currentTarget.dataset.id;
        this.skipReason = '';
    }

    handleSkipReason(event) {
        this.skipReason = event.target.value;
    }

    async confirmSkip(event) {
        await this.changeStop(event.currentTarget.dataset.id, 'Skipped', this.skipReason);
        this.skipFor = undefined;
    }

    async changeStop(stopId, status, reason) {
        this.loading = true;
        try {
            this.plan = await updateStop({ stopId, status, reason });
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not update the stop.';
        } finally {
            this.loading = false;
        }
    }

    refresh() {
        this.load(this.selectedWorker || null);
    }
}
