public with sharing class FantasyTeamController {
    @AuraEnabled(cacheable=true)
    public static List<Driver__c> getDrivers() {
        return [SELECT Id, Name, Nationality__c FROM Driver__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Constructor__c> getConstructors() {
        return [SELECT Id, Name, Nationality__c FROM Constructor__c];
    }

    @AuraEnabled
    public static void createFantasyTeam(String name, List<Id> drivers, List<Id> constructors) {
        FantasyTeam__c ft = new FantasyTeam__c(Name = name);
        insert ft;

        List<Team_Fantasy_Driver__c> driverRecords = new List<Team_Fantasy_Driver__c>();
        for (Id dId : drivers) {
            Driver__c d = [SELECT Price__c FROM Driver__c WHERE Id = :dId];
            driverRecords.add(new Team_Fantasy_Driver__c(FantasyTeam__c = ft.Id, Driver__c = dId, DriverCost__c = d.Price__c));
        }
        insert driverRecords;

        List<Team_Fantasy_Constructor__c> constructorRecords = new List<Team_Fantasy_Constructor__c>();
        for (Id cId : constructors) {
            Constructor__c c = [SELECT Price__c FROM Constructor__c WHERE Id = :cId];
            constructorRecords.add(new Team_Fantasy_Constructor__c(FantasyTeam__c = ft.Id, Constructor__c = cId, ConstructorCost__c = c.Price__c));
        }
        insert constructorRecords;
    }
}