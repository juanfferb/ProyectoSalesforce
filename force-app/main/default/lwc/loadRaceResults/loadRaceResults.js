import { LightningElement, api, track } from 'lwc';
import loadRaceResults from '@salesforce/apex/F1RaceResultLoader.loadRaceResults';

export default class LoadRaceResults extends LightningElement {
    @api recordId; // Id del registro Race__c
    @track message;

    async handleClick() {
        try {
            // Obtener RaceId__c del registro actual
            const race = await this.getRaceId();
            const result = await loadRaceResults({ raceId: race });
            this.message = result;
        } catch (error) {
            this.message = 'Error: ' + error.body.message;
        }
    }

    async getRaceId() {
        const res = await fetch(`/services/data/v57.0/sobjects/Race__c/${this.recordId}`);
        const data = await res.json();
        return data.RaceId__c;
    }
}