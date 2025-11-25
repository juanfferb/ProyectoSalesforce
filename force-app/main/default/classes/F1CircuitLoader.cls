public with sharing class F1CircuitLoader {
    public static void loadCircuits() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30;
            Boolean moreData = true;

            List<Circuit__c> allCircuits = new List<Circuit__c>();

            while (moreData) {
                String endpoint = 'f1/circuits.json?limit=' + pageLimit + '&offset=' + offset;
                String jsonResponse = ErgastAPI.getF1Data(endpoint);

                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                if (!root.containsKey('MRData')) break;

                Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
                Object circuitTableObj = mrData.get('CircuitTable');
                if (!(circuitTableObj instanceof Map<String, Object>)) break;

                Map<String, Object> circuitTable = (Map<String, Object>) circuitTableObj;
                List<Object> circuits = (List<Object>) circuitTable.get('Circuits');
                if (circuits == null || circuits.isEmpty()) {
                    moreData = false;
                    break;
                }

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

                    allCircuits.add(circuito);
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert allCircuits CircuitId__c;
            System.debug('Circuitos procesados: ' + allCircuits.size());
        } catch (Exception e) {
            System.debug('Error en loadCircuits: ' + e.getMessage());
        }
    }
}