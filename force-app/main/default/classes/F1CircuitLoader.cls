public with sharing class F1CircuitLoader {
    public static void loadCircuits() {
        try {
            String endpoint = 'f1/circuits.json'; // URL correcta para circuitos
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object circuitTableObj = mrData.get('CircuitTable');
            if (!(circuitTableObj instanceof Map<String, Object>)) return;

            Map<String, Object> circuitTable = (Map<String, Object>) circuitTableObj;
            List<Object> circuits = (List<Object>) circuitTable.get('Circuits');
            if (circuits == null || circuits.isEmpty()) return;

            List<Circuit__c> circuitosToUpsert = new List<Circuit__c>();

            for (Object obj : circuits) {
                Map<String, Object> circuit = (Map<String, Object>) obj;
                Map<String, Object> location = (Map<String, Object>) circuit.get('Location');

                Circuit__c circuito = new Circuit__c();
                circuito.Name = (String) circuit.get('circuitName');
                circuito.CircuitId__c = (String) circuit.get('circuitId'); // External ID
                circuito.Locality__c = (String) location.get('locality');
                circuito.Country__c = (String) location.get('country');
                circuito.Longitude__c = (String) location.get('long');
                circuito.Latitude__c = (String) location.get('lat');
                circuito.URL__c = (String) circuit.get('url');

                circuitosToUpsert.add(circuito);
            }

            // Upsert usando External ID
            upsert circuitosToUpsert CircuitId__c;

            System.debug('Circuitos procesados: ' + circuitosToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadCircuits: ' + e.getMessage());
        }
    }
}