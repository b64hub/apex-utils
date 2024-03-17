public virtual class DML implements IDML {
    Database.DMLOptions dmlOptions;

    public DML() {
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.OptAllOrNone = true;
        this.dmlOptions = dmlOptions;
    }

    public DML(Database.DMLOptions dmlOptions) {
        this.dmlOptions = dmlOptions;
    }

    public DML allowPartial() {
        this.dmlOptions.OptAllOrNone = false;
        return this;
    }

    public SObject doInsert(SObject record) {
        return this.doInsert(new List<SObject>{ record })[0];
    }

    public virtual List<SObject> doInsert(List<SObject> records) {
        try {
            List<Database.SaveResult> result = Database.insert(
                records,
                dmlOptions
            );
        } catch (Exception e) {
            Logger.error(e.getMessage());
            Logger.saveLog();
            throw e;
        }
        return records;
    }

    public SObject doUpdate(SObject record) {
        return this.doUpdate(new List<SObject>{ record })[0];
    }

    public virtual List<SObject> doUpdate(List<SObject> records) {
        try {
            List<Database.SaveResult> result = Database.update(
                records,
                this.dmlOptions
            );
        } catch (Exception e) {
            Logger.error(e.getMessage());
            Logger.saveLog();
            throw e;
        }
        return records;
    }

    public SObject doUpsert(SObject record) {
        return this.doUpsert(new List<SObject>{ record })[0];
    }

    public virtual List<SObject> doUpsert(List<SObject> records) {
        try {
            List<Database.UpsertResult> result = Database.upsert(records);
        } catch (Exception e) {
            Logger.error(e.getMessage());
            Logger.saveLog();
            throw e;
        }
        return records;
    }

    public virtual List<SObject> doUpsert(
        List<SObject> records,
        Schema.SObjectField externalIDField
    ) {
        try {
            List<Database.UpsertResult> result = Database.upsert(
                records,
                externalIDField
            );
        } catch (Exception e) {
            Logger.error(e.getMessage());
            Logger.saveLog();
            throw e;
        }
        return records;
    }

    public void doDelete(SObject record) {
        this.doDelete(new List<SObject>{ record });
    }

    public virtual void doDelete(List<SObject> records) {
        try {
            List<Database.DeleteResult> result = Database.delete(
                records,
                this.dmlOptions.OptAllOrNone
            );
        } catch (Exception e) {
            Logger.error(e.getMessage());
            Logger.saveLog();
            throw e;
        }
    }

    public SObject doUndelete(SObject record) {
        return this.doUndelete(new List<SObject>{ record })[0];
    }

    public virtual List<SObject> doUndelete(List<SObject> records) {
        Database.undelete(records);
        return records;
    }

    public void doHardDelete(SObject record) {
        this.doHardDelete(new List<SObject>{ record });
    }

    public virtual void doHardDelete(List<SObject> records) {
        Database.emptyRecycleBin(records);
    }
}
