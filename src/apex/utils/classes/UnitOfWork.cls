public class UnitOfWork {
    private IDML dmlHandler;

    @TestVisible
    Map<String, DmlTransaction> transactions = new Map<String, DmlTransaction>();

    public UnitOfWork(IDML dmlHandler) {
        this.dmlHandler = dmlHandler;
    }

    public UnitOfWork() {
        this.dmlHandler = (IDML) TypeFactory.newInstance('DML');
    }

    public class TransactionException extends Exception {
    }

    /**
     * Saves all the registered DML transactions
     */
    public void save() {
        System.debug(transactions);
        for (DmlTransaction trx : this.transactions.values()) {
            if (trx.hasRelationship()) {
                trx.resolveRelationships();
            }

            trx.execute(this.dmlHandler);
        }
    }

    /**
     * Registers new records for insertion
     */
    public void registerNew(List<SObject> records) {
        DmlTransaction trx = this.getTransaction(
            records[0].getSObjectType().getDescribe().getName()
        );
        trx.operation = 'upsert';
        trx.addRecords(records);
        this.addTransaction(trx);
    }

    public void registerNew(SObject record) {
        this.registerNew(new List<SObject>{ record });
    }

    public void registerNew(
        SObject record,
        String relationField,
        SObject relatedTo
    ) {
        DmlTransaction trx = this.getTransaction(
            record.getSObjectType().getDescribe().getName()
        );
        trx.operation = 'upsert';
        trx.setRelationship(record, relationField, relatedTo);
        this.addTransaction(trx);
    }

    /**
     * Registers new records for update
     */
    public void registerUpdate(List<SObject> records) {
        DmlTransaction trx = this.getTransaction(
            records[0].getSObjectType().getDescribe().getName()
        );
        trx.operation = 'update';
        trx.addRecords(records);
        this.addTransaction(trx);
    }

    public void registerUpdate(SObject record) {
        this.registerUpdate(new List<SObject>{ record });
    }

    /**
     * Registers new records for delete
     */
    public void registerDelete(List<SObject> records) {
        DmlTransaction trx = this.getTransaction(
            records[0].getSObjectType().getDescribe().getName()
        );
        trx.operation = 'delete';
        trx.addRecords(records);
        this.addTransaction(trx);
    }

    public void registerDelete(SObject record) {
        this.registerDelete(new List<SObject>{ record });
    }

    private DmlTransaction getTransaction(String sObjectType) {
        if (this.transactions.containsKey(sObjectType)) {
            return this.transactions.get(sObjectType);
        }
        DmlTransaction trx = new DmlTransaction();
        trx.sObjectType = sObjectType;
        return trx;
    }

    private void addTransaction(DmlTransaction trx) {
        this.transactions.put(trx.sObjectType, trx);
    }

    public interface ITransaction {
        void execute(IDML dmlHandler);
    }

    public virtual class DmlTransaction implements ITransaction {
        public String operation;
        public Integer order;

        public String sObjectType;
        public Savepoint trxSavePoint;

        public List<RelationshipDefinition> relationships = new List<RelationshipDefinition>();
        public List<SObject> records = new List<SObject>();

        public DmlTransaction() {
        }

        public DmlTransaction(List<SObject> records) {
            this.records.addAll(records);
            this.sObjectType = records[0]
                .getSObjectType()
                .getDescribe()
                .getName();
        }

        public DmlTransaction(List<SObject> records, String operation) {
            this(records);
            this.operation = operation;
        }

        public void execute(IDML dmlHandler) {
            this.trxSavePoint = Database.setSavepoint();

            switch on this.operation {
                when 'insert', 'update', 'upsert' {
                    dmlHandler.doUpsert(this.records);
                }
                when 'delete' {
                    dmlHandler.doDelete(this.records);
                }
                when else {
                    throw new UnitOfWork.TransactionException(
                        'Invalid operation'
                    );
                }
            }
        }

        public void rollback() {
            Database.rollback(this.trxSavePoint);
        }

        public Boolean hasRelationship() {
            return this.relationships.size() > 0;
        }

        public void setRelationship(
            sObject record,
            String relationField,
            sObject relatedTo
        ) {
            this.relationships.add(
                new RelationshipDefinition(record, relationField, relatedTo)
            );
        }

        public void resolveRelationships() {
            for (RelationshipDefinition rel : this.relationships) {
                this.records.add(rel.resolve());
            }
        }

        public void addRecords(List<SObject> records) {
            this.records.addAll(records);
        }
    }

    public class RelationshipDefinition {
        public sObject relatedTo;
        public String relationField;
        public sObject record;

        public RelationshipDefinition(
            sObject record,
            String relationField,
            sObject relatedTo
        ) {
            this.record = record;
            this.relationField = relationField;
            this.relatedTo = relatedTo;
        }

        public SObject resolve() {
            this.record.put(relationField, relatedTo.Id);
            return record;
        }
    }
}
