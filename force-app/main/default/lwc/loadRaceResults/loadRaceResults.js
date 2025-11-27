import { LightningElement, api, track } from 'lwc';
import loadRaceResults from '@salesforce/apex/F1RaceResultLoader.loadRaceResults';
import getRaceIdByRecordId from '@salesforce/apex/F1RaceResultLoader.getRaceIdByRecordId';

export default class LoadRaceResults extends LightningElement {
    @api recordId;
    @track message;
    @track messageClass = 'slds-text-color_default';

    async handleClick() {
        this.message = 'Procesando...';
        this.messageClass = 'slds-text-color_weak';
        try {
            const raceId = await getRaceIdByRecordId({ recordId: this.recordId });
            if (!raceId) {
                this.message = 'Error: RaceId__c no encontrado en el registro.';
                this.messageClass = 'slds-text-color_error';
                return;
            }
            const result = await loadRaceResults({ raceId: raceId });
            this.message = result;

            // Estilo según resultado
            if (result.startsWith('Resultados cargados')) {
                this.messageClass = 'slds-text-color_success';
            } else {
                this.messageClass = 'slds-text-color_error';
            }
        } catch (error) {
            this.message = 'Error inesperado: ' + (error.body ? error.body.message : error.message);
            this.messageClass = 'slds-text-color_error';
        }
    }
}