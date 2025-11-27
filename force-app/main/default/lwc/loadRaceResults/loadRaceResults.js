import { LightningElement, api, track } from 'lwc';
import loadRaceResults from '@salesforce/apex/F1RaceResultLoader.loadRaceResults';
import getRaceIdByRecordId from '@salesforce/apex/F1RaceResultLoader.getRaceIdByRecordId';

export default class LoadRaceResults extends LightningElement {
    @api recordId;
    @track message;

    async handleClick() {
        this.message = 'Procesando...';
        try {
            const raceId = await getRaceIdByRecordId({ recordId: this.recordId });
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
}