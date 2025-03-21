# ConfigReaderLocalConnectors

The ConfigReader flow retrieves externally stored config values for the parent flow based on the inputs provided.
It is to be called as a child flow by other flows, and as such it should reside as a utility flow that does not need to be copied, but can be re-used.

The Local Connectors version of the ConfigReader reads configurations from either a local file (JSON or Excel) or a Database table. See **Notes** below regarding the use of the ConfigReader flows.

## Disclaimer
This utility flow is only required if you want to config data externally, and do not want to have a cloud flow retrieving it and passing it into the desktop flow as inputs. If you prefer using Power Platform environment variables in solutions, or have external configurations retrieved via a cloud flow, this utility flow is not needed.

## Version compatibility

The code is compatible with Power Automate Desktop version 2.50.125.24304. Compatibility with other versions is not guaranteed, but it might work with earlier versions, too.
The code currently does not have a version for flows with Power Fx enabled. However, as this is a flow that should be called as a child flow by other flows, it should not matter. It should simply be created without enabling Power Fx.

## Inputs expected

There are several inputs required by this flow, and a couple that are optional (depending on other parameters):

1. **Input_ConfigAddress** - Should contain the address for where the config resource is stored. Should be marked as **sensitive** in case the string contains any sensitive information, such as credentials. Should also be marked as **optional** as it is optional for other config types. For the types where it is necessary, the flow expects it to contain:
    - the connection string the config type is 'Database'
    - the file path when the type is 'Excel'
1. **Input_ConfigPath** - Should contain the path to the config data. The flow expects it to contain:
    - the file path when the config type is 'JSON'
    - a sheet name when the type is 'Excel' 
    - a stored procedure name when the type is 'Database'
1. **Input_ConfigType** - Should contain the config type. Currently supported options are:
    1. JSON
    1. Excel
    1. Database
1. **Input_ProjectName** - Should contain the name of the project to identify the relevant entries in the database. Should be marked as **optional**, as it is irrelevant when config type is 'JSON' or 'Excel'.

## Output produced

The flow produces several output variables that are returned to the parent flow after execution:

1. **Output_ConfigObject** - Returns the custom object with the config data. Should be marked as **sensitive** as the data may contain sensitive values.
1. **Output_Message** - Contains the response of the flow. Can either return a success, or a failure response. Should be used by the parent flow for any logging after calling the child flow. Should be marked as **sensitive** in case the message may contain any sensitive data.
1. **Output_Status** - Contains the status code for the response of the flow. Uses standard HTTP status codes. Can either return a success (200), or a failure status (4xx, 5xx). Should be checked by the parent flow to verify if the child flow succeeded.

## Minimal path to awesome

1. If you have not prepared an environment and a solution for the framework yet:
    1. Open the browser and navigate to [Power Automate cloud portal](https://make.powerautomate.com/)
    1. Create an dedicated environment for the Framework (DEV environments for other flows should contain a managed solution of the Framework - see **Notes** below)
    1. Create a solution called **PADFramework** in the new environment
1. Open **Power Automate Desktop**
1. Create a new flow called **PADFramework: ConfigReaderLocalConnectors** - make sure to not enable Power Fx when creating it

    ![View of the flow creation window in PAD](./assets/creating-the-flow.png)

1. Create the following input and output variables (use the same names for "Variable name" and "External name" fields to avoid unneccessary confusion):
    1. Input:
        1. Input_ConfigAddress (Data type - Text; Mark as sensitive - False; Mark as optional - True)

            ![View of the parameters for the 'Input_ConfigAddress' input variable in PAD](./assets/input-config-address-variable-parameters.png)

        1. Input_ConfigPath (Data type - Text; Mark as sensitive - False; Mark as optional - False)
        1. Input_ConfigType (Data type - Text; Mark as sensitive - False; Mark as optional - False)
        1. Input_ProjectName (Data type - Text; Mark as sensitive - False; Mark as optional - True)
    1. Output:
        1. Output_ConfigObject (Data type: Custom object; Mark as sensitive - True)
        1. Output_Message (Data type: Text; Mark as sensitive - True)

            ![View of the parameters for the 'Output_Message' input variable in PAD](./assets/output-message-variable-parameters.png)

        1. Output_Status (Data type: Number; Mark as sensitive - False)

1. Create new subflows (see **Notes**): 
    1. **ConvertTabularConfigToCustomObject** 
    1. **ReadDatabaseConfig** 
    1. **ReadExcelConfig**
    1. **ReadJSONConfig**
    1. **RunExcelCloser**
1. Copy the code in the .txt files in `\source\` and paste it into Power Automate Desktop flow designer window into the appropriate subflows (see **Notes**):
    1. **main.txt** to the **Main** subflow
    1. **convert-tabular-config-to-custom-object.txt** to the **ConvertTabularConfigToCustomObject** subflow
    1. **read-database-config.txt** to the **ReadDatabaseConfig** subflow
    1. **read-excel-config.txt** to the **ReadExcelConfig** subflow
    1. **read-json-config.txt** to the **ReadJSONConfig** subflow
    1. **run-excel-closer.txt** to the **RunExcelCloser** subflow
1. Review the code for any syntax errors

    ![View of the code in the Main subflow in PAD](./assets/main-subflow-example.png)

1. Click **Save** in the flow designer
1. Add the **PADFramework: ConfigReaderLocalConnectors** flow to the **PADFramework** solution for exporting it to other environments

    ![View of the menu path to add an existing desktop flow to a solution](./assets/adding-existing-desktop-flow-to-solution.png)

1. When exporting to other environments, export it as a **Managed** solution, so that it can be used, but not modified. Logger should be managed even in DEV environments for other flows (see **Notes** below)
1. Create a config storage of your choice:
    1. If you decide to use a JSON config, try using a sample JSON config file provided in `/assets/` and build on it (optional, but recommended).
    1. If you want to use Dataverse for config, create a table in Dataverse with the following structure:
        
        ![View of a sample config table schema in Dataverse](./assets/dataverse-config-table-schema-example.png)

    1. If you want to use a Database for config, see the `/database-sql-server/` for sample code for setting up the database. It includes work item processing structures, but if you don't need those, you can focus on the tables, functions and procedures for configs only.
    1. If you want to use Excel for config, create an appropriate Excel file with a similar data structure to the samples above.

1. **Enjoy**

## Notes

### Environments

The Framework should have its own dedicated development environment. This is the only environment where the Framework should reside as an unmanaged solution. 

It should be imported as a managed solution to all other environments where flows will use the framework, including normal DEV, TEST, UAT and other non-production environments. This is so that changes cannot be made to the framework outside of its own DEV environment, but it can be used by calling utility flows such as the **ConfigReaderLocalConnectors** as child flows, as well as making copies of the template flows for new projects.

### Different types of configs

In most organizations, you would normally not want to have different types of storage for external configs being used across flows. It's best to pick one and stick to that. So, you do not actually need to create all of the subflows listed here, as this adds extra complexity where it is not necessary. Feel free to just go with the one type of config you prefer.

### Using other config types

This flow only supports reading configs from local files (Excel or JSON) and Database tables as these types do not require setting up connection references to the cloud and also do not require Premium, and does not require any connectors being allowed in the environment, which can prevent the solution from being imported to some environments, even if the user has Premium. Other types of configs based on Cloud connectors (SharePoint and Dataverse) are in a separate flow called **ConfigReaderLocalConnectors**.

It is recommended to only keep one of these utility flows, as configs should be stored universally within an organization anyway. So, pick your preferred way for storing configs and keep the one utility flow, while deleting the other one.

### Using direct SQL Statements vs Stored Procedures in SQL Server

Using Stored Procedures is the recommended approach when working with SQL Server, as SQL code is then handled by the database admin and it then becomes much easier to manage what a user or a group of users is allowed to do within the database. It requires actually creating those stored procedures, but it then enables much better governance.