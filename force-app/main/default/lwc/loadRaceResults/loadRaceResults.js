import { LightningElement, api, track } from 'lwc';
import loadRaceResults from '@salesforce/apex/F1RaceResultLoader.loadRaceResults';

export default class LoadRaceResults extends LightningElement {
    @api recordId; // Id del registro Race__c
    @track message;

    async handleClick() {
        this.message = 'Procesando...';
        try {
            const raceId = await this.getRaceId();
            if (!raceId) {
                this.message = 'Error: RaceId__c no encontrado en el registro.';
                return;
            }
            const result = await loadRaceResults({ raceId: raceId });
            this.message = result;
        } catch (error) {
            this.message = 'Error inesperado: ' + (error.body ? error.body.message : error.message);
        }
    }

    async getRaceId() {
        const res = await fetch(`/services/data/v57.0/sobjects/Race__c/${this.recordId}`);
        const data = await res.json();
        return data.RaceId__c;
    }
}