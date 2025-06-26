@IsTest
private class CustomMetadataDeployerTest {

    @IsTest
    static void testAddRecord() {
        CustomMetadataDeployer deployer = new CustomMetadataDeployer();
        Assert.isNotNull(deployer.deployContainer);

        Metadata.CustomMetadata metadataRecord = new Metadata.CustomMetadata();
        metadataRecord.fullName = 'Test__mdt.Test';
        metadataRecord.label = 'Test';

        deployer.addRecord(metadataRecord);

        Assert.areEqual(new List<Metadata.CustomMetadata> { metadataRecord }, deployer.deployContainer.getMetadata());
    }

    @IsTest
    static void testInitRecords() {
        Metadata.CustomMetadata metadataRecord = new Metadata.CustomMetadata();
        metadataRecord.fullName = 'Test__mdt.Test';
        metadataRecord.label = 'Test';

        CustomMetadataDeployer deployer = new CustomMetadataDeployer(new List<Metadata.CustomMetadata> { metadataRecord });

        Assert.areEqual(new List<Metadata.CustomMetadata> { metadataRecord }, deployer.deployContainer.getMetadata());
    }


}