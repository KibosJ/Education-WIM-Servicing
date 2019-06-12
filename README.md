# Education WIM Servicing

**Ensure that you uncomment any parts of the script you don't need**

## What the script does?

- Asks for the name of the original WIM file (usually just install.wim)
- Asks for the name of the required WIM file
- Extracts the “Windows 10 Education” index from the original WIM file 
- Removes the original WIM file 
- Applies default app associations from AppAssociations.xml
- Disables Internet Explorer
- Enables .NET Framework 3.5 from relevant net35 folder 
- Modifies default registry settings
  - Customise explorer items
  - Disable lockscreen
  - Disable fast user switching
  - Customise taskbar/search settings
  - Customise cloud content settings
  - Customise content delivery manager settings
- Copies folders/files from *Root_Folders* to root of WIM
- Commits the new image
