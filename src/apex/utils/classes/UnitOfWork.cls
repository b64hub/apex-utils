public class UnitOfWork {
    IDML dmlHandler;
    UnitOfWork.TransactionControls controls;

    public static UnitOfWork instance;
    public Map<String, ITransaction> transactions = new Map<String, ITransaction>();

    public UnitOfWork(
        IDML dmlHandler,
        UnitOfWork.TransactionControls controls
    ) {
        this.dmlHandler = dmlHandler;
        this.controls = controls;
    }

    public UnitOfWork() {
        this.dmlHandler = (IDML) TypeFactory.newInstance('DML');
        this.controls = new UnitOfWork.TransactionControls();
    }

    /**
     * Returns the singleton instance of the UnitOfWork
     */
    public static UnitOfWork getInstance() {
        if (UnitOfWork.instance == null) {
            UnitOfWork.instance = new UnitOfWork();
        }

        return UnitOfWork.instance;
    }

    public class TransactionControls {
        public Map<String, String> defaultTransactionTypes = new Map<String, String>{
            'insert' => 'UnitOfWork.InsertTransaction',
            'update' => 'UnitOfWork.UpdateTransaction',
            'upsert' => 'UnitOfWork.UpsertTransaction',
            'delete' => 'UnitOfWork.DeleteTransaction',
            'event' => 'UnitOfWork.EventTransaction'
        };
        public Integer orderIncrement = 10;
        public Integer order = 0;
        public List<String> sObjectOrder;

        // During trigger recursion, one trasaction might be commited by another trigger if the singleton instance is used
        // This flag allows to skip the transaction if null and continue with the next one. By default throws error.
        public Boolean throwTrxNull = true;

        private Integer order() {
            this.order += this.orderIncrement;
            return this.order;
        }
    }

    public class TransactionException extends Exception {
    }

    /**
     * Saves all the registered DML transactions.
     * It sorts the transactions, logs the execution of each transaction, and executes each transaction.
     * If a transaction fails, it logs the error, re-adds the transaction to the map, and rethrows the exception.
     */
    public void save() {
        for (String key : this.sortTransactions()) {
            Logger.info('Executing transaction ' + key);
            ITransaction trx = this.popTransaction(key);

            if (trx == null) {
                continue;
            }

            try {
                trx.execute(this.dmlHandler);
            } catch (Exception e) {
                Logger.error(e.getMessage());
                this.transactions.put(key, trx);
                throw e;
            }
        }
    }

    /**
     * Pops a transaction from the map.
     * If the transaction is null and throwTrxNull is true, it logs an error and throws a TransactionException.
     * @param key The key of the transaction to pop.
     * @return The popped transaction.
     * @throws TransactionException If the transaction is null and throwTrxNull is true.
     */
    private ITransaction popTransaction(String key) {
        ITransaction trx = this.transactions.remove(key);

        if (trx == null && this.controls.throwTrxNull) {
            Logger.error('Transaction ' + key + ' is null');
            throw new TransactionException('Transaction ' + key + ' is null');
        }

        return trx;
    }

    @TestVisible
    private List<String> sortTransactions() {
        List<String> keys = new List<String>(this.transactions.keySet());
        List<ITransaction> values = new List<ITransaction>(
            this.transactions.values()
        );

        values.sort(
            new UnitOfWork.TransactionOrder(this.controls.sObjectOrder)
        );

        List<String> sortedKeys = new List<String>();
        for (ITransaction value : values) {
            for (String key : keys) {
                if (this.transactions.get(key) == value) {
                    sortedKeys.add(key);
                    keys.remove(keys.indexOf(key));
                    break;
                }
            }
        }

        return sortedKeys;
    }

    /**
     * Registers new records for insertion
     */
    public DmlTransaction registerNew(List<SObject> records) {
        DmlTransaction trx = (DmlTransaction) this.getTransaction(
            records.get(0)?.getSObjectType().getDescribe().getName(),
            this.controls.defaultTransactionTypes.get('insert')
        );
        trx.addRecords(records);
        return trx;
    }

    public DmlTransaction registerNew(SObject record) {
        return this.registerNew(new List<SObject>{ record });
    }

    public DmlTransaction registerNew(
        List<SObject> records,
        String relationField,
        SObject relatedTo
    ) {
        DmlTransaction trx = this.registerNew(records);
        trx.setRelationship(records, relationField, relatedTo);
        return trx;
    }

    public DmlTransaction registerNew(
        SObject record,
        String relationField,
        SObject relatedTo
    ) {
        return this.registerNew(
            new List<SObject>{ record },
            relationField,
            relatedTo
        );
    }

    public DmlTransaction registerNew(
        List<SObject> records,
        Schema.SObjectField externalId
    ) {
        UpsertTransaction trx = (UpsertTransaction) this.getTransaction(
            records.get(0)?.getSObjectType().getDescribe().getName(),
            this.controls.defaultTransactionTypes.get('upsert')
        );
        trx.addRecords(records);
        trx.setExternalId(externalId);
        return trx;
    }

    public DmlTransaction registerNew(
        SObject record,
        Schema.SObjectField externalId
    ) {
        return this.registerNew(new List<SObject>{ record }, externalId);
    }

    public DmlTransaction registerNew(
        List<SObject> records,
        String relationField,
        SObject relatedTo,
        Schema.SObjectField externalId
    ) {
        DmlTransaction trx = this.registerNew(records, externalId);
        trx.setRelationship(records, relationField, relatedTo);
        return trx;
    }

    public DmlTransaction registerNew(
        SObject record,
        String relationField,
        SObject relatedTo,
        Schema.SObjectField externalId
    ) {
        return this.registerNew(
            new List<SObject>{ record },
            relationField,
            relatedTo,
            externalId
        );
    }

    /**
     * Registers new records for update
     */
    public DmlTransaction registerUpdate(List<SObject> records) {
        DmlTransaction trx = (DmlTransaction) this.getTransaction(
            records.get(0)?.getSObjectType().getDescribe().getName(),
            this.controls.defaultTransactionTypes.get('update')
        );
        trx.addRecords(records);
        return trx;
    }

    public DmlTransaction registerUpdate(SObject record) {
        return this.registerUpdate(new List<SObject>{ record });
    }

    public DmlTransaction registerUpdate(
        List<SObject> records,
        String relationField,
        SObject relatedTo
    ) {
        DmlTransaction trx = this.registerUpdate(records);
        trx.setRelationship(records, relationField, relatedTo);
        return trx;
    }

    public DmlTransaction registerUpdate(
        SObject record,
        String relationField,
        SObject relatedTo
    ) {
        DmlTransaction trx = this.registerUpdate(record);
        trx.setRelationship(record, relationField, relatedTo);
        return trx;
    }

    /**
     * Registers new records for delete
     */
    public DmlTransaction registerDelete(List<SObject> records) {
        DmlTransaction trx = (DmlTransaction) this.getTransaction(
            records.get(0)?.getSObjectType().getDescribe().getName(),
            this.controls.defaultTransactionTypes.get('delete')
        );
        trx.addRecords(records);
        return trx;
    }

    public DmlTransaction registerDelete(SObject record) {
        return this.registerDelete(new List<SObject>{ record });
    }

    public EventTransaction registerPublish(List<SObject> records) {
        EventTransaction trx = (EventTransaction) this.getTransaction(
            records.get(0)?.getSObjectType().getDescribe().getName(),
            this.controls.defaultTransactionTypes.get('event')
        );
        trx.addRecords(records);
        return trx;
    }

    public EventTransaction registerPublish(SObject record) {
        return this.registerPublish(new List<SObject>{ record });
    }

    private ITransaction getTransaction(
        String sObjectType,
        String transactionType
    ) {
        if (
            !this.transactions.containsKey(
                UnitOfWork.key(sObjectType, transactionType)
            )
        ) {
            Object typeInstance = TypeFactory.newInstance(transactionType);
            if (
                typeInstance == null || !(typeInstance instanceof ITransaction)
            ) {
                throw new TransactionException(
                    'Invalid transaction type: ' + transactionType
                );
            }

            ITransaction trx = (ITransaction) typeInstance;
            trx.setSObjectType(sObjectType);
            this.addTransaction(trx, transactionType);
        }

        return this.transactions.get(
            UnitOfWork.key(sObjectType, transactionType)
        );
    }

    public void addTransaction(ITransaction trx, String transactionType) {
        if (trx.getOrder() == null) {
            trx.setOrder(this.controls.order());
        }
        this.transactions.put(
            UnitOfWork.key(trx.getSObjectType(), transactionType),
            trx
        );
    }

    private static String key(String sObjectType, String transactionType) {
        return transactionType + '(' + sObjectType + ')';
    }

    public interface ITransaction {
        void addRecords(List<SObject> records);
        List<SObject> getRecords();
        void setSObjectType(String sObjectType);
        String getSObjectType();
        void setOrder(Integer order);
        Integer getOrder();
        void execute(IDML dmlHandler);
    }

    public abstract class TransactionUnit implements ITransaction {
        public Integer order;
        public String sObjectType;
        public List<SObject> records = new List<SObject>();

        public TransactionUnit() {
        }

        public TransactionUnit(List<SObject> records) {
            this.addRecords(records);
            this.setSObjectType(
                records.get(0)?.getSObjectType().getDescribe().getName()
            );
        }

        public void setSObjectType(String sObjectType) {
            this.sObjectType = sObjectType;
        }

        public String getSObjectType() {
            return this.sObjectType;
        }

        public void addRecords(List<SObject> records) {
            this.records.addAll(records);
        }

        public List<SObject> getRecords() {
            return this.records;
        }

        public void setOrder(Integer order) {
            this.order = order;
        }

        public Integer getOrder() {
            return this.order;
        }

        public abstract void execute(IDML dmlHandler);
    }

    public abstract class DmlTransaction extends TransactionUnit {
        public Savepoint trxSavePoint;
        public List<IRelationship> relationships = new List<IRelationship>();

        public void rollback() {
            Database.rollback(this.trxSavePoint);
        }

        public Boolean hasRelationship() {
            return this.relationships.size() > 0;
        }

        public void setRelationship(
            SObject record,
            String relationField,
            SObject relatedTo
        ) {
            this.setRelationship(
                new List<SObject>{ record },
                relationField,
                relatedTo
            );
        }

        public void setRelationship(
            List<SObject> records,
            String relationField,
            SObject relatedTo
        ) {
            for (SObject record : records) {
                this.relationships.add(
                    new RelationshipDefinition(record, relationField, relatedTo)
                );
            }
        }

        public void setRelationship(
            SObject record,
            String targetField,
            SObject source,
            String sourceField,
            Callable resolveHook
        ) {
            this.setRelationship(
                new List<SObject>{ record },
                targetField,
                source,
                sourceField,
                resolveHook
            );
        }

        public void setRelationship(
            List<SObject> records,
            String targetField,
            sObject source,
            String sourceField,
            Callable resolveHook
        ) {
            for (SObject target : records) {
                this.relationships.add(
                    new UnitOfWork.CustomRelationshipDefinition(
                        target,
                        targetField,
                        source,
                        sourceField,
                        resolveHook
                    )
                );
            }
        }

        public void resolveRelationships() {
            for (IRelationship rel : this.relationships) {
                rel.resolve();
            }
        }
    }

    public class InsertTransaction extends DmlTransaction {
        public override void execute(IDML dmlHandler) {
            this.trxSavePoint = Database.setSavepoint();

            if (this.hasRelationship()) {
                this.resolveRelationships();
            }

            dmlHandler.doInsert(this.records);
        }
    }

    public class UpsertTransaction extends DmlTransaction {
        public Schema.SObjectField externalIdField;

        public void setExternalId(Schema.SObjectField externalIdField) {
            this.externalIdField = externalIdField;
        }

        public override void execute(IDML dmlHandler) {
            this.trxSavePoint = Database.setSavepoint();

            if (this.hasRelationship()) {
                this.resolveRelationships();
            }

            if (this.externalIdField != null) {
                dmlHandler.doUpsert(this.records, this.externalIdField);
            } else {
                dmlHandler.doUpsert(this.records);
            }
        }
    }

    public class UpdateTransaction extends DmlTransaction {
        public override void execute(IDML dmlHandler) {
            this.trxSavePoint = Database.setSavepoint();

            if (this.hasRelationship()) {
                this.resolveRelationships();
            }

            dmlHandler.doUpdate(this.records);
        }
    }

    public class DeleteTransaction extends DmlTransaction {
        public override void execute(IDML dmlHandler) {
            this.trxSavePoint = Database.setSavepoint();

            dmlHandler.doDelete(this.records);
        }
    }

    public class EventTransaction extends TransactionUnit {
        public override void execute(IDML dmlHandler) {
            dmlHandler.doPublish(this.records);
        }
    }

    public interface IRelationship {
        SObject resolve();
    }

    public class RelationshipDefinition extends CustomRelationshipDefinition {
        public RelationshipDefinition(
            sObject record,
            String relationField,
            sObject relatedTo
        ) {
            super(record, relationField, relatedTo, 'Id');
        }
    }

    public virtual class CustomRelationshipDefinition implements IRelationship {
        public SObject source;
        public String sourceField;
        public SObject target;
        public String targetField;
        public Callable resolveHook;

        public CustomRelationshipDefinition(
            sObject target,
            String targetField,
            sObject source,
            String sourceField
        ) {
            this(target, targetField, source, sourceField, null);
        }

        public CustomRelationshipDefinition(
            sObject target,
            String targetField,
            sObject source,
            String sourceField,
            Callable resolveHook
        ) {
            this.target = target;
            this.targetField = targetField;
            this.source = source;
            this.sourceField = sourceField;
            this.resolveHook = resolveHook;
        }

        public virtual SObject resolve() {
            if (resolveHook != null) {
                this.target.put(
                    targetField,
                    this.resolveHook.call(
                        this.sourceField,
                        new Map<String, Object>{ 'source' => this.source }
                    )
                );
            } else {
                this.target.put(targetField, source.get(sourceField));
            }

            return this.target;
        }
    }

    public class TransactionOrder implements System.Comparator<ITransaction> {
        List<String> sObjectOrder;

        public TransactionOrder(List<String> sObjectOrder) {
            this.sObjectOrder = sObjectOrder;
        }

        public Integer compare(ITransaction trx_1, ITransaction trx_2) {
            if (this.sObjectOrder != null) {
                return this.sObjectOrder.indexOf(trx_1.getSObjectType()) -
                    this.sObjectOrder.indexOf(trx_2.getSObjectType());
            }

            return trx_1.getOrder() - trx_2.getOrder();
        }
    }
}
