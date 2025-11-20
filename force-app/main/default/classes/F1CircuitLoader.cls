public with sharing class F1CircuitLoader {

    public static void loadCircuits() {
        String endpoint = 'f1/current.json';
        String jsonResponse = ErgastAPI.getF1Data(endpoint);

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
        List<Object> races = (List<Object>) raceTable.get('Races');

        List<Circuit__c> circuitosToInsert = new List<Circuit__c>();

        for (Object obj : races) {
            Map<String, Object> race = (Map<String, Object>) obj;
            Map<String, Object> circuit = (Map<String, Object>) race.get('Circuit');
            Map<String, Object> location = (Map<String, Object>) circuit.get('Location');

            Circuit__c circuito = new Circuit__c();
            circuito.Name = (String) circuit.get('circuitName');
            circuito.Circuit_Code__c = (String) circuit.get('circuitId');
            circuito.City__c = (String) location.get('locality');
            circuito.Country__c = (String) location.get('country');
            circuito.Reference_URL__c = (String) circuit.get('url');
            circuitosToInsert.add(circuito);
        }

        insert circuitosToInsert;
    }
}