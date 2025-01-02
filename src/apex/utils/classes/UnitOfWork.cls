public class UnitOfWork {
    UnitOfWork.TransactionControls controls;
    public static UnitOfWork instance;
    public Map<String, ITransaction> transactions = new Map<String, ITransaction>();

    public UnitOfWork(UnitOfWork.TransactionControls controls) {
        this.controls = controls;
    }

    public UnitOfWork() {
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

    public void setControls(UnitOfWork.TransactionControls controls) {
        this.controls = controls;
    }

    public class TransactionException extends Exception {
    }

    /**
     * Saves all the registered DML transactions.
     * It sorts the transactions, logs the execution of each transaction, and executes each transaction.
     * If a transaction fails, it logs the error, puts the transaction back to the map, and rethrows the exception.
     */
    public void save() {
        for (String key : this.sortTransactions()) {
            Logger.info('Executing transaction ' + key);
            ITransaction trx = this.popTransaction(key);

            if (trx == null) {
                continue;
            }

            try {
                trx.execute();
            } catch (Exception e) {
                Logger.error(
                    'Transaction ' +
                        key +
                        ' failed with the following error: ' +
                        e.getMessage()
                );
                this.transactions.put(key, trx);
                throw e;
            }
            Logger.info(
                'Transaction ' +
                    key +
                    ' successfully executed with ' +
                    trx.getRecords().size() +
                    ' records.'
            );
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
        List<ITransaction> values = this.getTransactions();

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

    public List<ITransaction> getTransactions() {
        return new List<ITransaction>(this.transactions.values());
    }

    /**
     * Registers new records for insertion
     */
    public DmlTransaction registerNew(List<SObject> records) {
        DmlTransaction trx = (DmlTransaction) this.newTransaction(
            this.controls.defaultTransactionTypes.get('insert')
        );
        trx.addRecords(records);
        return (DmlTransaction) this.addTransaction(trx);
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
        UpsertTransaction trx = (UpsertTransaction) this.newTransaction(
            this.controls.defaultTransactionTypes.get('upsert')
        );
        trx.addRecords(records);
        trx.setExternalId(externalId);
        return (DmlTransaction) this.addTransaction(trx);
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
        DmlTransaction trx = (DmlTransaction) this.newTransaction(
            this.controls.defaultTransactionTypes.get('update')
        );
        trx.addRecords(records);
        return (DmlTransaction) this.addTransaction(trx);
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
        DmlTransaction trx = (DmlTransaction) this.newTransaction(
            this.controls.defaultTransactionTypes.get('delete')
        );
        trx.addRecords(records);
        return (DmlTransaction) this.addTransaction(trx);
    }

    public DmlTransaction registerDelete(SObject record) {
        return this.registerDelete(new List<SObject>{ record });
    }

    public EventTransaction registerPublish(List<SObject> records) {
        EventTransaction trx = (EventTransaction) this.newTransaction(
            this.controls.defaultTransactionTypes.get('event')
        );
        trx.addRecords(records);
        return (EventTransaction) this.addTransaction(trx);
    }

    public EventTransaction registerPublish(SObject record) {
        return this.registerPublish(new List<SObject>{ record });
    }

    private ITransaction newTransaction(String transactionType) {
        Object typeInstance = TypeFactory.newInstance(transactionType);
        if (typeInstance == null || !(typeInstance instanceof ITransaction)) {
            throw new TransactionException(
                'Invalid transaction type: ' + transactionType
            );
        }
        return (ITransaction) typeInstance;
    }

    private ITransaction getTransaction(String key) {
        return this.transactions.get(key);
    }

    /**
     * Idempotent method to add a transaction to the map
     * If the transaction already exists, the records are added to the existing transaction
     *
     * @param trx The transaction to add
     * @return The resulting transaction
     */
    public ITransaction addTransaction(ITransaction trx) {
        if (this.transactions.containsKey(trx.key())) {
            ITransaction existingTrx = this.getTransaction(trx.key());
            existingTrx.add(trx);
            return existingTrx;
        }

        if (trx.getOrder() == null) {
            trx.setOrder(this.controls.order());
        }

        this.transactions.put(trx.key(), trx);

        return trx;
    }

    public interface ITransaction {
        void addRecords(List<SObject> records);
        List<SObject> getRecords();
        String getSObjectType();
        void add(ITransaction trx);
        void setOrder(Integer order);
        Integer getOrder();
        void execute();
        String key();
    }

    public abstract class TransactionUnit implements ITransaction {
        public Integer order;
        protected String sObjectType;
        public List<SObject> records = new List<SObject>();
        protected IDML dmlHandler;

        public TransactionUnit() {
        }

        public TransactionUnit(List<SObject> records) {
            this.addRecords(records);
        }

        public void setSObjectType(String sObjectType) {
            this.sObjectType = sObjectType;
        }

        public String getSObjectType() {
            if (this.sObjectType == null) {
                this.sObjectType = this.getRecords()
                    .get(0)
                    ?.getSObjectType()
                    .getDescribe()
                    .getName();
            }
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

        public virtual void setHandler(IDML dmlHandler) {
            this.dmlHandler = dmlHandler;
        }

        private virtual void verifyTransaction() {
            if (this.dmlHandler == null) {
                throw new TransactionException('DML handler is not set');
            }

            if (this.getRecords().isEmpty()) {
                throw new TransactionException('No records to process');
            }
        }

        public abstract void execute();

        public virtual String key() {
            return String.valueOf(this).substringBefore(':') +
                '(' +
                this.getSObjectType() +
                ')';
        }

        public virtual void add(ITransaction trx) {
            if (this.getSObjectType() != trx.getSObjectType()) {
                throw new TransactionException(
                    'Cannot add transaction with different sObjectType'
                );
            }
            this.addRecords(trx.getRecords());
        }
    }

    public abstract class DmlTransaction extends TransactionUnit {
        public Savepoint trxSavePoint;

        private List<IHook> preHooks = new List<IHook>();
        private List<IHook> postHooks = new List<IHook>();

        public void rollback() {
            Database.rollback(this.trxSavePoint);
        }

        public void setSavepoint() {
            this.trxSavePoint = Database.setSavepoint();
        }

        public override void verifyTransaction() {
            if (this.dmlHandler == null) {
                this.setHandler((DML) TypeFactory.newInstance('DML'));
            }

            if (this.getRecords().isEmpty()) {
                throw new TransactionException('No records to process');
            }
        }

        public void addPreHook(IHook hook) {
            this.preHooks.add(hook);
        }

        public void addPostHook(IHook hook) {
            this.postHooks.add(hook);
        }

        private void executeHooks(List<IHook> hooks) {
            for (IHook hook : hooks) {
                hook.call();
            }
        }

        private void executePreHooks() {
            if (this.preHooks.size() == 0) {
                return;
            }

            Logger.info('executing pre transaction hooks for ' + this.key());
            this.executehooks(this.prehooks);
        }

        private void executePostHooks() {
            if (this.postHooks.size() == 0) {
                return;
            }

            Logger.info('executing post transaction hooks for ' + this.key());
            this.executehooks(this.postHooks);
        }

        public void addRelationship(SObjectRelationship relationship) {
            this.preHooks.add(relationship);
        }

        public void setRelationship(
            SObject record,
            String relationField,
            SObject relatedTo
        ) {
            this.addRelationship(
                new LookupRelationship(record, relationField, relatedTo)
            );
        }

        public void setRelationship(
            List<SObject> records,
            String relationField,
            SObject relatedTo
        ) {
            for (SObject record : records) {
                this.addRelationship(
                    new LookupRelationship(record, relationField, relatedTo)
                );
            }
        }

        public void setRelationship(
            SObject record,
            String targetField,
            SObject source,
            String sourceField
        ) {
            this.addRelationship(
                new SObjectRelationship(
                    record,
                    targetField,
                    source,
                    sourceField
                )
            );
        }

        public override void add(ITransaction trx) {
            super.add(trx);
            if (trx instanceof DmlTransaction) {
                this.preHooks.addAll(((DmlTransaction) trx).preHooks);
                this.postHooks.addAll(((DmlTransaction) trx).postHooks);
            }
        }
    }

    public class InsertTransaction extends DmlTransaction {
        public override void execute() {
            this.verifyTransaction();
            this.setSavepoint();

            this.executePreHooks();
            this.dmlHandler.doInsert(this.records);
            this.executePostHooks();
        }
    }

    public class UpsertTransaction extends DmlTransaction {
        public Schema.SObjectField externalIdField;

        public void setExternalId(Schema.SObjectField externalIdField) {
            this.externalIdField = externalIdField;
        }

        public override void execute() {
            this.verifyTransaction();
            this.setSavepoint();
            this.executePreHooks();

            if (this.externalIdField != null) {
                this.dmlHandler.doUpsert(this.records, this.externalIdField);
            } else {
                this.dmlHandler.doUpsert(this.records);
            }

            this.executePostHooks();
        }

        public override String key() {
            if (externalIdField == null) {
                return super.key();
            }

            return String.valueOf(this).substringBefore(':') +
                '(' +
                this.getSObjectType() +
                '.' +
                this.externalIdField.toString() +
                ')';
        }
    }

    public class UpdateTransaction extends DmlTransaction {
        public override void execute() {
            this.verifyTransaction();
            this.setSavepoint();

            this.executePreHooks();
            this.dmlHandler.doUpdate(this.records);
            this.executePostHooks();
        }
    }

    public class DeleteTransaction extends DmlTransaction {
        public override void execute() {
            this.verifyTransaction();
            this.setSavepoint();

            this.executePreHooks();
            this.dmlHandler.doDelete(this.records);
            this.executePostHooks();
        }
    }

    public class EventTransaction extends TransactionUnit {
        public override void verifyTransaction() {
            if (this.dmlHandler == null) {
                this.setHandler((DML) TypeFactory.newInstance('DML'));
            }

            if (this.getRecords().isEmpty()) {
                throw new TransactionException('No records to process');
            }
        }

        public override void execute() {
            this.verifyTransaction();
            this.dmlHandler.doPublish(this.records);
        }
    }

    public interface IHook {
        Object call();
    }

    public abstract class Hook implements IHook, Callable {
        Map<String, Object> args;
        String action;

        public void setArgs(Map<String, Object> args) {
            this.args = args;
        }

        public void setAction(String action) {
            this.action = action;
        }

        public virtual Object call() {
            return (SObject) this.call(this.action, this.args);
        }

        public abstract Object call(String action, Map<String, Object> args);
    }

    public class LookupRelationship extends SObjectRelationship {
        public LookupRelationship(
            sObject record,
            String relationField,
            sObject relatedTo
        ) {
            super(record, relationField, relatedTo, 'Id');
        }
    }

    public virtual class SObjectRelationship extends Hook {
        public SObjectRelationship() {
        }

        public SObjectRelationship(
            sObject target,
            String targetField,
            sObject source,
            String sourceField
        ) {
            this.setAction('resolve');
            this.setArgs(
                new Map<String, Object>{
                    'source' => source,
                    'sourceField' => sourceField,
                    'target' => target,
                    'targetField' => targetField
                }
            );
        }

        /**
         * Generic implementation of SObject1.field1 = SObject2.field2
         */
        public override Object call(String action, Map<String, Object> args) {
            if (action == 'resolve') {
                SObject source = (SObject) args.get('source');
                String sourceField = (String) args.get('sourceField');
                SObject target = (SObject) args.get('target');
                String targetField = (String) args.get('targetField');

                return target.put(targetField, source.get(sourceField));
            }

            return null;
        }
    }

    public class TransactionOrder implements System.Comparator<ITransaction> {
        List<String> sObjectOrder;

        public TransactionOrder(List<String> sObjectOrder) {
            this.sObjectOrder = sObjectOrder;
        }

        public Integer compare(ITransaction trx1, ITransaction trx2) {
            if (this.sObjectOrder != null) {
                Integer index1 = this.sObjectOrder.indexOf(
                    trx1.getSObjectType()
                );
                Integer index2 = this.sObjectOrder.indexOf(
                    trx2.getSObjectType()
                );

                if (index1 != -1 && index2 != -1) {
                    return index1 - index2;
                }

                if (index1 != -1) {
                    return -1;
                }

                if (index2 != -1) {
                    return 1;
                }
            }

            return trx1.getOrder() - trx2.getOrder();
        }
    }
}
