public with sharing class FantasyTeamController {

    // =====================================================================
    // 1. Listas para el LWC
    // =====================================================================

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

    // =====================================================================
    // 2. Crear equipo + registros detalle (Team Fantasy Driver/Constructor)
    // =====================================================================

    @AuraEnabled
    public static String createFantasyTeam(String name, List<Id> driverIds, List<Id> constructorIds) {

        System.debug('=== createFantasyTeam CALLED ===');
        System.debug('name           => ' + name);
        System.debug('driverIds      => ' + driverIds);
        System.debug('constructorIds => ' + constructorIds);
        System.debug('driverIds size => ' + (driverIds == null ? 'null' : String.valueOf(driverIds.size())));
        System.debug('constructorIds size => ' + (constructorIds == null ? 'null' : String.valueOf(constructorIds.size())));

        try {
            // ---------------------------
            // Validaciones básicas
            // ---------------------------
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

            // Presupuesto fijo para el equipo (puedes ajustarlo)
            Decimal budget = 100000000;

            // ------------------------------------------------------
            // 1) Crear el registro FantasyTeam__c (padre)
            //    Campos según tus capturas: Budget__c, Status__c, etc.
            //    Los roll-ups (DriversValueSum, ConstructorsValueSum,
            //    DriversPoints_Sum, ConstructorPoints_Sum, Current_Value__c,
            //    TotalPoints__c) se calculan solos.
            // ------------------------------------------------------
            FantasyTeam__c ft = new FantasyTeam__c(
                Name      = name,          // FantasyTeam Name (Name)
                Budget__c = budget,
                Status__c = 'Active'       // asegúrate de tener este valor en el picklist
            );
            insert ft;

            // ------------------------------------------------------
            // 2) Crear registros detalle Team Fantasy Driver
            //    Objeto: Team_Fantasy_Driver__c
            //    Campos que vamos a llenar según tu esquema:
            //       - FantasyTeam__c (Master-Detail)
            //       - Driver__c (Lookup Driver)
            //       - DriverCost__c (Currency)
            //       - DriverPoints__c (Number)
            //       - Name (Team Fantasy Driver Name)
            // ------------------------------------------------------
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

            // ------------------------------------------------------
            // 3) Crear registros detalle Team Fantasy Constructor
            //    Objeto: Team_Fantasy_Constructor__c
            //    Campos:
            //       - FantasyTeam__c
            //       - Constructor__c
            //       - ConstructorCost__c
            //       - ConstructorPoints__c
            //       - Name
            // ------------------------------------------------------
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
                    Name                = c.Name   // “Team Fantasy Constructor Name”
                );
                constructorRecords.add(tfc);
            }
            insert constructorRecords;

            // Los totales se calculan con tus roll-ups:
            // DriversValueSum, ConstructorsValue_Sum, DriversPoints_Sum,
            // ConstructorPoints_Sum, Current_Value__c, TotalPoints__c, etc.

            return ft.Id;

        } catch (Exception e) {
            System.debug('*** ERROR en createFantasyTeam: ' + e.getMessage());
            // Enviamos el mensaje real al LWC
            throw new AuraHandledException('Error técnico al crear el equipo: ' + e.getMessage());
        }
    }
}