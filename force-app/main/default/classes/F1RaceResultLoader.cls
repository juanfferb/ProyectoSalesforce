public with sharing class F1RaceResultLoader {

    public static void loadRaceResults(Integer roundNumber) {
        String endpoint = 'f1/' + roundNumber + '/results.json';
        String jsonResponse = ErgastAPI.getF1Data(endpoint);

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
        List<Object> races = (List<Object>) raceTable.get('Races');

        if (races.isEmpty()) return;

        Map<String, Object> race = (Map<String, Object>) races[0];
        List<Object> results = (List<Object>) race.get('Results');

        List<Result__c> resultadosToInsert = new List<Result__c>();

        for (Object obj : results) {
            Map<String, Object> result = (Map<String, Object>) obj;
            Map<String, Object> driver = (Map<String, Object>) result.get('Driver');
            Map<String, Object> constructor = (Map<String, Object>) result.get('Constructor');

            String driverName = driver.get('givenName') + ' ' + driver.get('familyName');
            String constructorName = (String) constructor.get('name');

            // Buscar piloto y escudería
            List<Driver__c> pilotoList = [SELECT Id FROM Driver__c WHERE Name = :driverName LIMIT 1];
            List<Constructor__c> escuderiaList = [SELECT Id FROM Constructor__c WHERE Name = :constructorName LIMIT 1];

            if (pilotoList.isEmpty() || escuderiaList.isEmpty()) continue;

            Result__c resultado = new Result__c();
            resultado.Driver__c = pilotoList[0].Id;
            resultado.Constructor__c = escuderiaList[0].Id;
            resultado.Points__c = Decimal.valueOf((String) result.get('points'));
            resultado.Position__c = Integer.valueOf((String) result.get('position'));
            resultado.Grid__c = Integer.valueOf((String) result.get('grid'));
            resultado.Laps__c = Integer.valueOf((String) result.get('laps'));
            resultado.FastestLap__c = (result.get('FastestLap') != null);
            resultadosToInsert.add(resultado);
        }

        insert resultadosToInsert;
    }
}