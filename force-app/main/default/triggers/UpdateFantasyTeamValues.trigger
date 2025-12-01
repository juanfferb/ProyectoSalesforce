trigger UpdateFantasyTeamValues on Team_Fantasy_Driver__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> teamIds = new Set<Id>();

    // Recoger IDs de equipos impactados
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Team_Fantasy_Driver__c rec : Trigger.new) {
            if (rec.FantasyTeam__c != null) {
                teamIds.add(rec.FantasyTeam__c);
            }
        }
    }
    if (Trigger.isDelete) {
        for (Team_Fantasy_Driver__c rec : Trigger.old) {
            if (rec.FantasyTeam__c != null) {
                teamIds.add(rec.FantasyTeam__c);
            }
        }
    }

    if (teamIds.isEmpty()) return;

    // ---- Agregado de Drivers ----
    Map<Id, Decimal> driverCostByTeam   = new Map<Id, Decimal>();
    Map<Id, Decimal> driverPointsByTeam = new Map<Id, Decimal>();

    AggregateResult[] driverAgg = [
        SELECT FantasyTeam__c teamId,
               SUM(DriverCost__c)  totalCost,
               SUM(DriverPoints__c) totalPoints
        FROM Team_Fantasy_Driver__c
        WHERE FantasyTeam__c IN :teamIds
        GROUP BY FantasyTeam__c
    ];

    for (AggregateResult ar : driverAgg) {
        Id tId = (Id) ar.get('teamId');
        driverCostByTeam.put(tId, (Decimal)(ar.get('totalCost')   == null ? 0 : ar.get('totalCost')));
        driverPointsByTeam.put(tId,(Decimal)(ar.get('totalPoints') == null ? 0 : ar.get('totalPoints')));
    }

    // ---- Agregado de Constructors ----
    Map<Id, Decimal> consCostByTeam   = new Map<Id, Decimal>();
    Map<Id, Decimal> consPointsByTeam = new Map<Id, Decimal>();

    AggregateResult[] consAgg = [
        SELECT FantasyTeam__c teamId,
               SUM(ConstructorCost__c)  totalCost,
               SUM(ConstructorPoints__c) totalPoints
        FROM Team_Fantasy_Constructor__c
        WHERE FantasyTeam__c IN :teamIds
        GROUP BY FantasyTeam__c
    ];

    for (AggregateResult ar : consAgg) {
        Id tId = (Id) ar.get('teamId');
        consCostByTeam.put(tId, (Decimal)(ar.get('totalCost')   == null ? 0 : ar.get('totalCost')));
        consPointsByTeam.put(tId,(Decimal)(ar.get('totalPoints') == null ? 0 : ar.get('totalPoints')));
    }

    // ---- Construir updates ----
    List<FantasyTeam__c> teamsToUpdate = new List<FantasyTeam__c>();

    for (Id tId : teamIds) {
        Decimal totalValue  = 0;
        Decimal totalPoints = 0;

        if (driverCostByTeam.containsKey(tId))   totalValue  += driverCostByTeam.get(tId);
        if (consCostByTeam.containsKey(tId))     totalValue  += consCostByTeam.get(tId);

        if (driverPointsByTeam.containsKey(tId)) totalPoints += driverPointsByTeam.get(tId);
        if (consPointsByTeam.containsKey(tId))   totalPoints += consPointsByTeam.get(tId);

        FantasyTeam__c ft = new FantasyTeam__c(
            Id              = tId,
            CurrentValue__c = totalValue,
            Total_Points__c = totalPoints
        );
        teamsToUpdate.add(ft);
    }

    if (!teamsToUpdate.isEmpty()) {
        update teamsToUpdate;
    }
}