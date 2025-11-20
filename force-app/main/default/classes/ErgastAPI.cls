public with sharing class ErgastAPI {

    public static String getF1Data(String endpoint) {
        String baseUrl = 'https://api.jolpi.ca/ergast/';
        String fullUrl = baseUrl + endpoint;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullUrl);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            return 'Error: ' + response.getStatusCode() + ' - ' + response.getStatus();
        }
    }
}