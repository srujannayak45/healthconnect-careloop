import { LightningElement } from 'lwc';
import getHome from '@salesforce/apex/PatientPortalController.getHome';
import respond from '@salesforce/apex/PatientPortalController.respond';
import markRead from '@salesforce/apex/PatientPortalController.markRead';
import setReminderConsent from '@salesforce/apex/PatientPortalController.setReminderConsent';

const STATUS_CLASS = { Overdue: 'pill pill-red', Due: 'pill pill-amber', Scheduled: 'pill pill-blue', Completed: 'pill pill-green' };

export default class PatientPortalHome extends LightningElement {
    home;
    error;
    notice;
    busy = false;
    activeDateFor;
    proposedDate;

    connectedCallback() {
        this.run(() => getHome());
    }

    async run(action, notice) {
        this.busy = true;
        this.error = undefined;
        try {
            this.home = await action();
            this.notice = notice;
            this.activeDateFor = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Something went wrong. Please try again.';
        } finally {
            this.busy = false;
        }
    }

    get people() {
        if (!this.home) {
            return [];
        }
        return this.home.people.map((p) => {
            const open = p.care.filter((c) => c.open);
            const done = p.care.filter((c) => !c.open);
            return {
                ...p,
                hasOpen: open.length > 0,
                hasDone: done.length > 0,
                open: open.map((c) => this.decorate(c)),
                done: done.map((c) => this.decorate(c))
            };
        });
    }

    decorate(c) {
        return {
            ...c,
            pillClass: STATUS_CLASS[c.status] || 'pill',
            overdueText: c.daysOverdue > 0 ? `${c.daysOverdue} days late` : '',
            answered: c.response ? `Your answer: ${c.response}${c.proposedDate ? ' · ' + c.proposedDate : ''}` : '',
            showDate: this.activeDateFor === c.id
        };
    }

    get messages() {
        return (this.home?.inbox || []).map((m) => ({ ...m, unread: m.status === 'Sent', cls: m.status === 'Sent' ? 'msg unread' : 'msg' }));
    }

    get hasMessages() {
        return this.messages.length > 0;
    }

    get visits() {
        return (this.home?.visits || []).map((v) => ({ ...v, hasAdvice: !!v.doctorAdvice }));
    }

    get hasVisits() {
        return this.visits.length > 0;
    }

    get consentLabel() {
        return this.home?.reminderConsent ? 'Reminders are ON' : 'Reminders are OFF';
    }

    get consentButton() {
        return this.home?.reminderConsent ? 'Stop reminders' : 'Send me reminders';
    }

    get today() {
        return new Date().toISOString().slice(0, 10);
    }

    handleWillAttend(event) {
        this.answer(event.currentTarget.dataset.id, 'Will Attend', null, 'Thank you. Your health worker knows you will come.');
    }

    handleDoneElsewhere(event) {
        this.answer(event.currentTarget.dataset.id, 'Completed Elsewhere', null, 'Thank you. Your health worker will update the record.');
    }

    handleNeedHelp(event) {
        this.answer(event.currentTarget.dataset.id, 'Need Help', null, 'Your health worker has been told and will contact you.');
    }

    handleShowDate(event) {
        this.activeDateFor = event.currentTarget.dataset.id;
        this.proposedDate = undefined;
    }

    handleDateChange(event) {
        this.proposedDate = event.target.value;
    }

    handleSendDate(event) {
        if (!this.proposedDate) {
            this.error = 'Please choose a date first.';
            return;
        }
        this.answer(event.currentTarget.dataset.id, 'Will Attend', this.proposedDate, 'Thank you. Your health worker will confirm the new date.');
    }

    answer(activityId, response, proposedDate, notice) {
        this.run(() => respond({ activityId, response, proposedDate, note: null }), notice);
    }

    handleRead(event) {
        this.run(() => markRead({ notificationId: event.currentTarget.dataset.id }));
    }

    handleConsent() {
        const granted = !this.home?.reminderConsent;
        this.run(() => setReminderConsent({ granted }), granted ? 'Reminders switched on.' : 'Reminders switched off.');
    }
}
