Version 1.0
Created by Daniel Sonnenburg

Purpose:
1. Download appplications from web from a list provided in Download.json
2. Extract Zip files
3. Create ConfigMgr source directory structure based on internal naming schema.
	\\<Sever>\Source\Apps\<AppName>-<Version>
4. Create (a string) unattended command line for the ConfigMgr application
5. Create ConfigMgr Application
6. Create ConfigMgr Deployment Type (Install)