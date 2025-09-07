
from simple_salesforce import Salesforce

class SalesforceClient:
    def __init__(self, username, password, security_token):
        try:
            self.sf = Salesforce(username=username, password=password, security_token=security_token)
            print("Successfully connected to Salesforce.")
        except Exception as e:
            print(f"Failed to connect to Salesforce: {e}")
            self.sf = None

    def is_connected(self):
        return self.sf is not None

    def update_contact_segment(self, email, segment):
        """
        Updates the 'User_Segment__c' custom field for a Contact based on their email.
        
        NOTE: This assumes you have a custom field with the API name 'User_Segment__c' on the Contact object.
        You will need to adjust the object and field names to match your Salesforce setup.
        """
        if not self.is_connected():
            raise ConnectionError("Not connected to Salesforce.")

        try:
            # Find the contact by email
            contact = self.sf.Contact.get_by_custom_id('Email', email)
            if contact:
                # Update the contact record
                self.sf.Contact.update(contact['Id'], {'User_Segment__c': segment})
                print(f"Successfully updated segment for contact with email: {email}")
                return True
            else:
                print(f"Could not find contact with email: {email}")
                return False
        except Exception as e:
            print(f"Error updating contact in Salesforce: {e}")
            return False
