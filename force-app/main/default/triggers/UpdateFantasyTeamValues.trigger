trigger UpdateFantasyTeamValues on Team_Fantasy_Driver__c (after insert, after update, after delete) {
    Set<Id> teamIds = new Set<Id>();
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Team_Fantasy_Driver__c tfd : Trigger.new) {
            teamIds.add(tfd.FantasyTeam__c);
        }
    }
    if (Trigger.isDelete) {
        for (Team_Fantasy_Driver__c tfd : Trigger.old) {
            teamIds.add(tfd.FantasyTeam__c);
        }
    }

    List<FantasyTeam__c> teamsToUpdate = new List<FantasyTeam__c>();
    for (Id teamId : teamIds) {
        Decimal totalValue = 0;
        Decimal totalPoints = 0;

        for (Team_Fantasy_Driver__c d : [SELECT DriverCost__c, DriverPoints__c FROM Team_Fantasy_Driver__c WHERE FantasyTeam__c = :teamId]) {
            totalValue += (d.DriverCost__c != null) ? d.DriverCost__c : 0;
            totalPoints += (d.DriverPoints__c != null) ? d.DriverPoints__c : 0;
        }

        for (Team_Fantasy_Constructor__c c : [SELECT ConstructorCost__c, ConstructorPoints__c FROM Team_Fantasy_Constructor__c WHERE FantasyTeam__c = :teamId]) {
            totalValue += (c.ConstructorCost__c != null) ? c.ConstructorCost__c : 0;
            totalPoints += (c.ConstructorPoints__c != null) ? c.ConstructorPoints__c : 0;
        }

        FantasyTeam__c ft = new FantasyTeam__c(Id = teamId, CurrentValue__c = totalValue, Total_Points__c = totalPoints);
        teamsToUpdate.add(ft);
    }
    update teamsToUpdate;
}