public class CustomMetadataDeployer implements Metadata.DeployCallback {
    @TestVisible
    Metadata.DeployContainer deployContainer;

    public CustomMetadataDeployer(
        List<Metadata.CustomMetadata> metadataRecords
    ) {
        this();
        this.addRecords(metadataRecords);
    }

    public CustomMetadataDeployer() {
        this.deployContainer = new Metadata.DeployContainer();
    }

    public class RecordBuilder {

        Metadata.CustomMetadata metadataRecord;

        public RecordBuilder(Metadata.CustomMetadata metadataRecord) {
            this.metadataRecord = metadataRecord;
        }

        public RecordBuilder(String fullName, String label) {
            this.metadataRecord = new Metadata.CustomMetadata();
            this.metadataRecord.fullName = fullName;
            this.metadataRecord.label = label;
        }

        public RecordBuilder addValue(String field, Object value) {
            Metadata.CustomMetadataValue metadataValue = new Metadata.CustomMetadataValue();
            metadataValue.field = field;
            metadataValue.value = value;
            
            metadataRecord.values.add(metadataValue);
            return this;
        }

        public Metadata.CustomMetadata getRecord() {
            return this.metadataRecord;
        }
    }

    public void addRecord(Metadata.CustomMetadata metadataRecord) {
        this.deployContainer.addMetadata(metadataRecord);
    }

    public void addRecords(List<Metadata.CustomMetadata> metadataRecords) {
        for (Metadata.CustomMetadata metadataRecord : metadataRecords) {
            this.deployContainer.addMetadata(metadataRecord);
        }
    }

    public void deploy() {
        Metadata.Operations.enqueueDeployment(this.deployContainer, this);
    }

    public void handleResult(
        Metadata.DeployResult result,
        Metadata.DeployCallbackContext context
    ) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            Logger.info('Metadata deployment succeeded').addTag('metadata-deployer');
        } else {
            Logger.error('Metadata deployment failed: ' + result.errorMessage).addTag('metadata-deployer');
        }

        Logger.saveLog();
    }
}
