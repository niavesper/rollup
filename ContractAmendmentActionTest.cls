@isTest
private class ContractAmendmentActionTest {
  /***** Method that returns the sum of Amendment Amounts. To be used in assertions in test methods. *****/
  private static Decimal returnSumOfAmendmentAmts() {
    // Decimal to store the sum of all Amendement Amounts
    Decimal sumOfAmendmentAmts = 0;

    // Query Contract Amendments (those that will be generated by the data factory) and assign them to a list
    List<Contract_Amendment__c> contractAmendments = [
      SELECT Id, Amendment_Amount__c
      FROM Contract_Amendment__c
    ];

    // Loop through queried Contract Amendments.
    // Add their Amendment Amounts (Amendment_Amount__c is the field being summarized) to the Decimal "sumOfAmendmentAmts".
    for (Contract_Amendment__c ca : contractAmendments) {
      if (ca.Amendment_Amount__c != null) {
        sumOfAmendmentAmts = sumOfAmendmentAmts + ca.Amendment_Amount__c;
      }
    }
    return sumOfAmendmentAmts;
  }

  /***** Method that returns the value of the rollup summary, i.e., the value of the Funding Application's field
   "Sum_of_All_Amendment_Amounts_Currency__c". To be used in assertions in test methods. *****/
  private static Decimal returnSumOfAllAmendmentAmtsCurrency() {
    // Decimal to store the value of the rollup summary field.
    Decimal sumOfAllAmendmentAmts = 0;

    // Query Funding Applications (those that will be generated by the data factory) and assign them to a list
    // (there will be only one)
    List<Grant__Funding_Application__c> fundingApps = [
      SELECT Id, Sum_of_All_Amendment_Amounts_Currency__c
      FROM Grant__Funding_Application__c
    ];

    // Assign the value of the rollup summary field to the decimal variable "sumOfAllAmendmentAmts"
    sumOfAllAmendmentAmts =
      sumOfAllAmendmentAmts +
      fundingApps[0].Sum_of_All_Amendment_Amounts_Currency__c;
    return sumOfAllAmendmentAmts;
  }

  /***** Method that tests insertion of Contract Amendments *****/
  @isTest
  private static void testContractAmendmentsInsert() {
    // Invoke a method from the data factory and assign its results to a list
    List<Contract_Amendment__c> contAmends = DataFactory_ContractAmendment.returnContractAmendments();

    test.startTest();
    insert contAmends;
    test.stopTest();

    // Assert that the sum of Amendment Amounts from Funding applications is the same as the value of the rollup summary field
    // on the parent Funding Application. To do so, use the results of the two non-test methods in this class.
    System.assert(
      returnSumOfAmendmentAmts() == returnSumOfAllAmendmentAmtsCurrency(),
      'Sum of Amendment Amts from Contract Amendment should be equal to the value of Funding Application Sum_of_All_Amendment_Amounts_Currency__c'
    );
  }

  /***** Method that tests update of Contract Amendments. *****/
  @isTest
  private static void testContractAmendmentsUpdate() {
    // Invoke a method from the data factory and assign its results to a list
    List<Contract_Amendment__c> contAmends = DataFactory_ContractAmendment.insertAndReturnContractAmendments();

    for (Contract_Amendment__c ca : contAmends) {
      ca.Amendment_Number__c = '1';
    }

    test.startTest();
    update contAmends;
    test.stopTest();

    // Assert that the sum of Amendment Amounts from Funding applications is the same as the value of the rollup summary field
    // on the parent Funding Application. To do so, use the results of the two non-test methods in this class.
    System.assert(
      returnSumOfAmendmentAmts() == returnSumOfAllAmendmentAmtsCurrency(),
      'Sum of Amendment Amts from Contract Amendment should be equal to the value of Funding Application Sum_of_All_Amendment_Amounts_Currency__c'
    );
  }

  /***** Method that tests change of Contract Amendment parent (Funding Application). *****/
  @isTest
  private static void testContractAmendmentsParentUpdate() {
    // Generate and insert two new test Funding Applicaiton
    Grant__Funding_Application__c fa1 = new Grant__Funding_Application__c(
      Grant__Application_Title__c = 'TestFundingApp1'
    );
    Grant__Funding_Application__c fa2 = new Grant__Funding_Application__c(
      Grant__Application_Title__c = 'TestFundingApp2'
    );

    insert fa1;
    insert fa2;

    // Invoke a method from the data factory and assign its results to a list
    List<Contract_Amendment__c> contAmends = DataFactory_ContractAmendment.insertAndReturnContractAmendments();

    // Loop through the list of contract amendments inserted by the data factory method
    // and change their parent Funding App to the first test funding app
    for (Contract_Amendment__c ca : contAmends) {
      ca.Funding_Application__c = fa1.Id;
    }

    test.startTest();
    // Update contract amendments with the new parent #1
    update contAmends;

    //  Query contract amendments that have a new parent
    List<Contract_Amendment__c> contractAmendmentsToUpdateParent = [
      SELECT Id, Amendment_Amount__c, Funding_Application__c
      FROM Contract_Amendment__c
      WHERE Funding_Application__c = :fa1.Id
    ];

    // Loop through the same list of contract amendments
    // and change their parent funding app to the second test funding app
    for (Contract_Amendment__c ca : contractAmendmentsToUpdateParent) {
      ca.Funding_Application__c = fa2.Id;
    }

    // Update contract amendments with the new parent #2
    update contractAmendmentsToUpdateParent;

    test.stopTest();

    // Query the first Funding Application
    List<Grant__Funding_Application__c> fundingApps1 = [
      SELECT Id, Sum_of_All_Amendment_Amounts_Currency__c
      FROM Grant__Funding_Application__c
      WHERE Id = :fa1.Id
    ];

    // Assert that the value of Sum_of_All_Amendment_Amounts_Currency__c is zero (because it's set to zero when there are no related Contract Amendments)
    System.assert(
      fundingApps1[0].Sum_of_All_Amendment_Amounts_Currency__c == 0,
      'Sum of Amendment Amts from Contract Amendment on the original Funding Applicaiton should be zero'
    );

    // Query contract amendments related to the second test funding app
    List<Contract_Amendment__c> contractAmendmentsOnNewFundingApp = [
      SELECT Id, Amendment_Amount__c
      FROM Contract_Amendment__c
      WHERE Funding_Application__c = :fa2.Id
    ];

    // Get the sum of Amendment Amounts of Contract Amendments related to the second Funding Application
    Decimal sumOfAmendmentAmts2 = 0;
    for (Contract_Amendment__c ca : contractAmendmentsOnNewFundingApp) {
      if (ca.Amendment_Amount__c != null) {
        sumOfAmendmentAmts2 = sumOfAmendmentAmts2 + ca.Amendment_Amount__c;
      }
    }

    // Query the second Funding Application
    List<Grant__Funding_Application__c> fundingApps2 = [
      SELECT Id, Sum_of_All_Amendment_Amounts_Currency__c
      FROM Grant__Funding_Application__c
      WHERE Id = :fa2.Id
    ];

    // Assert that the sum of Amendment Amounts from Funding applications is the same as the value of the rollup summary field on the parent Funding Application.
    System.assert(
      sumOfAmendmentAmts2 ==
      fundingApps2[0].Sum_of_All_Amendment_Amounts_Currency__c,
      'Sum of Amendment Amts from Contract Amendment on the new Funding Applicaiton should be equal to the value of Funding Application Sum_of_All_Amendment_Amounts_Currency__c'
    );
  }

  /***** Method that tests deletion of Contract Amendments *****/
  @isTest
  private static void testContractAmendmentsDelete() {
    // Invoke a method from the data factory and assign its results to a list
    List<Contract_Amendment__c> contAmends = DataFactory_ContractAmendment.insertAndReturnContractAmendments();

    test.startTest();
    delete contAmends;
    test.stopTest();

    // Assert that the sum of Amendment Amounts from Funding applications is the same as the value of the rollup summary field
    // on the parent Funding Application. To do so, use the results of the two non-test methods in this class.
    System.debug(
      LoggingLevel.Info,
      'returnSumOfAmendmentAmts (): ' + returnSumOfAmendmentAmts()
    );
    System.debug(
      LoggingLevel.Info,
      'returnSumOfAllAmendmentAmtsCurrency (): ' +
      returnSumOfAllAmendmentAmtsCurrency()
    );
    System.assert(
      returnSumOfAmendmentAmts() == returnSumOfAllAmendmentAmtsCurrency(),
      'Sum of Amendment Amts from Contract Amendment should be equal to the value of Funding Application Sum_of_All_Amendment_Amounts_Currency__c	'
    );
  }

  /***** Method that tests un-deletion of Contract Amendments *****/
  @isTest
  private static void testContractAmendmentsUndelete() {
    // Invoke a method from the data factory and assign its results to a list
    List<Contract_Amendment__c> contAmends = DataFactory_ContractAmendment.deleteContractAmendments();

    test.startTest();
    undelete contAmends;
    test.stopTest();

    // Assert that the sum of Amendment Amounts from Funding applications is the same as the value of the rollup summary field
    // on the parent Funding Application. To do so, use the results of the two non-test methods in this class.
    System.assert(
      returnSumOfAmendmentAmts() == returnSumOfAllAmendmentAmtsCurrency(),
      'Sum of Amendment Amts from Contract Amendment should be equal to the value of Funding Application Sum_of_All_Amendment_Amounts_Currency__c	'
    );
  }
}
