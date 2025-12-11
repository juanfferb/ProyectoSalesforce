import { LightningElement, track } from 'lwc';
import getDrivers from '@salesforce/apex/FantasyTeamController.getDrivers';
import getConstructors from '@salesforce/apex/FantasyTeamController.getConstructors';
import createFantasyTeam from '@salesforce/apex/FantasyTeamController.createFantasyTeam';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class FantasyTeamBuilder extends NavigationMixin(LightningElement) {

    @track driverOptions = [];
    @track constructorOptions = [];
    @track selectedDrivers = [];
    @track selectedConstructors = [];
    teamName = '';
    isSaving = false;

    connectedCallback() {
        this.loadDrivers();
        this.loadConstructors();
    }

    // Cargar pilotos
    loadDrivers() {
        getDrivers()
            .then(result => {
                this.driverOptions = result.map(d => ({
                    label: d.Name,
                    value: d.Id
                }));
            })
            .catch(error => {
                this.showError('Error al cargar pilotos', error.body ? error.body.message : error.message);
            });
    }

    // Cargar escuderías
    loadConstructors() {
        getConstructors()
            .then(result => {
                this.constructorOptions = result.map(c => ({
                    label: c.Name,
                    value: c.Id
                }));
            })
            .catch(error => {
                this.showError('Error al cargar escuderías', error.body ? error.body.message : error.message);
            });
    }

    // Handlers UI
    handleNameChange(event) {
        this.teamName = event.target.value;
    }

    handleDriversChange(event) {
        this.selectedDrivers = event.detail.value;
    }

    handleConstructorsChange(event) {
        this.selectedConstructors = event.detail.value;
    }

    // Crear equipo (llamando al Apex)
    handleCreateTeam() {
        if (!this.teamName) {
            this.showError('Datos incompletos', 'Debes ingresar un nombre para el equipo.');
            return;
        }
        if (this.selectedDrivers.length !== 5) {
            this.showError('Selección inválida', 'Debes seleccionar exactamente 5 pilotos.');
            return;
        }
        if (this.selectedConstructors.length !== 2) {
            this.showError('Selección inválida', 'Debes seleccionar exactamente 2 escuderías.');
            return;
        }

        this.isSaving = true;

        console.log('DEBUG - teamName:', this.teamName);
        console.log('DEBUG - selectedDrivers:', JSON.stringify(this.selectedDrivers));
        console.log('DEBUG - selectedConstructors:', JSON.stringify(this.selectedConstructors));

        createFantasyTeam({
            name: this.teamName,
            driverIds: this.selectedDrivers,
            constructorIds: this.selectedConstructors
        })
            .then(newTeamId => {
                this.isSaving = false;

                // Toast
                this.showSuccess('Equipo creado', 'El equipo fantasy fue creado correctamente');

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newTeamId,
                        objectApiName: 'FantasyTeam__c',
                        actionName: 'view'
                    }
                });

                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                this.isSaving = false;
                console.error('DEBUG - error al crear el equipo:', JSON.stringify(error));
                this.showError(
                    'Error al crear el equipo',
                    error.body && error.body.message
                        ? error.body.message
                        : (error && error.message ? error.message : JSON.stringify(error))
                );
            });
    }

    showSuccess(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: 'success'
        }));
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: 'error'
        }));
    }
}