public with sharing class F1DriverTeamLoader {
    public static void loadDriversAndTeams() {
        try {
            String endpoint = 'f1/current/driverStandings.json';
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object standingsObj = mrData.get('StandingsTable');
            if (!(standingsObj instanceof Map<String, Object>)) return;

            Map<String, Object> standingsTable = (Map<String, Object>) standingsObj;
            List<Object> standingsLists = (List<Object>) standingsTable.get('StandingsLists');
            if (standingsLists == null || standingsLists.isEmpty()) return;

            Map<String, Object> firstList = (Map<String, Object>) standingsLists[0];
            List<Object> driverStandings = (List<Object>) firstList.get('DriverStandings');

            Map<String, Id> escuderiasMap = new Map<String, Id>();
            List<Constructor__c> escuderiasToUpsert = new List<Constructor__c>();
            List<Driver__c> pilotosToUpsert = new List<Driver__c>();

            for (Object obj : driverStandings) {
                Map<String, Object> driverStanding = (Map<String, Object>) obj;
                Map<String, Object> driver = (Map<String, Object>) driverStanding.get('Driver');
                List<Object> constructorsList = (List<Object>) driverStanding.get('Constructors');
                if (constructorsList.isEmpty()) continue;

                Map<String, Object> constructor = (Map<String, Object>) constructorsList[0];
                String escuderiaName = (String) constructor.get('name');

                if (!escuderiasMap.containsKey(escuderiaName)) {
                    Constructor__c esc = new Constructor__c();
                    esc.Name = escuderiaName;
                    esc.Constructor_Code__c = (String) constructor.get('constructorId'); // External ID
                    esc.Nationality__c = (String) constructor.get('nationality');
                    esc.URL__c = (String) constructor.get('url');
                    escuderiasToUpsert.add(esc);
                    escuderiasMap.put(escuderiaName, null);
                }

                Driver__c piloto = new Driver__c();
                piloto.Name = driver.get('givenName') + ' ' + driver.get('familyName');
                piloto.GivenName__c = (String) driver.get('givenName');
                piloto.FamilyName__c = (String) driver.get('familyName');
                piloto.Nationality__c = (String) driver.get('nationality');
                piloto.DriverId__c = (String) driver.get('driverId');
                piloto.PermanentNumber__c = (String) driver.get('permanentNumber'); // External ID
                piloto.DateOfBirth__c = (String) driver.get('dateOfBirth');
                piloto.Code__c = (String) driver.get('code');
                piloto.URL__c = (String) driver.get('url');
                piloto.Constructor__c = escuderiasMap.get(escuderiaName);
                pilotosToUpsert.add(piloto);
            }

            upsert escuderiasToUpsert Constructor_Code__c;
            for (Constructor__c esc : escuderiasToUpsert) {
                escuderiasMap.put(esc.Name, esc.Id);
            }

            upsert pilotosToUpsert PermanentNumber__c;

            System.debug('Escuderías procesadas: ' + escuderiasToUpsert.size());
            System.debug('Pilotos procesados: ' + pilotosToUpsert.size());

        } catch (Exception e) {
            System.debug('Error en loadDriversAndTeams: ' + e.getMessage());
        }
    }
}