import { LightningElement, track, wire } from 'lwc';
import getDrivers from '@salesforce/apex/FantasyTeamController.getDrivers';
import getConstructors from '@salesforce/apex/FantasyTeamController.getConstructors';
import createFantasyTeam from '@salesforce/apex/FantasyTeamController.createFantasyTeam';

export default class CreateFantasyTeam extends LightningElement {
    @track teamName = '';
    @track selectedDrivers = [];
    @track selectedConstructors = [];
    @track driverOptions = [];
    @track constructorOptions = [];

    @wire(getDrivers)
    wiredDrivers({ data }) {
        if (data) {
            this.driverOptions = data.map(d => ({ label: d.Name + ' (' + d.Nationality__c + ')', value: d.Id }));
        }
    }

    @wire(getConstructors)
    wiredConstructors({ data }) {
        if (data) {
            this.constructorOptions = data.map(c => ({ label: c.Name + ' (' + c.Nationality__c + ')', value: c.Id }));
        }
    }

    handleNameChange(event) {
        this.teamName = event.target.value;
    }

    handleDriverSelect(event) {
        this.selectedDrivers = event.detail.value;
    }

    handleConstructorSelect(event) {
        this.selectedConstructors = event.detail.value;
    }

    handleSave() {
        createFantasyTeam({ name: this.teamName, drivers: this.selectedDrivers, constructors: this.selectedConstructors })
            .then(() => {
                alert('Equipo creado exitosamente');
            })
            .catch(error => {
                alert('Error: ' + error.body.message);
            });
    }
}