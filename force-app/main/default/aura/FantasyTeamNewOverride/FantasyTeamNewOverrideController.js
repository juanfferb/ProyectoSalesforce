({
    handleClose : function(component, event, helper) {
        var closeEvt = $A.get("e.force:closeQuickAction");
        if (closeEvt) {
            closeEvt.fire();
        }
    }
})