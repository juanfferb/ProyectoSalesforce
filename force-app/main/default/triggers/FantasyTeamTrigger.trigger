trigger FantasyTeamTrigger on FantasyTeam__c (before insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        for (FantasyTeam__c ft : Trigger.new) {
            if (ft.CurrentValue__c > 100000000) {
                ft.addError('El presupuesto no puede superar los 100M.');
            }
        }
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        for (FantasyTeam__c ft : Trigger.new) {
            EmailHelper.sendFantasyTeamNotification(ft.Id);
        }
    }
}