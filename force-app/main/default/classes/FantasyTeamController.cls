public with sharing class FantasyTeamController {

    @AuraEnabled(cacheable=true)
    public static List<Driver__c> getDrivers() {
        return [
            SELECT Id, Name, Nationality__c, Price__c, Points__c
            FROM Driver__c
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Constructor__c> getConstructors() {
        return [
            SELECT Id, Name, Nationality__c, Price__c, Points__c
            FROM Constructor__c
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static String createFantasyTeam(String name, List<Id> driverIds, List<Id> constructorIds) {

        System.debug('=== createFantasyTeam CALLED ===');
        System.debug('name           => ' + name);
        System.debug('driverIds      => ' + driverIds);
        System.debug('constructorIds => ' + constructorIds);
        System.debug('driverIds size => ' + (driverIds == null ? 'null' : String.valueOf(driverIds.size())));
        System.debug('constructorIds size => ' + (constructorIds == null ? 'null' : String.valueOf(constructorIds.size())));

        try {
            if (String.isBlank(name)) {
                throw new AuraHandledException('Debe ingresar un nombre para el equipo.');
            }
            if (driverIds == null || driverIds.size() != 5) {
                throw new AuraHandledException(
                    'Debe seleccionar exactamente 5 pilotos (recibidos: ' +
                    (driverIds == null ? 'null' : String.valueOf(driverIds.size())) + ').'
                );
            }
            if (constructorIds == null || constructorIds.size() != 2) {
                throw new AuraHandledException(
                    'Debe seleccionar exactamente 2 escuderías (recibidas: ' +
                    (constructorIds == null ? 'null' : String.valueOf(constructorIds.size())) + ').'
                );
            }

            Decimal budget = 100000000;

            FantasyTeam__c ft = new FantasyTeam__c(
                Name      = name,          
                Budget__c = budget,
                Status__c = 'Active'       
            );
            insert ft;

            List<Team_Fantasy_Driver__c> driverRecords = new List<Team_Fantasy_Driver__c>();

            for (Id dId : driverIds) {
                Driver__c d = [
                    SELECT Name, Price__c, Points__c, Wins__c
                    FROM Driver__c
                    WHERE Id = :dId
                    LIMIT 1
                ];

                Team_Fantasy_Driver__c tfd = new Team_Fantasy_Driver__c(
                    FantasyTeam__c  = ft.Id,
                    Driver__c       = dId,
                    DriverCost__c   = d.Price__c,
                    DriverPoints__c = d.Points__c,
                    DriverWins__c   = (d.Wins__c != null ? d.Wins__c : 0),
                    Name            = d.Name     
                );
                driverRecords.add(tfd);
            }
            insert driverRecords;

            List<Team_Fantasy_Constructor__c> constructorRecords = new List<Team_Fantasy_Constructor__c>();

            for (Id cId : constructorIds) {
                Constructor__c c = [
                    SELECT Name, Price__c, Points__c
                    FROM Constructor__c
                    WHERE Id = :cId
                    LIMIT 1
                ];

                Team_Fantasy_Constructor__c tfc = new Team_Fantasy_Constructor__c(
                    FantasyTeam__c      = ft.Id,
                    Constructor__c      = cId,
                    ConstructorCost__c  = c.Price__c,
                    ConstructorPoints__c = c.Points__c,
                    Name                = c.Name   
                );
                constructorRecords.add(tfc);
            }
            insert constructorRecords;

            return ft.Id;

        } catch (Exception e) {
            System.debug('*** ERROR en createFantasyTeam: ' + e.getMessage());
            // Enviamos el mensaje real al LWC
            throw new AuraHandledException('Error técnico al crear el equipo: ' + e.getMessage());
        }
    }
}